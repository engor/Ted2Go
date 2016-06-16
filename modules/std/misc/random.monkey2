
Namespace std.random

#rem

Random number generator is based on the xorshift128plus:

https://en.wikipedia.org/wiki/Xorshift

#end

Private

Global state0:ULong=1
Global state1:ULong=2

Public

#rem monkeydoc Seeds the random number generator.

@param seed The seed value.

#end
Function SeedRnd( seed:ULong )
	state0=seed
	state1=seed+ULong( 1 )
End

#rem monkeydoc Generates a random unsigned long value.

This is the core function used by all other functions in the random namespace that generate random numbers.

@return A random unsigned long value.

#end
Function RndULong:ULong()
	Local s1:=state0
	Local s0:=state1
	state0=s0
	s1~=s1 Shl 23
	s1~=s1 Shr 17
	s1~=s0
	s1~=s0 Shr 26
	state1=s1
	Return s1+s0
End

#rem monkeydoc Generates a random double value.

When used with no parameters, returns a random double value in the range 0 (inclusive) to 1 (exclusive).

When used with one parameter, returns a random double value in the range 0 (inclusive) to `max` (exclusive).

When used with two parameters, returns a random double value in the range `min` (inclusive) to `max` (exclusive).

@param min Minimum value to return.

@param max Maximum value to return.

#end
Function Rnd:Double()
	Return Double( RndULong() & ULong( $1fffffffffffff ) ) / Double( $20000000000000 )
End

Function Rnd:Double( max:Double )
	Return Rnd()*max
End

Function Rnd:Double( min:Double,max:Double )
	Return Rnd(max-min)+min
End
