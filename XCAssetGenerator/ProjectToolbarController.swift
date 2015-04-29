//
//  ProjectController.swift
//  XCAssetGenerator
//
//  Created by Bader on 9/25/14.
//  Copyright (c) 2014 Bader Alabdulrazzaq. All rights reserved.
//

import Cocoa
import Result
import Box

protocol ProjectToolbarDelegate {
    func projectToolbarDidChangeProject(project: XCProject?)
}


class ProjectToolbarController: NSObject  {

    var recentProjectsDropdownListView: ProgressPopUpButton!
    var delegate : ProjectToolbarDelegate?
    
    private var directoryObserver: ProjectObserver!
    private let recentListMaintainer: RecentlySelectedProjectMaintainer
    private var panel: NSOpenPanel
    
    private let SelectedItemIndex: Int = 0
    
    var selectedProject: XCProject? {
        return recentListMaintainer.selectedProject
    }
    
    // MARK:- Initializers
    
    init(recentList: ProgressPopUpButton) {
        recentListMaintainer = RecentlySelectedProjectMaintainer()
        recentProjectsDropdownListView = recentList
        panel = NSOpenPanel()
        super.init()
        
        directoryObserver = ProjectObserver(delegate: self)
        
        panel.canChooseFiles            = true
        panel.allowedFileTypes          = ["xcodeproj"]
        panel.canChooseDirectories      = true
        panel.allowsMultipleSelection   = false
        dropdownListSetup()
        
    }
    
    // MARK: - Helpers
    
    private func setupError(message: String) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButtonWithTitle("OK")
        alert.alertStyle = NSAlertStyle.CriticalAlertStyle
        return alert
    }
    

    // MARK:- Public toolbar controller hooks.
    
    func browseButtonPressed() {
        panel.beginWithCompletionHandler() { (handler: Int) -> Void in
            if handler == NSFileHandlingPanelOKButton {
                let project = ProjectSelector.excavateProject(self.panel.URL!)
                switch project {
                case .Success(let box):
                    self.addNewProject(url: box.value)
                case .Failure(let box):
                    self.setupError(box.value.message).runModal() // (self.setupError <| box.value.message ).runModal()
                }
            }
        }
    }

   
    func recentProjectsListChanged(sender: NSPopUpButton) {
        // If we select a new project, proceed.
        let index = sender.indexOfSelectedItem
        if index != SelectedItemIndex {
            let idx = (recentListMaintainer.selectedProject != nil) ? index : index - 1 // This will never be called on index = 0
            recentListMaintainer.addProject(project: recentListMaintainer.projectAtIndex(idx)!)
            updateDropdownListTitles()
            delegate?.projectToolbarDidChangeProject(recentListMaintainer.selectedProject)
        }
    }
    
}

// MARK:- Dropdown list Management.
extension ProjectToolbarController {

    
    private func enableDropdownList() {
        recentProjectsDropdownListView.enabled     = true
        recentProjectsDropdownListView.alignment   = NSTextAlignment.LeftTextAlignment
        recentProjectsDropdownListView.alphaValue  = 1.0
    }
    
    private func disableDropdownList() {
        recentProjectsDropdownListView.removeAllItems()
        recentProjectsDropdownListView.addItemWithTitle(NSLocalizedString("Recent Projects", comment: ""))
        
        recentProjectsDropdownListView.enabled     = false
        recentProjectsDropdownListView.alignment   = NSTextAlignment.CenterTextAlignment
        recentProjectsDropdownListView.alphaValue  = 0.5 // lul.
    }
    
