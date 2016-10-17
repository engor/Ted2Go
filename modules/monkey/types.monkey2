
Namespace monkey.types

Extern

#rem monkeydoc Implemented by numeric types.
#end
Interface INumeric
End

#rem monkeydoc Implemented by integral numeric types.
#end
Interface IIntegral Extends INumeric
End

#rem monkeydoc Implemented by real numeric types.
#end
Interface IReal Extends INumeric
End

#rem monkeydoc Primitive bool type.
#end
Struct @Bool ="bbBool"
End

#rem monkeydoc Primitive 8 bit byte type.
#end
Struct @Byte Implements IIntegral ="bbByte"
End

#rem monkeydoc Primitive 8 bit unsigned byte type.
#end
Struct @UByte Implements IIntegral ="bbUByte"
End

#rem monkeydoc Primitive 16 bit short type.
#end
Struct @Short Implements IIntegral ="bbShort"
End

#rem monkeydoc Primitive 16 bit unsigned short type.
#end
Struct @UShort Implements IIntegral ="bbUShort"
End

#rem monkeydoc Primitive 32 bit int type.
#end
Struct @Int Implements IIntegral ="bbInt"
End

#rem monkeydoc Primitive 32 bit unsigned int type.
#end
Struct @UInt Implements IIntegral ="bbUInt"
End

#rem monkeydoc Primitive 64 bit long type.
#end
Struct @Long Implements IIntegral ="bbLong"
End

#rem monkeydoc Primitive 64 bit unsigned long type.
#end
Struct @ULong Implements IIntegral ="bbULong"
End

#rem monkeydoc Primitive 32 bit float type.
#end
Struct @Float Implements IReal ="bbFloat"
End

#rem monkeydoc Primitive 64 bit double type.
#end
Struct @Double Implements IReal ="bbDouble"
End

