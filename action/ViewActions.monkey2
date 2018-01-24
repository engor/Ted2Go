
Namespace ted2go


Class ViewActions
	
	Field _build:Action
	Field _output:Action
	Field _docs:Action
	Field _find:Action
	Field _chat:Action
	Field _project:Action
	Field _debug:Action
	Field _source:Action
	
	Global tabs:TabViewExt[]
	
	Method New( _tabs:TabViewExt[])
		
		tabs=_tabs
	
		_build=New Action( "Build" )
		_build.HotKey=Key.Key1
		_build.HotKeyModifiers=Modifier.Alt
		_build.Triggered=Lambda()
			SwitchView( "Build" )
		End
		
		_output=New Action( "Output" )
		_output.HotKey=Key.Key2
		_output.HotKeyModifiers=Modifier.Alt
		_output.Triggered=Lambda()
			SwitchView( "Output" )
		End
		
		_docs=New Action( "Docs" )
		_docs.HotKey=Key.Key3
		_docs.HotKeyModifiers=Modifier.Alt
		_docs.Triggered=Lambda()
			SwitchView( "Docs" )
		End
		
		_find=New Action( "Find" )
		_find.HotKey=Key.Key4
		_find.HotKeyModifiers=Modifier.Alt
		_find.Triggered=Lambda()
			SwitchView( "Find" )
		End
		
		_chat=New Action( "Chat" )
		_chat.HotKey=Key.Key5
		_chat.HotKeyModifiers=Modifier.Alt
		_chat.Triggered=Lambda()
			SwitchView( "Chat" )
		End
		
		_project=New Action( "Project" )
		_project.HotKey=Key.Key6
		_project.HotKeyModifiers=Modifier.Alt
		_project.Triggered=Lambda()
			SwitchView( "Project" )
		End
		
		_debug=New Action( "Debug" )
		_debug.HotKey=Key.Key7
		_debug.HotKeyModifiers=Modifier.Alt
		_debug.Triggered=Lambda()
			SwitchView( "Debug" )
		End
		
		_source=New Action( "Source" )
		_source.HotKey=Key.Key8
		_source.HotKeyModifiers=Modifier.Alt
		_source.Triggered=Lambda()
			SwitchView( "Source" )
		End
		
		
		
		
	End
	
	Method SwitchView(tabName:String)
		
		For Local i:=Eachin tabs
			Local tabb:=i.Tabs
			For Local docks:=Eachin tabb
				If docks.Text=tabName Then
					If docks.Visible 
						docks.Visible=False
						docks.View.Visible=False
					Else 
						docks.Visible=True
						docks.View.Visible=True
						docks.CurrentHolder.MakeCurrent(docks.Text)
					End
					docks.CurrentHolder.Visible=docks.CurrentHolder.VisibleTabs
				End	
			Next
		Next
	End
	
End
