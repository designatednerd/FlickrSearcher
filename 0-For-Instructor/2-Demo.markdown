XCTest In Practice, Part 2: Demo
=====

Open up the `FlickrSearcher` project which is in the `1-Starter/StarterProject` folder. Wait for it to load, and hit build and run. Please raise your hand when you’ve got it up and running. 

The application goes out to Flickr, and grabs photos tagged with "cats", and displays thumbnails and a few details about them in a UITableView. 

Select an individual photo, tap the heart, and when it turns red you've marked that photo as a favorite. When you go back to the table view, you can see that reflected in the cell for that photo with a heart. 

Tap the favorites button in the upper right hand corner, and you can see that there's a bigger view of the favorited item before you go to the detail. 

#1) Where The Tests Are, And How To Run Them

Tests all live in a separate bundle from the main application. This is particularly critical in Swift because it means that any function you want to test will need to be `public` so that it can be seen outside your application’s bundle.

To get to the tests through the file navigator, you can open up the `FlickrSearcherTests` folder. If you want to use the Test Navigator to run individual tests, look for the diamond at the top: 

![](demo_images/zero_tests.png)

You may see something else which is in this image: A false report of zero tests. Xcode 6 has a *lot* of problems with trying to run individual tests in Swift. There are a few [troubleshooting tips](XCTestTroubleshooting.markdown), but be forewarned that their reliability is inconsistent, and they generally involve the phrase “restart your computer”. 

You can run your tests by selecting the wrench where the “run” button normally lives in the main toolbar: 

![](demo_images/wrench.png)

And sometimes this will make things look the way they’re supposed to: 

![](demo_images/test_diamonds.png)

Each diamond reflects whether the test has passed or failed, and can (or at least should) be able to be clicked to run that individual test. You can also run all tests in a package by clicking the play button next to the package name. 

#2) Quick Review: Basic Unit Testing

Go to `FlickrAPITests.swift` in the test bundle, and run the `testAPIKeyExists` test. This test will fail at first, since the API key is not in the starter project. 

Go to `FlickrAPIConstants.swift`, and under the `FlickrAuthCredential` enum, change `APIKey` from `FIXME` to `262cabe358a00f6f9977965c287249c3`. 

Run the test again, and it will pass! You have successfully tested something in complete isolation.

#3) Async Testing

In `FlickrAPITests.swift`, you can run `testEchoEndpointResponding` - and you'll notice that despite the fact that it has an explicit failure in it, the test passes!

Well that's a bit silly. Why is that happening? 

Add two breakpoints: one at the point where it's supposed to fail, and one at the very end of the test case. Run the test again. 

The breakpoint at the end of the test case will get hit, but the one where it's supposed to fail will not. Aha! You are running asynchronous code. The test is completing before you have a chance to run the code in the closure. 

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

#4) Writing Practical Core Data Tests

There is a photo-favoriting mechanism already built into this application, but it’s not tested. You want to answer a number of questions here, and to do it you’re going to drill into the `if let` syntax.

As of the current version of Swift, testing is not generally a place to force-unwrap things. If a force-unwrap fails in a test, it will take down your entire test suite instead of simply failing that single test. 

There’s already a test in `FavingTests.swift` that’s designed to answer several key questions around fetching from Core Data: 

- Can you fetch stuff from Core Data? 
- Is what you fetched an array of photos? 
- If you favorite the first photo and save it to Core Data, can you pull it back out of Core Data and have it still be faved? 

To test these things, it takes several steps: 

- Imports a big list of photo json, parses it, and saves it into core data. 
- Faves the first photo it grabs out of Core Data, then re-fetches just the faves. 
- Makes sure there is only one fave, and that it is the same thing it just faved. 

D'oh! There's more than one fave! But why? Because it’s using the data that was already in the `.sqlite` file on disk as the persistent store, so it’s seeing the faves you already made when taking the app out for a spin earlier. 

##a) Resetting the database before every test

You always want to make sure that the database is reset prior to every test, so that you can ensure all state that you’re testing is state that *you* have built up, not that whoever was using your test device previously built up. 

In `BaseTests.swift`, add a line to the `setUp()` function to reset the database: 

```swift
//Nuke the database before every test.
CoreDataStack.sharedInstance().resetDatabase()
```

Run the faving test again, and woo hoo, the test passes! But you’ll notice a nasty side-effect if you build and run the app again: All of the favorites you saved earlier are gone! Boo-urns. 

Imagine how frustrating this would be if you were testing a complex app which took a lot of time to build up a proper set of test data for development. 

How can you avoid this nightmare? A special type of storage known as an `NSInMemoryStore`. 

##b) Using an In-Memory store

`NSInMemoryStore` allows you to continue to use CoreData, but without saving any of the data to disk. In `CoreDataStack.swift` add a new variable at the top of the class to help facilitate knowing when we’re in test mode: 

```swift
//Public variables
public var isTesting = false
```

Next, in the `coordinator()` function, right below where `var url: NSURL? = self.databaseFileURL()`, add the following lines to ensure that if you’re testing, you’re using an `NSInMemoryStore` and not the SQLite database (and nilling out the file URL for the SQLite file just in case): 

```swift
if (self.isTesting) {
  storeType = NSInMemoryStoreType
  url = nil
}
```

In the `resetDatabase()` function, after the context, model, and persistent store coordinator are reset, wrap the code which deletes the file from the file system in a testing check: 

```swift
if !self.isTesting {  
  let storePath = databaseFileURL().path!
  if NSFileManager.defaultManager().fileExistsAtPath(storePath) {
    var error: NSError?
    NSFileManager.defaultManager().removeItemAtPath(storePath, error: &error)
    if let unwrappedError = error {
      NSLog("Error deleting file: \(error)")
    }
  } //else there was nothing to delete.
} //else we are testing and we should not delete the SQLite file.
```

Finally, go to `BaseTests.swift` and add one more line right above resetting the database in the `setUp()` function: 

```swift
	CoreDataStack.sharedInstance().isTesting = true
```

Build and run the application, and add a bunch of favorites. Then, run your tests, which should pass. Build and run the application again, and you should find that your  faves are persisting now! Huzzah!

#5) Mock API Data

Open `FlickrAPIController.swift` and notice that there’s a `MockAPIController` class towards the bottom. This class is set up to have exactly the same interface as the real Flickr API Controller, but you want it to work differently under the hood. 

Instead of going out to the internet to get data, you want it get known data from JSON files stored locally on the system. This has the advantage of looking to your code like it’s getting live data, but having the data you’re actually processing be known.

Scroll to the two functions with `//TODOs` within `MockAPIController`, and replace the code with code which fetches the JSON from the appropriate file: 

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

Build and run your tests again, and you will see that even though you’ve only added one additional setup function, the entire suite of tests will run twice - once with live data, and once with mock data. 

The benefit of doing this is that if something changes on the server, you find out almost immediately. If your local tests are passing but your server tests are failing, then clearly something has changed on the server side. 

This is especially helpful when you’re working with an unstable API, especially one that’s still under development. Identifying this by running seconds of tests rather than trying to log in to something for minutes or hours is a huge, huge time-saver. 

You can also add tests in the mock API controller that either call `super` or call the API directly, and then run further tests on the mock data, which you’ll know much more about than the more easily-changed data on the live server. 