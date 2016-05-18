
Namespace test

Function Test:Float()
	Return 10
End

Global GlobalColor:Color

Struct Color

	Field r:Float
	Field g:Float
	Field b:Float
	Field a:Float=1
	
	Method New()
		a=Test()
	End
	
End

Function Main()

	Local color:Color
	
	Print color.a
	
	color=New Color
	
	Print color.a
End
