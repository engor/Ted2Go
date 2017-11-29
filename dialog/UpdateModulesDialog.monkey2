
Namespace ted2go

Class UpdateModulesDialog Extends DialogExt
	
	Method New( targets:StringStack,selectedModules:String,configs:String,clean:Bool )
		
		_modsNames.Clear()
		GetModulesNames( _modsNames )
		
		Local dock:=New DockingView
		
		Local modsDock:=New DockingView
		modsDock.AddView( New Label( "Modules:" ),"left" )
		' select all modules
		Local btn:=New Button( "All" )
		btn.Clicked+=Lambda()
			For Local v:=Eachin _modulesViews
				v.Checked=True
			Next
		End
		modsDock.AddView( btn,"right" )
		' select none modules
		btn=New Button( "None" )
		btn.Clicked+=Lambda()
			For Local v:=Eachin _modulesViews
				v.Checked=False
			Next
		End
		modsDock.AddView( New Label( " " ),"right" )
		modsDock.AddView( btn,"right" )
		
		dock.AddView( modsDock,"top" )
		
		' table with modules
		Local selMods:=New StringStack( selectedModules.Split( " " ) )
		
		Local cols:=4
		Local table:=New TableView( cols,1 )
		table.Rows=(_modsNames.Length/cols)+1
		Local r:=0,c:=0,i:=0
		For Local m:=Eachin _modsNames
		
			r=i/cols
			c=i Mod cols
			i+=1
		
			Local chb:=New CheckButton( m )
			chb.Checked=(Not selectedModules Or selMods.Contains( m ))
			table[c,r]=chb
			_modulesViews.Add( chb )
		Next
		dock.AddView( table,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		dock.AddView( New Label( "Targets:" ),"top" )
		Local targetDock:=New DockingView
		For Local t:=Eachin targets
			Local chb:=New CheckButton( t )
			targetDock.AddView( chb,"left" )
			_targetsViews.Add( chb )
			chb.Checked=(t="desktop")
		Next
		dock.AddView( targetDock,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		dock.AddView( New Label( "Configs:" ),"top" )
		Local configDock:=New DockingView
		'
		_releaseView=New CheckButton( "release" )
		_releaseView.Checked=configs.Contains( "release" )
		configDock.AddView( _releaseView,"left" )
		'
		_debugView=New CheckButton( "debug" )
		_debugView.Checked=configs.Contains( "debug" )
		configDock.AddView( _debugView,"left" )
		
		dock.AddView( configDock,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		_cleanView=New CheckButton( "Clean existing data (rebuild)" )
		_cleanView.Checked=clean
		_cleanView.Layout="float"
		dock.AddView( _cleanView,"top" )
		dock.AddView( New Label( " " ),"top" )
		
		Local actUpdate:=New Action( "Update" )
		actUpdate.Triggered+=Lambda()
			
			If Not SelectedModules
				ShowMessage( "","Please, select at least one module to update." )
				Return
			Endif
			If SelectedTargets.Empty
				ShowMessage( "","Please, select at least one target." )
				Return
			Endif
			If Not SelectedConfigs
				ShowMessage( "","Please, select at least one config." )
				Return
			Endif
			
			HideWithResult( True )
		End
		AddAction( actUpdate )
		
		Local actCancel:=New Action( "Cancel" )
		actCancel.Triggered+=Lambda()
			HideWithResult( False )
		End
		AddAction( actCancel )
		
		ContentView=dock
		
		SetKeyAction( Key.Enter,actUpdate )
		SetKeyAction( Key.Escape,actCancel )
	End
	
	Property SelectedModules:String()
		
		Local out:=""
		Local list:=_modulesViews
		For Local v:=Eachin list
			
			If v.Checked Then out+=v.Text+" "
		Next
		Return out
	End
	
	Property SelectedTargets:StringStack()
	
		Local out:=New StringStack
		Local list:=_targetsViews
		For Local v:=Eachin list
	
			If v.Checked Then out.Add( v.Text )
		Next
		Return out
	End
	
	Property SelectedConfigs:String()
	
		Local out:=""
		If _releaseView.Checked Then out="release"
		If _debugView.Checked
			If out Then out+=" "
			out+="debug"
		Endif
		Return out
	End
	
	Property NeedClean:Bool()
	
		Return _cleanView.Checked
	End
	
	
	Private
	
	Field _modulesViews:=New Stack<CheckButton>
	Field _targetsViews:=New Stack<CheckButton>
	Field _releaseView:CheckButton,_debugView:CheckButton
	Field _cleanView:CheckButton
	
	Global _modsNames:=New StringStack
	
	#rem MARK WAS HERE!!!!!
	
	EnumModules code lifted from mx2cc.monkey2
	
	This sorts modules into dependancy order.
	
	#end
	Function EnumModules( out:StringStack,cur:String,deps:StringMap<StringStack> )
		If out.Contains( cur ) Return
		
		For Local dep:=Eachin deps[cur]
			EnumModules( out,dep,deps )
		Next
		
		out.Push( cur )
	End
	
	Function EnumModules:String[]()
	
		LoadEnv()
		
		Local mods:=New StringMap<StringStack>
		
		For Local moddir:=Eachin ModuleDirs
	
			For Local f:=Eachin LoadDir( moddir )
			
				Local dir:=moddir+f+"/"
				If GetFileType( dir )<>FileType.Directory Continue
				
				Local str:=LoadString( dir+"module.json" )
				If Not str Continue
				
				Local obj:=JsonObject.Parse( str )
				If Not obj 
					Print "Error parsing json:"+dir+"module.json"
					Continue
				Endif
				
				Local name:=obj["module"].ToString()
				If name<>f Continue
				
				Local deps:=New StringStack
				If name<>"monkey" deps.Push( "monkey" )
				
				Local jdeps:=obj["depends"]
				If jdeps
					For Local dep:=Eachin jdeps.ToArray()
						deps.Push( dep.ToString() )
					Next
				Endif
				
				mods[name]=deps
			Next
		Next
				
		Local out:=New StringStack
		For Local cur:=Eachin mods.Keys
			EnumModules( out,cur,mods )
		Next
		
		Return out.ToArray()
	End
	
	Function GetModulesNames( out:StringStack )
		
		out.AddAll( EnumModules() )
	End

End
