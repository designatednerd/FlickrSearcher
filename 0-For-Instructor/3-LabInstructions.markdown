#XCTest In Practice, Part 3: Lab

One of the most frustrating things that can happen as a developer is when you make a change that causes your app to crash on launch. One of the easiest ways to do this is to make a change to your Core Data schema without properly versioning it. 

It’s easy to miss because you’re constantly deleting and reinstalling your application from the simulator, so schema changes won’t always affect your application during the testing process. But your users haven’t been deleting and reinstalling your app constantly - so they see a crash. 

#Lab: Test That Your Core Data Model Can Open Existing SQLite Files

For the lab, you will test if this application can properly complete automatic migration of the Core Data store, so that it does not crash on launch. 

#1) Get Old Versions of the Database. 

By having copies of the database on hand that are from specific points, you’ll be able to test that your updated database schemas will be able to open that version. 

Note that these copies should be grabbed from the simulator, not a device, since you can access the filesystem on the simulator *significantly* more easily than you can on a device, and the databases on simulator and device are identical (at least for the purposes of what will open with a given Core Data Model version). 

##a) Find the old versions of the database. 

First, you need to figure out where the file is being stored. There’s a convenience method to do this on the `CoreDataStack` class called `databaseFileURL()`. 

You want to log this out somewhere it will definitely get hit. Since the `CoreDataStack`’s `coordinator()` method uses the `databaseFileURL()` method, this is an ideal place to log out the file URL. 

Add the following line right above where you’re adding the persistent store to the persistent store coordinator:  

```swift
NSLog("Persistent store file path: \(url?.path)")
```

Build and run the application, and this line will log out the full file path on the simulator: 

![](lab_images/log_of_path.png)

Once you have that full file url, open up Finder, and select `Go > Go To Folder...` from the menu, and paste the path (the bit between the quote marks) into the dialog that comes up: 

![](lab_images/paste_in_dialog.png)

You will then be taken to the folder on your simulator where the `.sqlite` file has been output. You'll see 3 files with the same name but different extensions in that directory: 

