
Namespace monkey

Extern

Struct CChar="char"
End

Struct WChar="wchar_t"
End

Struct Utf8Char="unsigned char"
End

Struct CString="bbCString"
End

Struct WString="bbWString"
End

Struct Utf8String="bbUtf8String"
End

Interface INumeric
End

Interface IIntegral Extends INumeric
End

Interface IReal Extends INumeric
End

#rem monkeydoc Primitive bool type
#end
Struct @Bool Implements IIntegral ="bbBool"
End

#rem monkeydoc Primitive byte type
#end
Struct @Byte Implements IIntegral ="bbByte"
End

#rem monkeydoc Primitive unsigned byte type
#end
Struct @UByte Implements IIntegral ="bbUByte"
End

#rem monkeydoc Primitive short type
#end
Struct @Short Implements IIntegral ="bbShort"
End

#rem monkeydoc Primitive unsigned short type
#end
Struct @UShort Implements IIntegral ="bbUShort"
End

#rem monkeydoc Primitive int type
#end
Struct @Int Implements IIntegral ="bbInt"
End

#rem monkeydoc Primitive unsigned int type
#end
Struct @UInt Implements IIntegral ="bbUInt"
End

#rem monkeydoc Primitive long type
#end
Struct @Long Implements IIntegral ="bbLong"
End

#rem monkeydoc Primitive unsigned long type
#end
Struct @ULong Implements IIntegral ="bbULong"
End

#rem monkeydoc Primitive float type
#end
Struct @Float Implements IReal ="bbFloat"
End

#rem monkeydoc Primitive double type
#end
Struct @Double Implements IReal ="bbDouble"
End

#rem monkeydoc Primitive string type
#end
Struct @String ="bbString"

	Property Length:Int()="length"
	
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
	
	Function FromTString:String( data:Void Ptr )="bbString::fromTString"
	
	Function FromUtf8:String( data:Void Ptr,size:Int )="bbString::fromUtf8"
	
End

Struct @Array<T>

	Property Data:T Ptr()="data"
	
	Property Length:Int()="length"
	
	Method Slice:T[]( from:Int )="slice"
	
	Method Slice:T[]( from:Int,term:Int )="slice" 
	
	Method CopyTo( dstArray:T[],srcOffset:Int,dstOffset:Int,count:Int )="copyTo"

End

Class @Object="bbObject"

	Method typeName:CChar Ptr()="typeName"

End

Class @Throwable="bbThrowable"

	Method DebugStack:String[]()="debugStack"
	
End

#rem
Class @RuntimeError Extends @Throwable="bbRuntimeError"

	Method New()
	
	Method New( message:String )
	
	Property Message:String()="message"

End
#end

Function TypeName:String( type:CString )="bbTypeName"
