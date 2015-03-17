//
//  RecentlySelectedProjectCacheManager.swift
//  XCAssetGenerator
//
//  Created by Bader on 9/13/14.
//  Copyright (c) 2014 Pranav Shah. All rights reserved.
//

import Foundation

let kRecentProjectsKey: String = "XCAssetGeneratorRecentProjects"
let MaximumCacheCapacity: Int = 10


class RecentlySelectedProjectMaintainer : NSObject {
    
    private var recentProjects: [XCProject]?
    
    required override init() {
        super.init()
//        self.__flushStoredProjects()
        self.loadRecentProjects()
    }
    
    
    // Return whether the selected project is suitable for script execution
    func isSelectedProjectValid() -> Bool {
        return (self.selectedProject()? != nil) ? ProjectValidator.isProjectValid(self.selectedProject()!) && self.selectedProject()!.hasValidAssetsPath()
                                                : false
    }

    // TODO: Too much state manipulation. fix it buddy yea? HEY? fix it.
    // TODO: ......
    // TODO: ...... Terrible .......
    // FIXME:
    func addProject(project newProject: XCProject) {
        self.addProject(project: newProject, index: 0)
    }
    
    func addProject(project newProject: XCProject, index: Int) {
        if let projectsList = recentProjects {
            
            if let index: Int = find(projectsList, newProject) {
                recentProjects!.removeAtIndex(index)
            }
            if projectsList.count == MaximumCacheCapacity {
                recentProjects!.removeLast()
            }
            recentProjects!.insert(newProject, atIndex: index)
            
        } else {
            recentProjects = [newProject]
        }
        
        self.storeRecentProjects()
    }

    
    func addProject(#url: NSURL) {
        var bookmark: Bookmark = BookmarkResolver.resolveBookmarkFromURL(url)
        addProject(project: XCProject(bookmark: bookmark))
    }
    
    func removeProject(#project: XCProject) {
        if let projectsList = recentProjects {
            
            if let index: Int = find(projectsList, project) {
                recentProjects!.removeAtIndex(index)
            }
        }
        self.storeRecentProjects()
    }
    
    
    private func cullStaleAssets() -> Void {
        self.recentProjects = self.recentProjects?.map { (project: XCProject) -> XCProject in
            return !project.hasValidAssetsPath() ? XCProject(bookmark: project.bookmark) : project
        }
        
    }
}


// MARK:- Recent Project Queries Interface
extension RecentlySelectedProjectMaintainer {
    
    func recentProjectsCount() -> Int {
        return self.recentProjects?.count ?? 0
    }
    
    // TODO: If i can remove this function, it would make alot more sense.
    func projects() -> [XCProject]? {
        return self.recentProjects
    }
    
    // Returns the currenly selected Project/most recently used project. nil if "cache" empty.
    func selectedProject() -> XCProject? {
        return recentProjects?.first
    }
    
    func projectAtIndex(index: Int) -> XCProject? {
        return recentProjects?[index]
    }
    
    func indexOfProject(project: XCProject) -> Int? {
        return (self.recentProjects != nil) ? find(self.recentProjects!,project) : nil
    }
    
    // Returns the title of the projects which will appear in the dropdown view
    func recentProjectsTitlesList() -> [String]? {
//        return self.recentProjects?.filter { project: XCProject -> Bool
//                return ProjectValidator.isProjectValid(project)
//            }.map { proj in
//                return proj.title + "  > " + proj.assetTitle
//        }
        return self.recentProjects { (project) -> Bool in
            return ProjectValidator.isProjectValid(project)
            }?.map({ (project: XCProject) -> String in
                return project.title + "  > " + project.assetTitle
        })
        
    }
    
    // Returns the most recent project matching the predicate indicated in the closure.
    private func recentProject(closure: (project: XCProject) -> Bool) -> XCProject? {
        let matches = self.recentProjects?.filter(closure)
        if matches?.count > 1 {
            println("[XCAssetGenerator] Houston, we have a problem. Found multiple projects for a check that should return one.")
        }
        
        return matches?.first
    }
    
    func recentProjects(filter: (project: XCProject) -> Bool) -> [XCProject]? {
        return self.recentProjects?.filter(filter)
    }
    
}

extension RecentlySelectedProjectMaintainer {
    func renameRecentProject(project: XCProject, name: Path) {
        if let projects = self.recentProjects {
            let index = self.indexOfProject(project)
            
            if let idx = index {
                self.recentProjects?.removeAtIndex(idx)
                self.recentProjects?.insert(XCProject(bookmark: project.bookmark), atIndex: idx)
                
                self.storeRecentProjects()
            }
        }
    }
}

extension RecentlySelectedProjectMaintainer {
   
    // TODO: Find better hooks for these calls.
    private func storeRecentProjects() {
        let projects = self.recentProjects?.map { (proj: XCProject) -> [NSString: NSData] in
            return proj.userDefaultsDictionaryRepresentation()
        }
        NSUserDefaults.standardUserDefaults().setObject(projects, forKey: kRecentProjectsKey)
    }
    
    /*
        Load Recent Projects.
        Summary: Loads projects and checks if any project bookmark or asset bookmark corruption
    */
    private func loadRecentProjects() {
        let projectDicts = NSUserDefaults.standardUserDefaults().objectForKey(kRecentProjectsKey) as? [[String: NSData]]

        let validProjectDicts = projectDicts?.filter { (dictionary: [String: NSData]) -> Bool in
            return BookmarkResolver.isBookmarkValid(dictionary[pathKey]! as Bookmark)
        }
        
        self.recentProjects = validProjectDicts?.map { (a: [String: NSData]) -> XCProject in
            let project = XCProject.projectFromDictionary(a as [String: NSData])
            return project.hasValidAssetsPath() ? project : XCProject(bookmark: project.bookmark)
        }

        self.storeRecentProjects()
    }
    
    private func __flushStoredProjects() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(kRecentProjectsKey)
    }
}