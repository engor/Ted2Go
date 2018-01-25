
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


Interface IModuleBuilder
	
	' cleanState: 
	' -1: don't clean
	' 0: use previous
	' 1: clean
	Method BuildModules:Bool( modules:String="",configs:String="",cleanState:Int=0 )
	
End


Class BuildActions Implements IModuleBuilder

	Field buildAndRun:Action
	Field debugApp:Action
	Field build:Action
	Field semant:Action
	Field buildSettings:Action
	Field nextError:Action
	Field lockBuildFile:Action
	Field updateModules:Action
	Field moduleManager:Action
	Field rebuildHelp:Action
	
	Field targetMenu:MenuExt
	
	
	Field PreBuild:Void()
	Field PreSemant:Void()
	Field PreBuildModules:Void()
	Field ErrorsOccured:Void(errors:BuildError[])
	
	Method New( docs:DocumentManager,console:ConsoleExt,debugView:DebugView )
	
		_docs=docs
		_console=console
		_debugView=debugView
		
		_docs.DocumentRemoved+=Lambda( doc:Ted2Document )

			If doc=_locked _locked=Null
		End
		
		buildAndRun=New Action( "Run" )
#If __TARGET__="macos"
		buildAndRun.HotKey=Key.R
		buildAndRun.HotKeyModifiers=Modifier.Menu
#Else
		buildAndRun.HotKey=Key.F5
#Endif
		buildAndRun.Triggered=OnBuildAndRun
		
		debugApp=New Action( "Debug" )
#If __TARGET__="macos"
		debugApp.HotKey=Key.D
		debugApp.HotKeyModifiers=Modifier.Menu
#Else
		debugApp.HotKey=Key.F8
#Endif
		debugApp.Triggered=OnDebugApp

		build=New Action( "Build" )
#If __TARGET__="macos"
		build.HotKey=Key.B
		build.HotKeyModifiers=Modifier.Menu
#Else
		build.HotKey=Key.F6
#Endif
		build.Triggered=OnBuild
		
		semant=New Action( "Check" )
#If __TARGET__="macos"
		semant.HotKey=Key.R
		semant.HotKeyModifiers=Modifier.Menu|Modifier.Shift
#Else
		semant.HotKey=Key.F7
