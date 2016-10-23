
Namespace test

#Import "<std>"
#Import "<mojo>"

Using std..
Using mojo..

Function Test( v:Vec2f )
End

Enum E
	X,Y,Z
End

Function Main()

	Local e:=E.Z
	
'	Local v:=Variant( e )
	
'	Print v.Type
	
'	Print Int( Cast<E>( v ) )
	
	Local v2:=Variant( New Vec2( 1,1 ) )

End
