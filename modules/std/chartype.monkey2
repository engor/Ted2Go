
Namespace std.chartype

#rem monkeydoc Checks if a character is whitespace.

@return True if `char` is 32 or less.

#end
Function IsSpace:Bool( ch:Int )
	Return ch<=32
End

#rem monkeydoc Checks if a character is a decimal digit.

@return True if `ch` is '0'-'9'.

#end
Function IsDigit:Bool( ch:Int )
	Return (ch>=48 And ch<58)
End

#rem monkeydoc Checks if a character is alphabetic.

@return True if `ch` is 'a'-'z' or 'A'-'Z'.

#end
Function IsAlpha:Bool( ch:Int )
	Return (ch>=65 And ch<65+26) Or (ch>=97 And ch<97+26)
End

#rem monkeydoc Checks if a character is an identifier.

@return True if `ch` is '0'-'9', 'a'-'z', 'A'-'Z' or '_'.

#end
Function IsIdent:Bool( ch:Int )
	Return (ch>=65 And ch<65+26) Or (ch>=97 And ch<97+26) Or (ch>=48 And ch<58) Or ch=95
End

#rem monkeydoc Checks if a character is a hexadecimal digit.

@return True if `ch` is '0'-'9', 'a'-'f', or 'A'-'F'.

#end
Function IsHexDigit:Bool( ch:Int )
	Return (ch>=48 And ch<58) Or (ch>=65 And ch<71) Or (ch>=97 And ch<103)
End
