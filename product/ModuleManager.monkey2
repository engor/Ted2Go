
Namespace ted2go


Private

Class Module
	Field name:String
	Field about:String
	Field author:String
	Field version:String
	Field new_version:String
	Field status:String
	Field checked:Bool
End

Public

Class ModuleManager Extends Dialog

	Method New( console:ConsoleExt )
		Super.New( "Module Manager" )
		
		_console=console
		
		_table=New TableView
'		_table.Style=App.Theme.GetStyle( "TableView" )
'		_table.Style.BackgroundColor=App.Theme.GetColor( "content" )
		
		_table.AddColumn( "Module",,"20%" )
		_table.AddColumn( "About",,"40%" )
		_table.AddColumn( "Version",,"10%" )
		_table.AddColumn( "Status",,"17%" )
		_table.AddColumn( "Action",,"13%" )
		
		_docker=New DockingView
		_docker.ContentView=_table
		
		Local buttons:=New ToolBar
		
		buttons.AddView( New Label( "Filters: " ) )
		
		Local filters:=New String[]( "Local","Installed","Uninstalled" )
		
		For Local f:=Eachin filters
		
			Local button:=New CheckButton( f )
			
			button.Clicked=Lambda()
				UpdateTable()
			End
			
			buttons.AddView( button )
			
			_filters[f]=button
		Next
		
		buttons.AddAction( "All" ).Triggered=Lambda()
		
			For Local button:=Eachin _filters.Values
				button.Checked=True
			Next
			
			UpdateTable()
		End
			
		buttons.AddAction( "None" ).Triggered=Lambda()
		
			For Local button:=Eachin _filters.Values
				button.Checked=False
			Next
			
			UpdateTable()
		End
			
		_docker.AddView( buttons,"bottom" )
		
		ContentView=_docker
		
		AddAction( "Perform Actions" ).Triggered=Lambda()
		
			If PerformActions() OnActivated()
		End
	
		AddAction( "Close" ).Triggered=Lambda()
			Close()
			App.EndModal()
		End
		
		MinSize=New Vec2i( 800,600 )
		
		Activated+=Lambda()
			MainWindow.ShowBuildConsole( True )
			App.BeginModal( Self )
			OnActivated()
		End
	End
	
	Private
	
    Field downloadUrl:=MONKEY2_DOMAIN+"/send-file?file="
	
	Const downloadDir:="modules/module-manager/downloads/"
	
	Const backupDir:="modules/module-manager/backups/"
	
	Field _console:ConsoleExt
	Field _docker:DockingView
	Field _modules:=New StringMap<Module>
	Field _filters:=New StringMap<CheckButton>
	Field _table:TableView
	
	Field _progress:ProgressDialog
	Field _procmods:=New Stack<Module>
	
	Method WrapString:String( str:String,maxlen:Int )
	
		Local bits:=str.Split( " " ),out:="",len:=0
		
		For Local i:=0 Until bits.Length
			Local n:=bits[i].Length+1
			If len+n<=maxlen
				out+=" "+bits[i]
				len+=n
			Else
				out+="~n"+bits[i]
				len=0
			Endif
		Next
		
		Return out.Trim()
	End
	
	Method BackupModules:Bool()
	
		Local backupDir:="modules/module-manager/backups/"
		
		If Not DeleteDir( backupDir,True ) Or Not CreateDir( backupDir )
			Alert( "Failed to create backup dir '"+backupDir+"'" )
			Return False
		End
		
		For Local module:=Eachin _procmods
		
			Local src:="modules/"+module.name
			Local dst:=backupDir+module.name
			
			Select GetFileType( src )
			Case FileType.Directory
				If Not CopyDir( src,dst,True )
					Alert( "Failed to copy module dir '"+src+"' to backup dir '"+dst+"'" )
					Return False
				Endif
			End
		
		End
		
		Return True
	End
	
	Method RestoreModules:Bool()

		Local backupDir:="modules/module-manager/backups/"
		
		For Local module:=Eachin _procmods
		
			Local src:=backupDir+module.name
			Local dst:="modules/"+module.name
			
			Select GetFileType( src )
			Case FileType.Directory
			
				If Not DeleteDir( dst,True ) Or Not CopyDir( src,dst,True )
					Alert( "Failed to copy backup dir '"+src+"' to module dir '"+dst+"'" )
					Return False
				Endif
			
			Case FileType.None
			
				If Not DeleteDir( dst,True )
					Alert( "Failed to delete module dir '"+dst+"'" )
					Return False
				Endif
			End
		
		End
		
		Return True
	End

	Method DownloadModules:Bool()
	
		If Not CreateDir( downloadDir ) 
			Alert( "Failed to create download dir '"+downloadDir+"'" )
			Return False
		Endif
		
		For Local module:=Eachin _procmods
		
			Local zip:=module.name+"-v"+module.new_version+".zip"
			Local src:=downloadUrl+zip
			Local dst:=downloadDir+zip

