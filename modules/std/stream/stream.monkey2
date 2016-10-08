
Namespace std.stream

Using libc
Using std.memory
Using std.collections

#rem monkeydoc Stream class.
#end
Class Stream

	#rem monkeydoc True if no more data can be read from the stream.
	#end
	Property Eof:Bool() Abstract
	
	#rem monkeydoc Current stream position.
	
	In the case of non-seekable streams, `Position` will always be -1.
	
	#end
	Property Position:Int() Abstract

	#rem monkeydoc Current stream length.
	
	In the case of non-seekable streams, `Length` is the number of bytes that can be read from the stream without 'blocking'.
	
	#end	
	Property Length:Int() Abstract
	
	#rem monkeydoc Closes the stream.
	#end
	Method Close:Void()
		OnClose()
		_tmpbuf.Discard()
	End

	#rem monkeydoc Seeks to a position in the stream.
	
	In debug builds, a runtime error will occur if the stream is not seekable or `position` is out of range.
	
	@param position The position to seek to.
	
	#end
	Method Seek( position:Int ) Abstract
	
	#rem monkeydoc Reads data from the stream into memory.
	
	Reads `count` bytes of data from the stream into either a raw memory pointer or a databuffer.
	
	Returns the number of bytes actually read.
	
	@param buf A pointer to the memory to read the data into.
	
	@param data The databuffer to read the data into.
	
	@param count The number of bytes to read from the stream.
	
	@return The number of bytes actually read.
	
	#end
	Method Read:Int( buf:Void Ptr,count:Int ) Abstract
	
	Method Read:Int( data:DataBuffer,offset:Int,count:Int )
		DebugAssert( offset>=0 And count>=0 And offset+count<=data.Length )
		
		Return Read( data.Data+offset,count )
	End
	
	#rem monkeydoc Writes data to the stream from memory.
	
	Writes `count` bytes of data to the stream from either a raw memory pointer or a databuffer.
	
	Returns the number of bytes actually written
	
	@param buf A pointer to the memory to write the data from.

	@param data The databuffer to write the data from.
	
	@param count The number of bytes to write to the stream.
	
	@return The number of bytes actually written.
	
	#end
	Method Write:Int( buf:Void Ptr,count:Int ) Abstract

	Method Write:Int( data:DataBuffer,offset:Int,count:Int )
		DebugAssert( offset>=0 And count>=0 And offset+count<=data.Length )

		Return Write( data.Data+offset,count )
	End

	#rem monkeydoc The byte order of the stream.
	
	The default byte order is ByteOrder.BigEndian.
	
	#end
	Property ByteOrder:ByteOrder()
		Return _tmpbuf.ByteOrder
	Setter( byteOrder:ByteOrder )
		_tmpbuf.ByteOrder=byteOrder
	End
	
	#rem monkeydoc Reads as many bytes as possible from a stream into memory.
	
	Continously reads data from a stream until either `count` bytes are read or the end of stream is reached.
	
	Returns the number of bytes read or the data read.

	@param buf memory to read bytes into.
	
	@param data data buffer to read bytes into.
	
	@param count number of bytes to read.
	
	#end
	Method ReadAll:Int( buf:Void Ptr,count:Int )
	
		Local pos:=0
		
		While pos<count
			Local n:=Read( Cast<Byte Ptr>( buf )+pos,count-pos )
			If n<=0 Exit
			pos+=n
		Wend
		
		Return pos
	End
	
	Method ReadAll:Int( data:DataBuffer,offset:Int,count:Int )
	
		Return ReadAll( data.Data+offset,count )
	End
	
	Method ReadAll:DataBuffer( count:Int )
	
		Local data:=New DataBuffer( count )
		Local n:=ReadAll( data,0,count )
		If n>=count Return data
		Local tmp:=data.Slice( 0,n )
		data.Discard()
		Return tmp
	End
	
	Method ReadAll:DataBuffer()
	
		If Length>=0 Return ReadAll( Length-Position )

		Local bufs:=New Stack<DataBuffer>
		Local buf:=New DataBuffer( 4096 ),pos:=0
		Repeat
			pos=ReadAll( buf,0,4096 )
			If pos<4096 Exit
			bufs.Push( buf )
			buf=New DataBuffer( 4096 )
		Forever
		Local len:=bufs.Length * 4096 + pos
		Local data:=New DataBuffer( len )
		pos=0
		For Local buf:=Eachin bufs
			buf.CopyTo( data,0,pos,4096 )
			buf.Discard()
			pos+=4096
		Next
		buf.CopyTo( data,0,pos,len-pos )
		buf.Discard()
		Return data
	End
	
	#rem monkeydoc Reads data from the filestream and throws it away.

	@param count The number of bytes to skip.
	
	@return The number of bytes actually skipped.
	
	#end
	Method Skip:Int( count:Int )
		Local tmp:=libc.malloc( count )
		Local n:=Read( tmp,count )
		libc.free( tmp )
		Return n
	End
	
	#rem monkeydoc Reads a byte from the stream.
	
	@return The byte read.
	
	#end
	Method ReadByte:Byte()
		If Read( _tmpbuf.Data,1 )=1 Return _tmpbuf.PeekByte( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads an unsigned byte from the stream.
	
	@return The ubyte read.
	
	#end
	Method ReadUByte:UByte()
		If Read( _tmpbuf.Data,1 )=1 Return _tmpbuf.PeekUByte( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 16 bit short from the stream.
	
	@return The short read.
	
	#end
	Method ReadShort:Short()
		If ReadAll( _tmpbuf.Data,2 )=2 Return _tmpbuf.PeekShort( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 16 bit unsigned short from the stream.
	
	@return The ushort read.
	
	#end
	Method ReadUShort:UShort()
		If ReadAll( _tmpbuf.Data,2 )=2 Return _tmpbuf.PeekUShort( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit int from the stream.
	
	@return The int read.
	
	#end
	Method ReadInt:Int()
		If ReadAll( _tmpbuf.Data,4 )=4 Return _tmpbuf.PeekInt( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit unsigned int from the stream.
	
	@return The uint read.
	
	#end
	Method ReadUInt:UInt()
		If ReadAll( _tmpbuf.Data,4 )=4 Return _tmpbuf.PeekUInt( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit long from the stream.
	
	@return The long read.
	
	#end
	Method ReadLong:Long()
		If ReadAll( _tmpbuf.Data,8 )=8 Return _tmpbuf.PeekLong( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit unsigned long from the stream.
	
	@return The ulong read.
	
	#end
	Method ReadULong:ULong()
		If ReadAll( _tmpbuf.Data,8 )=8 Return _tmpbuf.PeekULong( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit float from the stream.
	
	@return The float read.
	
	#end
	Method ReadFloat:Float()
		If ReadAll( _tmpbuf.Data,4 )=4 Return _tmpbuf.PeekFloat( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads a 64 bit double from the stream.
	
	@return The double read.
	
	#end
	Method ReadDouble:Double()
		If ReadAll( _tmpbuf.Data,8 )=8 Return _tmpbuf.PeekDouble( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads the entire stream into a string.
	#end
	Method ReadString:String( encoding:String="utf8" )
		Local data:=ReadAll()
		Local str:=data.PeekString( 0,encoding )
		data.Discard()
		Return str
	End
	
	#rem monkeydoc Reads a null terminated string from the stream.
	
	@return the string read.
	
	#end
	Method ReadCString:String( encoding:String="utf8" )
		Local buf:=New Stack<Byte>
		While Not Eof
			Local chr:=ReadByte()
			If Not chr Exit
			buf.Push( chr )
		Wend
		If encoding="utf8" Return String.FromUtf8Data( buf.Data.Data,buf.Length )
		Return String.FromAsciiData( buf.Data.Data,buf.Length )
	End
	
	#rem monkeydoc Writes a byte to the stream.
	
	@param data The byte to write.
	
	#end
	Method WriteByte( data:Byte )
		_tmpbuf.PokeByte( 0,data )
		Write( _tmpbuf.Data,1 )
	End
	
	#rem monkeydoc Write an unsigned byte to the stream.
	
	@param data The ubyte to write.

	#end
	Method WriteUByte( data:UByte )
		_tmpbuf.PokeUByte( 0,data )
		Write( _tmpbuf.Data,1 )
	End
	
	#rem monkeydoc Writes a 16 bit short to the stream.
	
	@param data The short to write.

	#end
	Method WriteShort( data:Short )
		_tmpbuf.PokeShort( 0,data )
		Write( _tmpbuf.Data,2 )
	End
	
	#rem monkeydoc Writes a 16 bit unsigned short to the stream.
	
	@param data The ushort to write.

	#end
	Method WriteUShort( data:UShort )
		_tmpbuf.PokeUShort( 0,data )
		Write( _tmpbuf.Data,2 )
	End
	
	#rem monkeydoc Writes a 32 bit int to the stream.
	
	@param data The int to write.

	#end
	Method WriteInt( data:Int )
		_tmpbuf.PokeInt( 0,data )
		Write( _tmpbuf.Data,4 )
	End
	
	#rem monkeydoc Writes a 32 bit unsigned int to the stream.
	
	@param data The uint to write.

	#end
	Method WriteUInt( data:UInt )
		_tmpbuf.PokeUInt( 0,data )
		Write( _tmpbuf.Data,4 )
	End
	
	#rem monkeydoc Writes a 64 bit long to the stream.
	
	@param data The long to write.

	#end
	Method WriteLong( data:Long )
		_tmpbuf.PokeLong( 0,data )
		Write( _tmpbuf.Data,8 )
	End
	
	#rem monkeydoc Writes a 64 bit unsigned long to the stream.
	
	@param data The ulong to write.

	#end
	Method WriteULong( data:ULong )
		_tmpbuf.PokeULong( 0,data )
		Write( _tmpbuf.Data,8 )
	End
	
	#rem monkeydoc Writes a 32 bit float to the stream,
	
	@param data The float to write.

	#end
	Method WriteFloat:Void( data:Float )
		_tmpbuf.PokeFloat( 0,data )
		Write( _tmpbuf.Data,4 )
	End
	
	#rem monkeydoc Writes a 64 bit double to the stream.
	
	@param data The double to write.

	#end
	Method WriteDouble( data:Double )
		_tmpbuf.PokeDouble( 0,data )
		Write( _tmpbuf.Data,8 )
	End
	
	#rem monkeydoc Writes a string to the stream (NOT null terminated).

	@param str The string to write.
	
	#end
	Method WriteString( str:String,encoding:String="utf8" )
		Local size:=(encoding="utf8" ? str.Utf8Length Else str.Length)
		Local buf:=New DataBuffer( size )
		buf.PokeString( 0,str,encoding )
		Write( buf,0,size )
	End
	
	#rem monkeydoc Writes a null terminated string to the stream.

	@param str The string to write.
	
	#end
	Method WriteCString( str:String,encoding:String="utf8" )
		Local size:=(encoding="utf8" ? str.Utf8Length Else str.Length)+1
		Local buf:=New DataBuffer( size )
		buf.PokeString( 0,str,encoding )
		buf.PokeByte( size-1,0 )
		Write( buf,0,size )
	End
	
	#rem monkeydoc Opens a stream
	
	`mode` should be "r" for read, "w" for write or "rw" for read/write.
	
	@param mode The mode to open the stream in: "r", "w" or "rw"
	
	#end
	Function Open:Stream( path:String,mode:String )

		Local i:=path.Find( "::" )
		If i=-1 Return FileStream.Open( path,mode )
		
		Local proto:=path.Slice( 0,i )
		Local ipath:=path.Slice( i+2 )

		Return OpenFuncs[proto]( proto,ipath,mode )

	End
	
	#rem monkeydoc @hidden
	#end
	Alias OpenFunc:Stream( proto:String,path:String,mode:String )
	
	#rem monkeydoc @hidden
	#end
	Const OpenFuncs:=New StringMap<OpenFunc>
	
	Protected
	
	Method New()
		_tmpbuf=New DataBuffer( 8,ByteOrder.LittleEndian )
	End
	
	Method OnClose() Abstract
	
	Private
	
	Field _tmpbuf:DataBuffer

End
