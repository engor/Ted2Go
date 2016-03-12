
Namespace test

Interface I
	Method M1()
End

Interface J Extends I
	Method M2()
End

Interface K Extends I
	Method M3()
End

Interface L Extends J,K
	Method M4()
End

Class C Implements I
	Method M1()
	End
End

Class D Extends C Implements J
	Method M2()
	End
End

Class E Extends D Implements L
	Method M3()
	End
End

Class F Extends E
	Method M4()
	End
End

Function Main()

	New C
	New D
'	New E	'Error! M4() not implemented
	New F
End
