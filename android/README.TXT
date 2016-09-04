
***** Mostly functional android support for monkey2 *****

Note: Only armeabi-v7a supported right now.

Setting up for Android development:

1) Install android studio and make sure it works, ie: you can build and run one of the simple template projects on a device or emulator.

2) Install the 'NDK' (native development kit) using android studio via 'SDK Manager->SDK Tools'.

3) Edit your monkey2 bin/env_windows.txt file and change the ndk-bundle 'PATH' setting so it points to the NDK. Or, you can just add the
ndk-bundle dir to your system PATH.

4) Fire up Ted2 and select 'Build->Rebuild Modules->Android'. Wait...


Building an Android app:

1) Build your app in Ted2 using 'Build->Build Only' with 'Build Target->Android' selected. Either debug or release should work.

2) Open the generated Android Studio project (at myapp.products/Android) and attempt to run it!

Note: I recommend *disabling* the following android studio setting for mx2 dev:

File->Settings->Build, Execution, Deployment->Instant Run->Enable Instant Run

With this enabled, android studio doesn't seem to notice when external project files change.
