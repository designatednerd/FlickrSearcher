XCTest In Practice, Part 2: Demo
=====

#1) Open Up And Run The FlickrSearcher Project 

Open up the project, and hit build and run. The application goes out to Flickr, and grabs photos tagged with "cats", and displays thumbnails and a few details about them in a UITableView. 

Select an individual photo, tap the heart, and when it turns red you've marked that photo as a favorite. When you go back to the table view, you can see that reflected in the cell for that photo with a heart. 

Tap the favorites button in the upper right hand corner, and you can see that there's a bigger view of the favorited item before you go to the detail. 

#) Learn Where The Tests Are, And How To Run Them

Tests all live in a separate bundle from the main application. This is particularly critical in Swift because it means that any method you want to test will need to be `public` so that it can be seen outside your application’s bundle.

To get to the tests through the file navigator, you can open up the 

#) Quick Review: Basic Unit Testing

Go to `FlickrAPITests.swift` in the test bundle, and run the `testAPIKeyExists` test. This test will fail at first. 

Go to `FlickrAPIConstants.swift`, and under the `FlickrAuthCredential` enum, change `APIKey` from `FIXME` to `262cabe358a00f6f9977965c287249c3`. 

#) Async Testing

In `FlickrAPITests.swift`, you can run `testEchoEndpointRespondingSync` - and you'll notice that despite the fact that it has an explicit failure in it, the test passes!

Well that's a bit silly. Why is that happening? 

Add two breakpoints: one at the point where it's supposed to fail, and one at the very end of the test case. Run the test again. 

The breakpoint at the end of the test case will get hit, but the one where it's supposed to fail will not. Aha! You are running asynchronous code. The test is completing before you have a chance to run the code in the closure. 

###Create an Async Test Case

Copy the contents of `testEchoEndpointRespondingSync` and paste them directly below. Rename the case `testEchoEndpointRespondingAsync`. 

Add a new first line of the test: 

```swift
	let expectation = expectationWithDescription("Finished echo!")
```

And a new last line of the test: 

```swift
	waitForExpectationsWithTimeout(standardTimeout, handler: nil)
```

With these two lines you've said, "Here is what I am waiting for" and "here is where I want to wait for it." Now, all you have to do is add a line telling XCTest when the thing you're waiting for has happened. Just below `XCTFail("HIT THIS METHOD!")`, add a new line:

```swift
	expectation.fulfill()
```

Now, if you run this test, it will fail as soon as the closure executes, as you were expecting it to! 


#Writing Practical Tests

There is a photo-favoriting mechanism already built into this application, but it’s not tested. You want to answer a number of questions here, and to do it you’re going to drill into the `if let` syntax.


#a)Can You Fetch Stuff From Core Data? 

```swift
	func testFavoritingTheFirstItemRetrievedFromCoreDataWorks() {
		let allPhotosFetchRequest = Photo.flk_fetchRequestWithPredicate(nil)		
		var error: NSError?
		let allPhotos = CoreDataStack.sharedInstance().mainContext().executeFetchRequest(allPhotosFetchRequest, error: &error)
		
		if let unwrappedError = error {
			XCTFail("Error fetching all photos: \(unwrappedError)")
		} else {
			//TODO: MORE			
		}
	}
```

#)Is what you fetched an array of photos? 

```
if let unwrappedAll = allPhotos as? [Photo] {
	//TODO: More tests!
} else {
	XCTFail("No photos found!")
}
```

#)If you favorite the first photo and save it to Core Data, can you pull it back out of Core Data and have it still be faved? 

###a) Fave the first photo you grab out of core data, then grab just the faves. 

```swift
let firstPhoto = unwrappedAll.first!
				firstPhoto.isFavorite = true
				CoreDataStack.sharedInstance().saveMainContext()
				
				//Update the fetch request to add a predicate
				allPhotosFetchRequest.predicate = NSPredicate(format: "%K == YES", "isFavorite")
				let faves = CoreDataStack.sharedInstance().mainContext().executeFetchRequest(allPhotosFetchRequest, error: &error)
				if let unwrappedFaveError = error {
					XCTFail("Error fetching favorite photos:\(unwrappedFaveError)")
				} else {
					if let unwrappedFaves = faves as? [Photo] {
						//TODO: MOAR TESTS
					} else {
						XCTFail("No faves found!")
					}
				}				
```

###b) Make sure there is only one fave, and that it is the same thing you just faved. 


```swift
XCTAssertEqual(unwrappedFaves.count, 1, "\(unwrappedFaves.count) Unwrapped faves!")
		let firstFave = unwrappedFaves.first!
		XCTAssertEqual(firstPhoto.photoID, firstFave.photoID, "Faved photo is not the same!")
```

D'oh! There's more than one fave! 

###Resetting the database before every test

In `BaseTests.swift`, 

```swift
	//MARK: Instance setup/teardown

	override func setUp() {
		super.setUp()
		
		//Nuke the database before every test.
		CoreDataStack.sharedInstance().resetDatabase()
	}
```



#Using an In-Memory store

Set up ability to use in memory store

In `CoreDataStack.swift` add at top: 

```swift
	//Public variables
	public var isTesting = false
```

Right below where `var url: NSURL? = self.databaseFileURL()`, add the following lines: 


```swift
	if (self.isTesting) {
		//If we are testing, add the in-memory store type
		storeType = NSInMemoryStoreType
		
		//And we do not need a file URL
		url = nil
	}
```


In the `resetDatabase` method, make sure we're not deleting the file when we're testing: 

```swift
	if !self.isTesting {
	    //EXISTING CODE
	} //else we are testing and only want to reset the in-memory store.
```



```swift
	CoreDataStack.sharedInstance().isTesting = true
```




#)Mock API Data

Open `FlickrAPIController.swift` and notice that there’s a `MockAPIController` class towards the bottom. This class is set up to have exactly the same interface as the real Flickr API Controller, but you want it to work differently under the hood. 

Instead of going out to the internet to get data, you want it get known data from JSON files stored locally on the system. This has the advantage of looking to your code like it’s getting live data, but having the data you’re actually processing be known.

Scroll to the two `//TODOs` within `MockAPIController`, and replace the code with code which fetches the JSON from the appropriate file: 

```swift
	public override func fetchPhotosForTag(tag: String, completion:(success: Bool, result: NSDictionary?) -> Void) {
		let fileName = "test_" + tag
		JSONFromFileNamed(fileName, completion: completion)
	}
	
	public override func pingEchoEndpointWithCompletion(completion: (success: Bool, result: NSDictionary?) -> Void) {
		JSONFromFileNamed("echo", completion: completion)
	}
``` 

Now that you’ve updated the mock class, add some tests for the mock data: 

 - Open `FlickrAPITets.swift`, change the controller variable from a `let` to a `var`.
 - Make a new file, `MockFlickrAPITests.swift`, and set up the mock controller in the the instance setup: 

```swift
import FlickrSearcher

class MockFlickrAPITests : FlickrAPITests {
    
    override func setUp() {
        super.setUp()
        
        //Replace the standard controller with a mock API controller.
        controller = MockAPIController()
    }
}
```

- Build and run your tests again, and you will see that even though you’ve only added one additional setup method, the entire suite of tests will run twice - once with live data, and once with mock data. 

Since your data is known, you can now 