//
//  ViewController.swift
//  Interconnect
//
//  Created by Stefan Kruger on 18/02/2015.
//  Copyright (c) 2015 Stefan Kruger. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    var data          = [String]()
    var searchResults = [String]()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBAction func reload(sender: AnyObject) {
        // Pull data from remote
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        cloudant!.startPullReplicationWithHandler( { [unowned self] in
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.reloadFromDatastore()
            }
        }, errorHandler: nil)
    }
    
    @IBAction func add(sender: AnyObject) {
        let name = NameGenerator.name()
        data.append(name)
        
        cloudant!.save(["name": name], error: nil)
        cloudant!.startPushReplicationWithHandler({ }, errorHandler: nil)
        
        // Reload the data outside the replication callback; we've already added the item to
        // the model array. This should make the interface more responsive.
        tableView.reloadData()
    }
    
    func reloadFromDatastore() {
        // Read all documents from the database, store in 'data'
        
        let results = cloudant!.query([:])
        
        data = [String]()
        
        results?.enumerateObjectsUsingBlock { (obj, _, _) in
            if let name = obj.body()["name"] as? String {
                self.data.append(name)
            }
        }
        
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        reload(self)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Note: _must_ use self.tableView instead of just tableView here - the search display tableview doesn't know
        // how to dequeue a cell.
        
        var item: String
        let cell = self.tableView.dequeueReusableCellWithIdentifier("basicCell", forIndexPath: indexPath) as UITableViewCell
        if tableView == searchDisplayController?.searchResultsTableView! {
            item = searchResults[indexPath.row]
        } else {
            item = data[indexPath.row]
        }
        
        cell.textLabel?.text = item
        
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchDisplayController?.searchResultsTableView {
            return searchResults.count
        }
        
        return data.count
    }
    
    // MARK: - UISearchDisplayController Delegate
    
    func filterContentForSearchString(searchText:String) {
        searchResults = data.filter {
            $0.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
        }
    }
    
    // Search text changed
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String) -> Bool {
        filterContentForSearchString(searchString)
        return true
    }
    
}

