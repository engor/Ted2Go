
Namespace std

#rem monkeydoc List class.

#end
Class List<T> Implements IContainer<T>

	Class Node
	
		Field _succ:Node
		Field _pred:Node
		Field _value:T
		
		Method New( value:T )
			_value=value
		End
		
		Property Value:T()
			Return _value
		End
		
		Property Succ:Node()
			Return _succ
		End
		
		Property Pred:Node()
			Return _pred
		End
		
	End
	
	Struct Iterator 'Implements IIterator<T>
	
		Field _list:List
		Field _node:Node
		Field _seq:Int
		
		Method New( list:List,node:Node )
			_list=list
			_node=node
			_seq=list._seq
		End
		
		Method AssertSeq()
			DebugAssert( _seq=_list._seq,"Concurrent list modification" )
		End
		
		Method AssertValid()
			DebugAssert( Valid,"Invalid list iterator" )
		End
		
		Property Valid:Bool()
			AssertSeq()
			Return _node<>Null
		End
		
		Property Current:T()
			AssertValid()
			Return _node._value
			
		Setter( current:T )
			AssertValid()
			_node._value=current
		End
		
		Method Bump()
			AssertValid()
			_node=_node._succ
		End
		
		Method Erase()
			AssertSeq()
			_node=_list.Erase( _node )
			_seq=_list._seq
		End
		
		Method Insert( value:T )
			AssertSeq()
			_node=_list.Insert( _node,value )
			_seq=_list._seq
		End
	End
	
	Field _first:Node
	Field _last:Node
	Field _length:Int
	Field _seq:Int
	
	#rem monkeydoc Creates a new empty list
	#end
	Method New()
	End

	#rem monkeydoc Creates a new list with the contents of an array.
	
	@param data The array to create the list with.
	
	#end
	Method New( values:T[] )
		AddAll( values )
	End
	
	Method All:Iterator()
		Return New Iterator( Self,_first )
	End
	
	#rem monkeydoc Checks whether the list is empty.
	
	@return True if the list is empty.
	
	#end
	Property Empty:Bool()
		Return _first=Null
	End
	
	#rem monkeydoc Gets the number of values in the list.

	@return The number of values in the list.
	
	@see Empty
	
	#end
	Property Length:Int()
		Return _length
	End
	
	#rem monkeydoc Converts the list to an array.
	
	@return An array containing the items in the list.
	
	#end
	Method ToArray:T[]()
		Local data:=New T[_length],node:=_first
		For Local i:=0 Until _length
			data[i]=node._value
			node=node._succ
		Next
		Return data
	End
	
	#rem monkeydoc Gets the first value in the list.
	
	In debug builds, if the list is empty a runtime error occurs.
	
	@return The first value in the list.
	
	#end
	Property First:T()
		DebugAssert( Not Empty )
		Return _first._value
	End
	
	#rem monkeydoc Get the last item in a list
	
	In debug builds, if the list is empty a runtime error occurs.
	
	@return The last value in the list.
	
	#end
	Property Last:T()
		DebugAssert( Not Empty )
		Return _last._value
	End
	
	#rem monkeydoc Removes all values from the list.
	
	#end
	Method Clear()
		_first=Null
		_last=Null
		_length=0
		_seq+=1
	End
	
	#rem monkeydoc Adds a value to the start of the list.
	
	@param value The value to add to the list.

	#end
	Method AddFirst( value:T )
		Local node:=New Node( value )
		If _first
			node._succ=_first
			_first._pred=node
		Else
			_last=node
		Endif
		_first=node
		_length+=1
		_seq+=1
	End
	
	#rem monkeydoc Adds a value to the end of the list.

	@param value The value to add to the list.
	
	#end
	Method AddLast( value:T )
		Local node:=New Node( value )
		If _last
			node._pred=_last
			_last._succ=node
		Else
			_first=node
		Endif
		_last=node
		_length+=1
		_seq+=1
	End
	
	#rem monkeydoc Removes the first item in the list and returns it.
	
	In debug builds, if the list is empty a runtime error occurs.
	
	@return The first item in the list before the method was called.

	#end
	Method RemoveFirst:T()
		DebugAssert( Not Empty )
		Local value:=_first._value
		_first=_first._succ
		If _first _first._pred=Null Else _last=Null
		_length-=1
		_seq+=1
		Return value
	End
	
	#rem monkeydoc Removes the last value in the list and returns it.
	
	In debug builds, if the list is empty a runtime error occurs.
	
	@return The last item in the list before the method was called.

	#end
	Method RemoveLast:T()
		DebugAssert( Not Empty )
		Local value:=_last._value
		_last=_last._pred
		If _last _last._succ=Null Else _first=Null
		_length-=1
		_seq+=1
		Return value
	End
	
	#rem monkedoc Removes all values in the list equal to a given value.
	
	@param value The value to check for equality.
	
	#end
	Method RemoveEach( value:T )
		Local node:=_first
		While node
			If node._value=value
				node=Erase( node )
			Else
				node=node._succ
			Endif
		Wend
	End

	#rem monkeydoc Gets an iterator for the value at a given index in the list.
	
	Warning! This method can be SLOW if index is greater than 0 as the list must be linearly searched to find `index`.
	
	In debug builds, a runtime error will occur if index is out of range.

	@param index The index of the iterator to find.
	
	#end
	Method Index:Iterator( index:Int )
		DebugAssert( index>=0 And index<_length )
		
		Local node:=_first
		While node
			If Not index Return New Iterator( Self,node )
			node=node._succ
			index-=1
		Wend
		Return New Iterator( Self,Null )
	End
	
	#rem monkeydocs Adds a value to the end of the list.
	
	This method behaves identically to AddLast.
	
	@param value The value to add.
	
	#end
	Method Add( value:T )
		AddLast( value )
	End
	
	#rem monkeydocs Adds all values in an array to the end of the list.
	
	@param values The values to add.
	
	#end
	Method AddAll( values:T[] )
		For Local value:=Eachin values
			AddLast( value )
		Next
	End

	#rem monkedoc Adds all value in a container to the end of the list.
	
	@param values The values to add.
	
	#end	
	Method AddAll<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			AddLast( value )
		Next
	End

	Private	
	
	Method Erase:Node( node:Node )
		If Not node Return Null	'OK to erase tail element...
		Local succ:=node._succ
		If node=_first
			_first=succ
			If _first _first._pred=Null Else _last=Null
		Else If node=_last
			_last=node._pred
			_last._succ=Null
		Else
			node._pred._succ=succ
			node._succ._pred=node._pred
		Endif
		_length-=1
		_seq+=1
		Return succ
	End
	
	Method Insert:Node( succ:Node,value:T )
		Local node:=New Node( value )
		If succ
			node._succ=succ
			If succ=_first _first=node Else succ._pred._succ=node
			succ._pred=node
		Else If _last
			node._pred=_last
			_last._succ=node
			_last=node
		Else
			_first=node
			_last=node
		Endif
		_length+=1
		_seq+=1
		Return node
	End
	
End

Class IntList Extends List<Int>
End

Class FloatList Extends List<Float>
End

Class StringList Extends List<String>
End
