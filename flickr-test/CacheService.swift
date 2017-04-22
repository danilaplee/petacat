//
//  CacheService.swift
//  flickr-test
//
//  Created by Danila Puzikov on 18/04/2017.
//  Copyright © 2017 Danila Puzikov. All rights reserved.
//

import Foundation
import UIKit

class CacheService {
    var app:AppController?
    var fileManager:FileManager;
    var images:[String:Any] = [:]
    var total_faces = 0;
    var total_removed = 0;
    var harrasment_cache:[String:Any] = [:]
    var faces_cache:[String:Any] = [:]
    public typealias CompletionHandler = (_ success:[[String:Any]]) -> Void
    
    init(a:AppController) {
        app = a;
        fileManager = FileManager.default
    }
    
    func memorizeImage(_ key:String, _ path:String?) -> UIImage {
        if(images[key] != nil) { return images[key] as! UIImage }
        if(path == nil) { return UIImage(); }
        let data:Data       = NSData(contentsOfFile: path!)! as Data
        let compress:Data   = UIImageJPEGRepresentation(UIImage(data: data)!, 0.1)!
        let preview:UIImage = UIImage(data:compress)!
        return preview;
        
    }
    
    func initCacheDirectory() {
        do {
            let documents   = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let imageDir    = documents.appendingPathComponent("images", isDirectory: true)
            if(fileManager.fileExists(atPath: imageDir.path))
            {
            clearImageCache()
            return;
            }
            try fileManager.createDirectory(atPath: imageDir.path, withIntermediateDirectories: false, attributes: [:])
            }
            catch(let error){
            print("INIT CACHE DIR ERROR")
            print(error)
        }
    }
    
    func detectFace(_ path:String) -> Bool {
        if(faces_cache[path] != nil) { return true }
        do {
            guard let img       = UIImage(contentsOfFile: path) else { return true; }
            guard let faceImage = CIImage(image:img) else { return true; }
            let accuracy = [CIDetectorAccuracy:CIDetectorAccuracyHigh]
            let detector = CIDetector(ofType: CIDetectorTypeText, context: nil, options: accuracy)
            let faces    = detector?.features(in: faceImage)
            if(faces!.count == 0) { return false }
            total_faces += (faces?.count)!;
            faces_cache[path] = true;
            return true;
        }
    }
    
    func detectHarrasment(_ title:String) -> Bool {
        if(harrasment_cache[title] != nil) { return true }
        let _words:[String] = (app?.view?.nav?.banned_search)!;
        for (word) in _words {
            if(title.contains(word.lowercased())) {
                harrasment_cache[title] = true;
                return true
            }
        }
        return false;
    }
    
    func cacheCollection(images:[[String:Any]], done:@escaping CompletionHandler){
        let qu = app?.view?.col?.prev_query as! String;
        let per_page = app?.api?.per_page as! Int
        let current_page = app?.current_page as! Int
        let skip_barrier = 10
        if(current_page == 1) { total_removed = 0; }
        var new_img:[[String:Any]] = []
        self.total_faces = 0;
        let queue = DispatchQueue.global()
        queue.async() {
            var is_done   = false;
            let show_time = images.count as Int - 1
            var removed   = 0;
            print("STARTING CACHE TOTAL IMAGES = "+show_time.description )
            for(index, item) in images.enumerated() {
                var i   = item
                let url = item["url"]
                let title:String = (item["title"] as! String).lowercased()
                let imageView = UIImageView()
                imageView.imageFromUrl(url as! String, onload: { (response) in
                    if(is_done) { return; }
                    if(qu != self.app?.view?.col?.prev_query || self.app?.view?.col?.view?.isHidden == true) { return }
                    if(response == "false"
                        || response == "true"
                        || self.detectFace(response) == true
                        || self.detectHarrasment(title) == true)
                    {
                        print("REMOVED #"+index.description)
                        removed += 1;
                        print(removed.description+"/"+skip_barrier.description+"/"+self.total_removed.description)
                        if(removed - self.total_removed == skip_barrier && is_done == false) {
                            is_done = true;
                            self.total_removed += per_page
                            print("FILTERED THE WHOLE BATCH, RUNNING NEXT PAGE")
                            self.app?.incrementPage()
                        }
                        return;
                    }
                    let key = response.md5()
                    let img = self.memorizeImage(key, response)
                    i["cache_key"] = key
                    self.images[key] = img
                    new_img.append(i)
//                    print("CACHE STATUS: "+self.images.count.description+"/"+show_time.description)
                    if(self.images.count >= show_time-removed && is_done == false) {
                        is_done = true;
                        self.total_removed += removed;
                        print("collection cache done")
                        print("total images/faces = "+new_img.count.description+"/"+self.total_faces.description)
                        print("removed "+(images.count - new_img.count).description+" images")
                        DispatchQueue.main.async(execute: {
                            done(new_img)
                        });
                    }
                });
                
            }
        }
    }
    
    func clearImageCache(){
        let queue = DispatchQueue.global()
        queue.async() {
            do {
                self.images = [:]
                let documents   = try self.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let imageDir    = documents.appendingPathComponent("images", isDirectory: true)
                try self.fileManager.removeItem(at: imageDir)
                try self.fileManager.createDirectory(atPath: imageDir.path, withIntermediateDirectories: false, attributes: [:])
            }
            catch(let error){
                print("CACHE CLEARING ERROR")
                print(error)
            }
        }
    }
}
