
Namespace monkey.debug

Extern

#rem monkeydoc Stops the app and activates the debugger (debug builds only).

Stops the app, causing the debugger (if available) to activate. The app will then wait for further instructions from the
debugger (step, continue, end etc).

The debugger is only available in debug builds, and when running an app from the Ted2 IDE.

#end
Function DebugStop()="bbDB::stop"

#rem monkeydoc Generates a non-recoverable runtime error.

Halts the program with a non-recoverable runtime error.

@param message Runtime error message to generate.

#end
Function RuntimeError( message:String )="bbDB::error"

#rem monkeydoc Generates a runtime error if a boolean expression is false.

@param condition The boolean condition to check.

@param message Runtime error message to generate.

#end
Function Assert( condition:Bool,message:String="Assert failed" )="bbAssert"

#rem monkeydoc Generates a runtime error if a boolean expression is false (debug builds only).

This function does not execute at all in release builds, so make sure that `condition` doesn't inadvertantly execute
any critical code.

@param condition The boolean condition to check.

@param message Runtime error message to generate.

#end
Function DebugAssert( condition:Bool,message:String="Debug assert failed" )="bbDebugAssert"

#rem monkeydoc Gets the current stack state (debug builds only).

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
