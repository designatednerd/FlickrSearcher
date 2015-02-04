#Xcode 6.1.1 Troubleshooting

A few tips to work around the rough edges of Swift. 

##Re-enabling Indexing (autocomplete + individual tests)

If autocomplete decides to take the afternoon off or none of your tests are running individually, there are some repeatable, albeit annoying, steps to get it working again. Modified from [these steps](http://stackoverflow.com/a/26596341/681493):

1. Quit Xcode. 
2. Go to `~/Library/Developer/Xcode` and delete the `DerivedData` folder. 
4. Go to `~/Library/Caches` and delete `~/Library/Caches/com.apple.dt.Xcode`.
5. Restart your computer. Yes, seriously.  
5. Restart Xcode. 