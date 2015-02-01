//
//  JSONParserTests.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 11/30/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

//Import testing + iOS frameworks
import UIKit
import XCTest

//Import the module you wish to test.
import FlickrSearcher

class JSONParserTests : BaseTests {
  
  func testParsingPhotoListAgainstJSONFromFile() {
    let expectation = expectationWithDescription("Parsed Photos From File!")
    MockAPIController().fetchPhotosForTag(FlickrParameterValue.TestTag.rawValue) { (success, result) -> Void in
      if let unwrappedResult = result {
        let parsedPhotos = FlickrJSONParser.parsePhotoListDictionary(unwrappedResult)
        if let unwrappedPhotos = parsedPhotos {
          XCTAssertEqual(unwrappedPhotos.count, 100, "Did not parse 100 photos!")
        } else {
          XCTFail("No Parsed Photos for you!")
        }
      } else {
        XCTFail("No result!")
      }
      
      expectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(localTimeout, nil)
  }
  
  func testParsingUserInfoAgainstJSONFile() {
    let expectation = expectationWithDescription("Parsed User From File!")
    
    //Test against a known user - in this case, the instructor.
    MockAPIController().fetchDataForUser("83136939@N00", completion: { (success, result) -> Void in
      if let unwrappedResult = result {
        let parsedUser = FlickrJSONParser.parseUserDictionary(unwrappedResult)
        if let unwrappedUser = parsedUser {
          if let userName = unwrappedUser.name {
            XCTAssertEqual(userName, "loudguitars", "User name not parsed correctly!")
          } else {
            XCTFail("No username found!")
          }
          
          if let urlString = unwrappedUser.iconURLString {
            if !self.urlStringBecomesValidURL(urlString) {
              XCTFail("User \(unwrappedUser.userID) returns invalid url \(urlString)")
            }
          } else {
            XCTFail("No icon URL found!")
          }
          
        } else {
          XCTFail("User Parsing fail!")
        }
      } else {
        XCTFail("No result!")
      }
      
      expectation.fulfill()
    })
    
    waitForExpectationsWithTimeout(localTimeout, nil)
  }
  
}
