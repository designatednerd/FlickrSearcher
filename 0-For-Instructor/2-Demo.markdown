#XCTest In Practice, Part 2: Demo

#A Note On Resetting XCTest

One thing you will know if you've tried to do swift Unit testing previously: You will often not be able to see the little diamonds that allow you to run individual tests. 

The most repeatable steps I've found to fix this are: 

1. Open the project you want to test. 
2. Open the Organizer, and select the project in the organizer.
3. Close the window of the project you want to test. 
4. After the window has closed, delete the derived data folder of the project you want to test. 
5. Re-open the project you want to test, and build it. 

**Usually**, this will lead to the individual test diamonds being regenerated. This is not a 100% consistent process, and will often require a restart of Xcode or in the very worst cases, a full reboot of your machine. 

If anyone's got better suggestions on how to make this process less horrendous, I'd love to hear them. 

#Quick Review: Basic Unit Testing

Go to `FlickrAPITests.swift` in the test bundle, and run the `testAPIKeyExists` test. This test should fail at first. 

Go to `FlickrAPIConstants.swift`, and under the `FlickrAuthCredential` enum, change `APIKey` from `FIXME` to the API key your instructuor has provided. 

#Async Testing

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

There is a photo-favoriting mechanism already built into this applicaiton, but you know that you're going to have to eventually rewrite it. You decide to add a test to make sure it works, so that when you rewrite it, it still works. 

To do that, drill on into the `if let` syntax. With


#)Can You Fetch Stuff From Core Data? 

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
XCTAssertEqual(unwrappedFaves.count, 1, "Unwrapped faves was not 1 object, it was \(unwrappedFaves.count)")
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




#Mock API Data

In `FlickrAPIController.swift `in `MockAPIController` class towards the bottom: 

```swift
	public override func fetchPhotosForTag(tag: String, completion:(success: Bool, result: NSDictionary?) -> Void) {
		let fileName = "test_" + tag
		JSONFromFileNamed(fileName, completion: completion)
	}
	
	public override func pingEchoEndpointWithCompletion(completion: (success: Bool, result: NSDictionary?) -> Void) {
		JSONFromFileNamed("echo", completion: completion)
	}
```

