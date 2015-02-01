#XCTest In Practice, Part 4: Challenge

For the challenge, you’ll add information about which user took each cat photo in the list of photos you’re pulling down. You’ll start by adding the skeleton of information about what you want to the Core Data model, and test that it migrates properly. Then, you’ll get data from the Live Flickr API, and test it against both Live and Mock datasets. 

#1) Add Information About Users to Your Core Data Model

In order to save the data, you need to make sure that Core Data knows how to persist it. However, since you already have an existing version of your application, you want to make sure that people installing the new version will still have it work despite the model change. 

You can use the code that you added in the lab to check that you’ve done this in a way that won’t crash for users in the field. 

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

In `User.swift`, update these two property variables to be `@NSManaged` instead of just `public`: 

```swift
    @NSManaged public var name: NSString?
    @NSManaged public var iconURLString: NSString?
```

##c) Run Your Core Data Tests

Select the TestNavigator tab (the little diamond), then select the `CoreDataMigrationTests`, and press the run button to run only those tests. 

#2) Get User Data From the Flickr API

##a) Create a method to fetch user data. 

In `FlickrAPIController.swift`, add a new method at the bottom of the main data fetching class to get more 

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
      if let returnedError = error {
        self.fireCompletionOnMainQueueWithSuccess(false, result: nil, completion: completion)
      } else {
        self.fireCompletionOnMainQueueWithSuccess(true, result: responseDict, completion: completion)
      }
    }
  }
```

#b) 

#3) Parse User Data


#4) Test Data Fetching And Parsing Works

In `FlickrAPITests.swift`:

```swift
 //MARK: - Getting user data
    
func testRetrievingUserData() {
    let expectation = expectationWithDescription("Got user data!")
    
    //Test against a known user - in this case, your instructor.
    controller.fetchDataForUser("83136939@N00") {
      (success, result) -> Void in
      if let unwrappedResult = result {
        let user = FlickrJSONParser.parseUserDictionary(unwrappedResult)
        if let unwrappedUser = user {
          
          if let userName = unwrappedUser.name {
            XCTAssertEqual(userName, "loudguitars", "User name not parsed correctly!")
          } else {
            XCTFail("User name not found!")
          }
          
          if let iconURLString = unwrappedUser.iconURLString {
            if !self.urlStringBecomesValidURL(iconURLString) {
              XCTFail("Icon URL string \(iconURLString) for user \(unwrappedUser.userID) was not a valid URL!")
            }
          } else {
            XCTFail("Icon URL string not found!")
          }
          
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