#rem monkeydoc Primitive string type
#end
Struct @String ="bbString"

	#rem monkeydoc Gets the length of the string.
	
	@return The number of characters in the string.
	
	#end
	Property Length:Int()="length"
	
	
	#rem monkeydoc Gets the utf8 length of the string.
	
	@return The size of the buffer required to store a utf8 representation of the string.
	
	#end
	Property Utf8Length:Int()="utf8Length"

	
	#rem monkeydoc Gets the CString length of the string.
	
	@return The size of the buffer required to store a cstring representation of the string.
	
	#end
	Property CStringLength:Int()="utf8Length"

	
	#rem monkeydoc Finds a substring in the string.
	
	If `substr` is not found, -1 is returned.
	
	@param substr The substring to search for.
	
	@param from The start index for the search.
	
	@return The index of the first occurance of `substr` in the string, or -1 if `substr` was not found.
	
	#end
	Method Find:Int( substr:String,from:Int=0 )="find"
	
	#rem monkeydoc Finds the last occurance of a substring in the string.
	
	If `substr` is not found, -1 is returned.
	
	@param substr The substring to search for.
	
	@param from The start index for the search.
	
	@return The index of the last occurance of `substr` in the string, or -1 if `substr` was not found.
	
	#end
	Method FindLast:Int( substr:String,from:Int=0 )="findLast"
	
	#rem monkeydoc Checks if the string contains a substring.
	
	@param substr The substring to check for.
	
	@return True if the string contains `substr`.
	
	#end
	Method Contains:Bool( substr:String )="contains"
	
	#rem monkeydoc Check if the string starts with another string.
	
	@param substr The string to check for.
	
	@return True if the string starts with `substr`.
	
	#end
	Method StartsWith:Bool( str:String )="startsWith"
	
	#rem monkeydoc Check if the string ends with another string.
	
	@param substr The string to check for.
	
	@return True if the string ends with `substr`.
	
	#end
	Method EndsWith:Bool( str:String )="endsWith"
	
	#rem monkeydoc Extracts a substring from the string.
	
	Returns a string consisting of all characters from `from` until (but not including) `tail`, or until the end of the string if `tail` 
	is not specified.
	
	If either `from` or `tail` is negative, it represents an offset from the end of the string.
	
	@param `from` The starting index.
	
	@param `tail` The ending index.
	
	@return A substring.
	
	#end
	Method Slice:String( from:Int )="slice"
	
	Method Slice:String( from:Int,tail:Int )="slice"
	
	#rem monkeydoc Gets a substring from the start of the string.
	
	Returns a string consisting of the first `count` characters of this string.
	
	If `count` is less than or equal to 0, an empty string is returned.
	
	If `count` is greater than the length of this string, this string is returned.
	
	@param count The number of characters to return.

	@return A string consisting of the first `count` characters of this string.
	
	#end
	Method Left:String( count:Int )="left"
	
	#rem monkeydoc Gets a substring from the end of the string.

	Returns a string consisting of the last `count` characters of this string.

	If `count` is less than or equal to 0, an empty string is returned.
	
	If `count` is greater than the length of this string, this string is returned.
	
	@param count The number of characters to return.

	@return A string consisting of the last `count` characters of this string.
	
	#end
	Method Right:String( count:Int )="right"
	
	#rem monkeydoc Gets a substring from the middle of the string.
	
	Returns a string consisting of `count` characters starting from index `from`.
	
	If `count` is less than or equal to 0, an empty string is returned.
	
	If `from`+`count` is greater than the length of the string, the returned string is truncated.

	@param from The index of the first character to return.

	@param count The number of characters to return.

	@return A string consisting of `count` characters starting from index `from`.
	
	#end
	Method Mid:String( from:Int,count:Int )="mid"
	
	#rem monkeydoc Convert the string to uppercase.
	
	Return the string converted to uppercase.
	
	@return The string converted to uppercase.
	
	#end
	Method ToUpper:String()="toUpper"
	
	#rem monkeydoc Convert the string to lowercase.
	
	Returns the string converted to lowercase.
	
	@return The string converted to lowercase.
	
	#end
	Method ToLower:String()="toLower"

	#rem monkeydoc Capitalizes the string.
	
	Returns the string with the first character converted to uppercase and the remaining characters unmodified.

	@return The string with the first character converted to uppercase and the remaining characters unmodified.
	
	#end	
	Method Capitalize:String()="capitalize"
	
	#rem monkeydoc Trim whitespace from a string.
	
	Returns the string with leading and trailing whitespace removed.
	
	@return The string with leading and trailing whitespace removed.
	
	#end
	Method Trim:String()="trim"
	
	#rem monkeydoc Trim whitespace from the start a string.
	
	Returns the string with any leading whitespace removed.
	
	@return The string with any leading whitespace removed.
	
	#end
	Method TrimStart:String()="trimStart"
	
	#rem monkeydoc Trim whitespace from the end of a string.
	
	Returns the string with any trailing whitespace removed.

	@return The string with any trailing whitespace removed.
	
	#end
	Method TrimEnd:String()="trimEnd"
	
	#rem monkeydoc Duplicates a string.
	
	Returns the string duplicated `count` times.
	
	@return The string duplicated `count` times.
	
	#end
	Method Dup:String( count:Int )="dup"
	
	#rem monkeydoc Replace all occurances of a substring with another string.

	Returns the string with all occurances of `find` replaced with `replace`.
	
	@param find The string to search for.
	
	@param replace The string to replace with.
	
	@return The string with all occurances of `find` replaced with `replace`.
	
	#end
	Method Replace:String( find:String,replace:String )="replace"
	
	#rem monkeydoc Splits this string.
	
	Splits this string into an array of strings.
	
	@param separator Separator to use for splitting.
	
	@return An array of strings.
	
	#end
	Method Split:String[]( separator:String )="split"
	
	#rem monkeydoc Joins an array of strings.
	
	Joins an array of strings, inserting this string between elements.
	
	@param bits The strings to join.

	@return The joined string.	
	
	#end
	Method Join:String( bits:String[] )="join"
	

	#rem monkeydoc Converts the string to a CString.
	
	If there is enough room in the memory buffer, a null terminating '0' is appended to the CString.
	
	@param buf Memory buffer to write the CString to.
	
	@param bufSize Size of the memory buffer in bytes.
	
	#end
	Method ToCString( buf:Void Ptr,bufSize:Int )="toCString"


	#rem monkeydoc Converts the string to a WString.
	
	If there is enough room in the memory buffer, a null terminating '0' is appended to the WString.
	
	@param buf Memory buffer to write the WString to.
	
	@param bufSize Size of the memory buffer in bytes.
	
	#end
	Method ToWString( buf:Void Ptr,bufSize:Int )="toWString"
	

	#rem monkeydoc Creates a string containing a single character.
	
	@param chr The character.
	
	#end
	Function FromChar:String( chr:Int )="bbString::fromChar"
	
	
	#rem monkeydoc Creates a string from a CString.
	
	If `bufSize` is specified, the CString may contain null characters which will be included in the string.
	
	If `bufsize` is not specified, the CString must be correctly null terminated or Bad Things Will Happen.
	
	@param buf The memory buffer containing the CString.
	
	@param bufSize The size of the memory buffer in bytes.
	
	#end	
	Function FromCString:String( buf:Void Ptr,bufSize:Int )="bbString::fromCString"

	Function FromCString:String( buf:Void Ptr )="bbString::fromCString"

	
	#rem monkeydoc Creates a string from a null terminated WString.
	
	If `bufSize` is specified, the WString may contain null characters which will be included in the string.
	
	If `bufsize` is not specified, the WString must be correctly null terminated or Bad Things Will Happen.
	
	@param buf The memory buffer containing the WString.
	
	@param bufSize The size of the memory buffer in bytes.
	
	#end	
	Function FromWString:String( buf:Void Ptr,bufSize:Int )="bbString::fromWString"
	
	Function FromWString:String( buf:Void Ptr )="bbString::fromWString"
	
