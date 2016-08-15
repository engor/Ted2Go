
### User defined types

#### Classes

To declare a class:

`Class` _Identifier_ [ `Extends` _SuperClass_ ] [ `Implements` _Interfaces_ ] [ _Modifiers_ ]
```
	...Class members...
```
`End`

_SuperClass_ defaults to `Object` if omitted.
 
_Interfaces_ is a comma separated list of interface types.
 
_Modifiers_ can be one of:

* `Abstract` - class cannot be instantiated with 'New', it must be extended.
* `Final` - class cannot be extended.

Classes can contain consts, globals, fields, methods, functions and other user defined types.

#### Structs

To declare a struct:

`Struct` _Identifier_ 
```
	...Struct members...
```	
`End`

A struct can contain consts, globals, fields, methods, functions and other user defined types.

Structs are similar to classes, but differ in several important ways:

* A struct is a 'value type', whereas a class is a 'reference type'. This means that when you assign a struct to a variable, pass a struct to a function or return a struct from a function, the entire struct is copied in the process.

* Stucts are statically typed, whereas classes are dynamically typed.

* Struct methods cannot be virtual.

* A struct cannot extend anything.

#### Interfaces

To declare an interface:

`Interface` _Identifier_ [ `Extends` _Interfaces_ ]
```
	...Interface members...
```
`End`

_Interfaces_ is a comma separated list of interface types. 

An interface can contain consts, globals, fields, methods, functions and other user defined types.

Interface methods are always 'abstract' and cannot declared any code.


#### Fields

Fields are variables that live inside the memory allocated for an instance of a class or struct. To declare a field variable:

`Field` _identifier_ `:` _Type_ [ `=` _Expression_ ]
...or...
`Field` _identifier_ `:=` _Expression_

For struct fields, _Expression_ must not contain any code that has side effects.


#### Methods

To declare a method:

`Method` _Identifier_ [ `:` _ReturnType_ ] `(` _Arguments_ `)` [ _Modifiers_ ]
```
	...Statements...
```
`End`

_ReturnType_ defaults to `Void` if omitted.

_Arguments_ is a comma separated list of parameter declarations.

_Modifiers_ can only be used with class methods, and can be one of:

* `Abstract` - method is abstract and has no statements block or `End` terminator. Any class with an abstract method is implicitly abstract.
* `Virtual` - method is virtual and can be dynamically overridden by a subclass method.
* `Override` - method is virtual and overrides a super class or interface method.
* `Override Final` - method is virtual, overrides a super class or interace method and cannot be overridden by subclasses.
* `Final` - method is non-virtual and cannot be overridden by a subclass method.  

Methods are 'Final' by default.


#### Properties

To declare a read/write property:

`Property` _Identifier_ `:` _Type_ `()`
...getter code...
`Setter` `(` _Identifier `:` _Type_ `)`
...setter code...
`End`

To declare a read only property:

`Property` _Identifier_ `:` _Type_ `()`
...getter code...
`End`

To declare a write only property:

`property` `(` _Identifier `:` _Type_ `)`
...setter code...
`End`
