
Namespace std.collections

Alias IntList:List<Int>
Alias FloatList:List<Float>
Alias StringList:List<String>

#rem monkeydoc The List class.

#end
Class List<T> Implements IContainer<T>

	#rem monkeydoc The List.Node class.
	#end
	Class Node
	
		Private
	
		Field _succ:Node
		Field _pred:Node
		Field _value:T
		
		Public

		#rem monkeydoc Creates a new node not in any list.
		#end		
		Method New( value:T )
			_value=value
			_succ=Self
			_pred=Self
		End
		
		#rem monkeydoc Creates a new node with the given successor node.
		
		Warning! No error checking is performed!
		
		This method should not be used while iterating over the list containing `succ`.
		
		#endif
		Method New( value:T,succ:Node )
			_value=value
			_succ=succ
			_pred=succ._pred
			_pred._succ=Self
			succ._pred=Self
		End
		
		#rem monkeydoc Gets the node after this node.
		#end
		Property Succ:Node()
			Return _succ
		End
		
		#rem monkeydoc Gets the node before this node.
		#end
		Property Pred:Node()
			Return _pred
		End

		#rem monkeydoc Gets the value contained in this node.
		#end		
		Property Value:T()
			Return _value
		Setter( value:T )
			_value=value
		End
		
		#rem monkeydoc Inserts the node before another node.
		
		Warning! No error checking is performed!
		
		This method should not be used while iterating over the list containing `node`.
		
		#end
		Method InsertBefore( node:Node )
			_succ=node
			_pred=node._pred
			_pred._succ=Self
			node._pred=Self
		End
		
		#rem monkeydoc Inserts the node after another node.
		
		Warning! No error checking is performed! 
		
		This method should not be used while iterating over the list containing `node`.
		
		#end
		Method InsertAfter( node:Node )
			_pred=node
			_succ=node._succ
			_succ._pred=Self
			node._succ=Self
		End
		
		#rem monkeydoc Removes this node.
		
		Warning! No error checking is performed!
		
		This method should not be used while iterating over the list containing this node.
		
		#end
		Method Remove()
			_succ._pred=_pred
			_pred._succ=_succ
		End
		
	End
	
	#rem monkeydoc The List.Iterator struct.
	#end
	Struct Iterator
	
		Private
	
		Field _list:List
		Field _node:Node
		Field _seq:Int
		
		Method AssertSeq()
			DebugAssert( _seq=_list._seq,"Concurrent list modification" )
		End
		
		Method AssertCurrent()
			DebugAssert( Valid,"Invalid list iterator" )
		End
		
		Public
		
		#rem monkeydoc Creates a new iterator.
		#end
		Method New( list:List,node:Node )
			_list=list
			_node=node
			_seq=list._seq
		End

		#rem monkeydoc Checks whether the iterator has reached the end of the list.
		#end
		Property AtEnd:Bool()
			AssertSeq()
			Return _node=_list._head
		End
		
		#rem monkeydoc @hidden
		#end
		Property Valid:Bool()
			Return Not AtEnd
		End
		
		#rem monkeydoc The value contained in the node pointed to by the iterator.
		#end
		Property Current:T()
			AssertCurrent()
			Return _node._value
			
		Setter( current:T )
			AssertCurrent()
			_node._value=current
		End
		
		#rem monkeydoc Bumps the iterator so it points to the next node in the list.
		#end
		Method Bump()
			AssertCurrent()
			_node=_node._succ
		End
		
		#rem monkeydoc Safely erases the node referenced by the iterator.
		
		After calling this method, the iterator will point to the node after the removed node.
		
		Therefore, if you are manually iterating through a list you should not call [[Bump]] after calling this method or you
		will end up skipping a node.
		
		#end
		Method Erase()
			AssertSeq()
			_node=_node._succ
			_node._pred.Remove()
			_list._seq+=1
			_seq=_list._seq
		End
		
		#rem monkeydoc Safely insert a value before the iterator.

		After calling this method, the iterator will point to the newly added node.
		
		#end
		Method Insert( value:T )
			AssertSeq()
			_node=New Node( value,_node )
			_list._seq+=1
			_seq=_list._seq
		End
	End
	
	Private
	
