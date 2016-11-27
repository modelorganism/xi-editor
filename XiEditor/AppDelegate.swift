// Copyright 2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Cocoa

struct SearchParams {
    let isRegExp: Bool
    let matchCase: Bool
    let wholeWordOnly: Bool
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var dispatcher: Dispatcher?

    func applicationWillFinishLaunching(aNotification: NSNotification) {

        guard let corePath = NSBundle.mainBundle().pathForResource("xi-core", ofType: "")
            else { fatalError("XI Core not found") }

        let dispatcher: Dispatcher = {
            let coreConnection = CoreConnection(path: corePath) { [weak self] (json: AnyObject) -> Void in
                self?.handleCoreCmd(json)
            }

            return Dispatcher(coreConnection: coreConnection)
        }()

        self.dispatcher = dispatcher
    }
    
    func handleCoreCmd(json: AnyObject) {
        guard let obj = json as? [String : AnyObject],
            method = obj["method"] as? String,
            params = obj["params"]
            else { print("unknown json from core:", json); return }

        handleRpc(method, params: params)
    }

    func handleRpc(method: String, params: AnyObject) {
        switch method {
        case "update":
            if let obj = params as? [String : AnyObject], let update = obj["update"] as? [String : AnyObject] {
                guard let tab = obj["tab"] as? String
                    else { print("tab missing from update event"); return }
                
                for document in NSApplication.sharedApplication().orderedDocuments {
                    let doc = document as? Document
                    if doc?.tabName == tab {
                        doc?.update(update)
                    }
                }
            }
        case "alert":
            if let obj = params as? [String : AnyObject], let msg = obj["msg"] as? String {
                dispatch_async(dispatch_get_main_queue(), {
                    let alert =  NSAlert.init()
                    #if swift(>=2.3)
                        alert.alertStyle = .Informational
                    #else
                        alert.alertStyle = .InformationalAlertStyle
                    #endif
                    alert.messageText = msg
                    alert.runModal()
                });
            }
        default:
            print("unknown method from core:", method)
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    // Find/Replace 
    
    func applicationDidBecomeActive(notification: NSNotification) {
        if let newSearchText = NSPasteboard(name: NSFindPboard).stringForType(NSStringPboardType) {
            setSearchString(newSearchText)
        }
    }

    func applicationWillResignActive(notification: NSNotification) {
        let find_pboard = NSPasteboard(name: NSFindPboard)
        find_pboard.declareTypes([NSStringPboardType], owner: self)
        find_pboard.setString(self.searchText, forType: NSStringPboardType)
    }
    
    var searchWindowController : SearchController? = nil

    var searchText: String = ""
    var searchParams: SearchParams = SearchParams(
            isRegExp: false,
            matchCase: false,
            wholeWordOnly: false)
    
    // Show the search panel. As for cmd-f
    func showSearch()  {
        if searchWindowController==nil {
            self.searchWindowController = SearchController()
            self.searchWindowController!.appDelegate = self
        }
        if let searchWindowController = self.searchWindowController {
            searchWindowController.setSearchString(searchText)
            searchWindowController.showWindow(self)
            searchWindowController.window?.makeKeyAndOrderFront(self)
        }
    }
    
    // Set the search string as cmd-e dose with the current selection
    // This update is not comming from the search dlg, which calls updateSearch.
    // This update goes to the search dlg.
    func setSearchString(newSearchString: String) {
        searchText = newSearchString
        searchWindowController?.setSearchString(newSearchString)
        updateSearch2(true)
    }
    
    func getSearchString() -> String {
        return self.searchText
    }
    
    func autoSearch(searchText: String, params: SearchParams) -> Bool {
        return !params.isRegExp && searchText.characters.count > 2
    }
    
    /// Receives live notifications of changes in the search panel.
    func updateSearch(str: String, params: SearchParams, force: Bool) -> FindStrResponse {
        self.searchText = str
        self.searchParams = params
        
        return updateSearch2(false)
    }
    
    var searchDirty = false
    
    func updateSearch2 (force: Bool) -> FindStrResponse {
        // Comunicate the new search string/opts to the back end, thru the font doc.
        // The document that we are searching could be the 2nd window, if the find window is first.
        // This wouldn't be an issue if we hasn't let the find 'panel' become 'main' as well as 'key'.

        guard let doc1 = NSApp.orderedDocuments.first as? Document else {
            return FindStrResponse.Ok
        }
        
        //Auto-trigger the search/
        //Why is this here? Not in any of the other places that search winds thru?
        //Because the seach window contoler might never have come up. The user can still search with ⌘E, ⌘G
        
        if force || autoSearch(searchText, params: searchParams) {
            return doc1.updateSearch(searchText, params: searchParams)
        }
        else {
            self.searchDirty = true
            doc1.updateSearch("", params: searchParams)
            return FindStrResponse.Ok
        }
        
        //Swift.print("searching for \(text)")
    }
    
    func forceSearch() {
        updateSearch2(true)
    }
    
    // Select the next occurrence of the search string after the selection.
    func searchNext() {
        // The document that we are searching could be the 2nd window, if the find window is first.
        // This wouldn't be an issue if we hasn't let the find 'panel' become 'main' as well as 'key'.
        if let doc1 = NSApp.orderedDocuments.first as? Document {
            doc1.searchNext()
        }
    }
    func searchPrev() {
        // The document that we are searching could be the 2nd window, if the find window is first.
        // This wouldn't be an issue if we hasn't let the find 'panel' become 'main' as well as 'key'.
        if let doc1 = NSApp.orderedDocuments.first as? Document {
            doc1.searchPrev()
        }
    }
}

