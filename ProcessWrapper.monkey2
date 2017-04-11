
Namespace ted2go


Class ProcessWrapper
	
	Method New( command:String,callback:Void( output:String,exitCode:Int ) )
		
		_command=command
		_callback=callback
	End
	
	Method Run()
		
		If Not Start( _command )
			Alert( "Failed to start process '"+_command+"'" )
			Return
		Endif
	End
	
	Method Stop()
	
		If _running Then _process.Terminate()
	End
	
	
	Private
	
	Field _process:Process
	Field _command:String
	Field _output:String
	Field _callback:Void( output:String,exitCode:Int )
	Field _running:Bool
	
	Method Start:Bool( cmd:String )
		
		If _running Return False
		
		Local process:=New Process
	
		' FINISH
		process.Finished=Lambda()
			Print "proc. finished"
			OnFinished()
		End
		
		' STDOUT
		process.StdoutReady=Lambda()
			
			New Fiber( Lambda()
			
				Local stdout:=process.ReadStdout()
				
				If Not stdout
					Print "proc. have no stdout"
					OnFinished()
					Return
				Endif
				
				_output+=stdout.Replace( "~r~n","~n" ).Replace( "~r","~n" )
			End)
			
		End
		
		If Not process.Start( cmd ) Return False
		
		_process=process
		_running=True
		
		Return True
	End
	
	
	
	Method OnFinished()
	
		If Not _running Return
	
		_running=False
	
		_callback( _output,_process.ExitCode )
		
		_output=""
	End
	
End
