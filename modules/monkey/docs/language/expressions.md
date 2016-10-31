
### Expressions

#### Operators

| Operator			| Description				| Precedence
|:------------------|:--------------------------|:---------:
| `New`				| New object or array		| 1
| `Null`			| Null value				|
| `Self`			| Self instance				|
| `Super`			| Super instance			|
| `True`			| Boolean true				|
| `False`			| Boolean false				|
| `Typeof`			| Typeof operator			|
| `Cast`			| Cast operator				|
| `Lambda`			| Lambda function			|
| _identifier_		| Identifier				|
| _literal_			| Literal value				|
| | |
| `.`				| Postfix member acccess	| 2
| `( )`				| Postfix Invoke			|
| `[ ]`				| Postfix Index				|
| `< >`				| Postfix Generic instance	|
| | |
| `Varptr`			| Unary variable address	| 3
| `-`				| Unary numeric negate		| 
| `~`				| Unary integer complement 	|
| `Not`				| Unary boolean invert		|
| | |
| `*`				| Numeric multiplication	| 4
| `/`				| Numeric division			|
| `Mod`				| Numeric modulo			|
| | |
| `+`				| Numeric addition			| 5
| `-`				| Numeric subtraction		|
| | |
| `Shl`				| Integer shift left		| 6
| `Shr`				| Integer shift right		|
| | |
| `&`				| Integer and				| 7
| `~`				| Integer xor				|
| | |
| `\|`				| Integer or				| 8
| | |
| `<=>`				| Compare					| 9
| | |
| `<`				| Less than					| 10
| `>`				| Greater than				|
| `<=`				| Less than or equal		|
| `>=`				| Greater than or equal		|
| | |
| `=`				| Equal						| 11
| `<>`				| Not equal					|
| | |
| `And`				| Boolean and				| 12
| | |
| `Or`				| Boolean or				| 13
| | |
| `?` `Else`		| If-then-else				| 14

#### Type balancing

When evaluating an operator's operands, it is sometimes necessary to adjust the type of one or both operands.

When evaluating the operands of arithemetic or comparison operators, the following rules are used:

* If either operator String, the other is converted to String.
* Else If either operand is Double, the other is converted to Double.
* Else if either operand is Float, the other is converted to Float.
* Else if either operand is ULong, the other is converted to ULong.
* Else if either operand is Long, the other is converted to Long.
* Else if either operand is UInt, the other is converted to UInt.
* Else if either operand is unsigned, both are converted to UInt.
* Else both operands are converted to Int.

When evaluating the operands of the `&`, `|` and `^` integer operators, both operands must be integral types and are converted as follows:

* If either operand is ULong, the other is converted to ULong.
* Else if either operand is Long, the other is converted to Long.
* Else if either operand is UInt, the other is converted to UInt.
* Else if either operand is unsigned, both are converted to UInt.
* Else both operands are converted to Int.

When evaluating the operand of the `Shl` and `Shr` integer operators, the left-hand-side must be an integral type, while the right-hand-side 'shift amount' operand is converted to Int.

#### Operator overloading

Operator overloading allows you to customize the behavior of the built-in monkey2 operators for classes and structs.

You overload an operator by writing an 'operator method', which is effectively just a special kind of method. Operators must appear inside classes/structs - they cannot currently be 'global'.

Here is a simple example:
<pre>
 Struct Vec2

   Field x:Float
   Field y:Float

   Method New( x:Float,y:Float )
      Self.x=x
      Self.y=y
   End

   Method ToString:String()
      Return "Vec2("+x+","+y+")"
   End

   'Overload the addition operator.
   Operator+:Vec2( rhs:Vec2 )
      Return New Vec2( x+rhs.x,y+rhs.y )
   End

End
</pre>

The 'Operator+' declaration here defines an addition operator for Vec2. This is then used whenever a Vec2 appears as the 'left hand side' of an addition. For example:
<pre>
Function Main()
   Local v1:=New Vec2( 10.0,20.0 )
   Local v2:=New Vec2( 30.0,40.0 )
   Local v3:=v1+v2    'note: calls Operator+ in Vec2.
   Print v3.ToString()
End
</pre>

The following unary operators can be overloaded: `+` `-` `~`

The following binary operators can be overloaded: `*` `/` `Mod` `+` `-` `Shl` `Shr` `&` `|` `~` `=` `<>` `<` `>` `<=` `>=` `<=>`

The following assignment operators can be overloaded: `*=` `/=` `Mod=` `+=` `-=` `Shl=` `Shr=` `&=` `|=` `~=`

Indexing behaviour can also be overloaded using `[]` and `[]=`

Note that you cannot overload `Not`, `And`, `Or` or plain assignment `=`

Operators can return any type of value, and can take any type of value for their 'right hand side' argument(s). However, the precedence of operators cannot be changed.

The `[]` and `[]=` operators allow you to define 'indexing' like behaviour. The `[]` operator is used when an object is indexed, and `[]=` is used when an object is indexed and assigned. Both of these operators can accept any number of parameters of any type. The `[]=` operator requires an additional parameter that is the value to be assigned. This must appear at the end of the parameter list.

Here is an example of some indexing operators for the Vec2 class above:

<pre>
Struct Vec2

   ...as above...

   Operator[]:Float( index:Int )
      Assert( index=0 Or index=1 )
      If index=0 Return x Else Return y
   End

   Operator[]=( index:Int,value:Float )
      Assert( index=0 Or index=1 )
      If index=0 Then x=value Else y=value
   End
End
</pre>

With these additions, you can access Vec2 coordinates 'by index', eg:
<pre>
Function Main()
	Local v:=New Vec2
	v[0]=10.0
	v[1]=20.0
	Print v[0]
	Print v[1]
End
</pre>

You can also overload assignment operators, for example:
<pre>
Struct Vec2

	...as above...
	
	Operator+=( v:Vec2 )
		x+=v.x
		y+=v.y
	End
End
</pre>

If you have already written an Operator+ (as is the case here) this is not strictly necessary, as monkey2 will generate the code for Operator+= for you. However, you may still want to provide a custom version for Operator+= if your code can do so in a more efficient way.