#Endif
		semant.Triggered=OnSemant
		
		buildSettings=New Action( "Product settings..." )
		buildSettings.Triggered=OnBuildFileSettings
		
		nextError=New Action( "Next build error" )
		nextError.Triggered=OnNextError
		nextError.HotKey=Key.F4
		
		lockBuildFile=New Action( "Lock build file" )
		lockBuildFile.Triggered=LockBuildFile
		lockBuildFile.HotKey=Key.L
		lockBuildFile.HotKeyModifiers=Modifier.Menu
		
		updateModules=New Action( "Update / Rebuild modules..." )
		updateModules.Triggered=OnUpdateModules
		updateModules.HotKey=Key.U
		updateModules.HotKeyModifiers=Modifier.Menu
		
		moduleManager=New Action( "Module manager..." )
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
		
		_verboseMode=New CheckButton( "Verbose")
		_verboseMode.Layout="fill-x"
		
		targetMenu=New MenuExt( "Build target" )
		targetMenu.AddView( _debugConfig )
		targetMenu.AddView( _releaseConfig )
		targetMenu.AddSeparator()
		targetMenu.AddView( _desktopTarget )
		targetMenu.AddView( _emscriptenTarget )
		targetMenu.AddView( _androidTarget )
		targetMenu.AddView( _iosTarget )
		targetMenu.AddSeparator()
		targetMenu.AddAction( buildSettings )
		targetMenu.AddSeparator()
		targetMenu.AddView( _verboseMode )
		
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
	
	Property LockedDocument:CodeDocument()
	
		Return _locked
	End
	
	Property Verbosed:Bool()
	
		Return _verboseMode.Checked
	End
	
	Method LockBuildFile()
		
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		OnLockBuildFile( doc )
	End
	
	Method SaveState( jobj:JsonObject )
		
		If _locked jobj["lockedDocument"]=New JsonString( _locked.Path )
		
		jobj["buildConfig"]=New JsonString( _buildConfig )
		
		jobj["buildTarget"]=New JsonString( _buildTarget )
		
		jobj["buildVerbose"]=New JsonBool( _verboseMode.Checked )
	End
		
	Method LoadState( jobj:JsonObject )
	
		If jobj.Contains( "lockedDocument" )
			Local path:=jobj["lockedDocument"].ToString()
			_locked=Cast<CodeDocument>( _docs.FindDocument( path ) )
			If _locked Then SetLockedState( _locked,True )
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
		
		If jobj.Contains( "buildVerbose" )
			_verboseMode.Checked=jobj.GetBool( "buildVerbose" )
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
		rebuildHelp.Enabled=idle
		moduleManager.Enabled=idle
	End
	
	Method BuildModules:Bool( modules:String="",configs:String="",cleanState:Int=0 )
		
		If Not modules Then modules=_storedModules
		
		If Not configs
			configs=_storedConfigs
			If Not configs Then configs="debug release"
		Endif
		
		Local clean:Bool
		If cleanState=0
			clean=_storedClean
		Else
			clean=(cleanState=1)
		Endif
		
		Local selTargets:=(_storedTargets ?Else "desktop")
		
		Local dialog:=New UpdateModulesDialog( _validTargets,selTargets,modules,configs,clean )
		dialog.Title="Update / Rebuild modules"
		
		Local ok:=dialog.ShowModal()
		If Not ok Return False
		
		Local result:Bool
		
		Local targets:=dialog.SelectedTargets
		modules=dialog.SelectedModules
		configs=dialog.SelectedConfigs
		clean=dialog.NeedClean
		
		' store
		_storedTargets=targets.Join( " " )
		_storedModules=modules
		_storedConfigs=configs
		_storedClean=clean
		
		Local time:=Millisecs()
		
		For Local target:=Eachin targets
			result=BuildModules( target,modules,configs,clean )
			If result=False Exit
		Next
		
		time=Millisecs()-time
		Local prefix:=clean ? "Rebuild" Else "Update"
		
		If result
			_console.Write( "~n"+prefix+" modules completed successfully!~n" )
		Else
			_console.Write( "~n"+prefix+" modules failed.~n" )
		Endif
		_console.Write( "Total time elapsed: "+FormatTime( time )+".~n" )
		
		Return result
	End
	
	Method GotoError( err:BuildError )
	
		Local doc:=Cast<CodeDocument>( _docs.OpenDocument( GetCaseSensitivePath( err.path ),True ) )
		If Not doc Return
	
		Local tv := doc.CodeView
		If Not tv Return
	
		MainWindow.UpdateWindow( False )
	
		tv.GotoPosition( New Vec2i( err.line,0 ) )
		tv.MakeKeyView()
	End
	
	
	Private
	
	Field _docs:DocumentManager
	Field _console:ConsoleExt
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
	Field _verboseMode:CheckButton
	
	Field _validTargets:StringStack
	Field _timing:Long
	
	Field _storedModules:String
	Field _storedConfigs:String
	Field _storedTargets:String
	Field _storedClean:Bool
	
	Method BuildDoc:CodeDocument()
		
		If Not _locked Return Cast<CodeDocument>( _docs.CurrentDocument )
		
		Return _locked
	End
	
	Method SaveAll:Bool( buildFile:String )
		
		Local proj:="" 'ProjectView.FindProjectByFile( buildFile )
		
		For Local doc:=Eachin _docs.OpenDocuments
			' save docs only for built project
			If proj And Not doc.Path.StartsWith( proj ) Continue
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

	Method BuildMx2:Bool( cmd:String,progressText:String,action:String="build",buildFile:String="",showElapsedTime:Bool=False )
	
		ClearErrors()
		
		_console.Clear()
		
		MainWindow.StoreConsoleVisibility()
		
		MainWindow.ShowBuildConsole()
		
		If Not SaveAll( buildFile ) Return False
		
		_timing=Millisecs()
		
		If Not _console.Start( cmd )
			Alert( "Failed to start process: '"+cmd+"'" )
			Return False
		Endif
		
		Local title := (action="semant") ? "Checking" Else "Building"
		
		Local s:=progressText
		If Not s.EndsWith( "..." ) Then s+="..."
		
		MainWindow.ShowStatusBarText( s )
		MainWindow.ShowStatusBarProgress( _console.Terminate )
		
		Local hasErrors:=False
		
		Repeat
		
			Local result:=_console.ReadStdoutWithErrors()
			Local stdout:=result.stdout
			If Not stdout Exit
			
			If stdout.StartsWith( "Application built:" )