#if __HOSTOS__="macos"
			Local cmd:="curl -s -o ~q"+dst+"~q -data-binary ~q"+src+"~q"
#else
			Local cmd:="wget -q -O ~q"+dst+"~q ~q"+src+"~q"
#endif
			_progress.Text="Downloading "+zip+"..."
			
			If Not _console.Run( cmd ) Return False
			
			If _console.ExitCode
				Alert( "Process '"+cmd+"' failed with exit code "+_console.Process.ExitCode )
				Return False
			Endif
			
			If Not GetFileSize( dst )
				Alert( "Error downloading file '"+zip+"'" )
				Return False
			Endif
		
		Next
		
		Return True
	End
	
	Method InstallModules:Bool()

		For Local module:=Eachin _procmods

			Local zip:=module.name+"-v"+module.new_version+".zip"
			Local dst:=downloadDir+zip
			
			If Not DeleteDir( "modules/"+module.name,True )
				Alert( "Error deleting module directory '"+module.name+"'" )
				Return False
			End
		
			If Not ExtractZip( dst,"modules",module.name+"/" )
				Alert( "Error extracting zip to '"+dst+"'" )
				Return False
			Endif
			
			'Alert( "Test failure!" )
			'Return False
		
		Next
		
		Return True
	End
	
	Method UpdateModules:Bool()
	
		For Local config:=0 Until 2
			
			Local cmd:=MainWindow.Mx2ccPath+" makemods -config="+(config ? "debug" Else "release")
			
			If Not _console.Run( cmd ) Return False
			
			If _console.Process.ExitCode
				Alert( "Process '"+cmd+"' failed with exit code "+_console.Process.ExitCode )
				Return False
			Endif
			
		Next
		
		Local cmd:=MainWindow.Mx2ccPath+" makedocs"
		
		For Local module:=Eachin _procmods
			cmd+=" "+module.name
		Next
		
		_console.Run( cmd )
		
		Return True
	End
	
	Method PerformActions:Bool()
	
		_procmods=New Stack<Module>
		
		Local docker:=New DockingView
		
		For Local it:=Eachin _modules
		
			Local module:=it.Value
			
			If Not module.checked Continue
			
			_procmods.Push( module )
			
			If module.status="Installed"
				docker.AddView( New Label( "Update module: "+module.name ),"top" )
			Else
				docker.AddView( New Label( "Install module: "+module.name ),"top" )
			Endif
		Next
		
		If Not _procmods.Length
			Alert( "No actions to perform!" )
			Return False
		Endif
		
		
		If Dialog.Run( "Proceed with actions?",New ScrollView( docker ),New String[]( "Proceed!","Cancel" ) )=1 Return False
		

		_progress=New ProgressDialog( "Module Manager","Performing actions..." )
		
		_progress.MinSize=New Vec2i( 320,0 )
		
		_progress.Open()
		
		App.BeginModal( _progress )
		
		
		Local err:=""
		Local restore:=False

		_progress.Text="Downloading modules..."

		If DownloadModules()

			_progress.Text="Backing up modules..."

			If BackupModules()
			
				restore=True
				
				_progress.Text="Installing modules..."
				
				If InstallModules()
				
					_progress.Text="Updating modules..."
					
					If UpdateModules()
					
						MainWindow.UpdateHelpTree()
					
					Else
						err="Failed to update modules"
					Endif
				Else
					err="Failed to install modules"
				Endif
			Else
				err="Failed to backup modules"
			Endif
		Else
			err="Failed to download modules"
		Endif
		
		
		App.EndModal()		
		
		_progress.Close()
		
		If Not err
			Alert( "All actions successfully performed!" )
			Return True
		Endif
		
		Alert( "Error performing actions: "+err )
		
		If Not restore Return True
		
		If TextDialog.Run( "Restore modules","There was an error performing actions.~nWould you like to restore modules (recommended)?",New String[]( "Okay","Cancel" ) )<>0 Return True

	
		If RestoreModules()
			Alert( "Modules successfully restored" )
		Else
			Alert( "Failed to restore modules - old modules may be found in 'modules/module-manager/backups'" )
		Endif

		Return True
	End
	
	Method Version:Int( version:String )
	
		Local bits:=version.Split( "." )
		If bits.Length<>3 Return -1
		
		Local i0:=Int( bits[0] )
		If String(i0)<>bits[0] Return -1
		
		Local i1:=Int( bits[1] )
		If String(i1)<>bits[1] Return -1
		
		Local i2:=Int( bits[2] )
		If String(i2)<>bits[2] Return -1
		
		Return i0*1000000 + i1*1000 + i2
	End
	
	Method OnActivated()
	
		_modules.Clear()

		EnumLocalModules()
		
		EnumRemoteModules()
		
		_filters["Local"].Checked=False
		_filters["Installed"].Checked=True
		_filters["Uninstalled"].Checked=True
		
		UpdateTable()
	End
	
	Method EnumRemoteModules:Bool()
	
		Local src:=MONKEY2_DOMAIN+"/module-manager/?modules=1"
		
		Local tmp:="tmp/modules.json"
	
		DeleteFile( tmp )
		
		Local progress:=New ProgressDialog( "Contacting server","Downloading modules list..." )
		
		progress.AddAction( "Cancel" ).Triggered=lambda()
			_console.Terminate()
			progress.Close()
		End
		
		progress.Open()
		
