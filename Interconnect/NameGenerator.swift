//
//  NameGenerator.swift
//  Interconnect
//
//  Created by Stefan Kruger on 19/02/2015.
//  Copyright (c) 2015 Stefan Kruger. All rights reserved.
//

import Foundation

struct NameGenerator {
    static let source = ["Celsa","Linette","Treena","Roseanna","Olene","Alden","Cristopher","Antonina","Mikel","Danielle","Florence","Jackson","Lupe","Lucy","Alycia","Jenni","Mamie","Taunya","Gudrun","Jared","Ezra","Martina","Angelita","Burma","Donnette","Reba","Rubie","Osvaldo","Ian","Jeanie","Cherie","Fredericka","Malissa","Blair","Georgia","Nadia","Cary","Les","Roseann","Marceline","Corinne","Adeline","Mellissa","Celinda","Larraine","Nubia","Verla","Evie","Mana","Kourtney","Tresa","Sonny","Karlene","Rona","Sondra","Daniell","Emmanuel","Qiana","Tenisha","Kiesha","Carissa","Retta","Harris","Garrett","Riley","Avelina","Wally","Kristyn","Darcie","Piedad","Latrina","Jarrod","Natividad","Alycia","Karmen","Chante","Leif","Sherrie","Refugia","Corene","Renna","Saundra","Len","Marnie","Carroll","Jonah","Loree","May","Mayme","Logan","Ehtel","Yee","Sasha","Ryann","Ruthe","Jay","Sheri","Aiko","Shaunna","Eulalia"]
    
    
    static func name() -> String {
        let idx = Int(arc4random_uniform(UInt32(source.count)))
        return source[idx]
    }
}
