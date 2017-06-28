Namespace ted2go


Class UpdateModulesDialog Extends DialogExt

	Method New( targets:StringStack )
		
		_targets=targets
	End
	
	Method Show( modules:String )
		
		_modsNames.Clear()
		GetModulesNames( _modsNames )
		
		Title="Update modules"
		
		Local dock:=New DockingView
		
		Local modsDock:=New DockingView
		modsDock.AddView( New Label( "Modules:" ),"left" )
		Local btn:=New Button( "All" )
		btn.Clicked+=Lambda()
			
		End
		modsDock.AddView( btn,"right" )
		btn=New Button( "None" )
		btn.Clicked+=Lambda()
		
		End
		modsDock.AddView( New Label( " " ),"right" )
		modsDock.AddView( btn,"right" )
		
		dock.AddView( modsDock,"top" )
		
		Local cols:=4
		Local table:=New TableView( cols,1 )
		table.Rows=(_modsNames.Length/cols)+1
		Local r:=0,c:=0,i:=0
		For Local m:=Eachin _modsNames
			
			r=i/cols
			c=i Mod cols
			i+=1
			
			Local chb:=New CheckButton( m )
			chb.Checked=(Not modules Or modules.Contains( " "+m ) Or modules.Contains( m+" " ))
			table[c,r]=chb
		Next
		dock.AddView( table,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		dock.AddView( New Label( "Targets:" ),"top" )
		Local targetDock:=New DockingView
		For Local t:=Eachin _targets
			targetDock.AddView( New CheckButton( t ),"left" )
		Next
		dock.AddView( targetDock,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		dock.AddView( New Label( "Configs:" ),"top" )
		Local configDock:=New DockingView
		configDock.AddView( New CheckButton( "release" ),"left" )
		configDock.AddView( New CheckButton( "debug" ),"left" )
		dock.AddView( configDock,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		Local v:=New CheckButton( "Clean existing data" )
		v.Layout="float"
		dock.AddView( v,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		ContentView=dock
		
		Local actUpdate:=New Action( "Update modules" )
		actUpdate.Triggered+=Lambda()
			
			Hide()
			'PerformAction()
		End
		
		Local actCancel:=New Action( "Cancel" )
		actCancel.Triggered+=Lambda()
		
			Hide()
		End
		
		AddAction( actUpdate )
		AddAction( actCancel )
		
		Super.Show()
	End
	
	
	Private
	
	Global _modsNames:=New StringStack
	Field _targets:StringStack
	
	
	Function GetModulesNames( out:StringStack )
	
		Local modsPath:=MainWindow.ModsPath
	
		Local dd:=LoadDir( modsPath )
	
		For Local d:=Eachin dd
			If GetFileType( modsPath+d ) = FileType.Directory
				Local file:=modsPath + d + "/module.json"
				If GetFileType( file ) = FileType.File
					out.Add( d )
				Endif
			Endif
		Next
	End
	
End
