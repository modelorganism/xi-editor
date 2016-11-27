//
//  SearchControler.swift
//  XiEditor
//
//  Created by Christopher Stern on 11/20/16.
//  Copyright © 2016 Raph Levien. All rights reserved.
//

import Cocoa


enum FindStrResponse {
    case Ok
    case BadGrep
}


class SearchController: NSWindowController{
    @IBOutlet var textField: NSTextField!
    @IBOutlet var regExpCheck: NSButton!
    @IBOutlet var caseCheck: NSButton!
    @IBOutlet var wholeWordCheck: NSButton!
    
    @IBAction func findNext(sender: AnyObject) {
        appDelegate?.searchNext()
    }
    @IBAction func findPrev(sender: AnyObject) {
        appDelegate?.searchPrev()
    }

    @IBAction func textAction(sender: AnyObject) {
        appDelegate?.forceSearch()
    }
    
    weak var appDelegate: AppDelegate?
    
    class SearchData: NSObject {
        dynamic var regExp = 0
        dynamic var matchCase = 0
        dynamic var wholeWord = 0
        
        dynamic var text : NSString? = ""
        
        dynamic var isError = false
    }
    dynamic var searchData : SearchData = SearchData()
    
    
    convenience init() {
        self.init(windowNibName: "SearchController")
    }

    private var kvoContext: UInt8 = 1

    override func windowDidLoad() {
        
        searchData.addObserver(self, forKeyPath: "regExp", options: NSKeyValueObservingOptions.New, context: &kvoContext)
        searchData.addObserver(self, forKeyPath: "matchCase", options: NSKeyValueObservingOptions.New, context: &kvoContext)
        searchData.addObserver(self, forKeyPath: "wholeWord", options: NSKeyValueObservingOptions.New, context: &kvoContext)
        searchData.addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.New, context: &kvoContext)
        
    }
    
    func setSearchString(s: String) {
        searchData.text = s
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kvoContext {
            let searchText : String
            if let sdt = searchData.text {
                searchText = sdt as String
            }
            else {
                searchText = ""
            }
            
            if let appDelegate = self.appDelegate {
                let sp = SearchParams(
                        isRegExp: searchData.regExp != 0,
                        matchCase:searchData.matchCase != 0,
                        wholeWordOnly:searchData.wholeWord != 0 )
                let fr = appDelegate.updateSearch(searchText, params: sp, force: false)
                switch fr {
                case .Ok:
                    searchData.isError = false
                case .BadGrep:
                    searchData.isError = true
                }
            }
        }
    }
    
     @objc func performFindPanelAction(sender: AnyObject?) {
        guard
            let appDelegate = self.appDelegate,
            let rawTag = sender?.tag,
            let tag = NSTextFinderAction(rawValue: rawTag)
            else {
                return
        }
        switch tag {
        case .NextMatch:
            appDelegate.searchNext()
        case .PreviousMatch:
            appDelegate.searchPrev()
        default: ()
        }
    }
 
    deinit {
        searchData.removeObserver(self, forKeyPath: "regExp")
        searchData.removeObserver(self, forKeyPath: "matchCase")
        searchData.removeObserver(self, forKeyPath: "wholeWord")
        searchData.removeObserver(self, forKeyPath: "text")
    }
}
