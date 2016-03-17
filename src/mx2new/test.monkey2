
Namespace test

#Import "<libc.monkey2>"

Class List<T>

	Method First:T()
		Return Null
	End
	
End

Interface I

	Method Render()

	Method Update() Default Virtual
		Render()
		Print "Update!"
	End

End

Class C Implements I

	Method Render()
	End	

End

Class D Extends C

	Method Update() Override
	End
	
End

Function Test<T>:T( x:T,y:T ) Where T Implements INumeric
	Return x<y ? x Else y
End

Function Test<T>:T( x:T,y:T ) Where T=String
	Return x+y
End

Function Sizeof<T>:Int()
	Return libc.sizeof( Cast<T Ptr>( Null )[0] )
End

Function Read<T>:Int()
	Return Null
End

Struct S
	Field x:Float
	Field y:Float
End

Function Main()

	Print Sizeof<S>()

	Print Int( String Implements INumeric )

	Print Test( 10,20 )

	Print Test( 10.0,20.0 )

	Print Test( "20","10" )
	
	#rem
	Local c:=New C
	
	c.Update()
	
	Local list:=New List<Int>
	
	Local t:=list.First()
	#end
	
End
