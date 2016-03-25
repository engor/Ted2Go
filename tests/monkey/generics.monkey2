
Namespace test

Interface I<T>
End

Class C<T>
	Function F1() Where T=String
	End
End

Class C2<T> Implements I<T>
End

Function T1<T>:T()
	Return Null
End

Function T2<C,T>( c:C<T> ) Where T Implements INumeric
End

Function T2<C,T>:C<T>() Where T Implements INumeric
	Return New C<T>
End

Function T3<C,T>() Where T Implements INumeric
End

Function T4<C,T>() Where C<T> Implements I<T>
End

Function Main()

	Local i1:=T1<Int>()
	Local i2:=T1<Float>()
	Local i3:=T1<String>()
	
'	Print i1.Length			'Error!
'	Print i2.Length			'Error!
	Print i3.Length			'0
	
'	C<Int>.F1()				'Error!
'	C<Float>.F1()			'Error!
	C<String>.F1()			'Error!
	
	T2( New C<Int> )
	T2( New C<Float> )
'	T2( New C<String> )		'Error!

	T2< C,Int >()
	T2< C,Float >()
'	T2< C,String >()		'Error!

	T3< C,Int >()
	T3< C,Float >()
'	T3< C,String>()			'Error!

'	T4< C,Int >()			'Error!
	T4< C2,Int >()
	
End
