
Namespace monkey.debug

Extern

#rem monkeydoc @hidden
#end
Function DebugStop()="bbDB::stop"

#rem monkeydoc @hidden
#end
Function RuntimeError( message:String )="bbDB::error"

#rem monkeydoc Generates a runtime error if a boolean expression is false.

@param condition The boolean condition to check.

@param message Runtime error message to generate.

#end
Function Assert( condition:Bool )="bbAssert"

Function Assert( condition:Bool,message:String )="bbAssert"

#rem monkeydoc Generates a runtime error if a boolean expression is false (Debug builds only).

This function does not execute at all in release builds, so make sure that `condition` doesn't inadvertantly execute
any critical code.

@param condition The boolean condition to check.

@param message Runtime error message to generate.

#end
Function DebugAssert( condition:Bool )="bbDebugAssert"

Function DebugAssert( condition:Bool,message:String )="bbDebugAssert"

#rem monkeydoc Gets the current stack state (Debug builds only).

In release mode, an empty array is returned.

@example
Namespace test

Function Test2()
	Print "~n".Join( GetDebugStack() )
End

Function Test()
	Test2()
End

Function Main()
	Test()
End
@end

@return A string array reprenting the current stack state.

#end
Function GetDebugStack:String[]()="bbDB::stack"
