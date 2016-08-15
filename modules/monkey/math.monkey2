
Namespace monkey.math

Using monkey.types

#rem monkeydoc The value _Pi_.
#end
Const Pi:Double=3.1415926535897931

#rem monkeydoc The value _Pi_ times 2.
#end
Const TwoPi:Double=6.2831853071795862

Extern

#rem monkeydoc Computes the sine of an angle.

@param `x` the angle, in radians.

@return The sine of `x`.

#end
Function Sin:Double( x:Double )="std::sin"

#rem monkeydoc Computes the cosine of an angle.

@param `x` the angle, in radians.

@return The cosine of `x`.

#end
Function Cos:Double( x:Double )="std::cos"

#rem monkeydoc Computes the tangent of an angle.

@param `x` the angle, in radians.

@return The tangent of `x`.

#end
Function Tan:Double( x:Double )="std::tan"

#rem monkeydoc Computes the inverse sine of a number.

@param `x` The number.

@return The inverse sine of `x`, in radians.

#end
Function ASin:Double( x:Double )="std::asin"

#rem monkeydoc Computes the inverse cosine of a number.

@param `x` The number.

@return The inverse cosine of `x`, in radians.

#end
Function ACos:Double( x:Double )="std::acos"

#rem monkeydoc Computes the inverse tagent of a number.

@param `x` The number.

@return The inverse tangent of `x`, in radians.

#end
Function ATan:Double( x:Double )="std::atan"

#rem monkeydoc Computes the inverse tangent of a ratio.

The function uses the signs of `x` and `y` to compute the correct sign for the result.

@param `x` The numerator.

@param `y` The denominator.

@return The inverse tangent of `x`/`y`, in radians.

#end
Function ATan2:Double( x:Double,y:Double )="std::atan2"

#rem monkeydoc Computes the square root of a number.

@param `x` The number.

@return The square root of `x`.

#end
Function Sqrt:Double( x:Double )="std::sqrt"

#rem monkeydoc Computes the floor of a number.

@param `x` The number.

@return The largest integral value not greater than `x`.

#end
Function Floor:Double( x:Double )="std::floor"

#rem monkeydoc Computes the ceiling of a number.

@param `x` The number.

@return The smallest integral value not less than `x`.

#end
Function Ceil:Double( x:Double )="std::ceil"

#rem monkeydoc Rounds a number to the nearest integral value.

@param `x` The number.

@return The integral value nearest to `x`.

#end
#if __TARGET__="android"
Public
Function Round:Double( x:Double )
	Return Floor( x+.5 )
End
Extern
#else
Function Round:Double( x:Double )="std::round"
#endif


#rem monkeydoc Raises a number to a power.

@param `x` The number.

@return `x` raised to the power of `y`.

#end
Function Pow:Double( x:Double,y:Double )="std::pow"


#rem monkeydoc Computes the natural logarithm of a number.

@param `x` The number.

@return The natural logarithm of `x`.

#end
Function Log:Double( x:Double )="std::log"

#rem monkeydoc Computes the base 2 logarithm of a number.

@param `x` The number.

@return The base 2 logarithm of `x`.

#end
#if __TARGET__="android"
Public
Function Log2:Double( x:Double )
	Return Log(x)/Log(2)
End
Extern
#else
Function Log2:Double( x:Double )="std::log2"
#endif

#rem monkeydoc Computes the base 10 logarithm of a number.

@param `x` The number.

@return The base 10 logarithm of `x`.

#end
Function Log10:Double( x:Double )="std::log10"

#rem monkeydoc Raise _e_ to a power.

@param `x` The number.

@return The value _e_ raised to the power of `x`.

#end
Function Exp:Double( x:Double )="std::exp"


Public

#rem monkeydoc Gets the smaller of two numbers.

@return The smaller of `x` and `y`.

#end
Function Min<T>:T( x:T,y:T )
	If x<=y Return x
	Return y
End

#rem monkeydoc Gets the larger of two number.

@return The larger of `x` and `y`.

#end
Function Max<T>:T( x:T,y:T )
	If x>=y Return x
	Return y
End

#rem monkeydoc Clamps a value to a range.

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

#rem monkeydoc Gets the absolute value of a number.

If `x` is less than 0, then `-x` is returned.

If `x` is greater than or equal to 0, then `x` is returned.

@return The absolute value of `x`.

#end
Function Abs<T>:T( x:T ) Where T Implements INumeric
	If x>=0 Return x
	Return -x
End

#rem monkeydoc Gets the sign of a number.

Returns -1 is `x` less than 0, 1 if `x` is greater than 0 or 0 if `x` is equal to 0.

@return The sign of `x`.

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
