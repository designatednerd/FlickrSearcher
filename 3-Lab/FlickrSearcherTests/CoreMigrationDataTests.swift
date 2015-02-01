//
//  CoreDataMigrationTests.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 11/30/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

//Import testing + iOS frameworks
import UIKit
import XCTest
import CoreData

//Import the module you wish to test.
import FlickrSearcher

class CoreDataMigrationTests : BaseTests {
  
  /**
  Inspired by http://www.cocoanetics.com/2013/01/unit-testing-coredata-migrations/
  
  This will test if the application can properly complete automatic migration of the
  CoreData store - if that store is not properly migrated, the app will crash on launch.
  
  This class will NOT test if any content which needs to be migrated has been migrated
  properly. Seperate tests should be written for that case.
  */
  func performAutomaticMigrationTestWithStoreName(name: String) {
    //Grab the SQLite file that is in the test bundle with this class
    let bundle = NSBundle(forClass:self.dynamicType)
    let storeURL = bundle.URLForResource(name, withExtension:"sqlite")
    if let unwrappedStoreURL = storeURL {
      
      //Grab the core data model from the main bundle
      let modelURL = NSBundle.mainBundle().URLForResource(ManagedObjectModelName, withExtension:ManagedObjectModelExtension)
      if let unwrappedModelURL = modelURL {
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: unwrappedModelURL)
        if let unwrappedModel = managedObjectModel {
          //Create a persistent store coordinator and persistent store independent of our main stack.
          let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: unwrappedModel)
          let options = [
            NSMigratePersistentStoresAutomaticallyOption : true,
            NSInferMappingModelAutomaticallyOption : true,
          ]
          
          var error: NSError?
          let persistentStore = persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil,
            URL:storeURL,
            options:options,
            error:&error)
          
          XCTAssertNotNil(persistentStore, "Cannot load persistentStore: \(error)");
        } else {
          XCTFail("Could not load model!");
        }
      } else {
        XCTFail("Model URL was nil!")
      }
    } else {
      XCTFail("Cannot find \(name).sqlite")
    }
  }
  
  func testPart1DatabaseCanBeOpened() {
    performAutomaticMigrationTestWithStoreName("part_1_database")
  }
}
