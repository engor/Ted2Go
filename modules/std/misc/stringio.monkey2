
Namespace std.stringio

Using libc

#rem monkeydoc Loads a string from a file.

An empty string will be returned if the file could not be opened.

@param path The path of the file.

@param fixeols If true, converts eols to UNIX "~n" eols after loading.

@return A String containing the contents of the file. 

#end
Function LoadString:String( path:String,fixeols:Bool=False )

	Local data:=DataBuffer.Load( path )
	If Not data Return ""
	
	Local str:=String.FromCString( data.Data,data.Length )
	
	data.Discard()
	
	If fixeols
		str=str.Replace( "~r~n","~n" )
		str=str.Replace( "~r","~n" )
	Endif
	
	Return str
End

#rem monkeydoc Saves a string to a file.

@param str The string to save.

@param path The path of the file.

@param fixeols If true, converts eols to UNIX "~n" eols before saving.

@return False if the file could not be opened.

#end
Function SaveString:Bool( str:String,path:String,fixeols:Bool=False )

	If fixeols
		str=str.Replace( "~r~n","~n" )
		str=str.Replace( "~r","~n" )
	Endif
	
	Local data:=New DataBuffer( str.CStringLength )
	str.ToCString( data.Data,data.Length )
	
	Local ok:=data.Save( path )
	
	data.Discard()
	
	Return ok
End

#rem monkeydoc @deprecated Use [[ULongToString]] instead.
#end
Function Hex:String( value:ULong )

	Local str:=""
	
	While value
		Local nyb:=value & $f
		If nyb<10 str=String.FromChar( nyb+48 )+str Else str=String.FromChar( nyb+55 )+str
		value=value Shr 4
	Wend
	
	Return str ? str Else "0"
End

#rem monkeydoc @deprecated Use [[StringToULong]] instead.
#end
Function FromHex:ULong( hex:String )

	Local value:ULong
	
	For Local i:=0 Until hex.Length
		Local ch:=hex[i]
		If ch>=48 And ch<58
			value=value Shl 4 | (ch-48)
		Else If ch>=65 And ch<71
			value=value Shl 4 | (ch-55)
		Else If ch>=97 And ch<103
			value=value Shl 4 | (ch-87)
		Else
			Exit
		Endif
	Next
	
	Return value

End

#rem monkeydoc Converts an unsigned long value to a string.

@param value Value to convert.

@param base Numeric base for conversion, eg: 2 for binary, 16 for hex etc.

#end
Function ULongToString:String( value:ULong,base:UInt )

	Local str:=""
	
	While value
		Local n:=value Mod base
		If n<10 str=String.FromChar( n+48 )+str Else str=String.FromChar( n+55 )+str
		value/=base
	Wend
	
	Return str

End

#rem monkeydoc Converts a string to an unsigned long value.

@param str String to convert.

@param base Numeric base for conversion, eg: 2 for binary, 16 for hex etc.

#end
Function StringToULong:ULong( str:String,base:UInt )

	Local value:ULong
	
	If base<=10
	
		For Local ch:=Eachin str
			If ch>=48 And ch<48+base value=value*base+(ch-48) Else Exit
		Next
		
		Return value
	Endif

	For Local ch:=Eachin str
		
		If ch>=48 And ch<58
			value=value*base+(ch-48)
		Else If ch>=65 And ch<65+(base-10)
			value=value*base+(ch-55)
		Else If ch>=97 And ch<97+(base-10)
			value=value*base+(ch-87)
		Else
			Exit
		Endif
	Next
	
	Return value
End
