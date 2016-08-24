
Namespace std.fiber

#if __TARGET__<>"emscripten"

#import "fcontext"

#import "native/fcontext.cpp"
#Import "native/fiber.cpp"
#Import "native/fiber.h"

Extern Private

Function StartFiber:Int( entry:Void() )="bbFiber::startFiber"

Function CreateFiber:Int( entry:Void() )="bbFiber::createFiber"

Function ResumeFiber:Void( fiber:Int )="bbFiber::resumeFiber"

Function TerminateFiber:Void( fiber:Int )="bbFiber::terminateFiber"

Function SuspendCurrentFiber:Void()="bbFiber::suspendCurrentFiber"

Function GetCurrentFiber:Int()="bbFiber::getCurrentFiber"

Public

#rem monkeydoc Fibers provides support for cooperative multitasking.

A Fiber is a lightweight 'thread of execution' that can be used to achieve a form of cooperative multitasking.

A fiber can be in one of 4 states:

* Running. There is only ever one fiber in the running state at a time. This is the fiber returned by [[Current]].

* Suspended. A fiber is in the suspended state if it has called [[Suspend]]. A suspended fiber can only be returned to the running state
by some other fiber calling [[Resume]] on it.

* Paused. A fiber is in the paused state after it has called [[Resume]] on another fiber and that fiber has resumed running. A paused
fiber will continue running when the fiber it resumed calls [[Suspend]] or exits normally. A fiber is also paused after creating a new 
fiber, ie: creating a new fiber also implicty resumes the new fiber.

* Terminated. The fiber has either returned from it's entry function, or has been explicitly terminated via a call to [[Terminate]].

#end
Struct Fiber

	#rem monkeydoc Creates a new fiber.
	
	Creates a new fiber and starts it running.
	
	#end
	Method New( entry:Void() )
		_fiber=StartFiber( entry )
	End
	
	#rem monkeydoc @hidden
	#end
	Property Debug:String()
		Return _fiber
	End
	
	#rem monkeydoc Resumes a suspended fiber.
	#end	
	Method Resume()
		ResumeFiber( _fiber )
	End
	
	#rem monkeydoc Terminates a fiber.
	#end
	Method Terminate()
		TerminateFiber( _fiber )
	End
	
	#rem monkeydoc Suspends the current fiber.
	#end
	Function Suspend()
		SuspendCurrentFiber()
	End
	
	#rem monkeydoc Gets the main fiber.
	
	Suspending the main fiber will result in a runtime error.
	
	#end
	Function Main:Fiber()
		Return _main
	End
	
	#rem monkeydoc Gets the currently running fiber.
	#end
	Function Current:Fiber()
		Return New Fiber( GetCurrentFiber() )
	End
	
	#rem monkeydoc @hidden - not really needed?
	#end
	Function CreateSuspended:Fiber( entry:Void() )
		Return New Fiber( CreateFiber( entry ) )
	End
	
	Private
	
	Field _fiber:Int
	
	Global _main:=New Fiber( 0 )
	
	Method New( fiber:Int )
		_fiber=fiber
	End
	
End

#endif
