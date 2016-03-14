
Namespace monkey

Extern

Class RuntimeError="bbRuntimeError"

	Method New( message:String )
	
	Property Message:String()="message"
	
	Property DebugStack:String[]()="debugStack"
End

Function Assert( condition:Bool )="bbAssert"

Function Assert( condition:Bool,message:String )="bbAssert"

Function DebugAssert( condition:Bool )="bbDebugAssert"

Function DebugAssert( condition:Bool,message:String )="bbDebugAssert"
