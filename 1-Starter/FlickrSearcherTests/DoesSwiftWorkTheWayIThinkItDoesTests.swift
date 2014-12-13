//
//  DoesSwiftWorkTheWayIThinkItDoesTests.swift
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

class DoesSwiftWorkTheWayIThinkItDoesTests : BaseTests {

    func testClassNameExtensionWorks() {
        let name = Photo.flk_className()
        XCTAssertTrue(name == "Photo", "Class name not parsed correctly!")
    }
}