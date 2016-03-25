
Namespace test

#Import "<std>"

Using std.collections

Function Test<T>() Where T Implements IContainer<Int>

'	If T Extends IContainer<Int>
'		Print "YES!"
'	Else
'		Print "NO!"
'	Endif
	
End

Function Main()

	Test< List<Int> >()
	
End
