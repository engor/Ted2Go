
Namespace test

#Import "externs.cpp"
#Import "externs.h"

Extern

Enum E="test::E"

	V1
	V2

End

Enum E2="test::E2::"

	V1
	V2

End

Class C Extends Void="test::C"

	Class D
		Function F()
	End
	
	Field P:Int

	Global G:Int
	
	Const T:Int
	
	Method M()
	
	Function F()
End

Public

Function Main()

	Local c:=New C
	
	Local p:=c.P
	Local g:=C.G
	Local t:=C.T

	c.M()
	C.F()
	C.D.F()
	
	Local v1:=E.V1
	Local v2:=E.V2
	
	Local t1:=E2.V1
	Local t2:=E2.V2
	
End