End

#rem monkeydoc Primtive array type.

This is a 'pseduo type' extended by all array types.

#end
Struct @Array<T>

	#rem monkeydoc The raw memory used by the array.
	
	#end
	Property Data:T Ptr()="data"
	
	#rem monkeydoc The length of the array.
	
	In the case of multi-dimensional arrays, the length of the array is the product of the sizes of all dimensions.
	
	#end
	Property Length:Int()="length"
	
	#rem monkeydoc Extracts a subarray from the array.
	
	Returns an array consisting of all elements from `from` until (but not including) `tail`, or until the end of the string if `tail` is not specified.
	
	If either `from` or `tail` is negative, it represents an offset from the end of the array.
	
	@param `from` The starting index.
	
	@param `tail` The ending index.
	
	@return A subarray.
	
	#end
	Method Slice:T[]( from:Int )="slice"
	
	Method Slice:T[]( from:Int,term:Int )="slice" 
	
	
	#rem monkeydoc Resizes an array.
	
	Returns a copy of the array resized to length `newLength`.
	
	Note that this method does not modify this array in any way.
	
	@param newLength The length of the new array.
	
	@return A new array.
	
	#end
	Method Resize:T[]( newLength:Int )="resize"
	
	#rem monkeydoc Gets the size of a single array dimension.
	
	Returns The size of the array in the given dimension.
	
	@param dimensions The dimension.
	
	@return The size of the array in the given dimension.
	
	#end
	Method GetSize:Int( dimension:Int )="size"
	
	#rem monkeydoc Copies a range of elements from this array to another.
	
	In debug mode, a runtime error will occur if the copy is outside the range of the array.
	
	@param dstArray destination of the copy.
	
	@param srcOffset First element to copy from this array.
	
	@param dstOffset First element to copy to in destination array.
	
	@param count Number of elements to copy.
	
	#end
	Method CopyTo( dstArray:T[],srcOffset:Int,dstOffset:Int,count:Int )="copyTo"

End

#rem monkeydoc Base class of all objects.
#end
Class @Object="bbObject"

	#rem monkeydoc @hidden
	#end
	Method typeName:Void Ptr()="typeName"

End

#rem monkeydoc Base class of all throwable objects.

#end
Class @Throwable="bbThrowable"

End

#rem monkeydoc @hidden
#end
Function TypeName:String( type:CString )="bbTypeName"

#rem monkeydoc String wrapper type for native 'char *' strings.

This type should only be used when declaring parameters for extern functions.

#end
Struct CString="bbCString"
End

#rem monkeydoc String wrapper type for native 'wchar_t *' strings.

This type should only be used when declaring parameters for extern functions.

#end
Struct WString="bbWString"
End
