
#Import "<std.monkey2>"

Namespace test

Using std

Function Main()

	For Local i:=0 Until 2
	
		Print ""
	
		Local t:=New DataBuffer( 16 )
		t.ByteOrder=i=0 ? ByteOrder.LittleEndian Else ByteOrder.BigEndian
		
		t.PokeByte( 0,99 )
		Print t.PeekByte( 0 )	'99
		Print t.PeekUByte( 0 )	'99
		
		t.PokeByte( 0,-99 )
		Print t.PeekByte( 0 )	'-99
		Print t.PeekUByte( 0 )	'157
		
		t.PokeShort( 0,1234 )
		Print t.PeekShort( 0 )	'1234
		Print t.PeekUShort( 0 )	'1234
		
		t.PokeShort( 0,-1234 )
		Print t.PeekShort( 0 )	'-1234
		Print t.PeekUShort( 0 )	'64302
		
		t.PokeInt( 0,1234 )
		Print t.PeekInt( 0 )	'1234
		Print t.PeekUInt( 0 )	'1234
		
		t.PokeInt( 0,-1234 )
		Print t.PeekInt( 0 )	'-1234
		Print t.PeekUInt( 0 )	'4294966062
		
		t.PokeLong( 0,1234 )
		Print t.PeekLong( 0 )	'1234
		Print t.PeekULong( 0 )	'1234
		
		t.PokeLong( 0,-1234 )
		Print t.PeekLong( 0 )	'-1234
		Print t.PeekULong( 0 )	'18446744073709551615
		
		t.PokeFloat( 0,1234.5678 )
		Print t.PeekFloat( 0 )	'1234.56775
		
		t.PokeDouble( 0,1234.5678 )
		Print t.PeekDouble( 0 )	'1234.5678
	
	Next
	
End
