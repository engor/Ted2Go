
Namespace test

#Import "<std.monkey2>"

Using std

Function RemoveOddValues<C,T>( c:C<T> ) Where C<T> Implements IContainer<T>

	Local it:=c.All()
	While it.Valid
		If it.Current & 1
			it.Erase()
		Else
			it.Bump()
		Endif
	Wend
	
End

Function PrintEachin<C,T>( c:C<T> ) Where C<T> Implements IContainer<T>

	For Local value:=Eachin c
		Print value
	Next
End

Function Main()

	Local stack:=New Stack<Int>( New Int[]( 5,4,3,2,1 ) )

	stack.Sort()
		
	Local list:=New List<Int>
	
	list.AddAll( stack )
	
	list.AddAll( New Int[]( 6,7,8,9,10 ) )
	
	RemoveOddValues( list )
	
	PrintEachin( list )	'2,4,6,8,10
	
End
