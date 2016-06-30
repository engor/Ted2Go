
Namespace mojox

Class Console Extends TextView

	Field Finished:Void( exitCode:Int )
	
	Property Running:Bool()

		Return _running
	End

	Property Process:Process()
	
		If _running Return _process
		
		Return Null
	End
	
	Method Start:Bool( cmd:String )
	
		If _running Return False
	
		_process=New Process
		
		_process.Finished=Lambda()
			_procOpen=False
			UpdateRunning()
		End
		
		_process.StdoutReady=Lambda()
		
			Local stdout:=_process.ReadStdout()
			
			If Not stdout
				If _stdout _stdoutBuf.Add( _stdout )
				_stdoutOpen=False
				UpdateRunning()
				Return
			Endif
			
			stdout=_stdout+stdout.Replace( "~r~n","~n" )
			
			Local i0:=0
			Repeat
				Local i:=stdout.Find( "~n",i0 )
				If i=-1
					_stdout=stdout.Slice( i0 )
					Exit
				Endif
				_stdoutBuf.Add( stdout.Slice( i0,i+1 ) )
				i0=i+1
			Forever
			
			If _stdoutWaiting And Not _stdoutBuf.Empty _stdoutWaiting.Set( True )
			
		End
		
		If Not _process.Start( cmd ) Return False
		
		_running=True
		_procOpen=True
		_stdoutOpen=True
		
		_stdout=""
		_stdoutBuf.Clear()
		_stdoutWaiting=Null
		
		Return True
	End
	
	Method ReadStdout:String()
	
		While _stdoutBuf.Empty
		
			If Not _stdoutOpen
				If _procOpen
					_stdoutWaiting=New Future<Bool>
					_stdoutWaiting.Get()
					_stdoutWaiting=Null
				Endif
				Return ""
			Endif
			
			_stdoutWaiting=New Future<Bool>
			_stdoutWaiting.Get()
			_stdoutWaiting=Null
		Wend
		
		Return _stdoutBuf.RemoveFirst()
	End
	
	Method WriteStdin( str:String )
	
		If Not _procOpen Return
	
		_process.WriteStdin( str )
	End
	
	Method Terminate()
	
		If Not _procOpen Return
	
		_process.Terminate()
	End
	
	Method Write( text:String )
	
		ReplaceText( text )
	End
	
	Private
	
	Field _process:Process
	
	Field _running:Bool
	Field _procOpen:Bool
	
	Field _stdoutOpen:Bool
	Field _stdout:String
	Field _stdoutBuf:=New StringList
	Field _stdoutWaiting:Future<Bool>
	
	Method UpdateRunning()
	
		If Not _running Or _procOpen Or _stdoutOpen Return
		
		_running=False
		
		Finished( _process.ExitCode )
		
		If _stdoutWaiting _stdoutWaiting.Set( True )
	End

End
