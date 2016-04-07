
Namespace test

Class E1 Extends Throwable
End

Class E2 Extends Throwable
End

Function F1()
	Throw New E1
End

Function F2()

	Try
		F1()
	Catch e1:E1
		Print "Caught E1"
		Throw
	End
End

Function F3()

	Try
		F2()
	Catch e1:E1
		Print "Caught E1"
		Throw New E2
	End
End

Function F4()
	Try
		F3()
	Catch e2:E2
		Print "Caught E2"
		Throw
	End
End

Function Main()

	Try
		F4()
	Catch e2:E2
		Print "Caught E2"
	End

End
