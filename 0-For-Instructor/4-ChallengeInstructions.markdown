#XCTest In Practice, Part 4: Challenge

Not having user icons or names is a bit boring. So for the challenge, you’ll add basic information about which user took each cat photo in the list of photos you’re pulling down. 

You’ll start by adding the skeleton of information about what you want to the Core Data model, and test that it migrates properly. Then, you’ll get data from the Live Flickr API, and test it against both Live and Mock datasets. 

#1) Add Information About Users to Your Core Data Model

In order to save the data, you need to make sure that Core Data knows how to persist it. However, since you already have an existing version of your application, you want to make sure that people installing the new version will still have it work despite the model change. 

You can use the code that you added in the lab to make sure that you’ve done this in a way that won’t crash for users in the field. 

##a) Add A New Version of the Core Data Model

Go to the `Editor` menu and select `Add model version...` to begin adding a new model: 

![](challenge_images/add_model_version.png) 

Give your new model version a name. Keep it clear and call it `FlickrSearcher2`: 

![](challenge_images/model_version_name.png)

After the new version is added, you’ll see a disclosure indicator (aka the “flippy triangle”) next to your `xcdatamodeld` file, which will be flipped open.

![](challenge_images/model_old_selected.png)

The new model will be there, and show as added, but the green check indicates that the old model is still selected. Open the File Inspector tab while you have one of the model versions selected and look for the `Current Version` section: 

![](challenge_images/file_inspector_tab.png) 

Use the drop-down to select `FlickrSearcher2` as your current model version: 

![](challenge_images/model_change_version.png)

Once you’ve changed the version, you can check that version 2 is properly selected by making sure the check moved: 

![](challenge_images/model_new_selected.png)

Select `FlickrSearcher2` in the project navigator to make sure you’re changing the appropriate model. Select the `User` entity: 

![](challenge_images/user_before_change.png)

Then, add `name` and `iconURLString` string properties:

![](challenge_images/user_after_change.png)

##b) Update the `User` Model Object

In `User.swift`, update the two property variables you just added to the Core Data model to be `@NSManaged` instead of just `public`: 

```swift
@NSManaged public var name: NSString?
@NSManaged public var iconURLString: NSString?
```

##c) Run Your Core Data Tests

Select the TestNavigator tab (the little diamond), then select the `CoreDataMigrationTests`, and press the run button to run only those tests. 

If it fails, start looking for where it failed. Other points of failure are similar to those in the lab, but if it fails after making it through all the `if-let` statements, check to make sure you’ve made the changes to the correct version of the Core Data model.

If you’ve set everything up correctly, your test should pass! Now you’re ready to get data and parse it. 

#2) Get User Data From the Flickr API

Since each photo returns the user’s ID, you would normally look through the Flickr API Explorer to find the API endpoint for getting more information about a given user. 

