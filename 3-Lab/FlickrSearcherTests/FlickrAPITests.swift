//
//  FlickrAPITests.swift
//  FlickrAPITests
//
//  Created by Ellen Shapiro on 11/14/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

//Import testing + iOS frameworks
import UIKit
import XCTest

//Import the module you wish to test.
import FlickrSearcher

class FlickrAPITests : BaseTests {
    
    var controller: FlickrAPIController = FlickrAPIController()
    
    override func setUp() {
        super.setUp()
        
        if ShouldUseFakeData {
            controller = MockAPIController()
        }
    }
    
    //MARK: - Make sure you have signed up for Flickr Creds
    
    func testAPIKeyExists() {
        XCTAssertFalse(FlickrAuthCredential.APIKey.rawValue == "FIXME", "You need to add your Flickr API key!")
    }
    
    //MARK: - Sync vs. Async testing
    
    func testEchoEndpointRespondingSync() {
        controller.pingEchoEndpointWithCompletion { (success, result) -> Void in
            XCTAssertTrue(success, "Success was not true!")
            XCTAssertNotNil(result, "Result was nil!")
            
            /**
            In theory, this should cause failure. In practice, if you run only this test, it will pass and this line will never get hit. It WILL, however, get hit when running the entire suite since the completion will fire as other tests are running. 
            */

//            XCTFail("HIT THIS METHOD!")
        }
        
        NSLog("End of test method body")
    }
    
    func testEchoEndpointRespondingAsync() {
        let expectation = expectationWithDescription("Finished echo!")
        controller.pingEchoEndpointWithCompletion { (success, result) -> Void in
            XCTAssertTrue(success, "Success was not true!")
            XCTAssertNotNil(result, "Result was nil!")
            
            //Aha, NOW we hit this method, and it fails
            //If you comment it out, the test will pass.
//            XCTFail("HIT THIS METHOD!")
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(standardTimeout, handler: nil)
    }
    
    func testEchoEndpointReturningSuccessAsync() {
        let expectation = expectationWithDescription("Finished echo!")

        controller.pingEchoEndpointWithCompletion { (success, result) -> Void in
            XCTAssertTrue(success, "Success was not true!")
            XCTAssertNotNil(result, "Result was nil!")
            
            if let unwrappedDict = result {
                XCTAssertTrue(FlickrJSONParser.isResponseOK(unwrappedDict), "Response is not OK!")
            } else {
                XCTFail("Dict did not unwrap!")
            }
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(standardTimeout, handler: nil)
    }
    
    //MARK: - Getting photos
    
    func testRetrievingPhotosForTagWithLotsOfResults() {
        let expectation = expectationWithDescription("Got photo results!")
        
        controller.fetchPhotosForTag("cats") { (success, result : NSDictionary?) -> Void in

            XCTAssertTrue(success, "Success was not true!")
            XCTAssertNotNil(result, "Result was nil!")
            
            if let unwrappedDict: NSDictionary = result {
                XCTAssertTrue(FlickrJSONParser.isResponseOK(unwrappedDict), "Response is not OK!")
                let parsedPhotos = FlickrJSONParser.parsePhotoListDictionary(unwrappedDict)
                if let unwrappedParsedPhotos = parsedPhotos {
                    XCTAssertEqual(unwrappedParsedPhotos.count, 100, "100 photos not returned!")
                    for photo in unwrappedParsedPhotos {
                        if !self.urlStringBecomesValidURL(photo.fullURLString) {
                            XCTFail("Photo with ID \(photo.photoID) had invalid URL \(photo.fullURLString)")
                        }
                    }
                } else {
                    XCTFail("No list of photos!")
                }
            } else {
                XCTFail("Top-level dict did not unwrap!")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(standardTimeout, handler: nil)
    }
}
