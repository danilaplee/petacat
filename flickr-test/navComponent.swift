//
//  navComponent.swift
//  flickr-test
//
//  Created by Danila Puzikov on 17/04/2017.
//  Copyright © 2017 Danila Puzikov. All rights reserved.
//

import Foundation
import UIKit

class NavComponent: UIViewController, UISearchBarDelegate {
    
    //DEPENDENCY INJECTION
    var app:AppController?
    var mainView:UIViewController?
    
    //VIEWS
    var search:UISearchBar?
    var back_button:UIImageView?
    var fav_button:UIImageView?
    var back_title:UITextView?
    
    // CONSTANTS
    var frame_height = 65;
    let release_timer = 3.0;
    let default_search_text = "Try Cats"
    let background_color = UIColor(red: 198, green: 198, blue: 203)
    
    //GENERAL PARAMS
    var screen_bounds:CGRect?
    var frame_portrait:CGRect?
    var frame_horizontal:CGRect?
    var search_frame:CGRect?
    
    //DYNAMIC PARAMS
    var prev_search:String = ""
    
    //UI SERVICES
    var release_service:Timer?
    
    func calcViewFrames() {
        let w_int = Int(screen_bounds!.width)
        let h_int = Int(screen_bounds!.height)
        let offset_y = 20
        
        frame_portrait = CGRect(x:0,y:0,width:w_int, height:frame_height)
        frame_horizontal = CGRect(x:0,y:0,width:h_int, height:frame_height)
        
        //SEARCH FRAME
        var s_offset_x  = 0
        var s_width     = w_int
        
        if(back_button?.isHidden == false) {
            s_offset_x = Int(back_button!.frame.width);
            s_width = w_int - s_offset_x;
        }
        if(fav_button?.isHidden == false) {
            s_width = s_width - Int(fav_button!.frame.width)
        }
        
        search_frame = CGRect(x:s_offset_x, y:offset_y, width:s_width, height:frame_height-offset_y)
    }
    
    init(v:UIViewController, a:AppController)
    {
        
        super.init(nibName: nil, bundle: nil)
        
        //DEPENDENCY INJECTION
        app = a;
        mainView = v
        frame_height = a.nav_height;
        
        //INITIALIZE GENERAL PARAMS
        screen_bounds = UIScreen.main.bounds
        calcViewFrames()
        
        //INIT VIEWS
        
            //MAIN VIEW
            view.frame = frame_portrait!;
            view.backgroundColor = background_color;
        
            //ADDITIONAL VIEWS
        
                //SEARCH BAR
                search = UISearchBar(frame: search_frame!)
                search?.placeholder = default_search_text;
                search?.isUserInteractionEnabled = true;
                search?.barStyle = .default
                search?.delegate = self;
                view.addSubview(search!)
        
            //
        
        //END VIEWS
        
        print("INITIALIAZED NAV")
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("NAV DID LOAD")
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //SEARCH
    
    func startSearch(){
        let text = search!.text!
        if(text == "") { app?.hideCollectionView() }
        if(text == "" || prev_search == text) { return }
        prev_search = text;
        app!.api!.searchFullText(text, 1)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async(execute: {
            self.release_service?.invalidate()
        });
        startSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        startSearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        DispatchQueue.main.async(execute: {
            self.release_service?.invalidate()
            self.release_service = Timer.scheduledTimer(timeInterval: self.release_timer, target: self, selector:#selector(self.startSearch), userInfo: nil, repeats: true)
        });
    }
    
    //END SEARCH
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
