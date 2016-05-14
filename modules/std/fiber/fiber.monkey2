
Namespace std.fiber

#Import "native/fiber.cpp"
#Import "native/fiber.h"

Extern Private

Function StartFiber:Int( entry:Void() )="bbFiber::StartFiber"

Function CreateFiber:Int( entry:Void() )="bbFiber::CreateFiber"

Function ResumeFiber:Void( fiber:Int )="bbFiber::ResumeFiber"

Function TerminateFiber:Void( fiber:Int )="bbFiber::TerminateFiber"

Function SuspendCurrentFiber:Void()="bbFiber::SuspendCurrentFiber"

Function GetCurrentFiber:Int()="bbFiber::GetCurrentFiber"

Public

Struct Fiber

	Method New( entry:Void() )
		_fiber=StartFiber( entry )
	End
	
	Method Resume()
		ResumeFiber( _fiber )
	End
	
	Method Terminate()
		TerminateFiber( _fiber )
	End
	
	Function Suspend()
		SuspendCurrentFiber()
	End
	
	Function Current:Fiber()
		Return New Fiber( GetCurrentFiber() )
	End
	
	Function CreateSuspended:Fiber( entry:Void() )
		Return New Fiber( CreateFiber( entry ) )
	End

	Private
	
	Field _fiber:Int
	
	Method New( fiber:Int )
		_fiber=fiber
	End
	
End
