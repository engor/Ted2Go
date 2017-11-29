
Namespace ted2go


Class WindowActions

	Field nextTab:Action
	Field prevTab:Action
	Field zoomIn:Action
	Field zoomOut:Action
	Field zoomDefault:Action
	Field themes:Action
	Field fullscreenWindow:Action
	Field fullscreenEditor:Action
	
	Method New( docs:DocumentManager )
		
		nextTab=docs.nextDocument
		prevTab=docs.prevDocument
		
		fullscreenWindow=New Action( "Fullscreen window" )
#If __TARGET__="macos"
		fullscreenWindow.HotKey=Key.F
		fullscreenWindow.HotKeyModifiers=Modifier.Menu|Modifier.Control
#Else
		fullscreenWindow.HotKey=Key.F11
#Endif
		fullscreenWindow.Triggered=Lambda()
			MainWindow.SwapFullscreenWindow()
		End
		
		fullscreenEditor=New Action( "Fullscreen editor" )
#If __TARGET__="macos"
		fullscreenEditor.HotKey=Key.F
		fullscreenEditor.HotKeyModifiers=Modifier.Menu|Modifier.Control|Modifier.Shift
#Else
		fullscreenEditor.HotKey=Key.F11
		fullscreenEditor.HotKeyModifiers=Modifier.Shift
#Endif
		fullscreenEditor.Triggered=Lambda()
			MainWindow.SwapFullscreenEditor()
		End
		
		zoomIn=New Action( "Zoom in" )
		zoomIn.Triggered=Lambda()
			
			Local sc:=App.Theme.Scale.x
			If sc>=4 Return
			sc+=.125
			App.Theme.Scale=New Vec2f( sc )
		End
		
		zoomOut=New Action( "Zoom out" )
		zoomOut.Triggered=Lambda()
			
			Local sc:=App.Theme.Scale.x
			If sc<=.5 Return
			sc-=.125
			App.Theme.Scale=New Vec2f( sc )
		End
		
		zoomDefault=New Action( "Reset zoom" )
		zoomDefault.Triggered=Lambda()
		
			App.Theme.Scale=New Vec2f( 1 )
		End
		
	End
	
End
