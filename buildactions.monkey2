
Namespace ted2go


Class BuildError

	Field path:String
	Field line:Int
	Field msg:String
	Field removed:Bool
	
	Method New( path:String,line:Int,msg:String )
		Self.path=path
		Self.line=line
		Self.msg=msg
	End

	Operator<=>:Int( err:BuildError )
		If line<err.line Return -1
		If line>err.line Return 1
		Return 0
	End
	
End

Class BuildActions

	Field buildAndRun:Action
	Field build:Action
	Field check:Action
	Field buildSettings:Action
	Field nextError:Action
	Field lockBuildFile:Action
	Field updateModules:Action
	Field rebuildModules:Action
	Field moduleManager:Action
	Field rebuildHelp:Action
	
	Field targetMenu:Menu
	
	Method New( docs:DocumentManager,console:Console,debugView:DebugView )
	
		_docs=docs
		_console=console
		_debugView=debugView
		
		_docs.DocumentRemoved+=Lambda( doc:Ted2Document )

			If doc=_locked _locked=Null
		End
		
		buildAndRun=New Action( "Build and run" )
		buildAndRun.Triggered=OnBuildAndRun
		buildAndRun.HotKey=Key.F5

		build=New Action( "Build only" )
		build.Triggered=OnBuild
		build.HotKey=Key.F6
		
		check=New Action( "Check for errors" )
		check.Triggered=OnCheck
		check.HotKey=Key.F7
		
		buildSettings=New Action( "Target settings" )
		buildSettings.Triggered=OnBuildFileSettings
		
		nextError=New Action( "Next build error" )
		nextError.Triggered=OnNextError
		nextError.HotKey=Key.F4
		
		lockBuildFile=New Action( "Lock build file" )
		lockBuildFile.Triggered=OnLockBuildFile
		lockBuildFile.HotKey=Key.L
		lockBuildFile.HotKeyModifiers=Modifier.Menu
		
		updateModules=New Action( "Update modules" )
		updateModules.Triggered=OnUpdateModules
		updateModules.HotKey=Key.U
		updateModules.HotKeyModifiers=Modifier.Menu
		
		rebuildModules=New Action( "Rebuild modules" )
		rebuildModules.Triggered=OnRebuildModules
		rebuildModules.HotKey=Key.U
		rebuildModules.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		
		moduleManager=New Action( "Module manager" )
		moduleManager.Triggered=OnModuleManager
		
		rebuildHelp=New Action( "Rebuild documentation" )
		rebuildHelp.Triggered=OnRebuildHelp
		
		local group:=New CheckGroup
		_debugConfig=New CheckButton( "Debug",,group )
		_debugConfig.Layout="fill-x"
		_releaseConfig=New CheckButton( "Release",,group )
		_releaseConfig.Layout="fill-x"
		_debugConfig.Clicked+=Lambda()
			_buildConfig="debug"
		End
		_releaseConfig.Clicked+=Lambda()
			_buildConfig="release"
		End
		_buildConfig="debug"

		group=New CheckGroup

		_desktopTarget=New CheckButton( "Desktop",,group )
		_desktopTarget.Layout="fill-x"
		
		_emscriptenTarget=New CheckButton( "Emscripten",,group )
		_emscriptenTarget.Layout="fill-x"
		
		_androidTarget=New CheckButton( "Android",,group )
		_androidTarget.Layout="fill-x"
		
		_iosTarget=New CheckButton( "iOS",,group )
		_iosTarget.Layout="fill-x"
		
		targetMenu=New Menu( "Build target..." )
		targetMenu.AddView( _debugConfig )
		targetMenu.AddView( _releaseConfig )
		targetMenu.AddSeparator()
		targetMenu.AddView( _desktopTarget )
		targetMenu.AddView( _emscriptenTarget )
		targetMenu.AddView( _androidTarget )
		targetMenu.AddView( _iosTarget )
		targetMenu.AddSeparator()
		targetMenu.AddAction( buildSettings )
		
		'check valid targets...WIP...
		
		_validTargets=EnumValidTargets( _console )
		
		If _validTargets _buildTarget=_validTargets[0].ToLower()
		
		If _validTargets.Contains( "desktop" )
			_desktopTarget.Clicked+=Lambda()
				_buildTarget="desktop"
			End
		Else
			_desktopTarget.Enabled=False
		Endif
		
		If _validTargets.Contains( "emscripten" )
			_emscriptenTarget.Clicked+=Lambda()
				_buildTarget="emscripten"
			End
		Else
			_emscriptenTarget.Enabled=False
		Endif

		If _validTargets.Contains( "android" )
			_androidTarget.Clicked+=Lambda()
				_buildTarget="android"
			End
		Else
			_androidTarget.Enabled=False
		Endif

		If _validTargets.Contains( "ios" )
			_iosTarget.Clicked+=Lambda()
				_buildTarget="ios"
			End
		Else
			_iosTarget.Enabled=False
		Endif
	End
	
	Method SaveState( jobj:JsonObject )
		
		If _locked jobj["lockedDocument"]=New JsonString( _locked.Path )
		
		jobj["buildConfig"]=New JsonString( _buildConfig )
		
		jobj["buildTarget"]=New JsonString( _buildTarget )
	End
		
	Method LoadState( jobj:JsonObject )
	
		If jobj.Contains( "lockedDocument" )
			Local path:=jobj["lockedDocument"].ToString()
			_locked=Cast<CodeDocument>( _docs.FindDocument( path ) )
			If _locked _locked.State="+"
		Endif
		
		If jobj.Contains( "buildConfig" )
			_buildConfig=jobj["buildConfig"].ToString()
			Select _buildConfig
			Case "release"
				_releaseConfig.Checked=True
			Default
				_debugConfig.Checked=True
				_buildConfig="debug"
			End
		Endif
		
		If jobj.Contains( "buildTarget" )
					
			local target:=jobj["buildTarget"].ToString()

			If _validTargets.Contains( target )
			
				 _buildTarget=target
				
				Select _buildTarget
				Case "desktop"
					_desktopTarget.Checked=True
				Case "emscripten"
					_emscriptenTarget.Checked=True
				Case "android"
					_androidTarget.Checked=True
				Case "ios"
					_iosTarget.Checked=True
				End
			
			Endif
			
		Endif
		
	End
	
	Method Update()
	
		While Not _errors.Empty And _errors.First.removed
			_errors.RemoveFirst()
		Wend
	
		Local idle:=Not _console.Running
		Local canbuild:=idle And BuildDoc()<>Null And _buildTarget
		
		build.Enabled=canbuild
		buildAndRun.Enabled=canbuild
		nextError.Enabled=Not _errors.Empty
		updateModules.Enabled=idle
		rebuildModules.Enabled=idle
		rebuildHelp.Enabled=idle
	End
	
	Private
	
	Field _docs:DocumentManager
	Field _console:Console
	Field _debugView:DebugView
	
	Field _locked:CodeDocument
	
	Field _errors:=New List<BuildError>
	
	Field _buildConfig:String
	Field _buildTarget:String
	
	Field _debugConfig:CheckButton
	Field _releaseConfig:CheckButton
	Field _desktopTarget:CheckButton
	Field _emscriptenTarget:CheckButton
	Field _androidTarget:CheckButton
	Field _iosTarget:CheckButton
	
	Field _validTargets:StringStack
	
	Method BuildDoc:CodeDocument()
		
		If Not _locked Return Cast<CodeDocument>( _docs.CurrentDocument )
		
		Return _locked
	End
	
	Method SaveAll:Bool()
	
		For Local doc:=Eachin _docs.OpenDocuments
			If Not doc.Save() Return False
		Next
		
		Return True
	End
	
	Method ClearErrors()
	
		_errors.Clear()
	
		For Local doc:=Eachin _docs.OpenDocuments
			Local mx2Doc:=Cast<CodeDocument>( doc )
			If mx2Doc mx2Doc.Errors.Clear()
		Next

	End

	Method GotoError( err:BuildError )
	
		Local doc:=Cast<CodeDocument>( _docs.OpenDocument( err.path,True ) )
		If Not doc Return
		
		Local tv := doc.TextView
		If Not tv Return
		
		MainWindow.UpdateWindow( False )
		
		tv.GotoLine( err.line )
	End
	
	Method BuildMx2:Bool( cmd:String,progressText:String,checkOnly:Bool=False )
	
		ClearErrors()
		
		_console.Clear()
		
		MainWindow.ShowBuildConsole( False )
		
		If _console.Running Return False
		
		If Not SaveAll() Return False

		If Not _console.Start( cmd )
			Alert( "Failed to start process: '"+cmd+"'" )
			Return False
		Endif
		
		Local progress:=New ProgressDialog( "Building",progressText )
		
		progress.MinSize=New Vec2i( 320,0 )
		
		Local cancel:=progress.AddAction( "Cancel" )
		
		cancel.Triggered=Lambda()
			_console.Terminate()
		End
		
		App.KeyEventFilter += Lambda(event:KeyEvent)
			If event.Type = EventType.KeyDown And event.Key = Key.Escape
				_console.Terminate()
				event.Eat()
			Endif
		End
		
		progress.Open()
		
		Repeat
		
			Local stdout:=_console.ReadStdout()
			If Not stdout Exit
			
			If stdout.StartsWith( "Application built:" )

