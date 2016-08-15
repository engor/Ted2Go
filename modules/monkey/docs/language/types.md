
### Monkey2 types

#### Primitive types

The following primtive types are supported by monkey2:

| Type		| Description
|:----------|:-----------
| `Void`	| No type.
| `Bool`	| Boolean type.
| `Byte`	| 8 bit signed integer.
| `UByte`	| 8 bit unsigned integer.
| `Short`	| 16 bit signed integer.
| `UShort`	| 16 bit unsigned integer.
| `Int`		| 32 bit signed integer.
| `UInt`	| 32 bit unsigned integer.
| `Long`	| 64 bit signed integer.
| `ULong`	| 64 bit signed integer.
| `Float`	| 32 bit floating point.
| `Double`	| 64 bit floating point.
| `String`	| String of 16 bit characters.


#### Compound types

The following compound types are supported by monkey2:

| Type						| Description
|:--------------------------|:-----------
| _Type_ `[]`				| Array type
| _Type_ `Ptr`				| Pointer type
| _Type_ `(` _Types_ `)`		| Function type


#### Implicit type conversions

These type conversions are performed automatically:

| Source type					| Destination type
|:------------------------------|:-----------------
| Any numeric type	 			| `Bool`
| String or array type 			| `Bool`
| Class or interface type	 	| `Bool`
| Any numeric type				| Any numeric type
| Any numeric type				| `String`
| Any pointer type				| `Void Ptr`
| Any enum type					| Any integral type
| Class or interface type		| Base class type or implemented interface type

When numeric values are converted to bool, the result will be true if the value is not equal to 0.

When strings and arrays are converted to bool, the result will be true if the length of the string or array is not 0.

When class or interface instances are converted to bool, the result will be true if the instance is not equal to null.

When floating point values are converted to integral values, the fractional part of the floating point value is simply chopped off - no rounding is performed.


#### Explicit type conversions

The `Cast` `<` _dest-type_ `>` `:` _dest-type_ `(` _expression_ `)` operator must be used for these type conversions:

| Source type			| Destination type
|:----------------------|:-----------------
| `Bool`				| Any numeric type
| `String`				| Any numeric type
| Any pointer type		| Any pointer type, any integral type
| Any integral type		| Any pointer type, any enum type
| Class type			| Derived class type, any interface type
| Interface type		| Any class type, any interface type

When casting bool values to a numeric type, the result will be 1 for true, 0 for false.
