//
//  MockPhotoDataTests.swift
//  FlickrSearcher
//
//  Created by Ellen Shapiro on 12/9/14.
//  Copyright (c) 2014 Designated Nerd Software. All rights reserved.
//

//Import testing + iOS frameworks
import UIKit
import XCTest
import CoreData

//Import the module you wish to test.
import FlickrSearcher

class MockPhotoDataTests: BaseTests {

    //MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        let expectation = expectationWithDescription("mock photos imported")
        MockAPIController().fetchPhotosForTag("cats") { (success, result) -> Void in
            if let unwrappedResult = result {
                FlickrJSONParser.parsePhotoListDictionary(unwrappedResult)
                CoreDataStack.sharedInstance().saveMainContext()
            } else {
                XCTFail("Importing mock data failed!")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(localTimeout, handler: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        
        //Nuke the cached images folder
        FlickrPhotoDownloader.nukeDownloadedImagesFolder()
    }
    
    //MARK: Convenience downloader of user JSON
    
    func downloadJSONForUsers(userIDs: [String]) {
        for userID in userIDs {
            let expectation = expectationWithDescription("Downloaded and wrote json")

            FlickrAPIController().fetchDataForUser(userID) { (success, result) -> Void in
                if let unwrappedResult = result {
                    var jsonError: NSError?
                    let JSONdata = NSJSONSerialization.dataWithJSONObject(unwrappedResult, options: .PrettyPrinted, error: &jsonError)
                    if let unwrappedData = JSONdata {
                        let fileName = "user_\(userID).json"
                        
                        let destinationFolder = NSString.flk_createdDocumentsSubdirectory("user_json")
                        let fullFilePath = destinationFolder.stringByAppendingPathComponent(fileName)
                        
                        unwrappedData.writeToFile(fullFilePath, atomically: false)
                    } else {
                        XCTFail("Could not convert dictionary to JSON for user \(userID)")
                    }
                } else {
                    XCTFail("Failed to download JSON for user \(userID)")
                }
                
                expectation.fulfill()
            }
            
            waitForExpectationsWithTimeout(standardTimeout, handler: nil)
        }
    }
    
    //MARK: Convenience downloader of missing images
    
    func downloadImage(urlString: String) {
        let expectation = expectationWithDescription("missing image downloaded")
        
        FlickrPhotoDownloader.sharedInstance().downloadImageFromURLString(urlString) {
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(standardTimeout, handler: nil)
    }
    
    //MARK: - Actual tests
    
    func testAllMockUserDataHasStoredImages() {
        let allPhotosRequest = Photo.flk_fetchRequestWithPredicate(nil)
        var error: NSError?
        let allPhotos = CoreDataStack.sharedInstance()
            .mainContext()
            .executeFetchRequest(allPhotosRequest, error: &error)
        var photosToDownload = [String]()
        if let photos = allPhotos as? [Photo] {
            var userIDs = [String]()
            XCTAssertNotEqual(photos.count, 0, "Photos count was zero!")
            for photo in photos {
                let expectation = expectationWithDescription("got user data")

                let userID = photo.owner.userID
                MockAPIController().fetchDataForUser(userID) { (success, result) -> Void in
                    if let unwrappedResult = result {
                        let user = FlickrJSONParser.parseUserDictionary(unwrappedResult)
                        if let unwrappedUser = user {
                            if let unwrappedIconURLString = unwrappedUser.iconURLString {
                                if MockPhotoDownloader.mockImageDataPathForURLString(unwrappedIconURLString) == nil {
                                    photosToDownload.append(unwrappedIconURLString)
                                    XCTFail("Image not downloaded!")
                                 }
                            } else {
                                //Not actually a failure - some users have no icon.
                                NSLog("No icon url for user \(userID)!")
                            }
                        } else {
                            XCTFail("User failed to parse!")
                        }
                    } else {
                        userIDs.append(userID)
                        XCTFail("Could not fetch data for user \(userID)")
                    }
                    
                    expectation.fulfill()
                }
                
                waitForExpectationsWithTimeout(standardTimeout, handler: nil)
            }
            
            self.downloadJSONForUsers(userIDs)
            
            for urlString in photosToDownload {
                downloadImage(urlString)
            }
        } else {
            XCTFail("404 Photos Not Found!")
        }
    }
    
    func testAllMockPhotoDataHasStoredImages() {
        let allPhotosRequest = Photo.flk_fetchRequestWithPredicate(nil)
        var error: NSError?
        let allPhotos = CoreDataStack.sharedInstance()
                                     .mainContext()
                                     .executeFetchRequest(allPhotosRequest, error: &error)
        
        if let photos = allPhotos as? [Photo] {
            XCTAssertNotEqual(photos.count, 0, "Photos count was zero!")
            for photo in photos {
                if MockPhotoDownloader.mockImageDataPathForURLString(photo.thumbnailURLString) == nil {
                    XCTFail("Thumb mock image not ready for url \(photo.thumbnailURLString)!")
                    self.downloadImage(photo.thumbnailURLString)
                }
                
                if MockPhotoDownloader.mockImageDataPathForURLString(photo.fullURLString) == nil {
                    XCTFail("Full mock image not ready for url \(photo.fullURLString)")
                    self.downloadImage(photo.fullURLString)
                }
            }
        } else {
            XCTFail("404 Photos Not Found!")
        }
    }
}