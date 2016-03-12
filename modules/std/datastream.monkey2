
Namespace std

#rem monkeydoc DataStream class.
#end
Class DataStream Extends Stream

	#rem monkeydoc Creates a new datastream.
	#end
	Method New( buf:DataBuffer )
		_buf=buf
		_pos=0
		_end=_buf.Length
	End
	
	#rem monkeydoc True if no more data can be read from or written to the stream.
	#end
	Property Eof:Bool() Override
		Return _pos>=_end
	End
	
	#rem monkeydoc Current datastream position.
	#end
	Property Position:Int() Override
		Return _pos
	End
	
	#rem monkeydoc Current datastream length.
	#end
	Property Length:Int() Override
		Return _end
	End
	
	#rem monkedoc Closes the datastream.
	
	Closing a datastream also sets its position and length to 0.
	
	#end
	Method Close() Override
		If Not _buf Return
		_buf=Null
		_pos=0
		_end=0
	End
	
	#rem monkedoc Seeks to a position in the datastream.
	
	@param position The position to seek to.
	
	#end
	Method Seek( position:Int ) Override
		DebugAssert( position>=0 And position<=_end )
		
		_pos=position
	End
	
	#rem monkedoc Reads data from the datastream.
	
	@param buf A pointer to the memory to read the data into.
	
	@param count The number of bytes to read.
	
	@return The number of bytes actually read.
	
	#end
	Method Read:Int( buf:Void Ptr,count:Int ) Override
		count=Clamp( count,0,_end-_pos )
		libc.memcpy( buf,_buf.Data+_pos,count )
		_pos+=count
		Return count
	End
	
	#rem monkeydoc Writes data to the datastream.
	
	@param buf A pointer to the memory to write the data from.
	
	@param count The number of bytes to write.
	
	@return The number of bytes actually written.
	
	#end
	Method Write:Int( buf:Void Ptr,count:Int ) Override
		count=Clamp( count,0,_end-_pos )
		libc.memcpy( _buf.Data+_pos,buf,count )
		_pos+=count
		Return count
	End

	Private
	
	Field _buf:DataBuffer
	Field _pos:Int
	Field _end:Int

End
