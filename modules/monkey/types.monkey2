
Namespace monkey.types

Alias Exception:Throwable

Extern

Interface INumeric
End

Interface IIntegral Extends INumeric
End

Interface IReal Extends INumeric
End

#rem monkeydoc Primitive bool type.
#end
Struct @Bool Implements IIntegral ="bbBool"
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
	
	Method Find:Int( str:String,from:Int=0 )="find"
	
	Method FindLast:Int( str:String,from:Int=0 )="findLast"
	
	Method Contains:Bool( str:String )="contains"
	
	Method StartsWith:Bool( str:String )="startsWith"
	
	Method EndsWith:Bool( str:String )="endsWith"
	
	Method Slice:String( from:Int )="slice"
	
	Method Slice:String( from:Int,term:Int )="slice"
	
	Method Left:String( count:Int )="left"
	
	Method Right:String( count:Int )="right"
	
	Method Mid:String( from:Int,count:Int )="mid"
	
	Method ToUpper:String()="toUpper"
	
	Method ToLower:String()="toLower"
	
	Method Capitalize:String()="capitalize"
	
	Method Trim:String()="trim"
	
	Method Replace:String( find:String,replace:String )="replace"
	
	Method Split:String[]( separator:String )="split"
	
	Method Join:String( bits:String[] )="join"
	
	Method ToUtf8:Int( buf:Void Ptr,size:Int )="toUtf8"
	
	Method ToCString:CString()="bbString::toCString"
	
	Function FromChar:String( chr:Int )="bbString::fromChar"
	
	Function FromCString:String( data:Void Ptr )="bbString::fromCString"
	
	Function FromWString:String( data:Void Ptr )="bbString::fromWString"
	
	Function FromUtf8String:String( data:Void Ptr )="bbString::fromUtf8String"
	
	Function FromUtf8:String( data:Void Ptr,size:Int )="bbString::fromUtf8"
	
End

#rem monkeydoc Primtive array type.
#end
Struct @Array<T>

	Property Data:T Ptr()="data"
	
	Property Length:Int()="length"
	
	Method Slice:T[]( from:Int )="slice"
	
	Method Slice:T[]( from:Int,term:Int )="slice" 
	
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

#rem monkeydoc Base class of all exception objects.
#end
Class @Exception Extends Throwable="bbException"

	Method New()
	
	Method New( message:String )

	Property Message:String()="message"

	Property DebugStack:String[]()="debugStack"
	
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

#rem monkeydoc String wrapper type for native utf8 'unsigned char*' strings.

This type should only be used when declaring parameters for extern functions.

#end
Struct Utf8String="bbUtf8String"
End
