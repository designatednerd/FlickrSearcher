//
//  NSStringExtension.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 12/9/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

import UIKit

extension NSString {
  
  class func flk_pathToDocumentsDirectory() -> String {
    return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).last! as String
  }
  
  /**
  Grabs the path of a sub-directory of the documents directory, creating it if needed.
  
  - parameter subdirectoryName: The name of the sub-directory
  - returns: The path of the existing or created sub-directory.
  */
  public class func flk_createdDocumentsSubdirectory(subdirectoryName: String) -> String {
    let docs = flk_pathToDocumentsDirectory()
    let subdirectory = (docs as NSString).stringByAppendingPathComponent(subdirectoryName)
    
    subdirectory.flk_createDirectoryIfNeeded()
    
    return subdirectory
  }
  
  func flk_createDirectoryIfNeeded() {
    if !NSFileManager.defaultManager().fileExistsAtPath(self as String) {
      var error: NSError?
      do {
        try NSFileManager.defaultManager().createDirectoryAtPath(self as String,
          withIntermediateDirectories: true,
          attributes: nil)
      } catch let error1 as NSError {
        error = error1
      }
      
      if let unwrappedError = error {
        NSLog("Error creating directory \(self): \(unwrappedError)")
      }
    } //else it already exists.
  }
}
