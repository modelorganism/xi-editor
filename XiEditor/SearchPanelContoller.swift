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
    
    @IBOutlet var searchTextField: NSTextField!
    
    private var kvoContext: UInt8 = 1
    
    //TODO: change name this is just 'user hit enter'
    @IBAction func forceUpdate(sender: AnyObject?) {
        findNext()
    }
    
    @IBAction func findNext(sender: AnyObject?) {
        //forceUpdate()
        appMainDoc()?.editView.findNext()
    
    }
    
    @IBAction func findPrev(sender: AnyObject?) {
        //forceUpdate()
        findPrev()
    }

    private func forceUpdate() {
        appMainDoc()?.editView.updateSearch(searchInfo.getSeachSpec())
    }

    
    private func findPrev() {
        appMainDoc()?.editView.findPrev()
    }
    
    private func findNext() {
        appMainDoc()?.editView.findNext()
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
            appMainDoc()?.editView.updateSearch(searchInfo.getSeachSpec())
        }
    }
    
    /*
    @objc func performFindPanelAction(sender: AnyObject?) {
        guard let rawTag = sender?.tag else {
            return
        }
        guard let tag = NSTextFinderAction(rawValue: rawTag) else{
            return
        }
        switch tag {
        case NSTextFinderAction.NextMatch:
            findNext()
        case NSTextFinderAction.PreviousMatch:
            findPrev()
        default: ()
        }
    }*/
}
