
### Variables and Consts

#### Local variables

Local variables live on the stack. To declare a local variable:

`Local` _identifier_ `:` _Type_ [ `=` _Expression_ ]
...or...
`Local` _identifier_ `:=` _Expression_


#### Global variables

Global variables live in global memory and exist for the lifetime of the application. To declare a global variable:

`Global` _identifier_ `:` _Type_ [ `=` _Expression_ ]
...or...
`Global` _identifier_ `:=` _Expression_


#### Consts

Consts are stored in the same way as globals, but cannot be modified after they are initialized. To declare a const:

`Const` _identifier_ `:` _Type_ `=` _Expression_
...or...
`Const` _identifier_ `:=` _Expression_
