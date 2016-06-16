
Namespace std.stringio

Using libc

'These will eventually be string extensions, eg: Function String.Load() and Method String.Save()

#rem monkeydoc Loads a utf8 encoded string from a file.

An empty string will be returned if the file could not be opened.

@param path The path of the file.

@return A String containing the contents of the file. 

#end
Function LoadString:String( path:String )

	Local data:=DataBuffer.Load( path )
	If Not data Return ""

	Local str:=String.FromUtf8String( data.Data,data.Length )

	data.Discard()
	
	Return str
End

#rem monkeydoc Saves a string to a file in utf8 encoding.

@param path The path of the file.

@param str The string to save.

@return False if the file could not be opened.

#end
Function SaveString:Bool( str:String,path:String )

	Local data:=New DataBuffer( str.Utf8Length )

	str.ToUtf8String( data.Data,data.Length )

	Local ok:=data.Save( path )

	data.Discard()
	
	Return ok
End

#rem monkeydoc @hidden Use ULongToString
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

#rem monkeydoc @hidden Use StringToULong
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
		Else If ch>=97 And ch<07+(base-10)
			value=value*base+(ch-87)
		Else
			Exit
		Endif
	Next
	
	Return value
End
