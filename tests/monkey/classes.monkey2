
Namespace test

Class B Abstract

	Method M0() Abstract

End

Class C	Extends B

	Method M1()
	End
	
	Method M2() Virtual
	End
	
	Method M3() Final
	End
	
End

Class D Extends C

	Method M0() Override Final
	End

'	Method M1()	'Error! Overrides non-virtual method
'	End
	
'	Method M2()	'Error! Needs 'Override'
'	End
	
	Method M2() Override
	End
	
'	Method M3() Override	'Error! M3 is Final!
'	End
	
End

Class E Extends D Final

'	Method M0() Override	'Error! M0 is final
'	End
	
'	Method M2() Virtual	'Error! Needs 'Override'
'	End
	
End

'Class F Extends E	'Error! E is final!
'End

Function Main()

	Print "Running classes test"

'	New B	'Error! B is abstract
'	New C	'Error! C is abstract
	New D
	New E
	
End
