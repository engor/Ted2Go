
Namespace std.fiber

#Import "native/fiber.h"
#Import "native/fiber.cpp"

Extern

#rem monkeydoc

Starts a new running fiber.

This is the same as using `CreateFiber` followed by `ResumeFiber`.

@return a new fiber handle.

#end
Function StartFiber:Int( entry:Void() )="bbFiber::StartFiber"

#rem monkeydoc

Creates a new suspended fiber.

Use `ResumeFiber` to start the fiber running.

@return a new fiber handle.

#end
Function CreateFiber:Int( entry:Void() )="bbFiber::CreateFiber"

#rem monkeydoc

Resumes a suspended fiber.

@param fiber a valid fiber handle.

#end
Function ResumeFiber:Void( fiber:Int )="bbFiber::ResumeFiber"

#rem monkeydoc

Terminates a fiber.

@param fiber a valid fiber handle.

#end
Function TerminateFiber:Void( fiber:Int )="bbFiber::CancelFiber"


#rem monkeydoc

Suspends the currently running fiber.

The fiber will remain suspended until `ResumeFiber` or `TerminateFiber` is used.

#end
Function SuspendCurrentFiber:Void()="bbFiber::SuspendCurrentFiber"

#rem monkeydoc

Gets the handle of the currently running fiber.

@return the handle of the currnt fiber.

#end
Function GetCurrentFiber:Int()="bbFiber::GetCurrentFiber"

Public

Class Future<T>

	Field _fiber:Int
	Field _value:T
	
	Method New()
		_fiber=std.fiber.GetCurrentFiber()
	End
	
	Method Set( value:T )
		_value=value
		std.fiber.ResumeFiber( _fiber )
	End
	
	Method Get:T()
		std.fiber.SuspendCurrentFiber()
		Return _value
	End
	
End

Function Await<T>:T( func:T() )

	Local future:=New Future<T>
	
	StartFiber( Lambda()
		future.Set( func() )
	End )
	
	Return future.Get()
End
