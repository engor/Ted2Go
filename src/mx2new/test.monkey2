
Namespace test

#Import "<std.monkey2>"

Using std..

Enum Mode
	Opaque
	Alpha
End

Struct Line

	Field state:Int
	
	Property Mode:Mode()
		Return _mode
	End
	
	Method update( line:Line )
		Self=line
	End
	
	Field _mode:=test.Mode.Opaque

End

Function Main()

	Local t:=1.5e-2
	
	Print t

	Local lines:=New Stack<Line>
	
	lines.Push( New Line )
	
'	lines[0].state=10

End
