
Namespace std.stringio

Using libc

'These will eventually be string extensions, eg: Function String.Load() and Method String.Save()

#rem monkeydoc Load a utf8 encoded string from a file.

An empty string will be returned if the file could not be opened.

@param path The path of the file.

@return A String containing the contents of the file. 

#end
Function LoadString:String( path:String )

	Local data:=DataBuffer.Load( path )
	If Not data Return ""

	Local str:=String.FromUtf8( data.Data,data.Length )

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

	str.ToUtf8( data.Data,data.Length )

	Local ok:=data.Save( path )

	data.Discard()
	
	Return ok
End

#rem monkeydoc Converts a ulong value to a hexadecimal string.

@param value The value to convert.

@return The hexadecimal representation of `value`.

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