To save you some time: It’s [right here](https://www.flickr.com/services/api/explore/flickr.people.getInfo), and there’s a `Person` value of the `FlickrMethod` struct in `FlickrAPIConstants.swift` which calls that endpoint. If you pass in a dictionary with that method as the value for the `Method` parameter name and the UTF-8 encoded ID of the user you wish to search as the value for the `UserID` search parameter name, the `makeAPIRequest` method will take care of the rest. 

##a) Create a method to fetch user data. 

In `FlickrAPIController.swift`, add a new method at the bottom of the main data fetching class to hit the Flickr API endpoint which allows you to get get additional data about a user using their user ID: 

```swift
/**
Requests and retrieves a JSON dictionary of information about the given user
  
:param: userID     The user's ID, non percent escaped
:param: completion The completion block to fire after executing.
*/
public func fetchDataForUser(userID: String, completion:FlickrAPICompletion) {
  let paramsDict = [
    FlickrParameterName.Method.rawValue : FlickrMethod.Person.rawValue,
    FlickrSearchParameterName.UserID.rawValue : userID.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
  ]
    
  makeAPIRequest(HTTPMethod.GET, params: paramsDict) {
    (responseDict, error) -> Void in
    if let error = error {
      self.fireCompletionOnMainQueueWithSuccess(false, result: nil, completion: completion)
    } else {
      self.fireCompletionOnMainQueueWithSuccess(true, result: responseDict, completion: completion)
    }
  }
}
```

##b) Create a mock test method which grabs user data from JSON files. 

You will notice that there are a large number of `.json` files under `fake_data/user_json` - these are `.json` files which represent the users in all of the mocked photo data. Note that each user’s `.json` file is set up in the format `user_[user id]`.json - that means you can easily 

```swift
public override func fetchDataForUser(userID: String, completion: FlickrAPICompletion) {
  JSONFromFileNamed("user_\(userID)", completion: completion)
}
```

#3) Test Data Parsing And Fetching Works

In the interest of time, you don’t have to research and write a parsing function - that’s already been done for you in `FlickrJSONParser.swift`. That class goes through and checks that the data is OK (since if it isn’t, it would crash when you tried to force-unwrap the keys you’re expecting), then parses out the data into the `User` model object. 

You don’t have to trust that the author of this class knew what they were doing, though. You can write a test to make sure that it works. 

##a) Test that parsing works properly with mock data. 

Start by testing that the local data you know is in a specific format - that way you can at least start from a known state. 

In `JSONParserTests.swift`, go to the `TODO` and replace it with a new test which checks that it retrieves a user, and is able to correctly parse the username and build a valid icon URL from mock data. Set up an expectation and a wait, since this is an async call:  

```swift
func testParsingUserInfoAgainstJSONFile() {
  let expectation = expectationWithDescription("Parsed User From File!")

  //TODO: Add actual call to mock API. 

  waitForExpectationsWithTimeout(localTimeout, nil)
}
```

Don’t try to run quite yet - if you run that test, it’ll wait until the timeout since `expectation.fulfill()` is never called. 

Next, check that a parsed user from mock data unwraps properly. We’ll use your instructor’s ID, since her profile is included in the mock data. Replace the `TODO` you just added with: 

```swift
MockAPIController().fetchDataForUser("83136939@N00") {
  (success, result) -> Void in
  if let result = result {
    let parsedUser = FlickrJSONParser.parseUserDictionary(result)
    if let parsedUser = parsedUser {

      //TODO: Test data was parsed correctly. 

    } else {
      XCTFail("User Parsing fail!")
    } 
  } else {
    XCTFail("No result!")
  }      
  expectation.fulfill()
}
```

Now, run the test - if the parser is working correctly, you’ll see it pass. Huzzah, a user!

Finally, since you’re using mock data and you know what to expect if things were parsed correctly, you can check that the exact username and icon URL are returned by the parser. Replace the `TODO` you just added with: 

```swift
if let userName = parsedUser.name {
  XCTAssertEqual(userName, "loudguitars", "User name not parsed correctly!")
} else {
  XCTFail("No username found!")
}
          
if let urlString = parsedUser.iconURLString {
  XCTAssertEqual(urlString, "http://farm1.staticflickr.com/48/buddyicons/83136939@N00.jpg", "URL String did not match expected");
} else {
  XCTFail("No icon URL found!")
}          
```

Run the test again, and if it passes, the parser is parsing all the data you want properly! :]

##b) Test fetching user data from the API

Now that you have known local data parsing correctly, it’s time to see how it works against the live Flickr API!

In `FlickrAPITests.swift`, add a test which grabs data which you know is both live and in the mock data, since this test will be run by both `FlickrAPITests` and its `MockFlickrAPITests` subclass. 

Since you know your instructor’s user ID is in the mock data (and she doesn’t plan on deleting it from Flickr anytime soon), start with hers:

```swift
//MARK: - Getting user data
    
func testRetrievingUserData() {
  let expectation = expectationWithDescription("Got user data!")    
  controller.fetchDataForUser("83136939@N00") {
    (success, result) -> Void in
    if let result = result {
      let user = FlickrJSONParser.parseUserDictionary(result)
        if let user = user {   
       
          //TODO: Check user data          

        } else {
          XCTFail("User parsing failed!")
        }
      } else {
        XCTFail("Could not load data for user!")
    }      
      expectation.fulfill()
  }    
  waitForExpectationsWithTimeout(standardTimeout, handler: nil)
}
```

Since live data can change, you should not test what the user name is - just that it’s there. At the `TODO` you just added, add this line: 

```swift
XCTAssertNotNil(user.name, "User name was nil!");
```

Next, check that the icon URL string that is returned is a valid URL. Since you’ve already checked with known data that it’s formatting properly, you just need to make sure that what’s parsed from the live server is valid. To do this, add a small `if-let` nest: 

```swift          
if let iconURLString = user.iconURLString {
  if !self.urlStringBecomesValidURL(iconURLString) {
    XCTFail("Icon URL string \(iconURLString) for user \(user.userID) was not a valid URL!")
  }
} else {
  XCTFail("Icon URL string not found!")
}
```

Build and run your entire test package, and this test will be run against both live and mock data. If you've set the tests up properly, all tests should pass. 

#4) Turn On The UI!

Now that you know the underlying data is working, it’s time to turn on the user interface!

Go to `PhotoDataSource.swift`, and uncomment the final line in the `tableView:cellForRowAtIndexPath:` function. Then uncomment the entire “Downloading User Information” section towards the bottom of the file. 

Build and run the application, and you’ll see that user data downloads, and you can now see the usernames and profile icons of your favorite cat photographers!


#Notes

If you were using this in a real application, when you release this version of the application, you would create a new test database file which you would indicate is a newer version than `starter_database` - that will help you catch any changes to your core data schema will break things not just in the starter version, but in this new version as well. 