#if __HOSTOS__="macos"
		Local cmd:="curl -s -o ~q"+tmp+"~q ~q"+src+"~q"
#else
		Local cmd:="wget -q -O ~q"+tmp+"~q ~q"+src+"~q"
#endif
		If Not _console.Run( cmd )
		
			progress.Close()
			Return False
		Endif
		
		If _console.Process.ExitCode
		
			Alert( "Process '"+cmd+"' failed with exit code "+_console.Process.ExitCode )
			progress.Close()
			Return False
		Endif
		
		progress.Close()
		
		Local str:=LoadString( tmp )
		If Not str
			Alert( "Failed to download modules list" )
			Return False
		Endif
		
		Local jobj:=JsonObject.Parse( str )
		If Not jobj
			Alert( "Failed to parse modules list" )
			Return False
		Endif
		
		Local mods:=jobj.ToObject()
		
		For Local it:=Eachin mods
		
			Local name:=it.Key
			Local info:=it.Value.ToObject()
			
			Local about:=info["about"].ToString()
			Local author:=info["author"].ToString()
			Local version:=info["version"].ToString()
			
			Local module:=_modules[name]
			If module
				module.new_version=version
				module.status="Installed"
				If Version( module.new_version )>Version( module.version )
					_filters["Installed"].Checked=True
					module.checked=True
				Endif
			Else
				module=New Module
				module.version=version
				module.new_version=version
				module.status="Uninstalled"
				_modules[name]=module
			Endif
			
			module.name=name
			module.about=about
			module.author=author
			
			_modules[name]=module
			
		Next
		
		Return True

	End
	
	Method EnumLocalModules()
	
		For Local f:=Eachin LoadDir( "modules" )
		
			Local dir:="modules/"+f+"/"
			If GetFileType( dir )<>FileType.Directory Continue
			
			Local str:=LoadString( dir+"module.json" )
			If Not str Continue
			
			Local obj:=JsonObject.Parse( str )
			If Not obj Continue
			
			Local jname:=obj["module"]
			If Not jname Or Not Cast<JsonString>( jname ) Continue
			
			Local jabout:=obj["about"]
			If Not jabout Or Not Cast<JsonString>( jabout ) Continue
			
			Local jauthor:=obj["author"]
			If Not jauthor Or Not Cast<JsonString>( jauthor ) Continue
			
			Local jversion:=obj["version"]
			If Not jversion Or Not Cast<JsonString>( jversion ) Continue
			
			Local name:=jname.ToString()
			Local about:=jabout.ToString()
			Local author:=jauthor.ToString()
			Local version:=jversion.ToString()
			
			Local module:=New Module
			module.name=name
			module.about=about
			module.author=author
			module.version=version
			module.status="Local"
			
			_modules[name]=module
		
		Next
	End

	Method UpdateTable()
	
		_table.RemoveAllRows()
		
		Local style:=New Style( App.Theme.GetStyle( "Label" ) )
		style.Border=New Recti( 0,-1,0,0 )
		style.BorderColor=App.Theme.GetColor( "knob" )
		
		Local i:=0

		For Local it:=Eachin _modules
			
			Local module:=it.Value
			If Not _filters[module.status].Checked Continue
			
			_table.Rows+=1
			
			Local about:=module.about
			
			Local maxlen:=40
			
			about=WrapString( about,40 )
			
			Local action:=""
			
			Local status:=module.status
			If status="Installed"
				If Version( module.new_version )>Version( module.version )
					status="Update available"
					action="Update"
				Endif
			Else If status="Uninstalled"
				action="Install"
			Endif
			
			_table[0,i]=New Label( module.name )
			_table[1,i]=New Label( about )
			_table[2,i]=New Label( module.version )
			_table[3,i]=New Label( status )
			
			If action
				Local button:=New CheckButton( action )
				button.Checked=module.checked
				button.Clicked=Lambda()
					module.checked=button.Checked
				End
				_table[4,i]=button
			Else
				_table[4,i]=New Label( "" )
			Endif
			
			For Local j:=0 Until 5
				_table[j,i].Layout="fill"
				_table[j,i].Style=style
			Next
			
			i+=1

		Next
		
		' some bottom pagdding
		_table.Rows+=1
		Local label:=New Label( "" )
		label.MinSize=New Vec2i( 0,30 )
		_table[0,_table.Rows-1]=label
		
		App.RequestRender()
	
	End
	
End
