
#Import "<std.monkey2>"

Namespace test

Using std.random

Function Main()

	'Check my logic!
	If Double( $1fffffffffffff ) / Double( $20000000000000 )>=1 Print "ERROR!"

	Local freq:=New Int[10]
	
	For Local i:=0 Until 10000000
		freq[ Rnd()*10 ]+=1
	Next
	
	For Local i:=0 Until 10
		Print freq[i]
	Next
End
