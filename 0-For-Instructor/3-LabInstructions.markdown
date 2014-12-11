#XCTest In Practice, Part 3: Lab

#Add information about users to core data model

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

#Add mock API Method too

```swift
    public override func fetchDataForUser(userID: String, completion: (success: Bool, result: NSDictionary?) -> Void) {
        let fileName = "user_" + userID
        JSONFromFileNamed(fileName, completion: completion)
    }
```

#Parse data

```swift
/**
    Parses a given dictionary into a User object.
    
    :param: userDict The dictionary to parse.
    
    :returns: The instantiated and populated user, inserted into the main context but not yet saved.
    */
    public class func parseUserDictionary(userDict: NSDictionary) -> User? {
        if !isResponseOK(userDict) {
            return nil
        }
        
        let personDict = userDict[FlickrUserDataJSONKeys.Person.rawValue]! as NSDictionary
        let usernameDict = personDict[FlickrUserDataJSONKeys.Username.rawValue]! as NSDictionary
        let username = usernameDict[FlickrReturnDataJSONKeys.InnerContent.rawValue]! as String
        let iconFarm = personDict[FlickrUserDataJSONKeys.IconFarm.rawValue]! as Int
        let iconServer: AnyObject = personDict[FlickrUserDataJSONKeys.IconServer.rawValue]!
        let userID = personDict[FlickrUserDataJSONKeys.ID.rawValue]! as String
        let NSID = personDict[FlickrUserDataJSONKeys.NSID.rawValue]! as String
        
        //http://farm{icon-farm}.staticflickr.com/{icon-server}/buddyicons/{nsid}.jpg

        var iconURLString: String
        if iconFarm > 0 {
            iconURLString = "http://farm\(iconFarm).staticflickr.com/\(iconServer)/buddyicons/\(NSID).jpg"
        } else {
            //Use the default icon per Flickr guidelines here: https://www.flickr.com/services/api/misc.buddyicons.html 
            iconURLString = "https://www.flickr.com/images/buddyicon.gif"
        }
        
        let user = User.userInContextOrNew(CoreDataStack.sharedInstance().mainContext(), userID: userID)
        user.name = username
        user.iconURLString = iconURLString
        
        return user
    }
```

#Test mock data 

```swift
func testParsingUserInfoAgainstJSONFile() {
        let expectation = expectationWithDescription("Parsed User From File!")

        //Test against a known user - in this case, the instructor. 
        MockAPIController().fetchDataForUser("83136939@N00", completion: { (success, result) -> Void in
            if let unwrappedResult = result {
                let parsedUser = FlickrJSONParser.parseUserDictionary(unwrappedResult)
                if let unwrappedUser = parsedUser {
                    if let userName = unwrappedUser.name {
                        XCTAssertEqual(userName, "loudguitars", "User name not parsed correctly!")
                    } else {
                        XCTFail("No username found!")
                    }
                    
                    if let urlString = unwrappedUser.iconURLString {
                        if !self.urlStringBecomesValidURL(urlString) {
                            XCTFail("User \(unwrappedUser.userID) returns invalid url \(urlString)")
                        }
                    } else {
                        XCTFail("No icon URL found!")
                    }
                    
                } else {
                    XCTFail("User Parsing fail!")
                }
            } else {
                XCTFail("No result!")
            }
            
            expectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(localTimeout, nil)
    }


```

#5) Test Live Data

```swift
 //MARK: - Getting user data
    
    func testRetrievingUserData() {
        let expectation = expectationWithDescription("Got user data!")
        
        //Test against a known user - in this case, your instructor. 
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

#Display

`PhotoDataSource`

Add method to get users

```swift
	func getUserDetails(userID: String) {
        self.loadingUser = true
        FlickrAPIController().fetchDataForUser(userID) { [unowned self] (success, result) -> Void in
            self.loadingUser = false
            if let unwrappedResult = result {
                FlickrJSONParser.parseUserDictionary(unwrappedResult)
                CoreDataStack.sharedInstance().saveMainContext()
                
                if let visiblePaths = self.tableView.flk_visibleIndexPaths() {
                    self.tableView.reloadRowsAtIndexPaths(visiblePaths, withRowAnimation: .None)
                } //else nothing is visible.

                self.loadNextUserIfExists()
            } //else did not load.
        }
    }

```

Methods to queue up users to get

```swift
//MARK: - Downloading user information
    
    func addUserIDToDownloadArray(userID: String) {
        if !contains(userIDsToDownload, userID) {
            userIDsToDownload.append(userID)
        } //else this user is already in the download queue
        
        if !loadingUser {
            loadNextUserIfExists()
        } //else user will load after current item finishes
    }
    
    func loadNextUserIfExists() {
        let first = userIDsToDownload.first
        if let unwrappedFirst = first {
            userIDsToDownload.removeAtIndex(0)
            getUserDetails(unwrappedFirst)
        } //else nothing in the array
    }
```

update config

Before: 

```swift
	cell.userNameLabel.text = photoAtIndex.owner.userID
```

After:

```swift
	if let username = photoAtIndex.owner.name {
	    cell.userNameLabel.text = username
	} else {
	    cell.userNameLabel.text = photoAtIndex.owner.userID
	    
	    //Need some details!
	    addUserIDToDownloadArray(photoAtIndex.owner.userID)
	}
```


`PhotoDetailViewController`

Before: 

```swift
	userNameLabel.text = aPhoto.owner.userID
```

After: 

```swift
	userNameLabel.text = aPhoto.owner.name ?? aPhoto.owner.userID
```

Before

```swift


```

After:

```swift
if let iconString = aPhoto.owner.iconURLString {
            downloader.setImageFromURLString(iconString, toImageView: userAvatarImageView)
        } else {
            //Use placeholder.
            userAvatarImageView.image = UIImage(named: "rwdevcon-logo")
        }
```