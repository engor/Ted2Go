
Namespace mojo.timer

#Import "native/timer.cpp"
#Import "native/timer.h"

Extern

Class Timer="bbTimer"

	#rem monkeydoc Creates a new timer.
	#end
	Method New( fps:Int,fired:Void() )

	#rem monkeydoc Suspended state.
	#end
	Property Suspended:Bool()="suspended"
	Setter( suspended:Bool )="setSuspended"

	#rem monkeydoc Cancels the timer.

	Once cancelled, a timer can no longer be used.
	
	#end
	Method Cancel()="cancel"

End
