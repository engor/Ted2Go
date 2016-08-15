
@manpage The mx2cc compiler

Mx2cc is the command line compiler for monkey2. The actual executable is named differently depending on the OS:

/bin/mx2cc_windows.exe  
/bin/mx2cc_macos  
/bin/mx2cc_linux  

The command line options for mx2cc are:

`mx2cc` _command_ _options_ _input_

Valid commands are:

* `makeapp` - make an app. _input_ should be a monkey2 file path.
* `makemods` - make a set of modules. _input_ should be a space separated list of module names, or nothing to make all modules.
* `makedocs` - make the documentation for a set of modules. _input_ should be a space separated list of module names, or nothing to make all modules.

Valid options are:

* `clean` - rebuilds everything from scratch.
* `verbose` - provides more information while building.
* `target=`_target_ - set target to `desktop` (the default) or `emscripten`.
* `config=`_config_ - set config to `debug` (the default) or `release`.
* `apptype=`_apptype_ set apptype to `gui` (the default) or `console`.
