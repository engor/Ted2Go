
Namespace std.collections

Alias IntList:List<Int>

Alias FloatList:List<Float>

Alias StringList:List<String>

#rem monkeydoc The List class.

#end
Class List<T> Implements IContainer<T>

	Private
	
	Class Node
	
		Private
	
		Field _succ:Node
		Field _pred:Node
		Field _value:T
		
		Public
		
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
	
	Public
	
	Struct Iterator 'Implements IIterator<T>
	
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
		
		Method New( list:List,node:Node )
			_list=list
			_node=node
			_seq=list._seq
		End
		
		Property AtEnd:Bool()
			AssertSeq()
			Return _node=Null
		End
		
		#rem monkeydoc @hidden
		#end
		Property Valid:Bool()
			Return Not AtEnd
		End
		
		Property Current:T()
			AssertCurrent()
			Return _node._value
			
		Setter( current:T )
			AssertCurrent()
			_node._value=current
		End
		
		Method Bump()
			AssertCurrent()
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
	
	Private
	
	Field _first:Node
	Field _last:Node
	Field _length:Int
	Field _seq:Int
	
	Public
	
	#rem monkeydoc Creates a new empty list.
	#end
	Method New()
	End

	#rem monkeydoc Creates a new list with the contents of an array.
	
	@param data The array to create the list with.
	
	#end
	Method New( values:T[] )
		AddAll( values )
	End
	
	#rem monkeydoc Gets an iterator to the list.

	@return A list iterator.
	
	#end
'	Method GetIterator:Iterator()
'		Return New Iterator( Self,_first )
'	End
	
	#rem monkeydoc @hidden
	#end
	Method All:Iterator()
		Return New Iterator( Self,_first )
	End
	
	#rem monkeydoc Checks whether the list is empty.
	
	@return True if the list is empty.
	
	#end
	Property Empty:Bool()
		Return _length=0
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
	
	In debug builds, a runtime error will occur if the list is empty.
	
	@return The first value in the list.
	
	#end
	Property First:T()
		DebugAssert( Not Empty )
		Return _first._value
	End
	
	#rem monkeydoc Gets the last value in the list
	
	In debug builds, a runtime error will occur if the list is empty.
	
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
	
	@return The new node containing the value.

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
	
	#rem monkeydoc Removes the first value in the list equal to a given value.
	
	@param value The value to remove.

	@return True if a value was removed.
		
	#end
	Method Remove:Bool( value:T )
		Local node:=FindNode( value )
		If Not node Return False
		Erase( node )
		Return True
	End
	
	#rem monkeydoc Removes the last value in the list equal to a given value.
	
	@param value The value to remove.
	
	@return True if a value was removed.
		
	#end
	Method RemoveLast:Bool( value:T )
		Local node:=FindLastNode( value )
		If Not node Return False
		Erase( node )
		Return True
	End
	
	#rem monkeydoc Removes all values in the list equal to a given value.
	
	@param value The value to remove.
	
	@return The number of values removed.
	
	#end
	Method RemoveEach:Int( value:T )
		Local node:=_first,n:=0
		While node
			If node._value=value
				node=Erase( node )
				n+=1
			Else
				node=node._succ
			Endif
		Wend
		Return n
	End
	
	#rem monkeydoc Removes and returns the first value in the list.
	
	In debug builds, a runtime error will occur if the list is empty.
	
	@return The value removed from the list.

	#end
	Method RemoveFirst:T()
		DebugAssert( _length )
		
		Local value:=_first._value
		_first=_first._succ
		If _first _first._pred=Null Else _last=Null
		_length-=1
		_seq+=1
		Return value
	End
	
	#rem monkeydoc Removes and returns the last value in the list.
	
	In debug builds, a runtime error will occur if the list is empty.
	
	@return The value removed from the list.

	#end
	Method RemoveLast:T()
		DebugAssert( _length )
		
		Local value:=_last._value
		_last=_last._pred
		If _last _last._succ=Null Else _first=Null
		_length-=1
		_seq+=1
		Return value
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
	
	#rem monkeydoc Adds a value to the end of the list.
	
	This method behaves identically to AddLast.
	
	@param value The value to add.
	
	#end
	Method Add( value:T )
		AddLast( value )
	End
	
	#rem monkeydoc Adds all values in an array to the end of the list.
	
	@param values The values to add.
	
	#end
	Method AddAll( values:T[] )
		For Local value:=Eachin values
			AddLast( value )
		Next
	End

	#rem monkedoc Adds all values in a container to the end of the list.
	
	@param values The values to add.
	
	#end	
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
	
		If _first=_last Return
	
		Local insize:=1
		
		Repeat
		
			Local merges:=0
			Local p:=_first,tail:Node
			
			While p

				merges+=1
				Local q:=p._succ,qsize:=insize,psize:=1
				
				While psize<insize And q
					psize+=1
					q=q._succ
				Wend

				Repeat
					Local t:Node
					
					If psize And qsize And q
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
					Else If qsize And q
						t=q
						q=q._succ
						qsize-=1
					Else
						Exit
					Endif
					
					t._pred=tail
					If tail tail._succ=t Else _first=t
					tail=t
					
'					t._pred=tail
'					tail._succ=t
'					tail=t
					
				Forever
				
				p=q
				
			Wend
			
			tail._succ=Null
			_last=tail
			
'			tail._succ=_head
'			_head._pred=tail

			If merges<=1 Return

			insize*=2
		Forever

	End Method
	
	#rem monkeydoc Joins the values in the string list.
	
	@param sepeator The separator to be used when joining values.
	
	@return The joined values.
	
	#end
	Method Join:String( separator:String="" ) Where T=String
		Return separator.Join( ToArray() )
	End

	Private
	
	Method FirstNode:Node()
		Return _first
	End
	
	Method LastNode:Node()
		Return _last
	End
	
	Method FindNode:Node( value:T )
		Local node:=_first
		While node And node._value<>value
			node=node._succ
		Wend
		Return node
	End
	
	Method FindLastNode:Node( value:T )
		Local node:=_last
		While node And node._value<>value
			node=node._pred
		Wend
		Return node
	End
	
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
