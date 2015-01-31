#XCTest In Practice, Part 3: Lab

#Add information about users to core data model


###Add a new version of the Core Data Model

[SCREENSHOTS]

Add `name` and `iconURLString` properties to User

###Update model object

In `User.swift`, update these two variables to be `@NSManaged`

```swift
    @NSManaged public var name: NSString?
    @NSManaged public var iconURLString: NSString?
```


#Get from API

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
