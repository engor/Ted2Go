
Namespace test

Class Ex Extends Exception
End

Function Test2( test:Int )
	Throw New Ex
End

Function Test( test:Int )
	Test2( 2 )
End

Function Main()
	Try
		Test( 1 )
	Catch ex:Ex
		Print "Caught Ex. DebugStack:"
		Print "~n".Join( ex.DebugStack )
		Throw ex
	End
End
