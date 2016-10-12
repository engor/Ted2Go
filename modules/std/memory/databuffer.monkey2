
Namespace std.memory

Using std.stream

#rem monkeydoc DataBuffer class.
#end
Class DataBuffer Extends std.resource.Resource

	#rem monkeydoc Creates a new databuffer.
	
	The new databuffer initally uses little endian byte order. You can change this via the ByteOrder property.
	
	When you have finished with the data buffer, you should call its inherited [[Resource.Discard]] method.
	
	@example
	
	\#Import "<std>"
	
	Using std.memory
	
	Function Main()

		Local buf:=New DataBuffer( 10 )
		
		Print buf.Length
	
		For Local i:=0 Until 10
			buf.PokeByte( i,i*2 )
		Next
		
		For Local i:=0 Until 10
			Print buf.PeekByte( i )
		Next
		
	End
	
	@end
	
	@param length The length of the databuffer to create, in bytes.
	
	@param byteOrder Initial byte order of the data.
	
	#end
	Method New( length:Int,byteOrder:ByteOrder=std.memory.ByteOrder.LittleEndian )
	
		_length=length
		_data=Cast<UByte Ptr>( libc.malloc( length ) )
		_byteOrder=byteOrder
		_swapEndian=False
		
		OnDiscarded+=Lambda()
			libc.free( _data )
			_data=Null
		End
	End
	
	#rem monkeydoc A raw pointer to the databuffer's internal memory.
	
	Note: This pointer will change if the databuffer is resized using Resize.
	
	#end
	Property Data:UByte Ptr()
		Return _data
	End
	
	#rem monkeydoc The length of the databuffer in bytes.
	#end
	Property Length:Int()
		Return _length
	End
	
	#rem monkeydoc The byte order of the databuffer.
	#end
	Property ByteOrder:ByteOrder()
		Return _byteOrder
	Setter( byteOrder:ByteOrder )
		_byteOrder=byteOrder
		_swapEndian=(_byteOrder=ByteOrder.BigEndian)
	End

	#rem monkeydoc Resizes the databuffer.
	
	Note: This method reallocates the internal memory buffer and will cause the [[Data]] property to change.
	
	@param length The new length of the databuffer.
	
	#end	
	Method Resize( length:Int )
		Local data:=Cast<UByte Ptr>( libc.malloc( length ) )
		libc.memcpy( data,_data,Min( length,_length ) )
		libc.free( _data )
		_data=data
	End
	
	#rem monkeydoc Reads a byte from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The byte read from `offset`.
	
	#end
	Method PeekByte:Byte( offset:Int )
		DebugAssert( offset>=0 And offset<_length )
		
		Return Cast<Byte Ptr>( _data+offset )[0]
	End
	
	#rem monkeydoc Reads a ubyte from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The ubyte read from `offset`.
	
	#end
	Method PeekUByte:UByte( offset:Int )
		DebugAssert( offset>=0 And offset<_length )

		Return Cast<UByte Ptr>( _data+offset )[0]
	End
	
	#rem monkeydoc Reads a 16 bit short from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The short read from `offset`.
	
	#end
	Method PeekShort:Short( offset:Int )
		DebugAssert( offset>=0 And offset<_length-1 )
		
		Local t:=Cast<Short Ptr>( _data+offset )[0]
		If _swapEndian Swap2( Varptr t )
		Return t
	End
	
	#rem monkeydoc Reads a 16 bit ushort from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The ushort read from `offset`.
	
	#end
	Method PeekUShort:UShort( offset:Int )
		DebugAssert( offset>=0 And offset<_length-1 )

		Local t:=Cast<UShort Ptr>( _data+offset )[0]
		If _swapEndian Swap2( Varptr t )
		Return t
	End
	
	#rem monkeydoc Reads a 32 bit int from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The int read from `offset`.
	
	#end
	Method PeekInt:Int( offset:Int )
		DebugAssert( offset>=0 And offset<_length-3 )
	
		Local t:=Cast<Int Ptr>( _data+offset )[0]
		If _swapEndian Swap4( Varptr t )
		Return t
	End
	
	#rem monkeydoc Reads a 32 bit uint from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The uint read from `offset`.
	
	#end
	Method PeekUInt:UInt( offset:Int )
		DebugAssert( offset>=0 And offset<_length-3 )

		Local t:=Cast<UInt Ptr>( _data+offset )[0]
		If _swapEndian Swap4( Varptr t )
		Return t
	End
	
	#rem monkeydoc Reads a 64 bit long from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The long read from `offset`.
	
	#end
	Method PeekLong:Long( offset:Int )
		DebugAssert( offset>=0 And offset<_length-7 )
		
		Local t:=Cast<Long Ptr>( _data+offset )[0]
		If _swapEndian Swap8( Varptr t )
		Return t
	End
		
	#rem monkeydoc Reads a 64 bit ulong from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The ulong read from `offset`.
	
	#end
	Method PeekULong:ULong( offset:Int )
		DebugAssert( offset>=0 And offset<_length-7 )

		Local t:=Cast<ULong Ptr>( _data+offset )[0]
		If _swapEndian Swap8( Varptr t )
		Return t
	End
	
	#rem monkeydoc Reads a 32 bit float from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The float read from `offset`.
	
	#end
	Method PeekFloat:Float( offset:Int )
		DebugAssert( offset>=0 And offset<_length-3 )

		Local t:=Cast<Float Ptr>( _data+offset )[0]
		If _swapEndian Swap4( Varptr t )
		Return t
	End
	
	#rem monkeydoc Reads a 64 bit double from the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to read.
	
	@return The double read from `offset`.
	
	#end
	Method PeekDouble:Double( offset:Int )
		DebugAssert( offset>=0 And offset<_length-7 )
	
		Local t:=Cast<Double Ptr>( _data+offset )[0]
		If _swapEndian Swap8( Varptr t )
		Return t
	End
	
	#rem monkeydoc Reads a string from the databuffer.
	
	If `count` is omitted, all bytes from `offset` until the end of the data buffer are read.
	
	`encoding` should be one of "utf8" or "ansi".

	@param offset Byte offset to read the string.
	
	@param count Number of bytes to read.
	
	@param encoding The encoding to use.
	
	#end
	Method PeekString:String( offset:Int,encoding:String="utf8" )
		DebugAssert( offset>=0 And offset<=_length )
		
		Return PeekString( offset,_length-offset,encoding )
	End
	
	Method PeekString:String( offset:Int,count:Int,encoding:String="utf8" )
		DebugAssert( offset>=0 And count>=0 And offset+count<=_length )

		If encoding="ansi" Or encoding="ascii" Return String.FromAsciiData( _data+offset,count )
		
		Return String.FromUtf8Data( _data+offset,count )
	End
	
	#rem monkeydoc Writes a byte to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeByte( offset:Int,value:Byte )
		DebugAssert( offset>=0 And offset<_length )
	
		Cast<Byte Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes an unsigned byte to the databuffer.
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeUByte( offset:Int,value:UByte )
		DebugAssert( offset>=0 And offset<_length )

		Cast<UByte Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 16 bit short to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeShort( offset:Int,value:Short )
		DebugAssert( offset>=0 And offset<_length-1 )
	
		If _swapEndian Swap2( Varptr value )
		Cast<Short Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 16 bit unsigned short to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeUShort( offset:Int,value:UShort )
		DebugAssert( offset>=0 And offset<_length-1 )

		If _swapEndian Swap2( Varptr value )
		Cast<UShort Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 32 bit int to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeInt( offset:Int,value:Int )
		DebugAssert( offset>=0 And offset<_length-3 )
	
		If _swapEndian Swap4( Varptr value )
		Cast<Int Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 32 bit unsigned int to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeUInt( offset:Int,value:UInt )
		DebugAssert( offset>=0 And offset<_length-3 )

		If _swapEndian Swap4( Varptr value )
		Cast<UInt Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 64 bit long to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeLong( offset:Int,value:Long )
		DebugAssert( offset>=0 And offset<_length-7 )

		If _swapEndian Swap8( Varptr value )
		Cast<Long Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 64 bit unsigned long to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeULong( offset:Int,value:ULong )
		DebugAssert( offset>=0 And offset<_length-7 )
		
		If _swapEndian Swap8( Varptr value )
		Cast<ULong Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 32 bit float to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeFloat( offset:Int,value:Float )
		DebugAssert( offset>=0 And offset<_length-3 )
	
		If _swapEndian Swap4( Varptr value )
		Cast<Float Ptr>( _data+offset )[0]=value
	End
	
	#rem monkeydoc Writes a 64 bit double to the databuffer
	
	In debug builds, a runtime error will occur if `offset` is outside the range of the databuffer.
	
	@param offset The offset to write.
	
	#end
	Method PokeDouble( offset:Int,value:Double )
		DebugAssert( offset>=0 And offset<_length-7 )
	
		If _swapEndian Swap8( Varptr value )
		Cast<Double Ptr>( _data+offset )[0]=value
	End

	#rem monkeydoc Write a string to the databuffer.

	`encoding` should be one of "utf8" or "ansi".
	
	If there is not enough room in the data buffer, the string data is truncated.
	
	@param offset Byte offset to write the string.
	
	@param value The string to write.
	
	@param encoding The encoding to use.
	
	#end	
	Method PokeString( offset:Int,value:String,encoding:String="utf8" )
		DebugAssert( offset>=0 And offset<=_length )
		
		DebugAssert( encoding="utf8" Or encoding="ascii" )
		
		If encoding="ansi" Or encoding="ascii"
			Local count:=value.Length
			If offset+count>_length count=_length-offset
			value.ToCString( _data+offset,count )
		Else
			Local count:=value.Utf8Length
			If offset+count>_length count=_length-offset
			value.ToUtf8String( _data+offset,count )
		Endif

	End

	#rem monkeydoc Creates a slice of the databuffer.
	#end
	Method Slice:DataBuffer( from:Int=0 )
	
		Return Slice( from,_length )
	End
		
	Method Slice:DataBuffer( from:Int,term:int )
	
		If from<0
			from+=_length
		Else If from>_length
			from=_length
		Endif
		
		If term<0
			term+=_length
			If term<from term=from
		Else If term<from
			term=from
		Else If term>_length
			term=_length
		Endif
		
		Local newlen:=term-from
		
		Local data:=New DataBuffer( newlen )
		CopyTo( data,from,0,newlen )
		
		Return data
	End
	
	#rem monkeydoc Copies databuffer data to another databuffer.
	
	In debug builds, a runtime error while occur if an attempt it made to copy data outside the range of either databuffer.
	
	@param dst The destination databuffer.
	
	@param srcOffset The starting byte offset in this databuffer to copy from.
	
	@param dstOffset The starting byte offest in the destination databuffer to copy to.
	
	@param count The number of bytes to copy.
	
	#end
	Method CopyTo( dst:DataBuffer,srcOffset:Int,dstOffset:Int,count:Int )
		DebugAssert( srcOffset>=0 And srcOffset+count<=_length And dstOffset>=0 And dstOffset+count<=dst._length )
		
		libc.memmove( dst._data+dstOffset,_data+srcOffset,count )
	End
	
	#rem monkeydoc Saves the contents of the databuffer to a file.
	
	@param path The file path.
	
	@return True if successful, false if `path` could not be opened or not all data could be written.
	
	#end
	Method Save:Bool( path:String )
	
		Local stream:=Stream.Open( path,"w" )
		If Not stream Return False
		
		Local n:=stream.Write( _data,_length )
		
		stream.Close()
		
		Return n=_length
	End
	
	#rem monkeydoc Creates a databuffer with the contents of a file.
	
	@param path The file path.
	
	@return A new databuffer containing the contents of `path`, or null if `path` could not be opened.
	
	#end
	Function Load:DataBuffer( path:String )
	
		Local stream:=Stream.Open( path,"r" )
		If Not stream Return Null
		
		Local data:=stream.ReadAll()
		
		stream.Close()
		
		Return data
	End

	Private
	
	Field _data:UByte Ptr
	Field _length:Int
	Field _byteOrder:ByteOrder
	Field _swapEndian:Bool
	
	Function Swap2( v:Void Ptr )
		Local t:=Cast<UShort Ptr>( v )[0]
		Cast<UShort Ptr>( v )[0]=(t Shr 8 & $ff) | (t & $ff) Shl 8
	End
	
	Function Swap4( v:Void Ptr )
		Local t:=Cast<UInt Ptr>( v )[0]
		Cast<UInt Ptr>( v )[0]=(t Shr 24 & $ff) | (t & $ff) Shl 24 | (t Shr 8 & $ff00) | (t & $ff00) Shl 8
	End
	
	Function Swap8( v:Void Ptr )
		Local t:=Cast<ULong Ptr>( v )[0]
		Cast<ULong Ptr>( v )[0]=(t Shr 56 & $ff) | (t & $ff) Shl 56 | (t Shr 40 & $ff00) | (t & $ff00) Shl 40 | (t Shr 24 & $ff0000) | (t & $ff0000) Shl 24 | (t Shr 8 & $ff000000) | (t & $ff000000) Shl 8
	End

End
