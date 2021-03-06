//
//  User.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 11/30/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

import CoreData

public class User : NSManagedObject {
  
  //MARK: Managed Object Properties
  
  @NSManaged public var userID: String
  @NSManaged public var name: String?
  public var iconURLString: String?
  
  //MARK: Helper method
  
  /**
  Grabs a user from the given context with the given ID, or creates a new one.
  
  - parameter context: The managed object context to search
  - parameter userID: The ID to search for
  
  - returns: The existing or new user with the given ID
  */
  
  class func userInContextOrNew(context: NSManagedObjectContext, userID: String) -> User {
    let predicate = NSPredicate(format: "userID ==[c] '\(userID)'")
    let fetchRequest = flk_fetchRequestWithPredicate(predicate)
    
    let results: [AnyObject]?
    do {
      results = try context.executeFetchRequest(fetchRequest)
    } catch {
      results = nil
    }
    
    if let unwrappedResults = results {
      if let user = unwrappedResults.first as? User {
        //User found!
        return user
      }
    }
    
    //None found, create new
    let created = flk_newInContext(context) as! User
    created.userID = userID
    return created
  }
}
