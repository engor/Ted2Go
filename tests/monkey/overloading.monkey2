
Namespace test

Class C<T>
End

Function F1( t:Int )
	Print "F1( Int )"
End

Function F1<T>( t:T )
	Print "F1( T? )"
End

Function F1( t:Void() )
	Print "F1( Void() )"
End

Function F1<T>( t:T() )
	Print "F1( T?() )"
End

Function F1<C>( c:C<Int> )
	Print "F1( C?<Int> )"
End

Function F1<C,T>( c:C<T> )
	Print "F1( C?<T?> )"
End

Function F2()
End

Function F3:Int()
	Return 0
End

Function Main()

	F1( 10 )				'F1( Int )
	F1( 10.0 )				'F1( T? )
	F1( F2 )				'F1( Void() )
	F1( F3 )				'F1( T?() )
	F1( New C<Int> )		'F1( C?<Int> )
	F1( New C<Float> )		'F1( C?<T?> )
	
End
