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
        appMainDoc()?.editView.selectFind(0)
    }
    
    @IBAction func findNext(sender: AnyObject?) {
        appMainDoc()?.editView.findNext()
    
    }
    
    @IBAction func findPrev(sender: AnyObject?) {
        findPrev()
    }

    private func forceUpdate(hard: Bool) {
        appMainDoc()?.editView.updateSearch(searchInfo.getSeachSpec(), hard: hard)
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
        s.searchInfo.addObserver(s, forKeyPath: "wholeWords", options: NSKeyValueObservingOptions.New, context: &s.kvoContext)
        s.searchInfo.addObserver(s, forKeyPath: "caseSensitive", options: NSKeyValueObservingOptions.New, context: &s.kvoContext)
        return s
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kvoContext {
            forceUpdate(true)
        }
    }
    
    @objc func performFindPanelAction(sender: AnyObject?) {
        guard
            let rawTag = sender?.tag,
            let tag = NSTextFinderAction(rawValue: rawTag)
            else {
                return
        }
        switch tag {
        case .NextMatch:
            findNext()
        case .PreviousMatch:
           findPrev()
        default: ()
        }
    }
    
    
    deinit {
        searchInfo.removeObserver(self, forKeyPath: "wholeWords")
        searchInfo.removeObserver(self, forKeyPath: "caseSensitive")
        searchInfo.removeObserver(self, forKeyPath: "searchText")
    }
    
}
