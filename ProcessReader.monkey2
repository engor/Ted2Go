
Namespace ted2go


#rem monkeydoc The ProcessReader class.

Allow us to read output from process.
We can reuse this class with any commands.
Each command starts new process.
You should to wait until work is finished - if you run while process already running then nothing happen.

There are 2 usage scenarios: RunAsync and Run.

With RunAsync we get output by PortionRead and Finished events.
This is not blocked method.

With Run we get output as result of this call.
This is blocked method.

Both methods are using Fiber to waiting process finished.
#end
Class ProcessReader
	
	#rem monkeydoc Invoked when a process finishes execution.
	#end
	Field Finished:Void( output:String,exitCode:Int )
	
	#rem monkeydoc Invoked when read portion of output from process.
	#end
	Field PortionRead:Void( output:String )
	
	#rem monkeydoc Invoked when a process finishes execution AND exitCode <> 0.
	#end
	Field Error:Void( exitCode:Int )
	
	#rem monkeydoc Obtain a reader instance.
	#end
	Function Obtain:ProcessReader()
	
		Local r:ProcessReader
		If _recycled.Empty
			r=New ProcessReader
			Print "create new reader"
		Else
			r=_recycled[0]
			_recycled.Remove( r )
			Print "use existing reader"
		Endif
		r.Finished=Null
		r.PortionRead=Null
		r.Error=Null
		_items.Add( r )
		Return r
	End
	
	#rem monkeydoc Recycle a reader instance. So we can get it again using Obtain.
	#end
	Function Recycle( r:ProcessReader )
	
		_items.Remove( r )
		r.Stop()
		_recycled.Add( r )
	End
	
	#rem monkeydoc Stops all obtained readers if them are running and not recycled.
	#end
	Function StopAll()
	
		For Local r:=Eachin _items
			r.Stop()
		Next
	End
	
	
	#rem monkeydoc Async reading of process. You should to subscribe on (at least) Finished event to get result.
	This method can be used without creation of new Fiber.
	#end
	Method RunAsync( command:String )
		
		If _running Return
		
		New Fiber( Lambda()
		
			RunInternal( command )
		End )
	End
	
	#rem monkeydoc Sync reading of process.
	This method must be used with creation of new Fiber, because it uses Future to waiting for process finished.
	Return full output of a process.
	#end
	Method Run:String( command:String )
	
		If _running Return ""
	
		Return RunInternal( command )
	End
	
	#rem monkeydoc Terminate process execution.
	#end
	Method Stop()
	
		If _running Then _process.Terminate()
	End
	
	#rem monkeydoc Is reading currently in progress.
	#end
	Method IsRunning:Bool()
	
		Return _running
	End
	
	Protected
	
	Method New()
	End
	
	Private
	
	Field _process:Process
	Field _output:String
	Field _running:Bool
	Field _stdoutWaiting:Future<Bool>
	Field _stdoutOpen:Bool,_procOpen:Bool
	Global _items:=New Stack<ProcessReader>
	Global _recycled:=New Stack<ProcessReader>
	
	Method RunInternal:String( cmd:String )
	
		If Not Start( cmd )
			Print "Failed to start process '"+cmd+"'"
			Return ""
		Endif
		
		' waiting for the end
		_stdoutWaiting=New Future<Bool>
		_stdoutWaiting.Get()
		_stdoutWaiting=Null
		
		Return _output
	End
	
	Method Start:Bool( cmd:String )
		
		If _running Return False
		
		Local process:=New Process
	
		process.Finished=Lambda()
			
			_procOpen=False
			UpdateRunning()
		End
		
		process.StdoutReady=Lambda()
		
			Local stdout:=process.ReadStdout()
			
			If stdout
				stdout=stdout.Replace( "~r~n","~n" ).Replace( "~r","~n" )
				_output+=stdout
				PortionRead( stdout )
			Else
				_stdoutOpen=False
				UpdateRunning()
			Endif
		End
		
		If Not process.Start( cmd ) Return False
		
		_process=process
		
		_running=True
		_procOpen=True
		_stdoutOpen=True
		_output=""
		
		Return True
	End
	
	Method UpdateRunning()
	
		If Not _running Or _procOpen Or _stdoutOpen Return
	
		_running=False
		
		If _stdoutWaiting Then _stdoutWaiting.Set( True )
		
		Local code:=_process.ExitCode
		
		Finished( _output,code )
		If code<>0 Then Error( code )
	End
	
End


Private

' Extends ProcessReader - to get access to protected New()
Class ProcessBridge Extends ProcessReader

	Function Create:ProcessReader()
		
		Return New ProcessReader
	End
End
