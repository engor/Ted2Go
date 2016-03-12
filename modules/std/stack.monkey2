
Namespace std

Using std

Class Stack<T> Implements IContainer<T>

	Struct Iterator 'Implements IIterator<T>
	
		Field _stack:Stack
		Field _index:Int
		Field _seq:Int
		
		Method New( stack:Stack,index:Int )
			_stack=stack
			_index=index
			_seq=stack._seq
		End
		
		Method AssertSeq()
			DebugAssert( _seq=_stack._seq,"Concurrent list modification" )
		End
		
		Method AssertValid()
			DebugAssert( Valid,"Invalid list iterator" )
		End
		
		Property Valid:Bool()
			AssertSeq()
			Return _index<_stack._length
		End
		
		Property Current:T()
			AssertValid()
			Return _stack._data[_index]
		Setter( current:T )
			AssertValid()
			_stack._data[_index]=current
		End
		
		Method Bump()
			AssertValid()
			_index+=1
		End
		
		Method Erase()
			AssertSeq()
			_stack.Erase( _index )
			_seq=_stack._seq
		End
		
		Method Insert( value:T )
			AssertSeq()
			_stack.Insert( _index,value )
			_seq=_stack._seq
		End
	End
	
	Protected

	Field _data:T[]
	Field _length:Int
	Field _seq:Int	
	
	Public
	
	#rem monkeydoc Creates a new empty stack.
	#end
	Method New()
		_data=New T[10]
	End

	#rem monkeydoc Creates a new stack with the contents of an array.

	@param data The array to create the stack with.
	
	#end
	Method New( values:T[] )
		AddAll( values )
	End
	
	#rem monkeydoc Checks if the stack is empty.
	
	@return True if the stack is empty.
	
	#end
	Property Empty:Bool()
		Return _length=0
	End

	#rem monkeydoc Gets an iterator.
	
	@return An iterator
	#end
	Method All:Iterator()
		Return New Iterator( Self,0 )
	End

	#rem monkeydoc Converts the stack to an array.
	
	@return An array containing each element of the stack.
	
	#end
	Method ToArray:T[]()
		Return _data.Slice( 0,_length )
	End
	
	#rem monkedoc Gets the underlying array used by the stack.
	
	Note that the returned array may be longer than the stack length.
	
	@return The array used internally by the stack.
	
	#end
	Property Data:T[]()
		Return _data
	End
	
	#rem monkeydoc Gets the number of values in the stack.
	
	@return The number of values in the stack.
	
	#end
	Property Length:Int()
		Return _length
	End
	
	#rem monkeydoc Gets the storage capacity of the stack.
	
	The capacity of a stack is the number of values it can contain before memory needs to be reallocated to store more values.
	
	If a stack's length equals its capacity, then the next Add or Insert operation will need to allocate more memory to 'grow' the stack.
	
	You don't normally need to worry about stack capacity, but it can be useful to use [[Reserve]] to preallocate stack storage if you know in advance
	how many values a stack is likely to contain, in order to prevent the overhead of excessive memory allocation.
	
	@return The current stack capacity.
	
	#end
	Property Capacity:Int()
		Return _data.Length
	End
	
	#rem monkeydoc Resizes the stack.
	
	If `length` is greater than the current stack length, any extra elements are initialized to null.
	
	If `length` is less than the current stack length, the stack is truncated.
	
	@param length The new length of the stack.
	
	#end	
	Method Resize( length:Int )
		DebugAssert( length>=0 )
		
		For Local i:=length Until _length
			_data[i]=Null
		Next
		
		Reserve( length )
		_length=length
		_seq+=1
	End
	
	#rem monkeydoc Reserves stack storage capacity.
	
	The capacity of a stack is the number of values it can contain before memory needs to be reallocated to store more values.
	
	If a stack's length equals its capacity, then the next Push or Insert operation will need to allocate more memory to 'grow' the stack.
	
	You don't normally need to worry about stack capacity, but it can be useful to use [[Reserve]] to preallocate stack storage if you know in advance
	how many values a stack is likely to contain, in order to prevent the overhead of excessive memory allocation.
	
	@param capacity The new capacity.
	
	#end
	Method Reserve( capacity:Int )
		DebugAssert( capacity>=0 )
		
		If _data.Length>=capacity Return
		
		capacity=Max( _length*2+_length,capacity )
		Local data:=New T[capacity]
		_data.CopyTo( data,0,0,_length )
		_data=data
	End
	
	#rem monkeydoc Clears the stack.
	#end
	Method Clear()
		Resize( 0 )
	End
	
	#rem monkeydoc Erases an element at an index in the stack.
	
	In debug builds, a runtime error will occur if `index` is less than 0 or greater than the stack length.
	
	if `index` is equal to the stack length, the operation has no effect.
	
	@param index The index of the element to erase.
	
	#end
	Method Erase( index:Int )
		DebugAssert( index>=0 And index<=_length )
		If index=_length Return
		
		_data.CopyTo( _data,index+1,index,_length-index-1 )
		Resize( _length-1 )
	End
	
	#rem monkeydoc Erases a range of elements in the stack.
	
	If debug builds, a runtime error will occur if either index is less than 0 or greater than the stack length, or if index2 is less than index1.
	
	The number of elements actually erased is `index2`-`index1`.
	
	@param index1 The index of the first element to erase.
	
	@param index2 The index of the last+1 element to erase.
	
	#end
	Method Erase( index1:Int,index2:Int )
		DebugAssert( index1>=0 And index1<=_length And index2>=0 And index2<=_length And index1<=index2 )
		If index1=_length Return
		
		_data.CopyTo( _data,index2,index1,_length-index2 )
		Resize( _length-index2+index1 )
	End
	
	#rem monkeydoc Inserts a value at an index in the stack.
	
	In debug builds, a runtime error will occur if `index` is less than 0 or greater than the stack length.
	
	If `index` is equal to the stack length, the value is added to the end of the stack.
	
	@param index The index of the value to insert.
	
	@param value The value to insert.
	
	#end
	Method Insert( index:Int,value:T )
		DebugAssert( index>=0 And index<=_length )
		
		Reserve( _length+1 )
		_data.CopyTo( _data,index,index+1,_length-index )
		_data[index]=value
		_length+=1
		_seq+=1
	End
	
	#rem monkeydoc Gets the top element of the stack
	
	In debug builds, a runtime error will occur if the stack is empty.
	
	@return The top element of the stack.
	
	#end
	Property Top:T()
		DebugAssert( _length,"Stack is empty" )
		Return _data[_length-1]
	End
	
	#rem monkeydoc Pops the top element off the stack and returns it.
	
	In debug builds, a runtime error will occur if the stack is empty.
	
	@return The top element of the stack before it was popped.
	#end
	Method Pop:T()
		DebugAssert( _length,"Stack is empty" )
		
		_length-=1
		_seq+=1
		Local value:=_data[_length]
		_data[_length]=Null
		Return value
	End
	
	#rem monkeydoc Pushes a value on the stack.
	
	@param value The value to push.
	
	#end
	Method Push( value:T )
		Reserve( _length+1 )
		_data[_length]=value
		_length+=1
		_seq+=1
	End
	
	
	#rem monkeydoc Gets the value of a stack element.
	
	In debug builds, a runtime error will occur if `index` is less than 0, or greather than or equal to the length of the stack.
	
	@param index The index of the element to get.
	
	#end
	Method Get:T( index:Int )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		Return _data[index]
	End
	
	#rem monkeydoc Sets the value of a stack element.

	In debug builds, a runtime error will occur if `index` is less than 0, or greather than or equal to the length of the stack.
	
	@param index The index of the element to set.
	
	@param value The value to set.
	
	#end
	Method Set( index:Int,value:T )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		_data[index]=value
	End
	
	#rem monkeydoc Gets the value a stack element.
	
	In debug builds, a runtime error will occur if `index` is less than 0, or greather than or equal to the length of the stack.
	
	@param index The index of the element to get.

	#end
	Operator []:T( index:Int )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		Return _data[index]
	End
	
	#rem monkeydoc Sets the value of a stack element.
	
	In debug builds, a runtime error will occur if `index` is less than 0, or greather than or equal to the length of the stack.
	
	@param index The index of the element to set.
	
	@param value The value to set.
	
	#end
	Operator []=( index:Int,value:T )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		_data[index]=value
	End
	
	#rem monkeydoc Adds a value to the end of the stack.
	
	This method behaves identically to Push.
	
	@param value The value to add.
	
	#end
	Method Add( value:T )
		Push( value )
	End
	
	#rem monkeydoc Adds the values in an array to the end of the stack.
	
	@param values The values to add.
	
	#end
	Method AddAll( values:T[] )
		Reserve( _length+values.Length )
		values.CopyTo( _data,0,_length,values.Length )
		Resize( _length+values.Length )
	End

	#rem monkeydoc Adds the values in a container to the end of the stack.
	
	@param values The values to add.
	
	#end
	Method AddAll<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			Add( value )
		Next
	End

	'KILLME!
	Method Append<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			Add( value )
		Next
	End
	
	#rem monkeydoc Finds the index of the first matching value in the stack.
	
	In debug builds, a runtime error will occur if `start` is less than 0 or greater than the length of the stack.
	
	@param value The value to find.
	
	@param start The starting index for the search.
	
	@return The index of the value in the stack, or -1 if the value was not found.
	
	#end
	Method Find:Int( value:T,start:Int=0 )
		DebugAssert( start>=0 And start<=_length )
		
		Local i:=start
		While i<_length
			If _data[i]=value Return i
			i+=1
		Wend
		Return -1
	End
	
	#rem monkeydoc Finds the index of the last matching value in the stack.
	
	In debug builds, a runtime error will occur if `start` is less than 0 or greater than the length of the stack.
	
	@param value The value to find.
	
	@param start The starting index for the search.
	
	@return The index of the value in the stack, or -1 if the value was not found.
	
	#end
	Method FindLast:Int( value:T,start:Int=0 )
		DebugAssert( start>=0 And start<=_length )
		
		Local i:=_length
		While i>start
			i-=1
			If _data[i]=value Return i
		Wend
		Return -1
	End
	
	#rem monkeydoc Checks if the stack contains a value.
	
	@param value The value to check.
	
	@return True if the stack contains the value, else false.
	
	#end
	Method Contains:Bool( value:T )
		Return Find( value )<>-1
	End
	
	#rem monkeydoc Finds and removes the first matching value from the stack.
	
	@param start The starting index for the search.
	
	@param value The value to remove.
	
	#end
	Method Remove( value:T,start:Int=0 )
		Local i:=Find( value,start )
		If i<>-1 Erase( i )
	End
	
	#rem monkeydoc Finds and removes the last matching value from the stack.
	
	@param start The starting index for the search.
	
	@param value The value to remove.
	
	#end
	Method RemoveLast( value:T,start:Int=0 )
		Local i:=FindLast( value,start )
		If i<>-1 Erase( i )
	End
	
	#rem monkeydoc Finds and removes each matching value from the stack.
	
	@param value The value to remove.
	
	#end	
	Method RemoveEach( value:T )
		Local put:=0
		For Local get:=0 Until _length
			If _data[get]=value Continue
			_data[put]=_data[get]
			put+=1
		Next
		Resize( put )
	End
	
	#rem monkeydoc Returns a range of elements from the stack
	
	Returns a slice of the stack consisting of all elements from `index` to the end of the stack.
	
	If `index` is negative, then it represents an offset from the end of the stack.

	'index' is clamped to the length of the stack, so Slice will never cause a runtime error.
	
	@param index1 the index of the first element.
	
	@return A new stack.
	
	#end
	Method Slice:Stack( index:Int )
		Return Slice( index,_length )
	End

	#rem monkeydoc Returns a range of elements from the stack.
	
	Returns a slice of the stack consisting of all elements from `index1` up to but not including `index2`.

	If either index is negative, then it represents an offset from the end of the stack.
	
	'index' and `index2` are clamped to the length of the stack, so Slice will never cause a runtime error.
	
	@param index1 The index of the first element.
	
	@param index2 The index of the last+1 element.
	
	@return A new stack.
	
	#end	
	Method Slice:Stack( index1:Int,index2:Int )

		If index1<0
			index1+=_length
			If index1<0 index1=0
		Else If index1>_length
			index1=_length
		Endif
		
		If index2<0
			index2+=_length
			If index2<index1 index2=index1
		Else If index2>_length
			index2=_length
		Else If index2<index1
			index2=index1
		Endif
		
		Return New Stack( _data.Slice( index1,index2 ) )
	End
	
	#rem monkeydoc Swaps 2 elements in the stack.
	
	In debug builds, a runtime error will occur if `index1` or `index2` is out of range.
	
	@param index1 The index of the first element.
	
	@param index2 The index of the second element.
	
	#end
	Method Swap( index1:Int,index2:Int )
	
		DebugAssert( index1>=0 And index1<_length And index2>=0 And index2<_length,"Stack index out of range" )
		
		Local t:=_data[index1]
		_data[index1]=_data[index2]
		_data[index2]=t
	End
	
	#rem monkeydoc Sorts the stack.

	@param ascending True to sort the stack in ascending order, false to sort in descending order.

	#end
	Method Sort( ascending:Bool=True )
		If ascending
			Sort( 0,_length-1,Lambda:Int( x:T,y:T )
				Return x<=>y
			End )
		Else
			Sort( 0,_length-1,Lambda:Int( x:T,y:T )
				Return y<=>x
			End )
		Endif
	End
	
	#rem monkeydoc Sorts the stack using a comparison function.
	
	@param compareFunc The function used to compare values.
	
	#end
	Method Sort( compareFunc:Int( x:T,y:T ) )
		Sort( 0,_length-1,compareFunc )
	End
	
	#rem monkeydoc Sorts a range of stack elements using a comparison function.

	@param lo The first element.
	
	@param hi The last element.
	 
	@param compareFunc The function used to compare values.

	#end	
	Method Sort( lo:Int,hi:Int,cmp:Int( x:T,y:T ) )
	
		If hi<=lo Return
		
		If lo+1=hi
			If cmp( _data[hi],_data[lo] )<0 Swap( hi,lo )
			Return
		Endif
		
		Local i:=(lo+hi)/2
		
		If cmp( _data[i],_data[lo] )<0 Swap( i,lo )

		If cmp( _data[hi],_data[i] )<0
			Swap( hi,i )
			If cmp( _data[i],_data[lo] )<0 Swap( i,lo )
		Endif
		
		Local x:=lo+1
		Local y:=hi-1
		Repeat
			Local p:=_data[i]
			While cmp( _data[x],p )<0
				x+=1
			Wend
			While cmp( p,_data[y] )<0
				y-=1
			Wend
			If x>y Exit
			If x<y
				Swap( x,y )
				If i=x i=y Else If i=y i=x
			Endif
			x+=1
			y-=1
		Until x>y

		Sort( lo,y,cmp )
		Sort( x,hi,cmp )
	End
	
End

Class IntStack Extends Stack<Int>
End

Class FloatStack Extends Stack<Float>
End

Class StringStack Extends Stack<String>

	Method Join:String( separator:String )
		Return separator.Join( ToArray() )
	End
	
End
