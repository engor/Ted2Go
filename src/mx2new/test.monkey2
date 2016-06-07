
Namespace test

#Import "<std>"

Using std..

Interface I1
End

Interface I2
	Method Test()
End

Class C1 Implements I1
End

Class C2 Implements I2
End

Class C3 Extends C1 Implements I2
	Method Test()
		Print "C3.Test"
	End
End

Enum E
	X,Y,Z
End

Function Main()

	Local i1:I1=New C3
	
	Local i2:I2=Cast<I2>( i1 )
	
	i2.Test()
	
	Local e:E=E.X
	
	Local t:Byte=e

End
