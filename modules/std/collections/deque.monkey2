
Namespace std.collections

#rem monkeydoc @hidden Convenience type alias for Deque\<Int\>.
#end
Alias IntDeque:Deque<Int>

#rem monkeydoc @hidden Convenience type alias for Deqaue\<Float\>.
#end
Alias FloatDeque:Deque<Float>

#rem monkeydoc @hidden Convenience type alias for Dequq\<String\>.
#end
Alias StringDeque:Deque<String>

#rem monkeydoc @hidden
#end
Class Deque<T> Implements IContainer<T>

	Struct Iterator Implements IIterator<T>
	
		Private
		
		Field _deque:Deque
		Field _index:Int
		Field _seq:Int
		
		Method AssertSeq()
			DebugAssert( _seq=_deque._seq,"Concurrent list modification" )
		End
		
		Method AssertCurrent()
			DebugAssert( Not AtEnd,"Invalid list iterator" )
		End
		
		Method New( deque:Deque,index:Int )
			_deque=deque
			_index=index
			_seq=deque._seq
		End
		
		Public
		
		#rem monkeydoc Checks if the iterator has reached the end of the deque.
		#end
		Property AtEnd:Bool()
			AssertSeq()
			Return _index=_deque._tail
		End
		
		#rem monkeydoc The value currently pointed to by the iterator.
		#end
		Property Current:T()
			AssertCurrent()
			Return _deque._data[_index]
		Setter( current:T )
			AssertCurrent()
			_deque._data[_index]=current
		End
		
		#rem monkeydoc Bumps the iterator so it points to the next value in the deqeue.
		#end
		Method Bump()
			AssertCurrent()
			_index+=1
			If _index=_deque.Capacity _index=0
		End
		
		Method Erase()
			RuntimeError( "Erase not supported for Deques" )
		End
		
		#rem monkeydoc Safely inserts a value before the value pointed to by the iterator.

		After calling this method, the iterator will point to the newly added value.
		
		#end
		Method Insert( value:T )
			RuntimeError( "Insert not supported for Deques" )
		End
	End
	
	Private

	Field _data:T[]
	Field _head:Int
	Field _tail:Int
	Field _seq:Int	
	
	Method Normalize( capacity:Int )
	
		Local length:=Length
		
		Local data:=New T[capacity]
		
		If _head<=_tail
			_data.CopyTo( data,_head,0,length )
		Else
			Local n:=Capacity-_head
			_data.CopyTo( data,_head,0,n )
			_data.CopyTo( data,0,n,_tail )
		Endif
		
		_data=data
		_tail=length
		_head=0
		_seq+=1
	End
	
	Public
	
	Method New()
		_data=New T[10]
	End
	
	Method New( length:Int )
		_tail=length
		_data=New T[_tail+1]
	End

	Property Empty:Bool()
		Return _head=_tail
	End

	Property Capacity:Int()
		Return _data.Length
	End
	
	Property Length:Int()
		If _head<=_tail Return _tail-_head
		Return Capacity-_head+_tail
	End

	Property Data:T[]()

		If Not _head Return _data
		
		Normalize( Capacity )
		
		Return _data
	End
	
	Method ToArray:T[]()
	
		Local data:=New T[Length]
		
		If _head<=_tail
			_data.CopyTo( data,_head,0,Length )
		Else
			Local n:=Capacity-_head
			_data.CopyTo( data,_head,0,n )
			_data.CopyTo( data,0,n,_tail )
		Endif
		
		Return data
	End
	
	Method Reserve( capacity:Int )
		DebugAssert( capacity>=0 )
		
		If Capacity>=capacity Return

		capacity=Max( Length*2+Length,capacity )
		
		Normalize( capacity )
	End
	
	Method Clear()
		If _head<=_tail
			For Local i:=_head Until _tail
				_data[i]=Null
			Next
		Else
			For Local i:=0 Until _tail
				_data[i]=Null
			Next
			For Local i:=_head Until Capacity
				_data[i]=Null
			Next
		Endif
		_head=0
		_tail=0
		_seq+=1
	End
	
	Method PushFirst( value:T )
		If Length+1=Capacity Reserve( Capacity+1 )

		_head-=1
		If _head=-1 _head=Capacity-1
		_data[_head]=value
		_seq+=1
	End
	
	Method PushLast( value:T )
		If Length+1=Capacity Reserve( Capacity+1 )

		_data[_tail]=value
		_tail+=1
		If _tail=Capacity _tail=0
		_seq+=1
	End
	
	Method PopFirst:T()
		DebugAssert( Not Empty,"Illegal operation on empty deque" )

		Local value:=_data[_head]
		_data[_head]=Null
		_head+=1
		If _head=Capacity _head=0
		_seq+=1
		Return value
	End
	
	Method PopLast:T()
		DebugAssert( Not Empty,"Illegal operation on empty deque" )
		
		_tail-=1
		If _tail=-1 _tail=Capacity-1
		Local value:=_data[_tail]
		_data[_tail]=Null
		_seq+=1
		Return value
	End
	
	Method First:T()
		DebugAssert( Not Empty,"Illegal operation on empty deque" )
		
		Return _data[_head]
	End
	
	Method Last:T()
		DebugAssert( Not Empty,"Illegal operation on empty deque" )
		
		Return _data[ (_tail-1) Mod Capacity ]
	End
	
	Method Get:T( index:Int )
		DebugAssert( index>=0 And  index<Length,"Deque index out of range" )
		
		Return _data[ index Mod Capacity ]
	End
	
	Method Set( index:Int,value:T )
		DebugAssert( index>=0 And index<Length,"Deque index out of range" )
		
		_data[ index Mod Capacity ]=value
	End
	
	Operator[]:T( index:Int )
		DebugAssert( index>=0 And index<Length,"Deque index out of range" )
		
		Return _data[ index Mod Capacity ]
	End
	
	Operator[]=( index:Int,value:T )
		DebugAssert( index>=0 And index<Length,"Deque index out of range" )
		
		_data[ index Mod Capacity ]=value
	End
	
End
