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
    
    //MARK: Convenience downloader of missing images
    
    func downloadImage(urlString: String) {
        let expectation = expectationWithDescription("missing image downloaded")
        
        FlickrPhotoDownloader.sharedInstance().downloadImageFromURLString(urlString) {
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(standardTimeout, handler: nil)
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