
Namespace test

'#Import "<std.monkey2>"

Class B
End

Struct Test
	Field z:Int
	Field y:Int
	Field x:Int
	Field a:Int
	Field b:Int
	Field c:Int
	Field m:B
End

Class C
	Field t:=New Test[10]
End

Function Main()
	Local c:=New C
	c.t[0].x=10
End
