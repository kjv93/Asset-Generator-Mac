//
//  AssetCatalog.swift
//  XCAssetGenerator
//
//  Created by Bader on 10/6/14.
//  Copyright (c) 2014 Bader Alabdulrazzaq. All rights reserved.
//

import Foundation

func == (lhs: AssetCatalog, rhs: AssetCatalog) -> Bool {
    // TODO: This needs a rethink.
    if lhs.bookmark == rhs.bookmark { return true }
    
    switch ( ProjectValidator.isAssetValid(lhs), ProjectValidator.isAssetValid(rhs) ) {
    case (true, true): return lhs.path == rhs.path
    case (false, false): return true
    case (_,_): return false
    }
}

func == (lhs: AssetCatalog?, rhs: AssetCatalog?) -> Bool {
    switch (lhs, rhs) {
    case (.Some(let a), .Some(let b)): return a == b
    case (.None,.None): return true
    case (_,_): return false
    }
}


// The bookmark data canot be invalid in here. It doesnt make sense for an AssetCatalog to not exist.
// So, invalid data = crash. Protect.Yo.Self.
struct AssetCatalog: Equatable, Printable, Serializable {
    
    var bookmark: Bookmark
    let path: Path
    
    init (bookmark: Bookmark) {
        self.bookmark = bookmark
        self.path = BookmarkResolver.resolvePathFromBookmark(bookmark)!
    }
    
    init (bookmark: Bookmark, path: Path) {
        self.bookmark = bookmark
        self.path = path
    }
    
    var title: String {
        return path.lastPathComponent
    }
    
    // MARK: - Printable
    
    var description: String {
        return path
    }
    
    // MARK: - Serializable
    
    typealias Serialized = NSData
    
    var serialized: Serialized {
        return bookmark
    }
}