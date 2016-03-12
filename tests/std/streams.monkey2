
#Import "<std.monkey2>"

Namespace test

Using std

Function Write( stream:Stream )

	stream.WriteByte( 99 )
	stream.WriteByte( -99 )
	stream.WriteByte( -99 )
	
	stream.WriteShort( 9999 ) 
	stream.WriteShort( -9999 ) 
	stream.WriteShort( -9999 ) 
	
	stream.WriteInt( 999999 )
	stream.WriteInt( -999999 )
	stream.WriteInt( -999999 )
	
	stream.WriteLong( 99999999 )
	stream.WriteLong( -99999999 )
	stream.WriteLong( -99999999 )
	
	stream.WriteFloat( 1234.5678 )
	stream.WriteDouble( 1234.5678 )
	stream.WriteCString( "Hello World" )

End

Function Read( stream:Stream )

	Print stream.ReadByte()		'99
	Print stream.ReadByte()		'-99
	Print stream.ReadUByte()	'157
	
	Print stream.ReadShort()	'9999
	Print stream.ReadShort()	'-9999
	Print stream.ReadUShort()	'55537
	
	Print stream.ReadInt()		'999999
	Print stream.ReadInt()		'-999999
	Print stream.ReadUInt()		'4293967297
	
	Print stream.ReadLong()		'99999999
	Print stream.ReadLong()		'-99999999
	Print stream.ReadULong()	'18446744073609551617
	
	Print stream.ReadFloat()	'1234.56775
	Print stream.ReadDouble()	'1234.5678
	Print stream.ReadCString()	'Hello World

End

Function Test( stream:Stream,byteOrder:ByteOrder )
	Print ""
	stream.ByteOrder=byteOrder
	Write( stream )
	stream.Seek( 0 )
	Read( stream )
	stream.Close()
End

Function Main()

	For Local i:=0 Until 2
	
		Local byteOrder:=i=0 ? ByteOrder.LittleEndian Else ByteOrder.BigEndian
		
		Test( FileStream.Open( "testfile","rw" ),byteOrder )
		
		Test( New DataStream( New DataBuffer( 1024 )  ),byteOrder )
		
	Next
	
End
