
***** Welcome to Monkey2! *****

Some notes:

Emscripten support is currently disabled.

Doscs are currently limited to a VERY simple monkey2-quick-reference.html file.

The repository currently contains a fair few binaries. Some of these will go when a module manager happens, but it's likely prebuilt versions of mx2cc will remain as it's a fairly tricky process building mx2cc without mx2cc! May work on this later though...

Modules should be considered works in progress and subject to change, esp. the 'std' module. My current goal is to get these modules finalized and docced ASAP so people can start using them with confidence. More modules will be added to the repository over time as they are completed.


***** Installation on Windows *****

Before getting started, make sure the monkey2 folder is installed alongside (not inside!) an existing monkey1 installation. This will allow you to use the monkey1 IDE to launch the monkey2 compiler. If you don't already have monkey1, a free version is available from the 'shop' page at monkey-x.com

1) Download and extract mingw64-4.9.2 into the monkey2\devtools directory. A self extracting archive of mingw64 is available here: "http:/www.monkey-x.com/mak/devtools/TDM-GCC-64-4.9.2.exe". While it is possible to use an existing installation of mingw64 with monkey2, it is not recommended as it may cause version conflicts. In particular, mingw64-5.1.0 should not be used as it contains a linker bug.

2) Once mingw64 is installed, open a command prompt and change to the 'monkey2\src' directory.

3) Enter 'rebuildmods' and hit return. Wait...

4) Enter 'rebuildmx2cc' and hit return. Wait...

5) You should now be able to build and run monkey2 apps with monkey1. There is a 'simple hello-world.monkey2' test in the monkey2 directory.

6) Following a github update, you may need to rebuild the compiler. To do this, perform steps 2-4 again.


***** Installation on MacOS/Linux *****

Before getting started, make sure the monkey2 folder is installed alongside (not inside!) an existing monkey1 installation. This will allow you to use the monkey1 IDE to launch the monkey2 compiler. If you don't already have monkey1, a free version is available from the 'shop' page at monkey-x.com

1) Install the xcode command line tools. You can do this by entering 'xcode-select --install' in a shell.

2) Open a shell and change to the 'monkey2/src' directory.

3) Enter './rebuildmods.sh' and hit return. Wait...

4) Enter './rebuildmx2cc.sh' and hit return. Wait...

5) You should now be able to build and run monkey2 apps with monkey1. There is a simple 'hello-world.monkey2' test in the monkey2 directory.

6) Following a github update, you may need to rebuild the compiler. To do this, perform steps 2-4 again.


***** More information *****

Monkey2 patreon page: https://www.patreon.com/monkey2?ty=h

Monkey2 development blog: http://monkey2.monkey-x.com/

Monkey2 development forums: http://monkey2.monkey-x.com/forums

Monkey2 xmas 2015 demo: http://monkey2.monkey-x.com/2015/12/23/xmas-demo-2015/

