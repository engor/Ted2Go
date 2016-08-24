
***** Very early, very ugly Android support for monkey2 *****

VERY cumbersome! Involves copying build files around etc, but should work if you're curious!

Note: Only armeabi-v7a supported right now.


Setting up Android (The not so ugly bit):

1) Install Android Studio and make sure it works, ie: you can build and run one of the simple template projects on a device or emulator.

2) Install the 'NDK' (native development kit) using Android Studio via 'SDK Manager->SDK Tools'.

3) Edit your monkey2 bin/env_windows.txt file and change the ndk-bundle 'PATH' setting so it points to the NDK. Or, you can just add the
ndk-bundle dir to your system PATH.

4) Fire up Ted2 and select 'Build->Rebuild Modules->Android'.

5) With a bit of luck, this should build android versions of all your monkey2 modules for release and debug configs.


Building an App (The ugly bit):

1) Extract the 'Monkey2Game' zip in this directory somewhere poignant. This is the actual android project you will be 'creating'
in the following steps, and eventually running from within Android Studio. 

2) Build your app in Ted2 using 'Build->Build Only' with 'Build Settings->Android' selected. Either debug or release should work.

3) Go to the app's monkey2 build folder, ie: the '.buildvx.y.z/android_blah' folder next to your app's source code.

4) Copy the 'assets' folder from the monkey2 build folder to the android project's 'app/src/main/' folder.

5) Copy the *contents* of the 'libs' folder from the monkey2 build folder to the android projects 'app/src/main/jniLibs/' folder.
You should end up with something like this in your android project's app/src/main/ folder:

assets/
assets/asset1.png
assets/asset2.png...etc...
jniLibs/
jniLibs/armeabi-v7a
jniLibs/armeabi-v7a/libmx2_main.so
jniLibs/armeabi-v7a/libopenal.so
jniLibs/armeabi-v7a/libSDL2.so

6) You should now theoretically be able to run the android project from within Android Studio (this may involve a bit of trial and error).

The 'libmx2_main.so' file is the only one that actually changes when you rebuild via monkey2, so once you're up and running you can just copy that across.

I also recommend disabling the following setting for mx2 Android Studio projects:

File->Settings->Build, Execution, Deployment->Instant Run->Enable Instant Run

With this enabled, Android Studio doesn't seem to notice when external project files change, eg: when you copy new assets/libs across.

If all else fails and rebuilding doesn't seem to be uploading your changes, uninstall the app from the device and try again!



