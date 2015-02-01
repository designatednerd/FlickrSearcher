#XCTest In Practice, Part 4: Challenge

For the challenge, you’ll add information about which user took each cat photo in the list of photos you’re pulling down. You’ll start by adding the skeleton of information about what you want to the Core Data model, test that it migrates properly. Then, you’ll get data from the Live Flickr API - and test it against both Live and Mock datasets. 

#1) Add information about users to core data model

In order to save the data, you need to make sure that Core Data knows how to persist it. However, since you already have an existing version of your application, you want to make sure that people installing the new version will still have it work despite the model change. 

You can use the code that you added 

##a) Add A New Version of the Core Data Model

[SCREENSHOTS]

Add `name` and `iconURLString` properties to User

##b) Update the `User` Model Object

In `User.swift`, update these two property variables to be `@NSManaged` instead of just `public`: 

```swift
    @NSManaged public var name: NSString?
    @NSManaged public var iconURLString: NSString?
```

##c) Run Your Core Data Tests



#2) Get User Data From the Flickr API

##a) Create a method to fetch and 

```swift
/**
    Requests and retrieves a JSON dictionary of information about the given user
    
    :param: userID     The user's ID, non percent escaped
    :param: completion The completion block to fire after executing.
    */
    public func fetchDataForUser(userID: String, completion:(success: Bool, result: NSDictionary?) -> Void) {
        let paramsDict = [
            FlickrParameterName.Method.rawValue : FlickrMethod.Person.rawValue,
            FlickrSearchParameterName.UserID.rawValue : userID.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        ]
        
        makeAPIRequest(HTTPMethod.GET, params: paramsDict) { (responseDict, error) -> Void in
            if let returnedError = error {
                self.fireCompletionOnMainQueueWithSuccess(false, result: nil, completion: completion)
            } else {
                self.fireCompletionOnMainQueueWithSuccess(true, result: responseDict, completion: completion)
            }
        }
    }

```


#Test Data Fetching And Parsing Works

In `FlickrAPITests.swift`:

```swift
 //MARK: - Getting user data
    
    func testRetrievingUserData() {
        let expectation = expectationWithDescription("Got user data!")
        
        //TODO: aFIX TO TRAILING CLOSURE
        
        
        //Test against a known user who won't change their username - in this case, your instructor. 
        controller.fetchDataForUser("83136939@N00", completion: { (success, result) -> Void in
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
        })

        waitForExpectationsWithTimeout(standardTimeout, handler: nil)
    }

```


#Parse Icon URL and name
