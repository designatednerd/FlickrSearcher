#XCTest Troubleshooting
=====

##Re-enabling Individual Tests

One thing you will know if you've tried to do Swift Unit testing previously: You will often not be able to see the little diamonds that allow you to run individual tests. 

The most repeatable steps I've found to fix this are: 

1. Open the project you want to test. 
2. Open the Organizer, and select the project in the organizer.
3. Close the window of the project you want to test. 
4. After the window has closed, delete the derived data folder of the project you want to test. 
5. Re-open the project you want to test, and build it. 

**Usually**, this will lead to the individual test diamonds being regenerated. This is not a 100% consistent process, and will often require a restart of Xcode or in the very worst cases, a full reboot of your machine. 

If anyone's got better suggestions on how to make this process less horrendous, I'd love to hear them. 
