
Namespace std

#Import "bbthread.h"
#Import "bbthread.cpp"

Extern

Class Thread="bbThread"

	Method New( func:Void() )
	
	Method Detach()

	Method Join()
	
	Function Current:Thread()="bbThread::Current"

	Function Sleep( seconds:Double )="bbThread::Sleep"
	
	Function Yield()="bbThread::Yield_"
	
	Function HardwareThreads:Int()="bbThread::HardwareThreads"
	
End