'				_appFile=stdout.Slice( stdout.Find( ":" )+1 ).Trim()
			Else
				
				Local err:=result.error
				If err
					hasErrors=True
					
					Local buildErr:=New BuildError( err.path,err.line,err.message )
					Local doc:=Cast<CodeDocument>( _docs.OpenDocument( GetCaseSensitivePath( buildErr.path ),False ) )
					
					If doc
						doc.AddError( buildErr )
						'If _errors.Empty
						'	MainWindow.ShowBuildConsole( True )
						'	GotoError( err )
						'Endif
						_errors.Add( buildErr )
					Endif
					
				Endif
				
				If Not hasErrors
					Local i:=stdout.Find( "Build error: " )
					hasErrors=(i<>-1)
				Endif
				
			Endif
			
			_console.Write( stdout )
		
		Forever
		
		If Not _errors.Empty
			ErrorsOccured( _errors.ToArray() )
		Endif
		
		MainWindow.HideStatusBarProgress()
		
		Local status:=""
		If hasErrors
			status="{0} failed. See the build console for details."
		Else
			If _console.ExitCode=0
				status="{0} finished."
			Else
				status="{0} cancelled."
				' notify about cancellation
				_console.Write( "~n"+status.Replace( "{0}",title )+"~n" )
			Endif
		Endif
		status=status.Replace( "{0}",title )
		
		If showElapsedTime
			Local elapsed:=(Millisecs()-_timing)
			status+="   Time elapsed: "+FormatTime( elapsed )+"."
		Endif
		
		MainWindow.ShowStatusBarText( status )
		
		Return _console.ExitCode=0
	End

	Method BuildModules:Bool( target:String,modules:String,configs:String,clean:Bool )
		
		PreBuildModules()
		
		Local msg:=(clean ? "Rebuilding ~ " Else "Updating ~ ")+target
		
		Local arr:=configs.Split( " " )
		For Local cfg:=Eachin arr
		
			'Local cfg:=(config ? "debug" Else "release")
			
			Local cmd:=MainWindow.Mx2ccPath+" makemods -target="+target
			If clean cmd+=" -clean"
			If Verbosed cmd+=" -verbose"
			cmd+=" -config="+cfg
			If modules Then cmd+=" "+modules
			
			Local s:=msg+" ~ "+cfg+" ~ ["
			s+=modules ? modules Else "all modules"
			s+="]..."
			If Not BuildMx2( cmd,s ) Return False
		Next
		
		Return True
	End
	
	Method MakeDocs:Bool()
	
		Return BuildMx2( MainWindow.Mx2ccPath+" makedocs","Rebuilding documentation...","build","",True )
	End
	
	Method BuildApp:Bool( config:String,target:String,sourceAction:String )
	
		Local buildDoc:=BuildDoc()
		If Not buildDoc Return False
		
		Local product:=BuildProduct.GetBuildProduct( buildDoc.Path,target,False )
		If Not product Return False
		
		Local opts:=product.GetMx2ccOpts()
		
		Local run:=(sourceAction="run")
		
		Local action:=sourceAction
		If run Then action="build"

		Local cmd:=MainWindow.Mx2ccPath+" makeapp -"+action+" "+opts
		If Verbosed cmd+=" -verbose"
		cmd+=" -config="+config
		cmd+=" -target="+target
		cmd+=" ~q"+buildDoc.Path+"~q"
		
		Local title := sourceAction="build" ? "Building" Else (sourceAction="run" ? "Running" Else "Checking")
		Local msg:=title+" ~ "+target+" ~ "+config+" ~ "+StripDir( buildDoc.Path )
		
		If Not BuildMx2( cmd,msg,sourceAction,buildDoc.Path,True ) Return False
		
		_console.Write("~nDone.")
		
		If Not run
			MainWindow.RestoreConsoleVisibility()
			Return True
		Endif
		
		Local exeFile:=product.GetExecutable()
		If Not exeFile Return True
		
		Select target
		Case "desktop"
			
			MainWindow.ShowStatusBarText( "   App is running now...",True )
			MainWindow.SetStatusBarActive( True )
			MainWindow.ShowStatusBarProgress( MainWindow.OnForceStop,True )
			
			_debugView.DebugApp( exeFile,config )

		Case "emscripten"
		
			Local mserver:=GetEnv( "MX2_MSERVER" )
			If mserver _console.Run( mserver+" ~q"+exeFile+"~q" )
		
		End
		
		Return True
	End
	
	Method OnBuildAndRun()
		
		PreBuild()
		
		If _console.Running Return
		
		BuildApp( _buildConfig,_buildTarget,"run" )
	End
	
	Method OnDebugApp()
	
		PreBuild()
	
		If _console.Running Return
	
		BuildApp( "debug",_buildTarget,"run" )
	End
	
	Method OnBuild()
		
		PreBuild()
		
		If _console.Running Return
	
		BuildApp( _buildConfig,_buildTarget,"build" )
	End
	
	Method OnSemant()
	
		PreSemant()
		
		If _console.Running Return
	
		BuildApp( _buildConfig,_buildTarget,"semant" )
	End
	
	Method OnNextError()
	
		While Not _errors.Empty And _errors.First.removed
			_errors.RemoveFirst()
		Wend
		
		If _errors.Empty Return
		
		_errors.AddLast( _errors.RemoveFirst() )
			
		GotoError( _errors.First )
	End
	
	Method OnLockBuildFile( doc:CodeDocument )
	
		If Not doc Return
		
		If _locked Then SetLockedState( _locked,False )
		
		If doc=_locked
			_locked=Null
			Return
		Endif
		
		_locked=doc
		SetLockedState( _locked,True )
		
		
	End
	
	Method SetLockedState( doc:CodeDocument,locked:Bool )
		
		doc.State=locked ? "+" Else ""
		Local tab:=_docs.FindTab( doc.View )
		If tab Then tab.SetLockedState( locked )
		_docs.CurrentDocumentChanged()
	End
	
	Method OnBuildFileSettings()

		Local buildDoc:=BuildDoc()
		If Not buildDoc Return
		
		local product:=BuildProduct.GetBuildProduct( buildDoc.Path,_buildTarget,True )
	End
	
	Method OnUpdateModules()
		
		If _console.Running Return
	
		BuildModules()
	End
	
	Method OnModuleManager()
	
		If _console.Running Return
	
		Local modman:=New ModuleManager( _console )
		
		modman.Open()
	End
	
	Method OnRebuildHelp()
	
		If _console.Running Return
	
		MakeDocs()
		
		MainWindow.UpdateHelpTree()
	End
	
End
