
### Functions

#### Global functions

To declare a global function:

`Function` _Identifier_ [ `:` _ReturnType_ ] `(` _Arguments_ `)`
```
	...Statements...
```
`End`

_ReturnType_ defaults to `Void` if omitted.

_Arguments_ is a comma separated list of parameter declarations.


#### Lambda functions

To declare a lambda function:

...`Lambda` [ `:` _ReturnType_ `]` `(` _Parameters_ `)`
```
	...Statements...
```
`End`...

Lambda declarations must appear within an expression, and therefore should not start on a new line.

For example:

```
Local myLambda:=Lambda()
   Print "My Lambda!"
End

myLambda()
```

To pass a lambda to a function:

```
SomeFunc( Lambda()
   Print "MyLambda"
End )
```

Note the closing `)` after the `End` to match the opening `(` after `SomeFunc`.


#### Function values

Monkey2 supports 'first class' functions.

This means function 'values' can be stored in variables and arrays, passed to other functions and returned from functions.
