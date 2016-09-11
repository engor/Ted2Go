
Class List<T>

	Struct Node
		Field data:T
	End
	
	Field head:=New Node
End

Function Main()

	Local list:=New List<Int>
	
	list.head.data=10
	
End
