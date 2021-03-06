//
//  Extentions.swift
//  flickr-test
//
//  Created by Danila Puzikov on 17/04/2017.
//  Copyright © 2017 Danila Puzikov. All rights reserved.
//

import UIKit;
import Foundation


extension UIColor
{
    convenience init(red: Int, green: Int, blue: Int)
    {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int)
    {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

extension String
{
    func replace(_ key:String , _ value:String ) -> String {
        return self.replacingOccurrences(of: key, with: value)
    }
    subscript(pos: Int) -> String {
        precondition(pos >= 0, "character position can't be negative")
        return self[pos...pos]
    }
    subscript(range: Range<Int>) -> String {
        precondition(range.lowerBound >= 0, "range lowerBound can't be negative")
        let lowerIndex = index(startIndex, offsetBy: range.lowerBound, limitedBy: endIndex) ?? endIndex
        return self[lowerIndex..<(index(lowerIndex, offsetBy: range.count, limitedBy: endIndex) ?? endIndex)]
    }
    subscript(range: ClosedRange<Int>) -> String {
        precondition(range.lowerBound >= 0, "range lowerBound can't be negative")
        let lowerIndex = index(startIndex, offsetBy: range.lowerBound, limitedBy: endIndex) ?? endIndex
        return self[lowerIndex..<(index(lowerIndex, offsetBy: range.count, limitedBy: endIndex) ?? endIndex)]
    }
}

extension UIImageView
{
    public typealias CompletionHandler = (_ success:String) -> Void
    
    
    public func imageFromUrl(_ urlString: String, onload:@escaping CompletionHandler)
    {
        do {
            let fileManager = FileManager.default
            let documents = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileName    = urlString.md5()+".jpeg"
            let imageDir    = documents.appendingPathComponent("images", isDirectory: true)
            let fileString  = imageDir.appendingPathComponent(fileName)
            if(fileManager.fileExists(atPath: fileString.path))
            {
                onload(fileString.path)
                return;
            }
            URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
                if(error != nil || data == nil){
                    print("error on load")
                    print(error)
                    onload("false")
                    return;
                }
                do {
                    if(fileManager.fileExists(atPath: fileString.path))
                    {
                        try fileManager.removeItem(atPath: fileString.path)
                    }
                    try fileManager.createFile(atPath: fileString.path, contents: data as! Data, attributes: [:])
                    onload(fileString.path)
                }
                catch(let error){
                    print(error)
                    onload("false")
                }
            }.resume()
        }
        catch(let error){
            print(error)
            onload("false")
        }
    }
}
