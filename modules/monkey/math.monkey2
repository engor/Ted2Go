
Namespace monkey.math

Using monkey.types

Const Pi:Double=3.1415926535897932384626433832795028841971693993751058209749445923078164062

Extern

Function Sin:Double( x:Double )="std::sin"

Function Cos:Double( x:Double )="std::cos"

Function Tan:Double( x:Double )="std::tan"

Function ASin:Double( x:Double)="std::asin"

Function ACos:Double( x:Double)="std::acos"

Function ATan:Double( x:Double)="std::atan"

Function ATan2:Double( x:Double)="std::atan2"

Function Sqrt:Double( x:Double )="std::sqrt"

Function Floor:Double( x:Double )="std::floor"

Function Ceil:Double( x:Double )="std::ceil"

Function Round:Double( x:Double )="std::round"

Public

#rem monkeydoc

Returns the smaller of two values.

@return the smaller of `x` and `y`.

#end
Function Min<T>:T( x:T,y:T )
	If x<=y Return x
	Return y
End

#rem monkeydoc

Returns the larger of two values.

@return the larger of `x` and `y`.

#end
Function Max<T>:T( x:T,y:T )
	If x>=y Return x
	Return y
End

#rem monkeydoc

Clamps a value to a range.

If `x` is less than `min`, `min` is returned.

If `x` is greater than `max`, `max` is returned.

Otherwise, `x` is returned.

@return `x` clamped to the range [`min`,`max`].

#end
Function Clamp<T>:T( value:T,min:T,max:T )
	If value<=min Return min
	If value>=max Return max
	Return value
End

#rem monkeydoc

Returns the absolute value of a number.

If `x` is less than 0, then `-x` is returned.

If `x` is greater than or equal to 0, then `x` is returned.

@return the absolute value of `x`.

#end
Function Abs<T>:T( x:T ) Where T Implements INumeric
	If x>=0 Return x
	Return -x
End

#rem monkeydoc

Returns the sign of a number.

If `x` is less than 0, the value -1 is returned.

If `x` is equal to 0, the value 1 is returned.

Otherwise, if `x` is equal to 0, 0 is returned.

@return the sign of `x`.

#end
Function Sgn<T>:Int( x:T ) Where T Implements IIntegral
	If x<0 Return -1
	If x>0 Return 1
	Return 0
End

Function Sgn<T>:Double( x:T ) Where T Implements IReal
	If x<0 Return -1
	If x>0 Return 1
	Return 0
End
