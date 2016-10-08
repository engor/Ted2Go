
Namespace std.memory

#rem monkeydoc DataStream class.
#end
Class DataStream Extends std.stream.Stream

	#rem monkeydoc Creates a new datastream.
	
	A datastream wraps a databuffer so it can be used as if it were a stream.
	
	In debug mode, a RuntimeError will occur if `offset` or `count` are outside the range of the databuffer.
	
	@param data The databuffer to wrap.
	
	@param offset The starting offset.
	
	@param count The number of bytes.
	
	#end
	Method New( buf:DataBuffer,offset:Int=0 )
		Self.New( buf,offset,buf.Length-offset )
		
	End

	Method New( buf:DataBuffer,offset:Int,count:Int )
		DebugAssert( offset>=0 And count>=0 And offset+count<=buf.Length )
		
		_buf=buf
		_off=offset
		_len=count
		_pos=0
	End
	
	#rem monkeydoc True if no more data can be read from or written to the stream.
	#end
	Property Eof:Bool() Override
		Return _pos>=_len
	End
	
	#rem monkeydoc Current datastream position.
	#end
	Property Position:Int() Override
		Return _pos
	End
	
	#rem monkeydoc Current datastream length.
	#end
	Property Length:Int() Override
		Return _len
	End
	
	#rem monkeydoc Closes the datastream.
	
	#end
	Method OnClose() Override
		If Not _buf Return
		_buf=Null
		_off=0
		_pos=0
		_len=0
	End
	
	#rem monkeydoc Seeks to a position in the datastream.
	
	@param position The position to seek to.
	
	#end
	Method Seek( position:Int ) Override

		_pos=Clamp( position,0,_len )
	End
	
	#rem monkeydoc Reads data from the datastream.
	
	@param buf A pointer to the memory to read the data into.
	
	@param count The number of bytes to read.
	
	@return The number of bytes actually read.
	
	#end
	Method Read:Int( buf:Void Ptr,count:Int ) Override
	
		count=Clamp( count,0,_len-_pos )
		
		libc.memcpy( buf,_buf.Data+_off+_pos,count )
		
		_pos+=count
		
		Return count
	End
	
	#rem monkeydoc Writes data to the datastream.
	
	@param buf A pointer to the memory to write the data from.
	
	@param count The number of bytes to write.
	
	@return The number of bytes actually written.
	
	#end
	Method Write:Int( buf:Void Ptr,count:Int ) Override
	
		count=Clamp( count,0,_len-_pos )
		
		libc.memcpy( _buf.Data+_off+_pos,buf,count )
		
		_pos+=count
		
		Return count
	End

	Private
	
	Field _buf:DataBuffer
	Field _off:Int
	Field _pos:Int
	Field _len:Int

End
