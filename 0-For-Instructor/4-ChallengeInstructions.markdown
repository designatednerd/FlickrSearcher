#XCTest In Practice, Part 4: Challenge

One of the most frustrating things

This will test if the application can properly complete automatic migration of the  CoreData store - if that store is not properly migrated, the app will crash on launch.


#Challenge: Test automatic migrations from old versions of the database

For your final challenge, you'll add the ability to make sure your automatic migrations are working smoothly. 

#1) Get old versions of the database. 

First, you'll need to grab old versions of the database from the simulator. If you can figure out where the database file is stored (hint: There's a helper method for this in all versions of the project), you can log  out its full file URL. 

NOTE: In the real world, you'll want to make sure that you're tagging your releases in version control so that you can always go back to see exactly what your code was at the point when that version was released. 

Once you have that full file url, open up Finder, and select `Go > Go To Folder...` from the menu, and paste the path (the part that starts with `/Users/[your username]`) into the dialog that comes up. You will then be taken to the folder on your simulator where the `.sqlite` file has been output. 

You'll see 3 files with the same name but different extensions in that directory: 

- `FlickrSearcher.shm` - //TODO
- `FlickrSearcher.sqlite` - The main database file. This is what you'll use for migration tests.
- `FlickrSearcher.wal`- The write-ahead log, which //TODO

You'll want to copy all three files. For this particular test, you'll only need the `.sqlite` file, but for other tests in the future you may need to have all three. 

Create a folder under `FlickrSearcherTests` called `OldDatabaseVersions`. Then create a folder within that for each part: `starter_database`, `after_demo_database`, and `after_lab_database`. 

You will need to repeat this step with the Starter Project, the Demo Complete project, and the Lab Complete database. 

Once all these files have been gathered, drag the folder into Xcode - make sure that the files are added to the test target, **not** the main target. 


#2) Create a common testing method

Start with a new class to keep logic seperate - Name your class `CoreDataMigrationTests`. It should inherit from `BaseTests`. 

Since you will want to test multiple versions of the database, create a common method to test based on the file name. 

First, you'll want to make sure that your test can find the file you're looking for: 


```swift

    func performAutomaticMigrationTestWithStoreName(name: String) {
        //Grab the SQLite file that is in the test bundle with this class
        let bundle = NSBundle(forClass:self.dynamicType)
        let storeURL = bundle.URLForResource(name, withExtension:"sqlite")
        if let unwrappedStoreURL = storeURL {
			//TODO: More Code!            
        } else {
            XCTFail("Cannot find \(name).sqlite")
        }
    }
```

Next, look for the current Managed Object Model in the main bundle, and load it up (note: These constants are defined in `CoreDataStack.swift`): 

```swift
	let modelURL = NSBundle.mainBundle().URLForResource(ManagedObjectModelName, withExtension:ManagedObjectModelExtension)
	if let unwrappedModelURL = modelURL {
	    let managedObjectModel = NSManagedObjectModel(contentsOfURL: unwrappedModelURL)
	    if let unwrappedModel = managedObjectModel {
	
	    } else {
	        XCTFail("Could not load model!");
	    }
	} else {
	    XCTFail("Model URL was nil!")
	}
```

Create a persistent store coordinator and persistent store independent of the main stack, and see if it can use the automatic migration options to open the store. 
```swift
	let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: unwrappedModel)
	let options = [
	    NSMigratePersistentStoresAutomaticallyOption : true,
	    NSInferMappingModelAutomaticallyOption : true,
	]
	
	var error: NSError?
	let persistentStore = persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil,
	    URL:storeURL,
	    options:options,
	    error:&error)
	
	XCTAssertNotNil(persistentStore, "Cannot load persistentStore: \(error)");
```
#3) Create functions to test each database.

```swift
    func testStarterDatabaseCanBeOpened() {
        performAutomaticMigrationTestWithStoreName("starter_database")
    }
```

Pass!

#4) Check that it fails after you make a change to the database

Add random field, run again. Fail!

#Notes

This technique is inspired by Oliver Drobnik's post on [testing core data migrations](http://www.cocoanetics.com/2013/01/unit-testing-coredata-migrations/) in Objective-C. 

Remember: This is only testing if the database can be opened without the app crashing. It will NOT test if any content which needs to be migrated has been migrated properly. Seperate tests should be written for that case. 