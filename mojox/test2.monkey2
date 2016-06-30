
Global t:=New Float[100]

Function Main()

	Local sum:Float
	
	For Local i:=0 Until 100
	
		sum+=t[i]
		
		DebugAssert( True,"This better work!" )
	Next
	
End
