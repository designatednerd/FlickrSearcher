//
//  FlickrJSONParser.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 11/30/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

import Foundation

/**
Class to facilitate parsing of JSON from the API.
*/
public class FlickrJSONParser {
  
  //MARK - Generic JSON
  
  /**
  Will look at any dictionary received for a "stat" : "ok" key/value pair, which should be returned after any successful request to the Flickr API
  
  :param: responseDict The dictionary received from the API.
  
  :returns: true if the required Key/Value pair is there, false if it is not.
  */
  public class func isResponseOK(responseDict: NSDictionary) -> Bool {
    if let status = responseDict[FlickrReturnDataJSONKeys.Status.rawValue] as? String {
      if status == "ok" {
        return true
      } //Else there was a status not OK
    } //else there was no status
    
    return false
  }
  
  
  //MARK - Photo JSON
  
  /**
  Parses an NSDictionary received from the server into an array of Photo objects.
  Note: The caller is responsible for saving the main managed object context once the array
  of photos has been created.
  
  :param: photoListDict An NSDictionary received from the server of photos.
  
  :returns: An array of Photo objects corresponding with the received list of photos (inserted into the main context but not yet saved), or nil if parsing fails.
  */
  public class func parsePhotoListDictionary(photoListDict: NSDictionary) -> [Photo]? {
    //Make sure the dict is OK to go
    if !isResponseOK(photoListDict) {
      NSLog("Response not OK! It was: \(photoListDict)")
      return nil
    } //else, keep going
    
    if let unwrappedPhotoContainer = photoListDict[FlickrReturnDataJSONKeys.PhotoEnclosingDict.rawValue] as? NSDictionary {
      if let unwrappedPhotos = unwrappedPhotoContainer[FlickrReturnDataJSONKeys.ListOfPhotos.rawValue] as? NSArray {
        //This is the array of dictionaries we're looking for.
        //Create an array to store the photos
        var photos = [Photo]()
        
        for item in unwrappedPhotos {
          let photoDict = item as NSDictionary
          let photo = parseIndividualPhotoDictionary(photoDict)
          photos.append(photo)
        }
        
        return photos
      } //else list of photos did not unwrap.
    } //else photo container did not unwrap
    
    //In either case:
    return nil
  }
  
  /**
  Parses an individual photo dictionary to return a Photo
  
  :param: photoDict The dictionary to parse
  
  :returns: The instantiated and populated photo, inserted into the main context but not yet saved.
  */
  class func parseIndividualPhotoDictionary(photoDict: NSDictionary) -> Photo {
    // How to construct a Flickr URL: https://www.flickr.com/services/api/misc.urls.html
    // https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
    
    let farm = photoDict[FlickrPhotoDataJSONKeys.Farm.rawValue]! as Int
    let server = photoDict[FlickrPhotoDataJSONKeys.Server.rawValue]! as String
    let photoID = photoDict[FlickrPhotoDataJSONKeys.ID.rawValue]! as String
    let secret = photoDict[FlickrPhotoDataJSONKeys.Secret.rawValue]! as String
    let userID = photoDict[FlickrPhotoDataJSONKeys.Owner.rawValue]! as String
    
    let fullURL = "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret).jpg"
    let thumbURL = "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(FlickrPhotoSize.Thumbnail.rawValue).jpg"
    
    let mainContext = CoreDataStack.sharedInstance().mainContext()
    
    let photo = Photo.photoInContextOrNew(mainContext, photoID: photoID)
    photo.fullURLString = fullURL
    photo.thumbnailURLString = thumbURL
    photo.photoID = photoID
    photo.title = photoDict[FlickrPhotoDataJSONKeys.Title.rawValue]! as String
    
    let user = User.userInContextOrNew(mainContext, userID: userID)
    user.userID = userID
    photo.owner = user
    
    return photo
  }
  
  //TODO: Add a method which allows you to parse user JSON. 

}
