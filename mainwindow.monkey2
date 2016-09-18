
Namespace ted2go


#Import "assets/about.html@/ted2"
#Import "assets/scripts.json@/ted2"

#Import "assets/newfiles/Simple_Console_App.monkey2@/ted2/newfiles"
#Import "assets/newfiles/Simple_Mojo_App.monkey2@/ted2/newfiles"
#Import "assets/newfiles/Letterboxed_Mojo_App.monkey2@/ted2/newfiles"

Global MainWindow:MainWindowInstance

Class MainWindowInstance Extends Window

	Method New( title:String,rect:Recti,flags:WindowFlags,jobj:JsonObject )
		Super.New( title,rect,flags )
		
		MainWindow=Self
		
		_docsTabView=New TabView( TabViewFlags.DraggableTabs|TabViewFlags.ClosableTabs )
		_browsersTabView=New TabView( TabViewFlags.DraggableTabs )
		_consolesTabView=New TabView( TabViewFlags.DraggableTabs )
		
		_recentFilesMenu=New Menu( "Recent Files..." )
		_closeProjectMenu=New Menu( "Close Project..." )
		
		_docsManager=New DocumentManager( _docsTabView )

		_docsManager.CurrentDocumentChanged+=UpdateKeyView
		
		App.FileDropped+=Lambda( path:String )
			Print "Dropped:"+path
			_docsManager.OpenDocument( path,True )
		End

		_docsManager.DocumentAdded+=Lambda( doc:Ted2Document )
			AddRecentFile( doc.Path )
			UpdateRecentFilesMenu()
		End

		_docsManager.DocumentRemoved+=Lambda( doc:Ted2Document )
			If IsTmpPath( doc.Path ) DeleteFile( doc.Path )
		End

		_buildConsole=New ConsoleExt
		_outputConsole=New ConsoleExt
		_helpView=New HtmlView