'	Field _head:=New Node	'FIXME, causes internal compiler error...
	Field _head:Node
	Field _seq:Int
	
	Public
	
	#rem monkeydoc Creates a new list.
	
	New() create a new empty list.
	
	New( T[] ) creates a new list with the elements of an array.
	
	New( List<T> ) creates a new list with the contents of another list.
	
	New( Stack<T> ) create a new list the contents of a stack.
	
	@param values An existing array, list or stack.
	
	#end
	Method New()
		_head=New Node( Null )
	End

	Method New( values:T[] )
		Self.New()
		AddAll( values )
	End
	
	Method New( values:Stack<T> )
		Self.New()
		AddAll( values )
	End
	
	Method New( values:List<T> )
		Self.New()
		AddAll( values )
	End
	
	#rem monkeydoc Gets an iterator for all nodes in the list.
	
	Returns an iterator suitable for use with [[Eachin]], or for manual iteration.
	
	@return A list iterator.
	
	#end
	Method All:Iterator()
		Return New Iterator( Self,_head._succ )
	End
	
	#rem monkeydoc Checks whether the list is empty.
	
	@return True if the list is empty.
	
	#end
	Property Empty:Bool()
		Return _head._succ=_head
	End
	
	#rem monkeydoc Counts the number of values in the list.
	
	Note: This method can be slow when used with large lists, as it must visit each value. If you just
	want to know whether a list is empty or not, use [[Empty]] instead.

	@return The number of values in the list.
	
	#end
	Method Count:Int()
		Local node:=_head._succ,n:=0
		While node<>_head
			node=node._succ
			n+=1
		Wend
		Return n
	End
	
	#rem monkeydoc Converts the list to an array.
	
	@return An array containing the items in the list.
	
	#end
	Method ToArray:T[]()
		Local n:=Count()
		Local data:=New T[n],node:=_head._succ
		For Local i:=0 Until n
			data[i]=node._value
			node=node._succ
		Next
		Return data
	End
	
	#rem monkeydoc Gets the first value in the list.
	
	In debug builds, a runtime error will occur if the list is empty.
	
	@return The first value in the list.
	
	#end
	Property First:T()
		DebugAssert( Not Empty )
		
		Return _head._succ._value
	End
	
	#rem monkeydoc Gets the last value in the list
	
	In debug builds, a runtime error will occur if the list is empty.
	
	@return The last value in the list.
	
	#end
	Property Last:T()
		DebugAssert( Not Empty )
		
		Return _head._pred._value
	End
	
	#rem monkeydoc Removes all values from the list.
	
	#end
	Method Clear()
		_head._succ=_head
		_head._pred=_head
		_seq+=1
	End
	
	#rem monkeydoc Adds a value to the start of the list.
	
	@param value The value to add to the list.
	
	@return A new node containing the value.

	#end
	Method AddFirst:Node( value:T )
		Local node:=New Node( value,_head._succ )
		_seq+=1
		Return node
	End
	
	#rem monkeydoc Adds a value to the end of the list.

	@param value The value to add to the list.
	
	@return A new node containing the value.

	#end
	Method AddLast:Node( value:T )
		Local node:=New Node( value,_head )
		_seq+=1
		Return node
	End
	
	#rem monkeydoc Removes the first value in the list equal to a given value.
	
	@param value The value to remove.

	@return True if a value was removed.
		
	#end
	Method Remove:Bool( value:T )
		Local node:=FindNode( value )
		If Not node Return False
		node.Remove()
		_seq+=1
		Return True
	End
	
	#rem monkeydoc Removes the last value in the list equal to a given value.
	
	@param value The value to remove.
	
	@return True if a value was removed.
		
	#end
	Method RemoveLast:Bool( value:T )
		Local node:=FindLastNode( value )
		If Not node Return False
		node.Remove()
		_seq+=1
		Return True
	End
	
	#rem monkeydoc Removes all values in the list equal to a given value.
	
	@param value The value to remove.
	
	@return The number of values removed.
	
	#end
	Method RemoveEach:Int( value:T )
		Local node:=_head._succ,n:=0
		While node<>_head
			If node._value=value
				node=node._succ
				node._pred.Remove()
				n+=1
			Else
				node=node._succ
			Endif
		Wend
		If n _seq+=1
		Return n
	End
	
	#rem monkeydoc Removes and returns the first value in the list.
	
	In debug builds, a runtime error will occur if the list is empty.
	
	@return The value removed from the list.

	#end
	Method RemoveFirst:T()
		DebugAssert( Not Empty )
		
		Local value:=_head._succ._value
		_head._succ.Remove()
		_seq+=1
		Return value
	End
	
	#rem monkeydoc Removes and returns the last value in the list.
	
	In debug builds, a runtime error will occur if the list is empty.
	
	@return The value removed from the list.

	#end
	Method RemoveLast:T()
		DebugAssert( Not Empty )
		
		Local value:=_head._pred._value
		_head._pred.Remove()
		_seq+=1
		Return value
	End
	
	#rem monkeydoc Adds a value to the end of the list.
	
	This method behaves identically to AddLast.
	
	@param value The value to add.
	
	#end
	Method Add( value:T )
		AddLast( value )
	End
	
	#rem monkeydoc Adds all values in an array or container to the end of the list.
	
	@param values The values to add.
	
	@param values The values to add.
	
	#end
	Method AddAll( values:T[] )
		For Local value:=Eachin values
			AddLast( value )
		Next
	End

	Method AddAll<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			AddLast( value )
		Next
	End
	
	#rem monkeydoc Sorts the list.
	
	@param ascending True to sort the stack in ascending order, false to sort in descending order.
	
	@param compareFunc Function to be used to compare values when sorting.
	
	#end
	Method Sort( ascending:Bool=True )
		If ascending
			Sort( Lambda:Int( x:T,y:T )
				Return x<=>y
			End )
		Else
			Sort( Lambda:Int( x:T,y:T )
				Return -(x<=>y)
			End )
		Endif
	End

	Method Sort( compareFunc:Int( x:T,y:T ) )
	
		Local insize:=1
		
		Repeat
		
			Local merges:=0
			Local tail:=_head
			Local p:=_head._succ

			While p<>_head
				merges+=1
				Local q:=p._succ,qsize:=insize,psize:=1
				
				While psize<insize And q<>_head
					psize+=1
					q=q._succ
				Wend

				Repeat
					Local t:Node
					If psize And qsize And q<>_head
						Local cc:=compareFunc( p._value,q._value )
						If cc<=0
							t=p
							p=p._succ
							psize-=1
						Else
							t=q
							q=q._succ
							qsize-=1
						Endif
					Else If psize
						t=p
						p=p._succ
						psize-=1
					Else If qsize And q<>_head
						t=q
						q=q._succ
						qsize-=1
					Else
						Exit
					Endif
					t._pred=tail
					tail._succ=t
					tail=t
				Forever
				p=q
			Wend
			tail._succ=_head
			_head._pred=tail

			If merges<=1 Return

			insize*=2
		Forever

	End
	
	#rem monkeydoc Joins the values in the string list.
	
	@param sepeator The separator to be used when joining values.
	
	@return The joined values.
	
	#end
	Method Join:String( separator:String="" ) Where T=String
		Return separator.Join( ToArray() )
	End

	#rem monkeydoc Gets the head node of the list.
	#end
	Method HeadNode:Node()
		Return _head
	End
	
	#rem monkeydoc Gets the first node in the list.
	
	@return The first node in the list, or null if the list is empty.
	
	#end
	Method FirstNode:Node()
		If Not Empty Return _head._succ
		Return Null
	End
	
	#rem monkeydoc Gets the last node in the list.
	
	@return The last node in the list, or null if the list is empty.
	
	#end
	Method LastNode:Node()
		If Not Empty Return _head._pred
		Return Null
	End
	
	#rem monkeydoc Finds the first node in the list containing a value.
	
	@param value The value to find.
	
	@return The first node containing the value, or null if the value was not found.
	
	#end
	Method FindNode:Node( value:T )
		Local node:=_head._succ
		While node<>_head And node._value<>value
			node=node._succ
		Wend
		Return Null
	End
	
	#rem monkeydoc Finds the last node in the list containing a value.
	
	@param value The value to find.
	
	@return The last node containing the value, or null if the value was not found.
	
	#end
	Method FindLastNode:Node( value:T )
		Local node:=_head._pred
		While node<>_head And node._value<>value
			node=node._pred
		Wend
		Return Null
	End
	
End
