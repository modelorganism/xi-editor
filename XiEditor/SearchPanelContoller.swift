//
//  SearchPanelContoller.swift
//  XiEditor
//
//  Created by Christopher Stern on 11/28/16.
//  Copyright © 2016 Raph Levien. All rights reserved.
//

import Cocoa


class SearchPanelContoller: NSWindowController {

    dynamic var searchInfo: SearchInfo!
    var appDelegate: AppDelegate!
    
     convenience init() {
        self.init(windowNibName: "SearchPanel")
    }
    
    private var kvoContext: UInt8 = 1
    
    @IBAction func findNext(sender: AnyObject?) {
        appMainDoc()?.editView.findNext()
    
    }
    
    @IBAction func findPrev(sender: AnyObject?) {
        appMainDoc()?.editView.findPrev()
    }
    
    private func appMainDoc() -> AppWindowController? {
        return NSApplication.sharedApplication().mainWindow?.delegate as? AppWindowController
    }
    
    // This should be an init(), but is not at the moment to avoid messing up the default inits.
    class func make(searchInfo: SearchInfo, appDelegate: AppDelegate) -> SearchPanelContoller {
        let s = SearchPanelContoller()
        s.searchInfo = searchInfo
        s.appDelegate = appDelegate
        s.searchInfo.addObserver(s, forKeyPath: "searchText", options: NSKeyValueObservingOptions.New, context: &s.kvoContext)
        searchInfo
        return s
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kvoContext {
            let searchText = searchInfo.searchText as? String ?? ""
            appMainDoc()?.editView.updateSearch(searchText)
        }
    }
}

