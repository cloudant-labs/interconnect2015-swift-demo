//  Cloudant.swift
//
//  Interconnect demo
//
//  Swift-wrapper for Cloudant's CDTDatastore. See https://github.com/cloudant/CDTDatastore
//
//
//  Created by Stefan Kruger on 18/02/2015.
//  Copyright (c) 2014 Stefan Kruger. All rights reserved.

import Foundation

typealias handlerBlock = () -> Void

/// Required glue code to make NSFastEnumeration types work in Swift

extension CDTQueryResult: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

/// Swift-wrapper for Cloudant's CDTDatastore. See https://github.com/cloudant/CDTDatastore

class Cloudant: NSObject, CDTReplicatorDelegate {
    
    /**
    Abstraction for a Cloudant connection dealing with bi-directional replication and indexing.
    */
    
    var username    = ""
    var apiPassword = ""
    var apiKey      = ""
    var database    = ""

    var manager: CDTDatastoreManager?
    var datastore: CDTDatastore?
    var replicatorFactory: CDTReplicatorFactory?
    var replicator: CDTReplicator?
    var replHandler: handlerBlock?
    var indexManager: CDTIndexManager?
    var pullReplication: CDTPullReplication?
    var pushReplication: CDTPushReplication?
    
    var urlBase:String {
        return "https://\(apiKey):\(apiPassword)@\(username).cloudant.com/\(database)"
    }
    
    /**
    
    Create a Cloudant instance talking to a specified database.
    
    :param: database The name of the Cloudant database
    :param: username Account owner
    :param: key API key
    :param: password API password
    
    */
    
    convenience init?(database:String, username:String, key:String, password:String, error: NSErrorPointer) {
        self.init()
        
        self.database    = database
        self.username    = username
        self.apiKey      = key
        self.apiPassword = password
        
        
        // Set up the local data store
        var err: NSError?
        
        let fileManager  = NSFileManager.defaultManager()
        let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
        let storeURL     = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
        let path         = storeURL.path
        
        manager = CDTDatastoreManager(directory: path, error: &err)
        if manager == nil {
            if error != nil {
                if let err = err {
                    println("Error creating datastore manager: \(err.localizedDescription)")
                    error.memory = err
                }
            }
            return nil
        }
        
        datastore = manager!.datastoreNamed(database, error: &err)
        if datastore == nil {
            if error != nil {
                if let err = err {
                    println("Error creating datastore: \(err.localizedDescription)")
                }
                error.memory = err
            }
            return nil
        }
        
        indexManager = CDTIndexManager(datastore: datastore, error: &err)
        if indexManager == nil {
            if error != nil {
                if let err = err {
                    println("Error creating index manager: \(err.localizedDescription)")
                }
                error.memory = err
            }
            return nil
        }
        
        // Create replicator factory
        replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
        
        // We need at least one index in order to use Cloudant Query. We put an index on the guaranteed to exist field "_id"
        datastore!.ensureIndexed(["_id"], withName: "all")
    }
    
    /**
    
    Start a pull replication - Cloudant -> local database
    
    :param: completionHandler Closure to run on completion: () -> Void
    
    */
    
    func startPullReplicationWithHandler(completionHandler: handlerBlock) {
        var error: NSError?
        
        // Make a pull replicator, with ourself as the delegate. Note: must keep strong reference to the replication
        pullReplication = CDTPullReplication(source: NSURL(string: urlBase), target: datastore)
        replicator = replicatorFactory!.oneWay(pullReplication, error: &error)
        if let err = error {
            println("Error creating replicator: \(err.localizedDescription)")
            return
        }
        
        replHandler = completionHandler
        
        replicator!.delegate = self
        
        replicator!.startWithError(&error)
        if let err = error {
            println("Error starting replicator: \(err.localizedDescription)")
            return
        }
    }
    
    /**
    
    Start a push replication - local database-> Cloudant
    
    :param: completionHandler Closure to run on completion: () -> Void
    
    */
    
    func startPushReplicationWithHandler(completionHandler: handlerBlock) {
        var error: NSError?
        
        // Make a pull replicator, with ourself as the delegate. Note: must keep strong reference to the replication
        pushReplication = CDTPushReplication(source: datastore, target: NSURL(string: urlBase))
        replicator = replicatorFactory!.oneWay(pushReplication, error: &error)
        if let err = error {
            println("Error creating replicator: \(err.localizedDescription)")
            return
        }
        
        replHandler = completionHandler
        
        replicator!.delegate = self
        
        replicator!.startWithError(&error)
        if let err = error {
            println("Error starting replicator: \(err.localizedDescription)")
            return
        }
    }
    
    /**
    
    Bi-directional sync - pull-push. Posts a notification CDTSyncCompleted on successful completion.
    
    */
    
    func sync() {
        startPullReplicationWithHandler { [ unowned self ] in
            self.startPushReplicationWithHandler {
                NSNotificationCenter.defaultCenter().postNotificationName("CDTSyncCompleted", object: nil)
            }
        }
    }
    
    /**
    
    Create a new document and save it in the local database. Note that it will not be pushed automatically.
    
    :param: body NSDictionary describing the document
    :returns: the new document as a CDTDocumentRevision?
    
    */
    
    func save(body: NSDictionary, error: NSErrorPointer) -> CDTDocumentRevision? {
        var mrev = CDTMutableDocumentRevision()
        mrev.setBody(body)
        var err: NSError?
        
        let revision = datastore!.createDocumentFromRevision(mrev, error: &err)
        if revision == nil {
            if let err = err {
                println("An error occurred saving to the database: \(err.localizedDescription)")
                if error != nil {
                    error.memory = err
                }
            }

            return nil
        }
        
        updateIndexes()
        
        return revision
    }
    
    /**
    
    Fetch a document on document id.
    
    :param: docid Document id
    :returns: the document as a CDTDocumentRevision?
    
    */
    
    func document(docid: String, error: NSErrorPointer) -> CDTDocumentRevision? {
        var err: NSError?
        let retrieved = datastore!.getDocumentWithId(docid, error: &err)
        if retrieved == nil {
            if let err = err {
                println("An error occurred saving to the database: \(err.localizedDescription)")
                if error != nil {
                    error.memory = err
                }
            }
            
            return nil
        }
        
        return retrieved
    }
    
    // MARK: - Indexing & querying
    
    func updateIndexes() {
        var error: NSError?
        self.indexManager?.updateAllIndexes(&error)
        
        if let err = error {
            println("Error updating indexes: \(err.localizedDescription)")
        }
    }
    
    func query(parameters: NSDictionary) -> CDTQResultSet? {
        
        if let resultset = datastore!.find(parameters) {
            return resultset
        }
        
        return nil
    }
    
    // MARK: - CDTReplicatorDelegate
    
    func replicatorDidComplete(replicator: CDTReplicator?) {
        if let replicator = replicator {
            if let handler = replHandler {
                handler()
            }
        }
    }
    
    func replicatorDidChangeProgress(replicator: CDTReplicator?) {
        
    }
    
    func replicatorDidChangeState(replicator: CDTReplicator?) {
        
    }
    
    func replicatorDidError(replicator: CDTReplicator?, info: NSError!) {
        if let replicator = replicator {
            let state = CDTReplicator.stringForReplicatorState(replicator.state)
            println("\(state): \(info.localizedDescription)")
        } else {
            println(info.localizedDescription)
        }
    }
}


