//
//  FavingTests.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 12/8/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

//Import testing + iOS frameworks
import UIKit
import XCTest
import CoreData

//Import the module you wish to test.
import FlickrSearcher

class FavingTests : BaseTests {
    
    override func setUp() {
        super.setUp()
        
        let expectation = expectationWithDescription("Imported data!")
        FlickrAPIController().fetchPhotosForTag(FlickrParameterValue.TestTag.rawValue, completion: { (success, result) -> Void in
            if let unwrappedResult = result {
                FlickrJSONParser.parsePhotoListDictionary(unwrappedResult)
                CoreDataStack.sharedInstance().saveMainContext()
            } else {
                XCTFail("No result from API controller!")
            }
            
            expectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(localTimeout, handler: nil)
    }
    
    func testFavoritingTheFirstItemRetrievedFromCoreDataWorks() {
        //TODO: Add a test!
    }
}
