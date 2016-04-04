
Namespace test

#Import "<libc>"

Function Test2()
	Print "Debug Stack:"
	Print "~n".Join( GetDebugStack() )
End

Function Test()
	Test2()
End

Function Main()
	Test()
	Print "Bye!"
End