- `FlickrSearcher.sqlite` - The main database file. This is what you'll use for migration tests.
- `FlickrSearcher.sqlite-wal`- The [write-ahead log](https://www.sqlite.org/wal.html), which allows easier rollback of database transactions
- `FlickrSearcher.sqlite-shm` - The shared memory file, which facilitates sharing memory between the main database and the write-ahead log. 

You'll want to copy all three files. For this particular test, you'll only need the `.sqlite` file, but for other tests in the future which involve migrating actual data, you may need to have all three files. 

Create a folder under `FlickrSearcherTests` called `old_database_versions`. Then create a folder within that called `starter_database`. Paste the `.sqlite`, `.sqlite-shm`, and `.sqlite-wal` files into this folder. 

Rename all three files so that instead of `FlickrSearcher.sqlite` etc, they are named `starter_database.sqlite`, `starter_database.sqlite-shm`, and `starter_database.sqlite-wal`. Renaming the files for each version ensures that no version ever accidentally overwrites another version when you’re compiling your targets.

Once all these files have been gathered, drag the entire `old_database_files` folder into Xcode - make sure that the files are added to the test target, **not** the main target:

![](lab_images/add_to_test_target.png)

When you’re finished, your files should look like this: 

![](lab_images/databases_added.png)

#2) Create a common testing method

It helps keep logic separate to create new classes for explicitly different types of test. Since this test is pretty different then the existing tests, go to `File > New > File...` and create a new Swift file. 

Name your class `CoreDataMigrationTests`, and place it in the `FlickrSearcherTests` folder and add it to the `FlickrSearcherTests` bundle (not the main application bundle) when creating it. 

First, add the appropriate imports and have your new class inherit from `BaseTests` to grab a couple of convenience methods: 

```swift
//Import testing + iOS frameworks
import UIKit
import XCTest
import CoreData

//Import the module you wish to test.
import FlickrSearcher

class CoreDataMigrationTests : BaseTests {

}
```

Since you will want to test multiple versions of the database, create a common method to test based on the file name. First, you'll want to make sure that your helper method can find the file you're looking for: 

```swift
func performAutomaticMigrationTestWithStoreName(name: String) {
  //Grab the SQLite file that is in the test bundle with this class
  let bundle = NSBundle(forClass:self.dynamicType)
  let storeURL = bundle.URLForResource(name, withExtension:"sqlite")
  if let storeURL = storeURL {

    //TODO: More Code!            

  } else {
    XCTFail("Cannot find \(name).sqlite")
  }
}
```

Next, you’ll want to create an individual test to have the helper method try opening a single database file: 

```swift
func testStarterDatabaseCanBeOpened() {
  performAutomaticMigrationTestWithStoreName("starter_database")
}
```

Run this individual test - if your test fails here, it means your `starter_database` files are not being found by the system. Make sure you’ve added them to the proper target!

Next, look for the current Managed Object Model in the main bundle, and load it up. Replace the `TODO` you added above with the following (note: These constants are defined in `CoreDataStack.swift`): 

```swift
let modelURL = NSBundle.mainBundle().URLForResource(ManagedObjectModelName, withExtension:ManagedObjectModelExtension)
if let modelURL = modelURL {
  let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
  if let managedObjectModel = managedObjectModel {

    //TODO: Do tests with the model. 

  } else {
    XCTFail("Could not load model!");
  }
} else {
  XCTFail("Model URL was nil!")
}
```

Run the test again - this test should pass unless you’ve changed the name of the `.xcdatamodeld` file or any of its sub-files. 

You’ve confirmed you have the stored `.sqlite` file and are accessing the stored managed object model. Now it’s time to see if you can open it. 

Create an `NSPersistentStoreCoordinator` and persistent store independent of the main stack, and try to open the store using the standard automatic migration options. Replace the `TODO` you just added with the following: 

```swift
let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
let options = [
  NSMigratePersistentStoresAutomaticallyOption : true,
  NSInferMappingModelAutomaticallyOption : true,
]
	
var error: NSError?
let persistentStore = persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType,  
                           configuration:nil,
                           URL:storeURL,
                           options:options,
                           error:&error)
	
XCTAssertNotNil(persistentStore, "Cannot load persistentStore: \(error)");
```

If this test fails on the not-nil assertion, it means that your current managed object model cannot open this database. 

Since this version of the database was built using an identical version of the Core Data schema, it should pass immediately. So how do you tell if this test is working? 

#3) Check That It Fails After You Make A Change To The Database

Since you want this test to fail hard after an incompatible change, you can check it very easily by adding a new attribute to one of your entities. Go to your Core Data model, and add a `name` String attribute to your `User` entity: 

![](lab_images/add_name.png)

Run the migration test again, and SPLAT: 

![](lab_images/test_failola.png)

The test fails because the `NSPersistentStoreCoordinator` can’t open the database with this updated model. 

Delete the `name` attribute from your `User` entity, and run the test one more time - notice that it passes, since now the schema is back to what it was when the database was created. 

You will now have a quick warning any time you make changes to your schema that won’t work with the released version of your database. 

In the challenge, you’ll cover the correct way to do this - using Core Data versions to take advantage of automatic migration. 

#Notes

This technique is inspired by Oliver Drobnik's post on [testing core data migrations](http://www.cocoanetics.com/2013/01/unit-testing-coredata-migrations/) in Objective-C. 

In the real world, you'll want to make sure that you're tagging your releases in version control so that you can always go back to see exactly what your code was at the point when that version was released. 

On [Hum](http://justhum.com), this technique is used to test a database file from each major/minor/point release of our application: 

![](lab_images/hum_databases.png)

Remember: This is only testing if the database can be opened without the app crashing. It will **NOT** test if any content which needs to be migrated has been migrated properly. Separate tests should be written for that case. 