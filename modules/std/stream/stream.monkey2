
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
	Method Close:Void() Abstract

	#rem monkeydoc Seeks to a position in the stream.
	
	In debug builds, a runtime error will occur if the stream is not seekable or `position` is out of range.
	
	@param position The position to seek to.
	
	#end
	Method Seek( position:Int ) Abstract
	
	#rem monkeydoc Reads data from the filestream to memory.
	
	@param mem A pointer to the memory to read the data into.
	
	@param count The number of bytes to read.
	
	@return The number of bytes actually read.
	
	#end
	Method Read:Int( mem:Void Ptr,count:Int ) Abstract
	
	#rem monkeydoc Writes data to the stream from memory.
	
	@param mem A pointer to the memory to write the data from.
	
	@param count The number of bytes to write.
	
	@return The number of bytes actually written.
	
	#end
	Method Write:Int( mem:Void Ptr,count:Int ) Abstract
	
	#rem monkeydoc The byte order of the stream.
	#end
	Property ByteOrder:ByteOrder()
		Return _tmpbuf.ByteOrder
	Setter( byteOrder:ByteOrder )
		_tmpbuf.ByteOrder=byteOrder
	End
	
	#rem monkeydoc Reads data from the stream into a databuffer.
	
	@param buf The databuffer to read the data into.
	
	@param offset The start offset in the databuffer.
	
	@param count The number of bytes to transfer.
	
	@return The number of bytes actually read.
	
	#end
	Method Read:Int( buf:DataBuffer,offset:Int,count:Int )
		DebugAssert( offset>=0 And count>=0 And offset+count<=buf.Length )
		
		Return Read( buf.Data+offset,count )
	End
	
	#rem monkeydoc Writes data to a stream from a databuffer.
	
	@param buf The databuffer to write the data from.
	
	@param offset The start offset in the databuffer.
	
	@param count The number of bytes to transfer.
	
	@return The number of bytes actually written.
	
	#end
	Method Write:Int( buf:DataBuffer,offset:Int,count:Int )
		DebugAssert( offset>=0 And count>=0 And offset+count<=buf.Length )

		Return Write( buf.Data+offset,count )
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
		If Read( _tmpbuf.Data,2 )=2 Return _tmpbuf.PeekShort( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 16 bit unsigned short from the stream.
	
	@return The ushort read.
	
	#end
	Method ReadUShort:UShort()
		If Read( _tmpbuf.Data,2 )=2 Return _tmpbuf.PeekUShort( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit int from the stream.
	
	@return The int read.
	
	#end
	Method ReadInt:Int()
		If Read( _tmpbuf.Data,4 )=4 Return _tmpbuf.PeekInt( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit unsigned int from the stream.
	
	@return The uint read.
	
	#end
	Method ReadUInt:UInt()
		If Read( _tmpbuf.Data,4 )=4 Return _tmpbuf.PeekUInt( 0 )
		
		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit long from the stream.
	
	@return The long read.
	
	#end
	Method ReadLong:Long()
		If Read( _tmpbuf.Data,8 )=8 Return _tmpbuf.PeekLong( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit unsigned long from the stream.
	
	@return The ulong read.
	
	#end
	Method ReadULong:ULong()
		If Read( _tmpbuf.Data,8 )=8 Return _tmpbuf.PeekULong( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads a 32 bit float from the stream.
	
	@return The float read.
	
	#end
	Method ReadFloat:Float()
		If Read( _tmpbuf.Data,4 )=4 Return _tmpbuf.PeekFloat( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads a 64 bit double from the stream.
	
	@return The double read.
	
	#end
	Method ReadDouble:Double()
		If Read( _tmpbuf.Data,8 )=8 Return _tmpbuf.PeekDouble( 0 )

		Return 0
	End
	
	#rem monkeydoc Reads a null terminated cstring from the stream
	
	@return the string read.
	
	#end
	Method ReadCString:String()
		Local buf:=New Stack<Byte>
		While Not Eof
			Local chr:=ReadByte()
			If Not chr Exit
			buf.Push( chr )
		Wend
		buf.Push( 0 )
		Return String.FromCString( buf.Data.Data )
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
	
	#rem monkeydoc Write a nullterminated CString to the stream.
	
	@param data The string to write.
	
	#end
	Method WriteCString:Void( data:String )
		Local buf:=New Stack<UByte>
		buf.Resize( data.Length+1 )
		For Local i:=0 Until data.Length
			buf[i]=data[i]
		Next
		buf[ data.Length ]=0
		Write( buf.Data.Data,buf.Length )
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
	
	Private
	
	Field _tmpbuf:=New DataBuffer( 8 )

End
