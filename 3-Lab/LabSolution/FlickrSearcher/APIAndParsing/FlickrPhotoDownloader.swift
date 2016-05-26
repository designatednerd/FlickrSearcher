//
//  FlickrPhotoDownloader.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 12/1/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

import UIKit

private let _singletonInstance = FlickrPhotoDownloader()

/**
Class to handle the downloading of photos in the background. 
*/
public class FlickrPhotoDownloader {
  
  let downloadQueue = NSOperationQueue()
  
  init() {
    downloadQueue.maxConcurrentOperationCount = 5
  }
  
  /**
  - returns: Singleton instance.
  */
  public class func sharedInstance() -> FlickrPhotoDownloader {
    return _singletonInstance
  }
  
  /**
  Deletes any existing downloaded images.
  */
  public class func nukeDownloadedImagesFolder() {
    let path = FlickrDownloadOperation.pathToPhotoDownloadDirectory()
    var error: NSError?
    
    do {
      try NSFileManager.defaultManager().removeItemAtPath(path)
    } catch let error1 as NSError {
      error = error1
    }
    
    assert(error == nil)
  }
  
  /**
  Just download the image with a completion block.
  
  - parameter urlString:  The URL String to cache the image for.
  - parameter completion: The completion block to fire when done.
  */
  public func downloadImageFromURLString(urlString: String, completion: () -> ()) {
    let download = FlickrDownloadOperation(urlString: urlString, completion: completion)
    self.downloadQueue.addOperation(download)
  }
  
  /**
  Sets an image downloaded from a given URL to a given imageView.
  
  - parameter urlString: - The URL of the image as a string.
  - parameter imageView: - The imageView to set the image on.
  */
  func setImageFromURLString(urlString: String, toImageView imageView: UIImageView) {
    //See if a cached image exists
    let cachedImage = FlickrDownloadOperation.cachedImageForURLString(urlString)
    
    if let unwrappedImage = cachedImage {
      //Set the image immediately
      imageView.image = unwrappedImage
    } else {
      //Download the image in the background.
      let download = FlickrDownloadOperation(urlString: urlString, imageView: imageView)
      downloadQueue.addOperation(download)
    }
  }
  
  /**
  Cancels setting the image to the image view in any operation - will allow the download to complete.
  
  - parameter imageView: - The image view to cancel setting images on.
  */
  func cancelSetToImageView(imageView: UIImageView) {
    let imageViewOperations = downloadQueue.operations as! [FlickrDownloadOperation]
    for operation in imageViewOperations {
      if operation.imageView == imageView {
        operation.imageView = nil
      }
    }
  }
}

//MARK: - Mock Downloader

private let _mockSingletonInstance = MockPhotoDownloader()

public class MockPhotoDownloader : FlickrPhotoDownloader {
  
  override public class func sharedInstance() -> FlickrPhotoDownloader {
    return _mockSingletonInstance
  }
  
  /**
  - parameter urlString: The full URL string for the given photo.
  - returns: The path within the main bundle for the mock resource. 
  */
  public class func mockImageDataPathForURLString(urlString: String) -> String? {
    let fullDownloadPath = FlickrDownloadOperation.downloadDirectoryPathForURLString(urlString)
    let lastPath = (fullDownloadPath as NSString).lastPathComponent
    let lastPathExtension = (lastPath as NSString).pathExtension
    let lastPathSansExtension = (lastPath as NSString).stringByDeletingPathExtension
    
    let localPath = NSBundle.mainBundle().pathForResource(lastPathSansExtension, ofType: lastPathExtension)
    return localPath
  }
  
  override func setImageFromURLString(urlString: String, toImageView imageView: UIImageView) {
    //See if a cached image exists
    let cachedImage = FlickrDownloadOperation.cachedImageForURLString(urlString)
    
    if let unwrappedImage = cachedImage {
      //Set the image immediately
      imageView.image = unwrappedImage
    } else {
      //Move the image over from the fake data folder
      if let unwrappedLocalPath = MockPhotoDownloader.mockImageDataPathForURLString(urlString) {
        let targetPath = FlickrDownloadOperation.downloadDirectoryPathForURLString(urlString)
        var error: NSError?
        do {
          try NSFileManager.defaultManager().copyItemAtURL(NSURL(fileURLWithPath: unwrappedLocalPath),
            toURL: NSURL(fileURLWithPath: targetPath))
        } catch let error1 as NSError {
          error = error1
        }
        
        if let unwrappedError = error {
          NSLog("Error moving file to target path: \(unwrappedError)")
        } else {
          let cachedImageAfterMove = FlickrDownloadOperation.cachedImageForURLString(urlString)
          if let unwrappedCachedAfterMove = cachedImageAfterMove {
            imageView.image = unwrappedCachedAfterMove
          } else {
            NSLog("No image after moving!")
          }
        }
      } //else nothing to set.
    }
  }
}

private class FlickrDownloadOperation : NSOperation {
  
  var urlString: String
  var imageView: UIImageView?
  var completion: (() -> ())?
  
  init(urlString inUrlString: String, imageView inImageView: UIImageView) {
    urlString = inUrlString
    imageView = inImageView
  }
  
  init(urlString inURLString: String, completion inCompletion: () -> ()) {
    urlString = inURLString
    completion = inCompletion
  }
  
  override func main() {
    autoreleasepool {
      let downloadURL = NSURL(string: self.urlString)!
      let filePath = FlickrDownloadOperation.downloadDirectoryPathForURLString(self.urlString)
      
      let imageData = NSData(contentsOfURL: downloadURL)
      
      if let unwrappedData = imageData {
        let image = UIImage(data: unwrappedData)
        if let unwrappedImage = image {
          self.setImageToImageView(unwrappedImage, imageView: self.imageView)
        }
        
        //Cache the data.
        unwrappedData.writeToFile(filePath, atomically: false)
      }
      
      if let unwrappedCompletion = self.completion {
        dispatch_async(dispatch_get_main_queue()) {
          unwrappedCompletion()
        }
      }
      
    }
  }
  
  class func cachedImageForURLString(urlString: NSString) -> UIImage? {
    let filePath = downloadDirectoryPathForURLString(urlString)
    let imageData = NSData(contentsOfFile: filePath)
    if let unwrappedData = imageData {
      let image = UIImage(data: unwrappedData)
      if let unwrappedImage = image {
        return unwrappedImage
      }
    }
    return nil
  }
  
  func setImageToImageView(image: UIImage, imageView: UIImageView?) {
    //If the imageView hasn't been nuked, set the image to it on the main thread.
    NSOperationQueue.mainQueue().addOperationWithBlock {
      if let unwrappedImageView = imageView {
        unwrappedImageView.image = image
      }
    }
  }
  
  class func downloadDirectoryPathForURLString(urlString: NSString) -> String {
    let serverRange = urlString.rangeOfString("flickr.com/")
    let originalPath = urlString.substringFromIndex(serverRange.location + serverRange.length)
    let underscored = pathWithUnderscores(originalPath)
    let filePath = (pathToPhotoDownloadDirectory() as NSString).stringByAppendingPathComponent(underscored)
    return filePath
  }
  
  class func pathWithUnderscores(originalPath: NSString) -> String {
    _ = originalPath.substringFromIndex(1)
    return originalPath.stringByReplacingOccurrencesOfString("/", withString: "_")
  }
  
  class func pathToPhotoDownloadDirectory() -> String {
    let downloadsPath = NSString.flk_createdDocumentsSubdirectory("photoDownloads")
    
    return downloadsPath
  }
}