'				_appFile=stdout.Slice( stdout.Find( ":" )+1 ).Trim()
			Else
			
				Local i:=stdout.Find( "] : Error : " )
				If i<>-1
					Local j:=stdout.Find( " [" )
					If j<>-1
						Local path:=stdout.Slice( 0,j )
						Local line:=Int( stdout.Slice( j+2,i ) )-1
						Local msg:=stdout.Slice( i+12 )
						
						Local err:=New BuildError( path,line,msg )
						Local doc:=Cast<CodeDocument>( _docs.OpenDocument( path,False ) )
						
						If doc
							doc.Errors.Add( err )
							If _errors.Empty 
								MainWindow.ShowBuildConsole( True )
								GotoError( err )
							Endif
							_errors.Add( err )
						Endif
						
					Endif
				Endif
			Endif
			
			If checkOnly
				Local i := stdout.Find( "Compiling..." )
				If i<>-1
					_console.Write( "~nDone." )
					_console.Terminate()
					Exit
				Endif
			Endif
			
			_console.Write( stdout )
		
		Forever
		
		progress.Close()
		
		Return _console.ExitCode=0
	End

	Method BuildModules:Bool( clean:Bool,target:String )
	
		Local msg:=(clean ? "Rebuilding " Else "Updating ")+target
		
		For Local config:=0 Until 2
		
			Local cfg:=(config ? "debug" Else "release")
			
			Local cmd:=MainWindow.Mx2ccPath+" makemods -target="+target
			If clean cmd+=" -clean"
			cmd+=" -config="+cfg
			
			If Not BuildMx2( cmd,msg+" "+cfg+" modules..." ) Return False
		Next
		
		Return True
	End
	
	Method BuildModules:Bool( clean:Bool )
	
		Local targets:=New StringStack
		
		For Local target:=Eachin _validTargets
			targets.Push( target="ios" ? "iOS" Else target.Capitalize() )
		Next

		targets.Push( "All!" )
		targets.Push( "Cancel" )
		
		Local i:=TextDialog.Run( "Build Modules","Select target..",targets.ToArray(),0,targets.Length-1 )
		
		Local result:=True
		
		Select i
		Case targets.Length-1	'Cancel
			Return False
		Case targets.Length-2	'All!
			For Local i:=0 Until targets.Length-2
				If BuildModules( clean,targets[i] ) Continue
				result=False
				Exit
			Next
		Default
			result=BuildModules( clean,targets[i] )
		End
		
		If result
			_console.Write( "~nBuild modules completed successfully!~n" )
		Else
			_console.Write( "~nBuild modules failed.~n" )
		Endif
		
		Return result
	End
	
	Method MakeDocs:Bool()
	
		Return BuildMx2( MainWindow.Mx2ccPath+" makedocs","Rebuilding documentation..." )
	End
	
	Method BuildApp:Bool( config:String,target:String,run:Bool,checkOnly:Bool )
	
		Local buildDoc:=BuildDoc()
		If Not buildDoc Return False
		
		Local product:=BuildProduct.GetBuildProduct( buildDoc.Path,target,False )
		If Not product Return False
		
		Local opts:=product.GetMx2ccOpts()
		
		Local appType:="gui"
		If target="console"
			appType="console"
			target="desktop"
		End

		Local cmd:=MainWindow.Mx2ccPath+" makeapp -build "+opts
		cmd+=" -apptype="+appType+" "
		cmd+=" -config="+config
		cmd+=" -target="+target
		cmd+=" ~q"+buildDoc.Path+"~q"
		
		Local msg:="Building "+StripDir( buildDoc.Path )+" for "+target+" "+config
		
		If Not BuildMx2( cmd,msg,checkOnly ) Return False
		
		If Not run Return True
		
		Local exeFile:=product.GetExecutable()
		If Not exeFile Return True
		
		Select target
		Case "desktop"

			_debugView.DebugApp( exeFile,config )

		Case "emscripten"
		
			Local mserver:=GetEnv( "MX2_MSERVER" )
			If mserver _console.Run( mserver+" ~q"+exeFile+"~q" )
		
		End
		
		Return True
	End
	
	Method OnBuildAndRun()

		BuildApp( _buildConfig,_buildTarget,True,False )
	End
	
	Method OnBuild()
	
		BuildApp( _buildConfig,_buildTarget,False,False )
	End
	
	Method OnCheck()
	
		BuildApp( _buildConfig,_buildTarget,False,True )
	End
	
	Method OnNextError()
	
		While Not _errors.Empty And _errors.First.removed
			_errors.RemoveFirst()
		Wend
		
		If _errors.Empty Return
		
		_errors.AddLast( _errors.RemoveFirst() )
			
		GotoError( _errors.First )
	End
	
	Method OnLockBuildFile()
	
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		If Not doc Return
		
		If _locked _locked.State=""
		
		If doc=_locked
			_locked=Null
			Return
		Endif
		
		_locked=doc
		_locked.State="+"
		
	End
	
	Method OnBuildFileSettings()

		Local buildDoc:=BuildDoc()
		If Not buildDoc Return
		
		local product:=BuildProduct.GetBuildProduct( buildDoc.Path,_buildTarget,True )
	End
	
	Method OnUpdateModules()
	
		BuildModules( False )
	End
	
	Method OnRebuildModules()
	
		BuildModules( True )
	End
	
	Method OnModuleManager()
	
		Local modman:=New ModuleManager( _console )
		
		modman.Open()
	End
	
	Method OnRebuildHelp()
	
		MakeDocs()
		
		MainWindow.UpdateHelpTree()
	End
	
End
