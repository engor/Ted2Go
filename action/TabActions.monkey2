Namespace ted2go


Class TabActions
	
	Global tabs:TabViewExt[]
	
	Method New( _tabs:TabViewExt[] )
		
		tabs=_tabs
	End
	
	Function SwitchView( tabName:String )
		
			For Local i:=Eachin tabs
				Local _docks:=i.Tabs
				For Local _tabb:=Eachin _docks	
					If _tabb.Text=tabName Then
						If _tabb.Visible
							_tabb.Visible=False
							_tabb.View.Visible=False
							'make first tab as current
							For Local firstCurrent:=Eachin _docks
								If firstCurrent.Visible Then firstCurrent.CurrentHolder.MakeCurrent( firstCurrent.Text ); Exit
							Next	
						Else
							If( _tabb.View )
								_tabb.Visible=True
								_tabb.View.Visible=True
								_tabb.CurrentHolder.MakeCurrent( _tabb.Text )
							End
						End
						_tabb.CurrentHolder.Visible=_tabb.CurrentHolder.VisibleTabs
					End
					
				Next
			Next
	End
	
	Function CreateMenu( view:MenuExt )
		
		Local keynr:Int
		Local tabNames:=New String[]( "Project","Debug","Source","Build","Output","Docs","Find","Chat" )	
		For Local a:=Eachin tabNames
			Local key:=Cast<Key>( 49+keynr )
			Local i:=view.AddAction( a )
			i.HotKey=key
			i.HotKeyModifiers=Modifier.Alt
			i.Triggered=Lambda()
				SwitchView( a )	
			End
			keynr+=1
		Next
		view.AddSeparator()
		'reset all tabs
		Local _reset:=view.AddAction( "Reset" )
		_reset.Triggered=Lambda()
			Reset()	
		End
	End
	
	Function Reset()
		
		For Local i:=Eachin tabs
			Local _docks:=i.Tabs
			For Local _tabb:=Eachin _docks	
					If _tabb.View
						_tabb.Visible=True
						_tabb.View.Visible=True
						_tabb.CurrentHolder.MakeCurrent( _tabb.Text )
						_tabb.CurrentHolder.Visible=_tabb.CurrentHolder.VisibleTabs
					End
			Next
		Next
		'Undock Reset
		UndockWindow.RestoreUndock()
	End
End
