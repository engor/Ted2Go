
Namespace ted2go


Class ProcessReader
	
	Field Finished:Void( output:String,exitCode:Int )
	Field PortionRead:Void( output:String )
	
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
		_items.Add( r )
		Return r
	End
	
	Function Recycle( r:ProcessReader )
	
		_items.Remove( r )
		r.Stop()
		_recycled.Add( r )
	End
	
	Function StopAll()
	
		For Local r:=Eachin _items
			r.Stop()
		Next
	End
	
	
	Method Run( command:String )
		
		If _running Return
		
		New Fiber( Lambda()
		
			RunInternal( command )
		End )
	End
	
	Method RunSync:String( command:String )
	
		If _running Return ""
	
		Return RunInternal( command )
	End
	
	Method Stop()
	
		If _running Then _process.Terminate()
	End
	
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
		
		Finished( _output,_process.ExitCode )
		
		If _stdoutWaiting _stdoutWaiting.Set( True )
	End
	
End


Private

' Extends ProcessReader - to get access to protected New()
Class ProcessBridge Extends ProcessReader

	Function Create:ProcessReader()
		
		Return New ProcessReader
	End
End
