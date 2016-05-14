
Namespace mojo.app

#Import "native/process.h"
#Import "native/process.cpp"

Extern

Class Process="bbProcess"

	Field Finished:Void()="finished"
	
	Field StdoutReady:Void()="stdoutReady"
	
	Field StderrReady:Void()="stderrReady"

	Property ExitCode:Int()="exitCode"
	
	Property StdoutAvail:Int()="stdoutAvail"

	Property StderrAvail:Int()="stderrAvail"
	
	Method Start:Bool( cmd:String )="start"
	
	Method ReadStdout:String()="readStdout"
	
	Method ReadStdout:Int( buf:Void Ptr,count:Int )="readStdout"

	Method ReadStderr:String()="readStderr"
	
	Method ReadStderr:Int( buf:Void Ptr,count:Int )="readStderr"

	Method WriteStdin( str:String )="writeStdin"
	
	Method SendBreak()="sendBreak"
	
	Method Terminate:Void()="terminate"	
End
