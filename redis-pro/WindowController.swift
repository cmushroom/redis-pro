//
//  WindowController.swift
//  redis-pro
//
//  Created by chengpan on 2022/5/16.
//

import Foundation
import Cocoa

class WindowController: NSWindowController {
    @IBAction override func newWindowForTab(_ sender: Any?) {
        let newWindowController = self.storyboard!.instantiateInitialController() as! WindowController
        let newWindow = newWindowController.window!
        
        // Add this line:
        newWindow.windowController = self
        
        self.window!.addTabbedWindow(newWindow, ordered: .above)
    }
}
