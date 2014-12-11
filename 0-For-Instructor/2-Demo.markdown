#XCTest In Practice, Part 2: Demo

#Async Testing

in `FlickrAPITests.swift` copy test and rerun with new name. 

```swift
	func testEchoEndpointRespondingAsync() {
		let expectation = expectationWithDescription("Finished echo!")
		controller.pingEchoEndpointWithCompletion { (success, result) -> Void in
			XCTAssertTrue(success, "Success was not true!")
			XCTAssertNotNil(result, "Result was nil!")
			
			//Aha, NOW we hit this method, and it fails
			//If you comment it out, the test will pass.
			XCTFail("HIT THIS METHOD!")
			expectation.fulfill()
		}
		
		waitForExpectationsWithTimeout(standardTimeout, handler: nil)
	}
```

Now you can do a real test: 

```swift

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

```



#Using an In-Memory Store

Add new boolean property `isFavorite` to photo entity.

in `Photo.swift`: 

```swift
	@NSManaged public var isFavorite: NSNumber
```

In `PhotoDetailViewController.swift`, in the method `configureFavoriteButtonColorBasedOnPhoto`: 

```swift
	if aPhoto.isFavorite.boolValue {
		favoriteButton.tintColor = UIColor.redColor()
	} else {
		favoriteButton.tintColor = UIColor.lightGrayColor()
	}
```

same file, in `toggleFavoriteStatus`
if let unwrappedPhoto = photo {
			unwrappedPhoto.isFavorite = !unwrappedPhoto.isFavorite.boolValue as NSNumber
			CoreDataStack.sharedInstance().saveMainContext()
			configureFavoriteButtonColorBasedOnPhoto(unwrappedPhoto)
		}

in `PhotoDataSource.swift` in `tableView:cellForRowAtIndexPath:`

```swift
cell.favoriteIcon.alpha CGFloat(photoAtIndex.isFavorite)
```

Select the `FlickrSearcherTests` folder. `File > New > File > Swift file`. Name file `FavingTests`. Make sure it's added to the `FlickrSearcherTests` bundle, not main `FlickrSearcher` bundle.

```swift
class FavingTests : BaseTests {
	
	override func setUp() {
		super.setUp()
		
		let expectation = expectationWithDescription("Imported fake data!")
		MockAPIController().fetchPhotosForTag("cats", completion: { (success, result) -> Void in
			if let unwrappedResult = result {
				FlickrJSONParser.parsePhotoListDictionary(unwrappedResult)
				CoreDataStack.sharedInstance().saveMainContext()
			} else {
				XCTFail("No result from mock API controller!")
			}
			
			expectation.fulfill()
		})
		
		waitForExpectationsWithTimeout(localTimeout, handler: nil)
	}
	
	func testFavoritingTheFirstItemRetrievedFromCoreDataWorks() {
		let allPhotosFetchRequest = Photo.flk_fetchRequestWithPredicate(nil)		
		var error: NSError?
		let allPhotos = CoreDataStack.sharedInstance().mainContext().executeFetchRequest(allPhotosFetchRequest, error: &error)
		
		if let unwrappedError = error {
			XCTFail("Error fetching all photos: \(unwrappedError)")
		} else {
			if let unwrappedAll = allPhotos as? [Photo] {
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
						XCTAssertEqual(unwrappedFaves.count, 1, "Unwrapped faves was not 1 object, it was \(unwrappedFaves.count)")
						let firstFave = unwrappedFaves.first!
						XCTAssertEqual(firstPhoto.photoID, firstFave.photoID, "Faved photo is not the same!")
					} else {
						XCTFail("No faves found!")
					}
				}				
			} else {
				XCTFail("No photos found!")
			}
		}
	}
```

Set up ability to use in memory store

In `CoreDataStack.swift` add at top: 

```swift
	//Public variables
	public var isTesting : Bool = false
```

then replace the old setter for the URL var to: 

```swift
	var url: NSURL? = nil
	if (self.isTesting) {
		//If we are testing, add the in-memory store type
		storeType = NSInMemoryStoreType
	} else {
		//If we are not testing, figure out the URL for the database file.
		url = self.databaseFileURL()
	}
```


```swift
	//MARK: Instance setup/teardown

	override func setUp() {
		super.setUp()
		
		//Nuke the database before every test.
		CoreDataStack.sharedInstance().isTesting = true
		CoreDataStack.sharedInstance().resetDatabase()
	}
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

