
Namespace ted2go


#if __TARGET__<>"emscripten"

#rem monkeydoc The Console class.
#end
Class ConsoleExt Extends TextView

	#rem monkeydoc Invoked when the console finishes executing a process.
	#end
	Field Finished:Void( exitCode:Int )
	
	#rem monkeydoc Creates a new console.
	#end
	Method New()
		Style=GetStyle( "Console" )
		
		ReadOnly=True
	End
	
	#rem monkeydoc True if the process is running.
	#end
	Property Running:Bool()

		Return _running
	End
	
	#rem monkeydoc The process.
	#end
	Property Process:Process()

		Return _process
	End
	
	#rem monkeydoc Process exit code.
	
	If the process is still running, -1 is returned.
	
	#end
	Property ExitCode:Int()

		If _process And Not _procOpen return _process.ExitCode

		Return -1
	End
	
	#rem monkeydoc Runs a process.
	
	Returns true if the process was successfully started, else false.
	
	Process stdout is written to the console while the process is running.
	
	This method waits for the process to complete, so should always be called on a fiber.
	
	#end
	Method Run:Bool( cmd:String )
	
		If Not Start( cmd )
			Alert( "Failed to start process '"+cmd+"'" )
			Return False
		Endif
		
		Repeat
		
			Local stdout:=ReadStdout()
			If Not stdout Exit
			
			Write( stdout )
		Forever
		
		Return True
	End

	#rem monkeydoc Starts a process.
	
	Returns true if the process was successfully started, else false.
	
	#end	
	Method Start:Bool( cmd:String )
	
		If _running Return False
		
		Local process:=New Process
	
		process.Finished=Lambda()
			_procOpen=False
			UpdateRunning()
		End
		
		process.StdoutReady=Lambda()
		
			Local stdout:=process.ReadStdout()
			
'			Print "**** CONSOLE STDOUT *****"
'			Print stdout
'			Print "***** END STDOUT *****"
			
			If Not stdout
				If _stdout _stdoutBuf.Add( _stdout )
				_stdoutOpen=False
				UpdateRunning()
				Return
			Endif
			
			stdout=_stdout+(stdout.Replace( "~r~n","~n" ).Replace( "~r","~n" ))
			
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
		
		If Not process.Start( cmd ) Return False
		
		_process=process
		
		_running=True
		_procOpen=True
		_stdoutOpen=True

		_stdout=""
		_stdoutBuf.Clear()
		_stdoutWaiting=Null
		
		Return True
	End
	
	#rem monkeydoc Reads process stdout.
	
	If an empty string is returned, the process has finished.
	
	This method may have to wait for stdout to become available, so should always be called on a fiber.
	
	#end
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
	
	#rem monkeydoc Writes to process stdin.
	#end
	Method WriteStdin( str:String )
	
		If Not _procOpen Return
	
		_process.WriteStdin( str )
	End
	
	#rem monkeydoc Terminates the process.
	#end
	Method Terminate()

		If Not _procOpen Return
		
		_process.Terminate()
	End
	
	#rem monkeydoc Writes text to the console.
	#end
	Method Write( text:String )
	
		_lines.Add( text )
		AddFiltered( text )
	End
	
	Method SetFilter( value:String )
	
		If value = _filter Return
		
		_filter=value
		Clear()
		For Local s:=Eachin _lines
			AddFiltered( s )
		End
		
		SelectText( Text.Length,Text.Length )
	End
	
	Method ClearAll()
		
		Clear()
		_lines.Clear()
	End
	
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		If CanCopy And (event.Key = Key.C Or event.Key = Key.Insert) And event.Type = EventType.KeyDown And event.Modifiers & Modifier.Control
		
			Copy()
			Return
		Endif
		
		If event.Type = EventType.KeyDown
			
			If event.Key = Key.PageUp
			
				Scroll-=New Vec2i( 0,VisibleRect.Height )
				
			Else If event.Key = Key.PageDown
			
				Scroll+=New Vec2i( 0,VisibleRect.Height )
				
			Else If event.Modifiers & Modifier.Control
				
				If event.Key = Key.Home
					SelectText( 0,0 )
				Else If event.Key = Key.KeyEnd
					SelectText( Text.Length,Text.Length )
				Endif
				
			Endif
		Endif
	
		'Super.OnKeyEvent( event )
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		'select whole line by double click
		If event.Type = EventType.MouseDoubleClick
			Local line:=Document.FindLine( Cursor )
			SelectText( Document.StartOfLine( line ),Document.EndOfLine( line ) )
			Return
		Endif
		
		Super.OnContentMouseEvent( event )
	End
	
	
	Private
	
	Field _lines:=New StringStack
	Field _filter:=""
	
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

	Method AddFiltered( text:String )
		
		If Not _filter Or text.Find( _filter) <> -1
			Local cur:=Cursor,anc:=Anchor
			Local sc:=Scroll
			Local maxScroll:=LineRect(Document.NumLines-1).Bottom-VisibleRect.Height
			Local atBottom:=Scroll.y>=maxScroll And cur=anc
			AppendText( text )
			SelectText( Text.Length,Text.Length )
			If Not atBottom
				SelectText( anc,cur )
				Scroll=sc 'restore
			Endif
			
		Endif
	End
	
End

#Endif
