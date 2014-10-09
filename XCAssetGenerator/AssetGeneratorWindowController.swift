//
//  AssetGeneratorWindowController.swift
//  XCAssetGenerator
//
//  Created by Bader on 9/15/14.
//  Copyright (c) 2014 Pranav Shah. All rights reserved.
//

import Cocoa

// TODO: the script option passing seems hacky and rushed. Revisit it later.

class AssetGeneratorWindowController: NSWindowController, NSToolbarDelegate, ScriptParametersDelegate, NSWindowDelegate {

    @IBOutlet var recentlyUsedProjectsDropdownList: ProgressPopUpButton!
    @IBOutlet var browseButton: NSButton!
    
    var generateButton: NSButton
    
    var assetGeneratorController: AssetGeneratorViewController!
    
    var generate1xButton: NSButton
    
    
    required init(coder: NSCoder!) {
        generateButton = NSButton()
        generate1xButton = NSButton()
        super.init(coder: coder)
    }
    
 
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window.delegate = self
        self.assetGeneratorController = self.contentViewController as AssetGeneratorViewController
        self.assetGeneratorController.setRecentListDropdown(self.recentlyUsedProjectsDropdownList)
        self.assetGeneratorController.parametersDelegate = self
        self.buttonSetup()
    }
    
    //
    func buttonSetup() {
        // Generate button setup
        self.generateButton.font                = self.browseButton.font // lolwut. Brogramming (tm)
        self.generateButton.title               = "Generate"
        self.generateButton.state               = true
        self.generateButton.target              = self
        self.generateButton.action              = Selector("generateButtonPressed")
        self.generateButton.bordered            = true
        self.generateButton.continuous          = false
        self.generateButton.bezelStyle          = NSBezelStyle.RoundedBezelStyle
        self.generateButton.transparent         = false
        self.generateButton.autoresizesSubviews = true
        self.generateButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.generateButton.setButtonType(NSButtonType.MomentaryLightButton)
        self.updateGenerateButton()
        self.window.contentView.addSubview(self.generateButton)
        
        let contraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:[generateButton(buttonWidth)]-offsetLeft-|", options: nil, metrics: ["offsetLeft": 10,"buttonWidth": 90], views: ["generateButton": generateButton])
        let contraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:[generateButton]-offsetBottom-|", options: nil, metrics: ["offsetBottom": 8], views: ["generateButton": generateButton])
        
        self.window.contentView.addConstraints(contraintH)
        self.window.contentView.addConstraints(contraintV)
        
        // Generate1x Radio button Setup
        self.generate1xButton.title                 = "Create @1x, @2x"
        self.generate1xButton.state                 = 0
        self.generate1xButton.target                = self
        self.generate1xButton.bordered              = false
        self.generate1xButton.bezelStyle            = NSBezelStyle.RoundRectBezelStyle
        self.generate1xButton.transparent           = false
        self.generate1xButton.focusRingType         = NSFocusRingType.None
        self.generate1xButton.autoresizesSubviews   = true
        self.generate1xButton.translatesAutoresizingMaskIntoConstraints = false
        self.generate1xButton.setButtonType(NSButtonType.SwitchButton)
        
        self.window.contentView.addSubview(self.generate1xButton)
        
        let Hcontraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-offsetLeft-[generate1xButton(buttonWidth)]", options: nil, metrics: ["offsetLeft": 20,"buttonWidth": 180], views: ["generate1xButton": generate1xButton])
        let Vcontraint = NSLayoutConstraint.constraintsWithVisualFormat("V:[generate1xButton]-offsetBottom-|", options: nil, metrics: ["offsetBottom": 8,"buttonHeight": 30], views: ["generate1xButton": generate1xButton])
        
        self.window.contentView.addConstraints(Hcontraint)
        self.window.contentView.addConstraints(Vcontraint)
    }
    
    func generateButtonPressed() {
        let generateMissingAssets: Bool = Bool(generate1xButton.state)
        
        self.assetGeneratorController.generateButtonPressed(generateAssets: generateMissingAssets, args: nil)
        self.updateGenerateButton()
    }

    
    
    // MARK:- Convenience Functions.
    
    func updateGenerateButton() -> Void {
        self.generateButton.enabled = self.assetGeneratorController.canExecuteScript()
    }
    
    
    // MARK:- IBAction outlets
    
    @IBAction func recentlyUsedProjectsDropdownListChanged(sender: ProgressPopUpButton!) {
        self.assetGeneratorController.recentlyUsedProjectsDropdownListChanged(sender)
    }
    
    @IBAction func browseButtonPressed(sender: AnyObject!) {
        self.assetGeneratorController.browseButtonPressed()
    }
    
    
    // MARK:- ScriptParameters Delegate
    
    func scriptParametersChanged(controller: AssetGeneratorViewController) {
        self.updateGenerateButton()
    }
    
    func windowDidBecomeKey(notification: NSNotification!) {
        self.assetGeneratorController.controllerDidBecomeActive()
    }
    
}
