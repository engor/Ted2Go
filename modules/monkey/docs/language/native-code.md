
### Integration with native code

In order to allow monkey2 code access to native code, monkey2 provides the 'extern' directive.

Extern begins an 'extern block' and must appear at file scope. Extern cannot be used inside a class or function. An extern block is ended by a plain 'public' or 'private' directive.

Declarations that appear inside an extern block describe the monkey2 interface to native code. Therefore, functions and methods that appear inside an extern block cannot have any implementation code, as they are already implemented natively.

Otherwise, declarations inside an extern block are very similar to normal monkey2 declarations, eg:

```
Extern

Struct S
   Field x:Int
   Field y:Int
   
   Method Update()   'note: no code here - it's already written.
   Method Render()   'ditto...
End

Global Counter:Int

Function DoSomething( x:int,y:Int )
```


#### Extern symbols

By default, monkey2 will use the name of an extern declaration as its 'symbol'. That is, when monkey2 code that refers to an extern declaration is compiled, it will use the name of the declaration directly in the generated output code.

You can modify this behaviour by providing an 'extern symbol' immediately after the declarations type, eg:

```
Extern

Global Player:Actor="mylib::Player"

Class Actor="mylib::Actor"
	Method Update()
	Method Render()
	Function Clear()="mylib::Actor::Clear"
End
```


#### Extern classes

Extern classes are assumed by default to be *real* monkey2 classes - that is, they must extend the native bbObject class. 

However, you can override this by declaring an extern class that extends `Void`. Objects of such a class are said to be native objects and differ from normal monkey object in several ways:

* A native object is not memory managed in any way. It is up to you to 'delete' or otherwise destroy it.

* A native object has no runtime type information, so it cannot be downcast using the `Cast<>` operator.
 
 ---

### The mx2cc tool

mx2cc is the command line compiler for monkey2. The actual executable is named differently depending on the OS:

/bin/mx2cc_windows.exe
/bin/mx2cc_macos
/bin/mx2cc_linux

The command line options for mx2cc are:

`mx2cc` _command_ _options_ _input_

Valid commands are:

* `makeapp` - make an app. _input_ should be a monkey2 file path.
* `makemods` - make a set of modules. _input_ should be a space separated list of module names in dependency order.
* `makedocs` - make the documentation for a set of modules. _input_ should be a space separated list of module names in dependency order.

Valid options are:

* `clean` - rebuilds everything from scratch.
* `verbose` - provides more information while building.
* `target=`_target_ - set target to `desktop` (the default) or `emscripten`.
*  `config=`_config_ - set config to `debug` (the default) or `release`.
* `apptype`=_apptype_ set apptype to `gui` (the default) or `console`.

