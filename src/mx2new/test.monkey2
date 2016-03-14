
Namespace test

#Import "<std.monkey2>"

Using std

Class C

	Method Update() Virtual
	
		Print "C.Update()!"
		
		Assert( False )
	End

End

Function Test()

	Print "Test!"
	
	Local c:C
	
	c.Update()
	
	New C().Update()

End

Function Main()

	Local p:Int[]
	
	Local f:Float

	For Local i:=0 Until 10
		Local t:=String( i*2 )
		debug.Stop()
	Next

	Print "Hello World!"
	
	Local t:=New Int[10]
	
	t[9]=0

	Test()

End
