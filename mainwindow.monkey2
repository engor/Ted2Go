
Namespace ted2go


#Import "assets/about.html@/ted2"
#Import "assets/aboutTed2Go.html@/ted2"

#Import "assets/themes/@/themes"

#Import "assets/newfiles/@/ted2/newfiles"

Global MainWindow:MainWindowInstance

Class MainWindowInstance Extends Window

	Method New( title:String,rect:Recti,flags:WindowFlags,jobj:JsonObject )
		Super.New( title,rect,flags )
		
		MainWindow=Self
		
		_tmp=RealPath( "tmp/" )
		
#If __TARGET__="macos"
		_mx2cc="bin/mx2cc_macos"
#Else If __TARGET__="windows"
		_mx2cc="bin/mx2cc_windows.exe"
#Else If __TARGET__="raspbian"
		_mx2cc="bin/mx2cc_raspbian"
#Else
		_mx2cc="bin/mx2cc_linux"
#Endif
		_mx2cc=RealPath( _mx2cc )
		
		_modsDir=RealPath( "modules/" )
		
		_docsTabView=New TabViewExt( TabViewFlags.DraggableTabs|TabViewFlags.ClosableTabs )
		
		_browsersTabView=New TabView( TabViewFlags.DraggableTabs )
		_consolesTabView=New TabView( TabViewFlags.DraggableTabs )
		
		_recentFilesMenu=New Menu( "Recent files..." )
		_closeProjectMenu=New Menu( "Close project..." )
		
		_docBrowser=New DockingView
		
		_docsManager=New DocumentManager( _docsTabView,_docBrowser )

		_docsManager.CurrentDocumentChanged+=UpdateKeyView
		
		App.FileDropped+=Lambda( path:String )
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
		
		_findConsole=New TreeViewExt
		_findConsole.NodeClicked+=Lambda( node:TreeView.Node )
		
			Local n:=Cast<NodeWithData<FileJumpData>>( node )
			If Not n Return
			
			Local data:=n.data
			
			Local doc:=_docsManager.OpenDocument( data.path,True )
			If Not doc Return
			
			Local tv:=doc.TextView
			If Not tv Return
			
			UpdateWindow( False )
			
			tv.SelectText( data.pos,data.pos+data.len ) 'set cursor here
		End
		
		'Help tab
		
		_helpView=New HtmlViewExt
		_helpViewDocker=New DockingView
		Local bar:=New ToolBarExt
		bar.MaxSize=New Vec2i( 300,30 )
		bar.AddIconicButton(
			ThemeImages.Get( "docbar/home.png" ),
			Lambda()
				_helpView.ClearHistory()
				_helpView.Navigate( "asset::ted2/about.html" )
			End,
			"Home" )
		bar.AddIconicButton(
			ThemeImages.Get( "docbar/back.png" ),
			Lambda()
				_helpView.Back()
			End,
			"Back" )
		bar.AddIconicButton(
			ThemeImages.Get( "docbar/forward.png" ),
			Lambda()
				_helpView.Forward()
			End,
			"Forward" )
		bar.AddSeparator()
		bar.AddSeparator()
		Local label:=New Label
		bar.AddView( label,"left" )
		
		_helpView.Navigated+=Lambda( url:String )
			
			label.Text=url
		End
		
		_helpViewDocker.AddView( bar,"top" )
		_helpViewDocker.ContentView=_helpView
		
		_helpView.Navigate( "asset::ted2/about.html" )
		
		_projectView=New ProjectView( _docsManager )
		
		_helpTree=New HelpTree( _helpView )
		
		_debugView=New DebugView( _docsManager,_outputConsole )
		
		_fileActions=New FileActions( _docsManager )
		_editActions=New EditActions( _docsManager )
		_findActions=New FindActions( _docsManager,_projectView,_findConsole )
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

		
		'File menu
		'
		_newFiles=New Menu( "New..." )
		Local p:=AssetsDir()+"ted2/newfiles/"
		For Local f:=Eachin LoadDir( p )
			Local src:=stringio.LoadString( p+f )
			_newFiles.AddAction( StripExt( f.Replace( "_"," " ) ) ).Triggered=Lambda()
				Local path:=AllocTmpPath( "untitled",ExtractExt( f ) )
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
		_fileMenu.AddAction( _fileActions.prefs )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _fileActions.quit )
		
		'Edit menu
		'
		_editMenu=New Menu( "Edit" )
		_editMenu.AddAction( _editActions.undo )
		_editMenu.AddAction( _editActions.redo )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.cut )
		_editMenu.AddAction( _editActions.copy )
		_editMenu.AddAction( _editActions.paste )
		_editMenu.AddAction( _editActions.selectAll )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.wordWrap )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _findActions.find )
		_editMenu.AddAction( _findActions.findNext )
		_editMenu.AddAction( _findActions.findPrevious )
		_editMenu.AddAction( _findActions.replace )
		_editMenu.AddAction( _findActions.replaceAll )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _findActions.findInFiles )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.gotoLine )
		_editMenu.AddAction( _editActions.gotoDeclaration )
		
		'Build menu
		'
		_forceStop=New Action( "Force Stop" )
		_forceStop.Triggered=OnForceStop
		_forceStop.HotKey=Key.F5
		_forceStop.HotKeyModifiers=Modifier.Shift
		
		'
		_buildActions.PreBuild+=OnForceStop		
		
		_buildMenu=New Menu( "Build" )
		_buildMenu.AddAction( _buildActions.buildAndRun )
		_buildMenu.AddAction( _buildActions.build )
		_buildMenu.AddAction( _buildActions.semant )
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
		
		'View menu
		'
		_themesMenu=CreateThemesMenu( "Themes..." )
		
		_viewMenu=New Menu( "View" )
		AddZoomActions( _viewMenu )
		_viewMenu.AddSeparator()
		_viewMenu.AddSubMenu( _themesMenu )
		
		'Help menu
		'
		_helpMenu=New Menu( "Help" )
		_helpMenu.AddAction( _helpActions.onlineHelp )
		_helpMenu.AddAction( _helpActions.viewManuals )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _helpActions.uploadModules )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _helpActions.about )
		_helpMenu.AddAction( _helpActions.aboutTed2go )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _helpActions.makeBetter )
		
		'Menu bar
		'
		_menuBar=New MenuBar
		_menuBar.AddMenu( _fileMenu )
		_menuBar.AddMenu( _editMenu )
		_menuBar.AddMenu( _buildMenu )
		_menuBar.AddMenu( _viewMenu )
		_menuBar.AddMenu( _helpMenu )
		
		'Tool Bar
		'
		If Prefs.MainToolBarVisible
			_toolBar=New ToolBarExt
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/new_file.png" ),_fileActions.new_.Triggered,"New file (Ctrl+N)" )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/open_file.png" ),_fileActions.open.Triggered,"Open file... (Ctrl+O)" )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/open_project.png" ),_projectView.openProject.Triggered,"Open project..." )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/save_all.png" ),_fileActions.saveAll.Triggered,"Save all (Ctrl+Shift+S)" )
			_toolBar.AddSeparator()
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/undo.png" ),_editActions.undo.Triggered,"Undo (Ctrl+Z)" )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/redo.png" ),_editActions.redo.Triggered,"Redo (Ctrl+Y)" )
			_toolBar.AddSeparator()
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/check.png" ),_buildActions.semant.Triggered,"Check errors (F7)" )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/build.png" ),_buildActions.build.Triggered,"Build (F6)" )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/run.png" ),_buildActions.buildAndRun.Triggered,"Run (F5)" )
			_toolBar.AddSeparator()
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/options.png" ),_buildActions.buildSettings.Triggered,"Target settings" )
			_toolBar.AddSeparator()
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/find.png" ),_findActions.find.Triggered,"Find (Ctrl+F)" )
			
		Endif
		
		_browsersTabView.AddTab( "Project",_projectView,True )
		_browsersTabView.AddTab( "Source",_docBrowser,False )
		_browsersTabView.AddTab( "Debug",_debugView,False )
		_browsersTabView.AddTab( "Help",_helpTree,False )
		
		_consolesTabView.AddTab( "Build",_buildConsole,True )
		_consolesTabView.AddTab( "Output",_outputConsole,False )
		_consolesTabView.AddTab( "Docs",_helpViewDocker,False )
		_consolesTabView.AddTab( "Find",_findConsole,False )
		
		_statusBar=New StatusBar
		
		_contentView=New DockingView
		_contentView.AddView( _menuBar,"top" )
		
		If _toolBar