'		_helpView.Style=New Style( _helpView.Style )
'		_helpView.Style.Border=New Recti( 0,-4,0,0 )
'		_helpView.Style.BorderColor=App.Theme.GetColor( "content" )
		_helpView.Go( "asset::ted2/about.html" )
		
		_projectView=New ProjectView( _docsManager )
		
		_helpTree=New HelpTree( _helpView )
		
		_debugView=New DebugView( _docsManager,_outputConsole )
		
		_fileActions=New FileActions( _docsManager )
		_editActions=New EditActions( _docsManager )
		_findActions=New FindActions( _docsManager )
		_buildActions=New BuildActions( _docsManager,_buildConsole,_debugView )
		_helpActions=New HelpActions

		_tabMenu=New Menu
		_tabMenu.AddAction( _fileActions.close )
		_tabMenu.AddAction( _fileActions.closeOthers )
		_tabMenu.AddAction( _fileActions.closeToRight )
		_tabMenu.AddSeparator()
		_tabMenu.AddAction( _fileActions.save )
		_tabMenu.AddAction( _fileActions.saveAs )
		_tabMenu.AddSeparator()
		_tabMenu.AddAction( _buildActions.lockBuildFile )
		_tabMenu.AddAction( _buildActions.buildSettings )
		
		_docsTabView.RightClicked+=Lambda()
			_tabMenu.Open()
		End
		
		_docsTabView.CloseClicked+=Lambda( index:Int )

			Local doc:=_docsManager.FindDocument( _docsTabView.TabView( index ) )
			If Not doc.Dirty And Not IsTmpPath( doc.Path )
				doc.Close()
				Return
			Endif
			_docsManager.CurrentDocument=doc
			_fileActions.close.Trigger()
		End

		_tmp=RealPath( "tmp/" )
		
		_newFiles=New Menu( "New..." )
		Local p:=AssetsDir()+"ted2/newfiles/"
		For Local f:=Eachin LoadDir( p )
			Local src:=stringio.LoadString( p+f )
			_newFiles.AddAction( StripExt( f.Replace( "_"," " ) ) ).Triggered=Lambda()
				Local path:=AllocTmpPath( ExtractExt( f ) )
				If Not path Return
				SaveString( src,path )
				Local doc:=_docsManager.OpenDocument( path,True )
			End
		Next
		
		_fileMenu=New Menu( "File" )
		_fileMenu.AddAction( _fileActions.new_ )
		_fileMenu.AddSubMenu( _newFiles )
		_fileMenu.AddAction( _fileActions.open )
		_fileMenu.AddSubMenu( _recentFilesMenu )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _fileActions.close )
		_fileMenu.AddAction( _fileActions.closeOthers )
		_fileMenu.AddAction( _fileActions.closeToRight )
		_fileMenu.AddAction( _fileActions.closeAll )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _fileActions.save )
		_fileMenu.AddAction( _fileActions.saveAs )
		_fileMenu.AddAction( _fileActions.saveAll )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _docsManager.nextDocument )
		_fileMenu.AddAction( _docsManager.prevDocument )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _projectView.openProject )
		_fileMenu.AddSubMenu( _closeProjectMenu )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _fileActions.quit )
		
		_editMenu=New Menu( "Edit" )
		_editMenu.AddAction( _editActions.undo )
		_editMenu.AddAction( _editActions.redo )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.cut )
		_editMenu.AddAction( _editActions.copy )
		_editMenu.AddAction( _editActions.paste )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.selectAll )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _findActions.find )
		_editMenu.AddAction( _findActions.findNext )
		_editMenu.AddAction( _findActions.findPrevious )
		_editMenu.AddAction( _findActions.replace )
		_editMenu.AddAction( _findActions.replaceAll )
		
		_forceStop=New Action( "Force Stop" )
		_forceStop.Triggered=Lambda()
			If _buildConsole.Running
				_buildConsole.Terminate()
			Else If _outputConsole.Running
				_outputConsole.Terminate()
			Endif
		End
		_forceStop.HotKey=Key.F5
		_forceStop.HotKeyModifiers=Modifier.Shift
		
		_buildMenu=New Menu( "Build" )
		_buildMenu.AddAction( _buildActions.buildAndRun )
		_buildMenu.AddAction( _buildActions.build )
		_buildMenu.AddAction( _buildActions.buildSettings )
		_buildMenu.AddSubMenu( _buildActions.targetMenu )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _buildActions.nextError )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _buildActions.lockBuildFile )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _buildActions.updateModules )
		_buildMenu.AddAction( _buildActions.rebuildModules )
		_buildMenu.AddAction( _buildActions.rebuildHelp )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _forceStop )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _buildActions.moduleManager )
		
		_helpMenu=New Menu( "Help" )
		_helpMenu.AddAction( _helpActions.onlineHelp )
		_helpMenu.AddAction( _helpActions.viewManuals )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _helpActions.uploadModules )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _helpActions.about )
		
		_menuBar=New MenuBar
		_menuBar.AddMenu( _fileMenu )
		_menuBar.AddMenu( _editMenu )
		_menuBar.AddMenu( _buildMenu )
		_menuBar.AddMenu( _helpMenu )
		
		_browsersTabView.AddTab( "Files",_projectView,True )
		_browsersTabView.AddTab( "Debug",_debugView,False )
		_browsersTabView.AddTab( "Help",_helpTree,False )
		
		_consolesTabView.AddTab( "Build",_buildConsole,True )
		_consolesTabView.AddTab( "Output",_outputConsole,False )
		_consolesTabView.AddTab( "Documentation",_helpView,False )
		
		_contentView=New DockingView
		_contentView.AddView( _menuBar,"top" )
		_contentView.AddView( _browsersTabView,"right",250,True )
		_contentView.AddView( _consolesTabView,"bottom",200,True )
		_contentView.ContentView=_docsTabView
		
		ContentView=_contentView

		OnCreatePlugins() 'init plugins before loadstate, to register doctypes before open last opened files
		
		LoadState( jobj )
		
		App.Idle+=OnAppIdle
		
		If GetFileType( "bin/ted2.state.json" )=FileType.None _helpActions.about.Trigger()
		
	End
	
	Method Terminate()
	
		SaveState()
		
		App.Terminate()
	End

	'Use these as macos still seems to have problems running requesters on a fiber - stacksize?
	'
	Method RequestFile:String( title:String,path:String,save:Bool )
	
		Local future:=New Future<String>
		
		App.Idle+=Lambda()
		
			future.Set( requesters.RequestFile( title,,save,path ) )
		End
		
		Return future.Get()
	End

	Method RequestDir:String( title:String,dir:String )
		
		Local future:=New Future<String>
		
		App.Idle+=Lambda()
			future.Set( requesters.RequestDir( title,dir ) )
		End
		
		Return future.Get()
	End
	
	Method AllocTmpPath:String( ext:String )
	
		For Local i:=1 Until 10
			Local path:=_tmp+"untitled"+i+ext
			If GetFileType( path )=FileType.None Return path
		Next

		Return ""
	End
	
	Method IsTmpPath:Bool( path:String )

		Return path.StartsWith( _tmp )
	End

	Private
		
	Method DeleteTmps()
	
		For Local f:=Eachin LoadDir( _tmp )
			Local path:=_tmp+f
			If GetFileType( path )=FileType.File
				If Not _docsManager.FindDocument( path ) DeleteFile( path )
			Else
				DeleteDir( path,True )
			Endif
		Next
		
	End
	
	Public
	
	Method ShowProjectView()
		_browsersTabView.CurrentView=_projectView
	End
	
	Method ShowDebugView()
		_browsersTabView.CurrentView=_debugView
	End
	
	Method ShowBuildConsole( vis:Bool=True )
		If vis _consolesTabView.Visible=True
		_consolesTabView.CurrentView=_buildConsole
	End
	
	Method ShowOutputConsole( vis:Bool=True )
		If vis _consolesTabView.Visible=True
		_consolesTabView.CurrentView=_outputConsole
	End
	
	Method ShowHelpView()
		_consolesTabView.Visible=True
		_consolesTabView.CurrentView=_helpView
	End
	
	Method ShowQuickHelp( ident:String )
		_helpTree.QuickHelp( ident )
	End
	
	Method ShowHelp( url:String  )
		ShowHelpView()
		_helpView.Go( url )
		_helpView.Scroll=New Vec2i( 0,0 )
	End
	
	Method UpdateHelpTree()
		_helpTree.Update()
	End
	
	Method ReadError( path:String )
		Alert( "I/O Error reading file '"+path+"'" )
	End
	
	Method WriteError( path:String )
		Alert( "I/O Error writing file '"+path+"'" )
	End

	Method UpdateKeyView()

		Local doc:=_docsManager.CurrentDocument
		If Not doc Return
		
		If doc.TextView doc.TextView.MakeKeyView() Else doc.View.MakeKeyView()
	End
	
	Method SaveState()
	
		Local jobj:=New JsonObject
		
		jobj["windowRect"]=ToJson( Frame )
		jobj["browserSize"]=New JsonNumber( _contentView.GetViewSize( _browsersTabView ) )
		jobj["consoleSize"]=New JsonNumber( _contentView.GetViewSize( _consolesTabView ) )
		
		Local recent:=New JsonArray
		For Local path:=Eachin _recentFiles
			recent.Add( New JsonString( path ) )
		End
		jobj["recentFiles"]=recent
		
		_docsManager.SaveState( jobj )
		_buildActions.SaveState( jobj )
		_projectView.SaveState( jobj )
		
		SaveString( jobj.ToJson(),"bin/ted2.state.json" )
	End

	Private
	
	Method LoadState( jobj:JsonObject )
	
		'for 'reload' later...
		_projectView.ProjectOpened-=UpdateCloseProjectMenu
		
		If jobj.Contains( "browserSize" ) _contentView.SetViewSize( _browsersTabView,jobj.GetNumber( "browserSize" ) )
		If jobj.Contains( "consoleSize" ) _contentView.SetViewSize( _consolesTabView,jobj.GetNumber( "consoleSize" ) )
			
		If jobj.Contains( "recentFiles" )
			For Local file:=Eachin jobj.GetArray( "recentFiles" )
				Local path:=file.ToString()
				If GetFileType( path )<>FileType.File Continue
				_recentFiles.Push( path )
			Next
		End
		
		_docsManager.LoadState( jobj )
		_buildActions.LoadState( jobj )
		_projectView.LoadState( jobj )
		
		If Not _projectView.OpenProjects _projectView.OpenProject( CurrentDir() )
		
		_projectView.ProjectOpened+=UpdateCloseProjectMenu
		
		UpdateRecentFilesMenu()
		
		UpdateCloseProjectMenu()

		DeleteTmps()
	End
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		Select event.Type
		Case EventType.KeyDown
			Select event.Key
			Case Key.Escape
				If event.Modifiers & Modifier.Shift
					_browsersTabView.Visible=Not _browsersTabView.Visible
				Else
					_consolesTabView.Visible=Not _consolesTabView.Visible
				Endif
			End
		End
	End
	
	Method OnWindowEvent( event:WindowEvent ) Override

		Select event.Type
		Case EventType.WindowClose
			SaveState()
			_fileActions.quit.Trigger()
		Default
			Super.OnWindowEvent( event )
		End
	
	End
	
	Method OnRender( canvas:Canvas ) Override
		
		'RequestRender()
		Super.OnRender( canvas )
		
	End
	
	
	Private
	
	Field _docsManager:DocumentManager
	Field _fileActions:FileActions
	Field _editActions:EditActions
	Field _findActions:FindActions
	Field _buildActions:BuildActions
	Field _helpActions:HelpActions
	
	Field _buildConsole:Console
	Field _outputConsole:Console
	Field _helpView:HtmlView

	Field _projectView:ProjectView
	Field _debugView:DebugView
	Field _helpTree:HelpTree

	Field _docsTabView:TabView
	Field _consolesTabView:TabView
	Field _browsersTabView:TabView
	
	Field _tmp:String
	Field _forceStop:Action

	Field _tabMenu:Menu
	Field _newFiles:Menu
	Field _fileMenu:Menu
	Field _editMenu:Menu
	Field _buildMenu:Menu
	Field _helpMenu:Menu
	Field _menuBar:MenuBar
	
	Field _contentView:DockingView

	Field _recentFiles:=New StringStack
	
	Field _recentFilesMenu:Menu
	Field _closeProjectMenu:Menu
	
	Method ToJson:JsonValue( rect:Recti )
		Return New JsonArray( New JsonValue[]( New JsonNumber( rect.min.x ),New JsonNumber( rect.min.y ),New JsonNumber( rect.max.x ),New JsonNumber( rect.max.y ) ) )
	End
	
	Method ToRecti:Recti( value:JsonValue )
		Local json:=value.ToArray()
		Return New Recti( json[0].ToNumber(),json[1].ToNumber(),json[2].ToNumber(),json[3].ToNumber() )
	End
	
	Method AddRecentFile( path:String )
	
		_recentFiles.Remove( path )
		_recentFiles.Insert( 0,path )
		
		If _recentFiles.Length>20 _recentFiles.Resize( 20 )
	End
	
	Method UpdateRecentFilesMenu()
	
		_recentFilesMenu.Clear()
		
		Local recentFiles:=New StringStack
		
		For Local path:=Eachin _recentFiles
			If GetFileType( path )<>FileType.File Continue
		
			_recentFilesMenu.AddAction( path ).Triggered=Lambda()
				_docsManager.OpenDocument( path,True )
			End
			
			recentFiles.Add( path )
		Next
		
		_recentFiles=recentFiles
	End
	
	Method UpdateCloseProjectMenu( dir:String="" )
	
		_closeProjectMenu.Clear()
		
		For Local dir:=Eachin _projectView.OpenProjects
		
			_closeProjectMenu.AddAction( dir ).Triggered=Lambda()
			
				_projectView.CloseProject( dir )
				
				UpdateCloseProjectMenu()
			End
			
		Next
	End
	
	Method OnAppIdle()
	
		_docsManager.Update()
		_fileActions.Update()
		_editActions.Update()
		_findActions.Update()
		_buildActions.Update()
		
		_forceStop.Enabled=_buildConsole.Running Or _outputConsole.Running
	
		App.Idle+=OnAppIdle
		
		GCCollect()	'thrash that GC!
	End
	
End


Private

Function OnCreatePlugins()

	For Local plugin:=Eachin Plugin.PluginsOfType<Plugin>()
		PluginBridge.OnCreate(plugin)
	Next
	
End


Class PluginBridge Extends Plugin

	Function OnCreate(plugin:Plugin)
		plugin.OnCreate() 'use protected method
	End
	
End
