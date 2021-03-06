//
//  navComponent.swift
//  flickr-test
//
//  Created by Danila Puzikov on 17/04/2017.
//  Copyright © 2017 Danila Puzikov. All rights reserved.
//

import Foundation
import UIKit

class CollectionComponent: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var app:AppController;
    var cache:CacheService;
    var mainView:UIViewController;
    public typealias CompletionHandler = (_ success:[String:Any]) -> Void
    
    //VIEWS
    
    var loader:LoaderComponent?;
    var collectionView:UICollectionView?;
    var singleItem:SingleItemViewComponent?;
    
    //GENERAL PARAMS;
    let backgrounds_color = UIColor(red: 250, green: 254, blue: 253)
    var single_item_index = 0;
    var nav_height = 0;
    var images:[[String:Any]] = []
    var total_images:[[String:Any]] = []
    var imageCache:[String:Any] = [:]
    var total_loaded = 0;
    var total_displayed = 0;
    var prev_query = ""
    var current_scroll:CGPoint?;
    var is_reloading = false;
    var inverted_direction = false;
    var displayed_first_image = false;
    
    
    init(v:UIViewController, a:AppController){
        app = a;
        cache = a.cache!;
        mainView = v;
        nav_height = a.nav_height;
        
        super.init(nibName: nil, bundle: nil)
        view.frame = CGRect(x:0,y:nav_height-app.collection_inset_fix,width:Int(v.view.frame.width), height:Int(v.view.frame.height)-nav_height+app.collection_inset_fix)
        loader = LoaderComponent(v:self, a:a)
        initCollectionView()
        view.addSubview(loader!.view)
        print("INITIALIAZED SINGLE VIEW CONTROLLER")
    }
    
    func incrementSingleItem(_ direction:Int){
        if(direction < 0) { inverted_direction = true; }
        let cache_count = images.count
        var new_index = (single_item_index as Int) + direction
        if(new_index >= cache_count) { new_index = 0; }
        if(new_index < 0) { new_index = cache_count-1 }
        print("single item index = "+single_item_index.description)
        if(images[single_item_index]["url"] == nil) {
            incrementSingleItem(direction + direction);
            return;
        }
        single_item_index = new_index
        openSingleItem();
    }
    
    func openSingleItem() {
        let current = app.single_item_id
        print("new single item index = "+single_item_index.description)
        var item:[String:Any]? = images[single_item_index]
        if(item == nil) { return }
        if(item?["id"] == nil || current == item?["id"] as! String) { return }
        app.single_item_id = item?["id"] as! String
        
        if(singleItem != nil){
            removeSingleItem({ (res) in
                self.addSingleItem(item!)
                self.inverted_direction = false;
            })
            return;
        }
        addSingleItem(item!)
    }
    
    func addSingleItem(_ item:[String:Any]){
        singleItem = SingleItemViewComponent(v: self, a: app, data:item)
        let old_x = singleItem!.view.center.x
        var direction:CGFloat = 1.0
        if(inverted_direction == true) { direction = -1.0}
        singleItem!.view.center.x = old_x * 2.0 * direction
        view.addSubview(singleItem!.view)
        UIView.animate(withDuration: 0.15) {
            self.singleItem!.view.center.x = old_x;
        }
    }
    
    func removeSingleItem(_ done:CompletionHandler?){
        if(singleItem != nil) {
            var direction:CGFloat = -1.0
            if(inverted_direction == true) { direction = 1.0 }
            UIView.animate(withDuration: 0.15, animations: {
                self.singleItem!.view.center.x = self.singleItem!.view.center.x * 2.0 * direction
                
            }) { (d) in
                if(self.singleItem != nil) {
                    self.singleItem!.view.removeFromSuperview();
                    self.singleItem = nil;
                    if(done != nil) { done!([:]) }
                    else {
                        self.single_item_index  = 0;
                        self.app.single_item_id = "";
                        self.inverted_direction = false;
                    }
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func showLoader(_ query:String){
        view.backgroundColor = backgrounds_color
        if(prev_query != query) {
            self.cache.images = [:]
            self.collectionView?.removeFromSuperview()
            self.collectionView = nil
            collectionView?.isHidden = true;
        }
        else {
            return;
        }
        prev_query = query;
        loader?.setText("Loading "+query+"... ")
        loader?.show()
        loader?.view.isHidden = false;
    }
    
    func displayCollection(_ data:[[String:Any]]){
        print("LOADING COLLECTION")
        print("TOTAL COUNT = "+data.count.description)
        self.total_loaded = 0;
        self.total_displayed = 0;
        self.view.isHidden = false;
        let page = app.current_page
        cache.cacheCollection(data) { (image_cache) in
            print("EVERYTHING CACHED")
            print("TOTAL CACHED = "+self.cache.images.count.description)
            self.images = image_cache;
            self.initCollectionView()
        }
    }
    
    func initCollectionView(){
        DispatchQueue.main.async(execute: {
            let layout = UICollectionViewFlowLayout()
            var is_new = true;
            if(self.collectionView != nil){
                is_new = false;
                print("reloading collection view!")
                self.current_scroll = self.collectionView!.contentOffset
                self.collectionView?.reloadData()
            }
            else {
                print("creating collection view!")
                self.collectionView = UICollectionView(frame:self.view.frame, collectionViewLayout: layout);
                self.collectionView!.register(ImagePreview.self, forCellWithReuseIdentifier: "imgCell")
                self.collectionView!.backgroundColor = UIColor.clear
                self.collectionView!.delegate = self
                self.collectionView!.dataSource = self
                self.collectionView?.isHidden = false
                self.view.isHidden = true;
                self.view.addSubview(self.collectionView!)
                self.collectionView?.reloadData()
                self.displayed_first_image = false;
            }
            if(self.app.current_page != 1 && self.current_scroll != nil) {
                self.collectionView?.contentOffset = self.current_scroll!
            }
            self.loader?.hide()
            self.loader?.view.isHidden = true;
            self.view.isHidden = false;
            self.is_reloading = false;
        });
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = images[indexPath.row]
        let url = data["url"]
        let qu = prev_query
        var key = data["cache_key"]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imgCell", for: indexPath) as! ImagePreview
        if(cell.imageView == nil) { cell.awakeFromNib() }
        if(key != nil) {
            self.total_loaded += 1;
            let img = self.cache.memorizeImage(key as! String, nil)
            DispatchQueue.main.async(execute: {
                cell.imageView?.image = img
                if(self.loader!.view.isHidden == false
                    && self.total_loaded == Int(Double(self.images.count)/self.app.min_loaded_images)) {
                        self.loader?.hide()
                }
            });
            return cell;
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if(indexPath.row == 0 && singleItem == nil && displayed_first_image == false && collectionView.isHidden == false) {
            displayed_first_image = true;
            single_item_index = indexPath.row
            self.openSingleItem();
        }
        if(indexPath.row > self.cache.images.count/2 && is_reloading == false) {
            is_reloading = true;
            app.incrementPage();
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("did select #"+indexPath.row.description)
//        let data = images[indexPath.row]
        single_item_index = indexPath.row
        self.openSingleItem();
        self.app.view?.nav?.dismissKeyboard()
    }
    
}

class ImagePreview:UICollectionViewCell {
    var imageView:UIImageView?;
    override func awakeFromNib() {
        imageView = UIImageView(frame:contentView.frame)
        imageView!.contentMode = .scaleAspectFill
        imageView!.clipsToBounds = true
        contentView.addSubview(imageView!)
    }
    
}