'			Local vv:=New DockingView
'			vv.AddView( _toolBar,"left" )
'			
'			Local better:=New DockingView
'			better.AddView( New Label( "Make me better" ),"left" )
'			vv.AddView( better,"right" )
			
			_contentView.AddView( _toolBar,"top" )
		Endif
		
		_contentView.AddView( _statusBar,"bottom" )
		_contentView.AddView( _browsersTabView,"right",250,True )
		_contentView.AddView( _consolesTabView,"bottom",200,True )
		_contentView.ContentView=_docsTabView
		
		ContentView=_contentView

		OnCreatePlugins() 'init plugins before loadstate, to register doctypes before open last opened files
		
		LoadState( jobj )
		
		App.MouseEventFilter+=ThemeScaleMouseFilter
				
		App.Idle+=OnAppIdle
		
		If GetFileType( "bin/ted2.state.json" )=FileType.None _helpActions.about.Trigger()
		
	End
	
	Method OnFind()
		_findActions.find.Trigger()
	End
	
	Method OnFindPrev()
		_findActions.findPrevious.Trigger()
	End
	
	Method OnFindNext()
		_findActions.findNext.Trigger()
	End
	
	Property Mx2ccPath:String()
	
		Return _mx2cc
	End
	
	Property ModsPath:String()
	
		Return _modsDir
	End
	
	Property OverrideTextMode:Bool()
	
		Return _ovdMode
	Setter( value:Bool )
		
		If value=_ovdMode Return
		_ovdMode=value
		SetStatusBarInsertMode( Not _ovdMode )
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
	
	Method AllocTmpPath:String( ident:String,ext:String )
	
		For Local i:=1 Until 100
			Local path:=_tmp+ident+i+ext
			If GetFileType( path )<>FileType.None Continue
			If CreateFile( path ) Return path
		Next

		Return ""
	End
	
	Method IsTmpPath:Bool( path:String )

		Return path.StartsWith( _tmp )
	End

	Method ShowStatusBarText( text:String )
	
		_statusBar.SetText( text )
	End
	
	Method SetStatusBarInsertMode( ins:Bool )
	
		_statusBar.SetInsMode( ins )
	End
	
	Method ShowStatusBarLineInfo( tv:TextView )
		
		Local line:=tv.Document.FindLine( tv.Cursor )
		Local pos:=tv.Cursor-tv.Document.StartOfLine( line )
		line+=1
		pos+=1
		_statusBar.SetLineInfo( "Ln : "+line+"  Col : "+pos )
	End
	
	Method ShowStatusBarProgress( cancelCallback:Void() )
	
		_statusBar.Cancelled=cancelCallback
		_statusBar.ShowProgress()
	End
	
	Method HideStatusBarProgress()
	
		_statusBar.HideProgress()
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
		_consolesTabView.CurrentView=_helpViewDocker
	End
	
	Method ShowFindResults()
		_consolesTabView.Visible=True
		_consolesTabView.CurrentView=_findConsole
	End
	
	Method ShowQuickHelp()
		
		Local doc:=Cast<CodeDocumentView>( _docsManager.CurrentTextView )
		If Not doc Return
		
		Local ident:=doc.FullIdentAtCursor()
		
		If Not ident Return
		
		Local parser:=ParsersManager.Get( doc.FileType )
		Local item:=parser.ItemAtScope( ident,doc.FilePath,doc.LineNumAtCursor )
		If item
			Local s:=item.Namespac
			If s
				Local i:=s.Find( "." )
				If i<>-1 Then s=s.Slice( 0,i )
			Endif
			Local ident2:="",parentIdent:=""
			ident=s+":"+item.Namespac+"."
			If item.Parent
				If item.Parent.IsLikeClass
					parentIdent=item.Parent.Ident
					ident2=s+":"+parentIdent+"."+item.Ident
				Endif
				ident+=item.Parent.Ident+"."
			Endif
			ident+=item.Ident
			
			If ident=_helpIdent
				If item.IsModuleMember
					Local url:=_helpTree.PageUrl( ident )
					If GetFileType( url )<>FileType.File Then url=_helpTree.PageUrl( ident2 )
					
					If GetFileType( url )<>FileType.File
						Local ext:=ExtractExt( url )
						Repeat
							Local i:=url.FindLast( "-" )
							If i=-1
								url=""
								Exit
							Endif
							url=url.Slice( 0,i )+ext
						Forever
					Endif
					If url ShowHelp( url )
				Else
					GotoCodePosition( item.FilePath,item.ScopeStartPos )
				Endif
			Else
				Local nmspace:=item.Namespac
				If parentIdent nmspace+="."+parentIdent
				ShowStatusBarText( "("+item.KindStr+") "+item.Text+"    |  "+nmspace+"  |  "+StripDir( item.FilePath )+"  |  line "+(item.ScopeStartPos.x+1) )
			Endif
			
			_helpIdent=ident
			
		Elseif KeywordsManager.Get( doc.FileType ).Contains( ident )
			
			ShowStatusBarText( "(keyword) "+ident )
		
		Else
			
			_helpTree.QuickHelp( ident )
				
		Endif
		
	End
	
	Method ShowHelp( url:String  )
		ShowHelpView()
		_helpView.Navigate( url )
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
		
		If doc.TextView
			doc.TextView.MakeKeyView()
			ShowStatusBarLineInfo( doc.TextView )
		Else
			doc.View.MakeKeyView()
		Endif
	End
	
	Method GotoCodePosition( docPath:String, pos:Vec2i )
		
		Local doc:=Cast<CodeDocument>( _docsManager.OpenDocument( docPath,True ) )
		If Not doc Return
		
		Local tv := Cast<CodeTextView>( doc.TextView )
		If Not tv Return
		
		UpdateWindow( False )
		
		tv.GotoPosition( pos )
	End
	
	Method GotoDeclaration()
	
		Local doc:=Cast<CodeDocument>( _docsManager.CurrentDocument )
		If Not doc Return
		
		doc.GotoDeclaration()
	End
	
	Method SaveState()
	
		Local jobj:=New JsonObject
		
		jobj["windowRect"]=ToJson( Frame )
		jobj["browserSize"]=New JsonNumber( Int( _contentView.GetViewSize( _browsersTabView ) ) )
		jobj["consoleSize"]=New JsonNumber( Int( _contentView.GetViewSize( _consolesTabView ) ) )
		
		Local recent:=New JsonArray
		For Local path:=Eachin _recentFiles
			recent.Add( New JsonString( path ) )
		End
		jobj["recentFiles"]=recent
		
		jobj["theme"]=New JsonString( _theme )
		
		jobj["themeScale"]=New JsonNumber( App.Theme.Scale.y )
		
		If _mx2ccDir jobj["mx2ccDir"]=New JsonString( _mx2ccDir )
		
		_docsManager.SaveState( jobj )
		_buildActions.SaveState( jobj )
		_projectView.SaveState( jobj )
		
		Prefs.SaveState( jobj )
		
		SaveString( jobj.ToJson(),"bin/ted2.state.json" )
	End

	Method OpenDocument( path:String )
	
		_docsManager.OpenDocument( path,True )
	End
	

	Private
	
	Field _inited:=False
	Field _helpIdent:String
	
	Method OnRender( canvas:Canvas ) Override
	
		If Not _inited
			_inited=True
			OnInit()
		Endif
		Super.OnRender( canvas )
	End
	
	Method OnInit()
		
		' need to make visible after layout
		_docsTabView.EnsureVisibleCurrentTab()
	End
	
	Method OnForceStop()
		
		If _buildConsole.Running
			_buildConsole.Terminate()
			HideStatusBarProgress()
		Else If _outputConsole.Running
			_outputConsole.Terminate()
		Endif
	End
	
	Method LoadState( jobj:JsonObject )
	
		If jobj.Contains( "browserSize" ) _contentView.SetViewSize( _browsersTabView,jobj.GetNumber( "browserSize" ) )

		If jobj.Contains( "consoleSize" ) _contentView.SetViewSize( _consolesTabView,jobj.GetNumber( "consoleSize" ) )
			
		If jobj.Contains( "recentFiles" )
			For Local file:=Eachin jobj.GetArray( "recentFiles" )
				Local path:=file.ToString()
				If GetFileType( path )<>FileType.File Continue
				_recentFiles.Push( path )
			Next
		End
		
		If jobj.Contains( "theme" ) _theme=jobj.GetString( "theme" )
		
		If jobj.Contains( "themeScale" )
			_themeScale=jobj.GetNumber( "themeScale" )
			App.Theme.Scale=New Vec2f( _themeScale,_themeScale )
		Endif
		
		If jobj.Contains( "mx2ccDir" )
			_mx2ccDir=jobj.GetString( "mx2ccDir" )
			If Not _mx2ccDir.EndsWith( "/" ) _mx2ccDir+="/"
			_mx2cc=_mx2ccDir+StripDir( _mx2cc )
		Endif
		
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
			Case Key.Keypad1
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
	
	
	Private

	Field _tmp:String
	Field _mx2cc:String
	Field _mx2ccDir:String
	Field _modsDir:String
	
	Field _toolBar:ToolBarExt
	Field _docsManager:DocumentManager
	Field _fileActions:FileActions
	Field _editActions:EditActions
	Field _findActions:FindActions
	Field _buildActions:BuildActions
	Field _helpActions:HelpActions
	
	Field _buildConsole:Console
	Field _outputConsole:Console
	Field _helpView:HtmlViewExt
	Field _helpViewDocker:DockingView
	Field _findConsole:TreeViewExt
	
	Field _projectView:ProjectView
	Field _docBrowser:DockingView
	Field _debugView:DebugView
	Field _helpTree:HelpTree

	Field _docsTabView:TabViewExt
	Field _consolesTabView:TabView
	Field _browsersTabView:TabView
	
	Field _forceStop:Action

	Field _tabMenu:Menu
	Field _newFiles:Menu
	Field _fileMenu:Menu
	Field _editMenu:Menu
	Field _viewMenu:Menu
	Field _buildMenu:Menu
	Field _helpMenu:Menu
	Field _menuBar:MenuBar
	
	Field _themesMenu:Menu
	
	Field _theme:String="default"
	Field _themeScale:Float=1
	
	Field _contentView:DockingView

	Field _recentFiles:=New StringStack
	
	Field _recentFilesMenu:Menu
	Field _closeProjectMenu:Menu
	Field _statusBar:StatusBar
	Field _ovdMode:=False
	
	
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
	
	Method AddZoomActions( menu:Menu )
		
		menu.AddAction( "Zoom in" ).Triggered=Lambda()
			If _themeScale>=4 Return
			
			_themeScale+=.125

			App.Theme.Scale=New Vec2f( _themeScale,_themeScale )
		End
		
		menu.AddAction( "Zoom out" ).Triggered=Lambda()
			If _themeScale<=.5 Return
			
			_themeScale-=.125

			App.Theme.Scale=New Vec2f( _themeScale,_themeScale )
		End
		
		menu.AddAction( "Reset zoom" ).Triggered=Lambda()
		
			_themeScale=1
			
			App.Theme.Scale=New Vec2f( _themeScale,_themeScale )
		End
	End

	Method ThemeScaleMouseFilter( event:MouseEvent )
	
		If event.Eaten Return
			
		If event.Type=EventType.MouseWheel And event.Modifiers & Modifier.Menu
			
			If event.Wheel.y>0
				If _themeScale<4 _themeScale+=0.125
			Else
				If _themeScale>.5 _themeScale-=0.125
			Endif
				
			App.Theme.Scale=New Vec2f( _themeScale,_themeScale )

			event.Eat()
				
		Else If event.Type=EventType.MouseDown And event.Button=MouseButton.Middle And event.Modifiers & Modifier.Menu
			
			_themeScale=1

			App.Theme.Scale=New Vec2f( _themeScale,_themeScale )
			
			event.Eat()
		Endif
		
	End
	
	Method CreateThemesMenu:Menu( text:String )
	
		Local menu:=New Menu( text )
		
		Local themes:=JsonObject.Load( "theme::themes.json" )
		If Not themes Return menu
		
		For Local it:=Eachin themes
			Local name:=it.Key
			Local value:=it.Value.ToString()
			menu.AddAction( name ).Triggered=Lambda()
				_theme=value
				App.Theme.Load( _theme,New Vec2f( _themeScale ) )
				SaveState()
			End
		Next
		
		Return menu
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
	
	#rem
	Local dialog:=New ProgressDialog( "Parsing modules...","+" )
	dialog.MinSize=New Vec2i( 256,128 )
	dialog.Open()
	
	Local onParse:=Lambda( file:String )
		dialog.Text=StripExt( StripDir( file ) )+"~n~nYou can work while parsing."
	End
	
	Monkey2Parser.OnParseModule+=onParse
	
	Monkey2Parser.OnDoneParseModules += Lambda()
		dialog.Close()
		Monkey2Parser.OnParseModule-=onParse
	End
	#end
	
	For Local plugin:=Eachin Plugin.PluginsOfType<Plugin>()
		PluginBridge.OnCreate(plugin)
	Next
	
End


Class PluginBridge Extends Plugin

	Function OnCreate(plugin:Plugin)
		plugin.OnCreate() 'use protected method
	End
	
End