    private func dropdownListSetup() {
        recentProjectsDropdownListView.preferredEdge = NSMaxYEdge
        recentProjectsDropdownListView.setProgressColor(color: NSColor(calibratedRed: 0.047, green: 0.261, blue: 0.993, alpha: 1))
        
        if let titles = recentListMaintainer.recentProjectsTitlesList() where titles.count > 0 {
            // If we have recent projects, set them up and observe them.
            enableDropdownList()
            recentProjectsDropdownListView.addItemsWithTitles(recentListMaintainer.recentProjectsTitlesList()!)
            
            if (recentListMaintainer.selectedProject == nil) {
                insertPlaceholderProject()
            }
            
            let projects = recentListMaintainer.recentProjects { _ in true }
            for proj in projects! {
                directoryObserver.observeProject(proj)
            }
            
        } else {
            disableDropdownList()
        }
        
        delegate?.projectToolbarDidChangeProject(recentListMaintainer.selectedProject)

    }
    
    private func addNewProject(#url: NSURL) {
        recentListMaintainer.addProject(url: url)
        updateDropdownListTitles()
        
        if !recentProjectsDropdownListView.enabled {
            enableDropdownList() // We dont need to really call it after each addition. just the first one.
        }
        directoryObserver.observeProject(recentListMaintainer.selectedProject!)
        delegate?.projectToolbarDidChangeProject(recentListMaintainer.selectedProject)
    }
    
    
    // TODO: Why do we remove all items? its the recentUsedProjectsManager concern to maintain order for its cache. So either trust its decisions or dont use it.
    private func updateDropdownListTitles() -> Void {
        recentProjectsDropdownListView.removeAllItems()
        if let titles = recentListMaintainer.recentProjectsTitlesList() where titles.count > 0 {
            recentProjectsDropdownListView.addItemsWithTitles(titles)
            recentProjectsDropdownListView.selectItemAtIndex(SelectedItemIndex)
        } else {
            disableDropdownList()
        }
    }
    
    private func insertPlaceholderProject() {
        recentProjectsDropdownListView.insertItemWithTitle(NSLocalizedString("Select a project…", comment: ""), atIndex: SelectedItemIndex)
        recentProjectsDropdownListView.selectItemAtIndex(SelectedItemIndex)
    }
    
}


// MARK: Directory Observer Compliance
extension ProjectToolbarController: FileSystemObserverDelegate {
    
    func FileSystemDirectory(oldPath: String!, renamedTo newPath: String!) {
        
        let project = recentListMaintainer.recentProjects { (project) -> Bool in
            return oldPath.isXCProject() ? project.path == oldPath : oldPath.isAssetCatalog() ? project.assetPath == oldPath : false
        }?.first
        
        if let proj = project, let index = recentListMaintainer.indexOfProject(proj) {
            recentListMaintainer.removeProject(proj)
            recentListMaintainer.addProject(project: XCProject(bookmark: proj.bookmark), index: index)
        }
        
        directoryObserver.updatePathForObserver(oldPath: oldPath, newPath: newPath)
        updateDropdownListTitles()
    }

    
    func FileSystemDirectoryDeleted(path: String!) {
        
        let project = recentListMaintainer.recentProjects { project in
            return (path.isXCProject()) ? project.path == path : (path.isAssetCatalog()) ? project.assetPath == path : false
        }?.first
        
        let wasSelected = project == recentListMaintainer.selectedProject
        
        if let proj = project {
            recentListMaintainer.removeProject(proj)
        }
        updateDropdownListTitles()
        
        if wasSelected {
            insertPlaceholderProject()
            recentListMaintainer.resetSelectedProject()
        }
        delegate?.projectToolbarDidChangeProject(nil)
    }
    
    func FileSystemDirectoryError(error: NSError!) {
        // TODO:
    }
    
    
}

// MARK:- The Toolbars Embeded Progress Indicator Extenstion
extension ProjectToolbarController {
    
    func setToolbarProgress(#progress: CGFloat) {
        if progress > 0 {
            recentProjectsDropdownListView.setProgress(progress: progress)
        }
    }
    
    func resetToolbarProgress(completion: () -> ()) {
        recentProjectsDropdownListView.resetProgress(completion)
    }
    
    func setToolbarProgressColor(#color: NSColor) {
        recentProjectsDropdownListView.setProgressColor(color: color)
    }
}
