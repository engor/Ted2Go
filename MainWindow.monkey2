
Namespace ted2go


#Import "assets/about.html@/ted2"
#Import "assets/aboutTed2Go.html@/ted2"

#Import "assets/themes/@/themes"

#Import "assets/newfiles/@/ted2/newfiles"

#Import "assets/fonts/@/fonts"

#Import "assets/themes/irc/@/themes/irc"


Global MainWindow:MainWindowInstance

Class MainWindowInstance Extends Window
	
	Field SizeChanged:Void()
	Field Rendered:Void()
	
	Method New( title:String,rect:Recti,flags:WindowFlags,jobj:JsonObject )
		Super.New( title,rect,flags )
		
		MainWindow=Self
		
		UpdateToolsPaths()
		
		LiveTemplates.Load()
		
		_docsTabView=New TabViewExt( TabViewFlags.DraggableTabs|TabViewFlags.ClosableTabs )
		
		_browsersTabView=New TabView( TabViewFlags.DraggableTabs )
		_browsersTabView.Style=GetStyle( "ProjectTabView" )
		_consolesTabView=New TabView( TabViewFlags.DraggableTabs )
		
		_recentFilesMenu=New MenuExt( "Recent files" )
		_recentProjectsMenu=New MenuExt( "Recent projects" )
		_closeProjectMenu=New MenuExt( "Close project" )
		
		_docBrowser=New DockingView
		
		_docsManager=New DocumentManager( _docsTabView,_docBrowser )

		_docsManager.CurrentDocumentChanged+=Lambda()
			
			UpdateKeyView()
			CodeDocument.HideAutocomplete()
		End
		
		App.FileDropped+=Lambda( path:String )
			
			OnFileDropped( path )
		End

		_docsManager.DocumentAdded+=Lambda( doc:Ted2Document )
			AddRecentFile( doc.Path )
			SaveState()
		End

		_docsManager.DocumentRemoved+=Lambda( doc:Ted2Document )
			If IsTmpPath( doc.Path ) DeleteFile( doc.Path )
			SaveState()
		End
		
		'IRC tab
		
		_ircView=New IRCView
		_ircView.introScreen.Text="Hang out with other Monkey 2 users"
		_ircView.introScreen.OnNickChange+=Lambda( nick:String )
			Prefs.IrcNickname=nick
		End
		
		SetupChatTab()
		
		If Prefs.IrcConnect Then _ircView.introScreen.Connect()
		
		'Build tab
		
		_buildConsole=New ConsoleExt
		
		'Output tab
		
		_outputConsole=New ConsoleExt
		Local bar:=New ToolBarExt
		bar.MaxSize=New Vec2i( 300,30 )
		
		Local label:=New Label( "Filter:" )
		bar.AddView( label,"left" )
		Local editFilter:=New TextField()
		editFilter.Style=GetStyle( "TextFieldBordered" )
		editFilter.CursorType=CursorType.Line
		editFilter.CursorBlinkRate=2.5
		bar.AddView( editFilter,"left",200 )
		editFilter.TextChanged+=Lambda()
		
			Local t:=editFilter.Text
			_outputConsole.SetFilter( t )
		End
		
		bar.AddSeparator()
		
		bar.AddIconicButton(
			ThemeImages.Get( "outputbar/clean.png" ),
			Lambda()
				_outputConsole.ClearAll()
			End,
			"Clear all" )
		
		Local it:=bar.AddIconicButton(
			ThemeImages.Get( "outputbar/wrap.png" ),
			Lambda()
				_outputConsole.WordWrap=Not _outputConsole.WordWrap
			End,
			"Word wrap" )
		it.ToggleMode=True
		
		_outputConsoleView=New DockingView
		_outputConsoleView.AddView( bar,"top" )
		_outputConsoleView.ContentView=_outputConsole
		
		
		'Find tab
		
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
		_helpConsole=New DockingView
		bar=New ToolBarExt
		bar.MaxSize=New Vec2i( 300,30 )
		bar.AddIconicButton(
			ThemeImages.Get( "docbar/home.png" ),
			Lambda()
				_helpView.ClearHistory()
				_helpView.Navigate( AboutPagePath )
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
		label=New Label
		bar.AddView( label,"left" )
		
		_helpView.Navigated+=Lambda( url:String )
			
			label.Text=url
		End
		
		_helpConsole.AddView( bar,"top" )
		_helpConsole.ContentView=_helpView
		
		_helpView.Navigate( AboutPagePath )
		
		_helpTree=New HelpTreeView( _helpView )
		
		_debugView=New DebugView( _docsManager,_outputConsole )
		
		
		_buildActions=New BuildActions( _docsManager,_buildConsole,_debugView )
		_buildActions.ErrorsOccured+=Lambda( errors:BuildError[] )
			ShowBuildConsole( True )
			_buildActions.GotoError( errors[0] )
			
			_buildErrorsList.Clear()
			For Local err:=Eachin errors
				_buildErrorsList.AddItem( New BuildErrorListViewItem( err ) )
			Next
			_buildErrorsList.Visible=True
		End
		
		' ProjectView
		'
		_projectView=New ProjectView( _docsManager,_buildActions )
		' project opened
		_projectView.ProjectOpened+=Lambda( dir:String )
			AddRecentProject( dir )
			SaveState()
		End
		' project closed
		_projectView.ProjectClosed+=OnProjectClosed
		' find in folder
		_projectView.RequestedFindInFolder+=Lambda( folder:String )
			_findActions.FindInFiles( folder )
		End
		
		_fileActions=New FileActions( _docsManager )
		_editActions=New EditActions( _docsManager )
		_findActions=New FindActions( _docsManager,_projectView,_findConsole )
		_helpActions=New HelpActions
		_viewActions=New ViewActions( _docsManager )
		
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
		_templateFiles=New MenuExt( "Templates" )
		Local p:=AssetsDir()+"ted2/newfiles/"
		For Local f:=Eachin LoadDir( p )
			Local src:=stringio.LoadString( p+f )
			_templateFiles.AddAction( StripExt( f.Replace( "_"," " ) ) ).Triggered=Lambda()
				Local path:=AllocTmpPath( "untitled",ExtractExt( f ) )
				If Not path Return
				SaveString( src,path )
				Local doc:=_docsManager.OpenDocument( path,True )
			End
		Next
		
		_fileMenu=New MenuExt( "File" )
		_fileMenu.AddAction( _fileActions.new_ )
		_fileMenu.AddAction( _fileActions.open )
		_fileMenu.AddSubMenu( _recentFilesMenu )
		_fileMenu.AddSubMenu( _templateFiles )
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
		_fileMenu.AddAction( _projectView.openProject )
		_fileMenu.AddSubMenu( _recentProjectsMenu )
		_fileMenu.AddSubMenu( _closeProjectMenu )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _fileActions.prefs )
		_fileMenu.AddSeparator()
		_fileMenu.AddAction( _fileActions.quit )
		
		'Edit menu
		'
		_editMenu=New MenuExt( "Edit" )
		_editMenu.AddAction( _editActions.undo )
		_editMenu.AddAction( _editActions.redo )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.cut )
		_editMenu.AddAction( _editActions.copy )
		_editMenu.AddAction( _editActions.paste )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.selectAll )
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.wordWrap )
		
		'Find menu
		'
		_findMenu=New MenuExt( "Find" )
		_findMenu.AddAction( _findActions.find )
		_findMenu.AddAction( _findActions.findNext )
		_findMenu.AddAction( _findActions.findPrevious )
		'_findMenu.AddAction( _findActions.replace )
		'_findMenu.AddAction( _findActions.replaceAll )
		_findMenu.AddSeparator()
		_findMenu.AddAction( _findActions.findInFiles )
		
		'View menu
		'
		_viewMenu=New MenuExt( "View" )
		_viewMenu.AddAction( _viewActions.gotoLine )
		_viewMenu.AddAction( _viewActions.gotoDeclaration )
		_viewMenu.AddSeparator()
		_viewMenu.AddAction( _viewActions.comment )
		_viewMenu.AddAction( _viewActions.uncomment )
		_viewMenu.AddSeparator()
		_viewMenu.AddAction( _viewActions.goBack )
		_viewMenu.AddAction( _viewActions.goForward )
		
		'Build menu
		'
		_forceStop=New Action( "Force Stop" )
		_forceStop.Triggered=OnForceStop
		_forceStop.HotKey=Key.F5
		_forceStop.HotKeyModifiers=Modifier.Shift
		
		'
		_buildActions.PreBuild+=OnPreBuild
		_buildActions.PreSemant+=OnPreSemant
		_buildActions.PreBuildModules+=OnPreBuildModules
		
		_buildMenu=New MenuExt( "Build" )
		_buildMenu.AddAction( _buildActions.buildAndRun )
		_buildMenu.AddAction( _buildActions.build )
		_buildMenu.AddAction( _buildActions.semant )
		_buildMenu.AddAction( _buildActions.debugApp )
		_buildMenu.AddSeparator()
		_buildMenu.AddSubMenu( _buildActions.targetMenu )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _forceStop )
		_buildMenu.AddAction( _buildActions.nextError )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _buildActions.lockBuildFile )
		_buildMenu.AddSeparator()
		_buildMenu.AddAction( _buildActions.updateModules )
		_buildMenu.AddAction( _buildActions.moduleManager )
		
		'Window menu
		'
		_windowMenu=New MenuExt( "Window" )
		_windowMenu.AddAction( _docsManager.nextDocument )
		_windowMenu.AddAction( _docsManager.prevDocument )
		_windowMenu.AddSeparator()
		
		_themesMenu=CreateThemesMenu( "Themes" )
		
		AddZoomActions( _windowMenu )
		_windowMenu.AddSeparator()
		_windowMenu.AddSubMenu( _themesMenu )
		
		
		'Help menu
		'
		_helpMenu=New MenuExt( "Help" )
		_helpMenu.AddAction( _helpActions.quickHelp )
		_helpMenu.AddAction( _helpActions.viewManuals )
		If IsBananasShowcaseAvailable() Then _helpMenu.AddAction( _helpActions.bananas )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _buildActions.rebuildHelp )
		_helpMenu.AddSeparator()
'		_helpMenu.AddAction( _helpActions.onlineHelp )
		_helpMenu.AddAction( _helpActions.mx2homepage )
		_helpMenu.AddAction( _helpActions.uploadModules )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _helpActions.about )
		_helpMenu.AddAction( _helpActions.aboutTed2go )
		_helpMenu.AddSeparator()
		_helpMenu.AddAction( _helpActions.makeBetter )
		
		'Menu bar
		'
		_menuBar=New MenuBarExt
		_menuBar.AddMenu( _fileMenu )
		_menuBar.AddMenu( _editMenu )
		_menuBar.AddMenu( _findMenu )
		_menuBar.AddMenu( _viewMenu )
		_menuBar.AddMenu( _buildMenu )
		_menuBar.AddMenu( _windowMenu )
		_menuBar.AddMenu( _helpMenu )
		
		
		_browsersTabView.AddTab( "Project",_projectView,True )
		_browsersTabView.AddTab( "Source",_docBrowser,False )
		_browsersTabView.AddTab( "Debug",_debugView,False )
		_browsersTabView.AddTab( "Help",_helpTree,False )
		
		_buildErrorsList=New ListViewExt
		_buildErrorsList.Visible=False
		_buildErrorsList.OnItemChoosen+=Lambda()
			Local item:=Cast<BuildErrorListViewItem>( _buildErrorsList.CurrentItem )
			_buildActions.GotoError( item.error )
		End
		
		_buildConsoleView=New DockingView
		_buildConsoleView.AddView( _buildErrorsList,"right","400",True )
		_buildConsoleView.ContentView=_buildConsole
		
		_consolesTabView.AddTab( "Build",_buildConsoleView,True )
		_consolesTabView.AddTab( "Output",_outputConsoleView,False )
		_consolesTabView.AddTab( "Docs",_helpConsole,False )
		_consolesTabView.AddTab( "Find",_findConsole,False )
		_consolesTabView.AddTab( "Chat",_ircView,False )
		
		_consolesTabView.CurrentChanged+=OnChatClicked
		
		_statusBar=New StatusBarView
		
		_contentView=New DockingView
		_contentView.AddView( _menuBar,"top" )
		
		ArrangeElements()
		
		ContentView=_contentView

		OnCreatePlugins() 'init plugins before loadstate, to register doctypes before open last opened files
		
		LoadState( jobj )
		
		App.MouseEventFilter+=ThemeScaleMouseFilter
		
		App.Idle+=OnAppIdle
		
		CheckFirstStart()
		
		_enableSaving=True
		
	End
	
	Field PrefsChanged:Void()
	Method OnPrefsChanged()
		
		ArrangeElements()
		PrefsChanged()
		
		SetupChatTab()
		
	End
	
	Method ArrangeElements()
		
		_contentView.RemoveView( _toolBar )
		_contentView.RemoveView( _statusBar )
		_contentView.RemoveView( _browsersTabView )
		_contentView.RemoveView( _consolesTabView )
		
		If Prefs.MainToolBarVisible
			_toolBar=GetMainToolBar()
			_contentView.AddView( _toolBar,"top" )
		Endif
		
		_contentView.AddView( _statusBar,"bottom" )
		
		Local location:=Prefs.MainProjectTabsRight ? "right" Else "left"
		
		Local size:=_browsersTabView.Rect.Width
		If size=0 Then size=300
		_contentView.AddView( _browsersTabView,location,size,True )
		
		size=_consolesTabView.Rect.Height
		If size=0 Then size=150
		_contentView.AddView( _consolesTabView,"bottom",size,True )
		
		_contentView.ContentView=_docsTabView
		
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
	
	Method OnForceStop()
	
		If _buildConsole.Running
			_buildConsole.Terminate()
			HideStatusBarProgress()
			RestoreConsoleVisibility()
		Endif
		If _outputConsole.Running
			_outputConsole.Terminate()
		Endif
	End
	
	Property Mx2ccPath:String()
	
		Return _mx2cc
	End
	
	Property ModsPath:String()
	
		Return _modsDir
	End
	
	Property OverwriteTextMode:Bool()
	
		Return _ovdMode
	Setter( value:Bool )
		
		If value=_ovdMode Return
		_ovdMode=value
		SetStatusBarInsertMode( Not _ovdMode )
	End
	
	Property DocsManager:DocumentManager()
	
		Return _docsManager
	End
	
	Property LockedDocument:CodeDocument()
	
		Return _buildActions.LockedDocument
	End
	
	Property IsTerminating:Bool()
		
		Return _isTerminating
	End
	
	Property ThemeName:String()
		
		Return _theme
	Setter( value:String )
		
		_theme=value
	End
	
	Property AboutPagePath:String()
		
		Local path:=Prefs.MonkeyRootPath+"ABOUT.HTML"
'		If Not IsFileExists( path )
'			path="asset::ted2/about.html"
'		Endif
		Return path
	End
	
	Method Terminate()
		
		_isTerminating=True
		SaveState()
		_enableSaving=False
		OnForceStop() ' kill build process if started
		ProcessReader.StopAll()
		If _ircView Then _ircView.Quit("Closing Ted2Go")
		
		App.Terminate()
	End

	'Use these as macos still seems to have problems running requesters on a fiber - stacksize?
	'
	Method RequestFile:String( title:String,path:String,save:Bool,filter:String="" )
	
		Local future:=New Future<String>
		
		If Not filter Then filter="Monkey2 files:monkey2;Text files:txt;Image files:png,jpg,jpeg;All files:*"
		
		App.Idle+=Lambda()
			
			Local s:=requesters.RequestFile( title,filter,save,path )
			future.Set( s )
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
	
	Method UpdateToolsPaths()
		
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
	End
	
	Method StoreConsoleVisibility()
	
		If Prefs.SiblyMode return
		
		_storedConsoleVisible=_consolesTabView.Visible
		_consoleVisibleCounter=0
	End
	
	Method RestoreConsoleVisibility()
	
		If Prefs.SiblyMode Return
	
		If _consoleVisibleCounter > 0 Return
		_consolesTabView.Visible=_storedConsoleVisible
		RequestRender()
	End
	
	Method IsTmpPath:Bool( path:String )

		Return path.StartsWith( _tmp )
	End
	
	Method SetStatusBarActive( active:Bool )
	
		_statusBar.SetActiveState( active )
	End
	
	Method ShowStatusBarText( text:String,append:Bool=False )
	
		_statusBar.SetText( text,append )
	End
	
	Method SetStatusBarInsertMode( ins:Bool )
	
		_statusBar.SetInsMode( ins )
	End
	
	Method ShowStatusBarLineInfo( tv:TextView )
		
		Local line:=tv.Document.FindLine( tv.Cursor )
		Local pos:=tv.Cursor-tv.Document.StartOfLine( line )
		line+=1
		pos+=1
		_statusBar.SetLineInfo( "Ln : "+line+"    Col : "+pos )
	End
	
	Method ShowStatusBarProgress( cancelCallback:Void(),cancelIconOnly:Bool=False )
	
		_statusBar.Cancelled=cancelCallback
		_statusBar.ShowProgress( cancelIconOnly )
	End
	
	Method HideStatusBarProgress()
	
		_statusBar.HideProgress()
	End
	
	
	Private
	
	Method GetMainToolBar:ToolBarExt()
		
		If _toolBar Return _toolBar
		
		'Tool Bar
		'
		Local newTitle:=GetActionTextWithShortcut( _fileActions.new_ )
		Local openTitle:=GetActionTextWithShortcut( _fileActions.open )
		Local saveTitle:=GetActionTextWithShortcut( _fileActions.save )
		Local saveAllTitle:=GetActionTextWithShortcut( _fileActions.saveAll )
		Local undoTitle:=GetActionTextWithShortcut( _editActions.undo )
		Local redoTitle:=GetActionTextWithShortcut( _editActions.redo )
		Local runTitle:=GetActionTextWithShortcut( _buildActions.buildAndRun )
		Local buildTitle:=GetActionTextWithShortcut( _buildActions.build )
		Local checkTitle:=GetActionTextWithShortcut( _buildActions.semant )
		Local findTitle:=GetActionTextWithShortcut( _findActions.find )
		Local debugTitle:=GetActionTextWithShortcut( _buildActions.debugApp )
		Local cutTitle:=GetActionTextWithShortcut( _editActions.cut )
		Local copyTitle:=GetActionTextWithShortcut( _editActions.copy )
		Local pasteTitle:=GetActionTextWithShortcut( _editActions.paste )
		
		_toolBar=New ToolBarExt
		_toolBar.Style=GetStyle( "MainToolBar" )
		_toolBar.MaxSize=New Vec2i( 10000,40 )
		
		Local goBack:=Lambda()
			Navigator.TryBack()
		End
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/back.png" ),goBack,"Go back (Alt+Left)" )
		
		Local goForw:=Lambda()
			Navigator.TryForward()
		End
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/forward.png" ),goForw,"Go forward (Alt+Right)" )
		_toolBar.AddSeparator()
		
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/new_file.png" ),_fileActions.new_.Triggered,newTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/open_file.png" ),_fileActions.open.Triggered,openTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/open_project.png" ),_projectView.openProject.Triggered,"Open project..." )
		Local icons:=New Image[]( ThemeImages.Get( "toolbar/save.png" ),ThemeImages.Get( "toolbar/save_dirty.png" ) )
		_saveItem=_toolBar.AddIconicButton( icons,_fileActions.save.Triggered,saveTitle )
		icons=New Image[]( ThemeImages.Get( "toolbar/save_all.png" ),ThemeImages.Get( "toolbar/save_all_dirty.png" ) )
		_saveAllItem=_toolBar.AddIconicButton( icons,_fileActions.saveAll.Triggered,saveAllTitle )
		_toolBar.AddSeparator()
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/cut.png" ),_editActions.cut.Triggered,cutTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/copy.png" ),_editActions.copy.Triggered,copyTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/paste.png" ),_editActions.paste.Triggered,pasteTitle )
		_toolBar.AddSeparator()
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/undo.png" ),_editActions.undo.Triggered,undoTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/redo.png" ),_editActions.redo.Triggered,redoTitle )
		_toolBar.AddSeparator()
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/check.png" ),_buildActions.semant.Triggered,checkTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/build.png" ),_buildActions.build.Triggered,buildTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/run.png" ),_buildActions.buildAndRun.Triggered,runTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/debug.png" ),_buildActions.debugApp.Triggered,debugTitle )
		_toolBar.AddSeparator()
		
		Local act:=Lambda()
			_buildActions.targetMenu.Open()
		End
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/options.png" ),act,"Target settings" )
		_toolBar.AddSeparator()
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/find.png" ),_findActions.find.Triggered,findTitle )
		
		Return _toolBar
	End
	
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
	
	Method CheckFirstStart()
		
		If GetFileType( "bin/ted2.state.json" )=FileType.None
			_helpActions.about.Trigger()
			ShowBananasShowcase()
		Endif
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
		_consolesTabView.CurrentView=_buildConsoleView
	End
	
	Method ShowOutputConsole( vis:Bool=True )
		If vis _consolesTabView.Visible=True
		_consolesTabView.CurrentView=_outputConsoleView
	End
	
	Method ShowHelpView()
		_consolesTabView.Visible=True
		_consolesTabView.CurrentView=_helpConsole
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
				If parentIdent Then nmspace+="."+parentIdent
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
	
	Method ShowEditorMenu( tv:TextView )
		
		If Not tv Then tv=_docsManager.CurrentTextView
		If Not tv Return
		
		If Not _editorMenu
			_editorMenu=New MenuExt
			_editorMenu.AddAction( _editActions.cut )
			_editorMenu.AddAction( _editActions.copy )
			_editorMenu.AddAction( _editActions.paste )
		Endif
		
		_editorMenu.Open()
	End
	
	Method UpdateHelpTree()
		_helpTree.Update()
	End
	
	Method ShowBananasShowcase()
		OpenDocument( Prefs.MonkeyRootPath+"bananas/ted2go-showcase/all.bananas" )
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
	
	Method GotoLine()
		
		Local tv:=_docsManager.CurrentTextView
		If Not tv Return
		
		New Fiber( Lambda()
			
			Local line:=RequestInt( "Goto line:","Goto line",tv.CursorLine+1,0,1,tv.Document.NumLines )
			
			If line Then tv.GotoLine( line-1 )
			
			tv.MakeKeyView()
			
		End )
		
	End
	
	
	Method SaveState()
	
		If Not _enableSaving Return

		Local jobj:=New JsonObject
		
		jobj["windowRect"]=ToJson( Frame )
		
		Local vis:Bool
		vis=_browsersTabView.Visible
		jobj["browserVisible"]=New JsonBool( vis )
		jobj["browserTab"]=New JsonString( GetBrowsersTabAsString() )
		If vis Then _browsersSize=Int( _contentView.GetViewSize( _browsersTabView ) )
		If _browsersSize > 0 Then jobj["browserSize"]=New JsonNumber( _browsersSize )
		
		vis=_consolesTabView.Visible
		jobj["consoleVisible"]=New JsonBool( vis )
		jobj["consoleTab"]=New JsonString( GetConsolesTabAsString() )
		If vis Then _consolesSize=Int( _contentView.GetViewSize( _consolesTabView ) ) 
		If _consolesSize > 0 Then jobj["consoleSize"]=New JsonNumber( _consolesSize )
		
		Local recent:=New JsonArray
		For Local path:=Eachin _recentFiles
			recent.Add( New JsonString( path ) )
		End
		jobj["recentFiles"]=recent
		
		recent=New JsonArray
		For Local path:=Eachin _recentProjects
			recent.Add( New JsonString( path ) )
		End
		jobj["recentProjects"]=recent
		
		jobj["theme"]=New JsonString( ThemeName )
		
		jobj["themeScale"]=New JsonNumber( App.Theme.Scale.y )
		
		If _mx2ccDir jobj["mx2ccDir"]=New JsonString( _mx2ccDir )
		
		_docsManager.SaveState( jobj )
		_buildActions.SaveState( jobj )
		_projectView.SaveState( jobj )
		
		Prefs.SaveState( jobj )
		
		SaveString( jobj.ToJson(),"bin/ted2.state.json" )
	End

	Method OpenDocument( path:String,lockIt:Bool=False )
	
		_docsManager.OpenDocument( path,True )
		If lockIt Then _buildActions.LockBuildFile()
		UpdateWindow( True )
	End
	
	Method GetActionFind:Action()
	
		Return _findActions.find
	End
	
	Method GetActionComment:Action()
	
		Return _viewActions.comment
	End
	
	Method GetActionUncomment:Action()
	
		Return _viewActions.uncomment
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
		
		If _resized
			_resized=False
			SizeChanged()
		Endif
		
		UpdateIrcIcon()
		
		Rendered()
		Rendered=Null
	End
	
	Method OnInit()
		
		' need to make visible after layout
		_docsTabView.EnsureVisibleCurrentTab()
	End
	
	Method OnFileDropped( path:String )
		
		If FileExists( path )
			_docsManager.OpenDocument( path,True )
		Else
			_projectView.OpenProject( path )
		Endif
	End
	
	Method OnAppClose()
		
		_fileActions.quit.Trigger()
	End
	
	Method OnPreBuild()
		
		OnForceStop()
		_buildErrorsList.Visible=False
	End
	
	Method OnPreSemant()
	
		_buildErrorsList.Visible=False
	End
	
	Method OnPreBuildModules()
	
		_buildErrorsList.Visible=False
	End
	
	Method OnProjectClosed( dir:String )
		
		UpdateCloseProjectMenu( dir )
		
		Local list:=New Stack<Ted2Document>
		' close all related files
		For Local doc:=Eachin _docsManager.OpenDocuments
			If doc.Path.StartsWith( dir ) Then list.Add( doc )
		Next
		
		_fileActions.CloseFiles( list.ToArray() )
		
		SaveState()
	End
	
	Method OnResized()
		
		' just set a flag here.
		' SizeChanged event will be called inside of OnRender to take re-layout effect.
		_resized=True
	End
	
	Method SetupChatTab()
		
		If Not _ircView Return
		
		_ircView.ircHandler.OnMessage+=Self.OnChatMessage
		
		Local intro:=_ircView.introScreen
		
		If intro.IsConnected Return
		
		Local nick:=Prefs.IrcNickname
		Local server:=Prefs.IrcServer
		Local port:=Prefs.IrcPort
		Local rooms:=Prefs.IrcRooms
		intro.AddOnlyServer( nick,server,server,port,rooms )
		
	End
	
	Method OnChatClicked()
		
		If _consolesTabView.CurrentView<>_ircView Then Return
		
		_consolesTabView.SetTabIcon( _ircView, Null )
		
		_ircNotifyIcon=0
		
		HideHint()
		
	End
	
	Method OnChatMessage( message:IRCMessage, container:IRCMessageContainer, server:IRCServer )
		
		If message.type<>"PRIVMSG" Or _consolesTabView.CurrentView=_ircView Then Return
		
		'Show notice icon
		If message.text.Contains(server.nickname) Then
			
			If _ircNotifyIcon<=1 Then
				
				_ircNotifyIcon=2
				
				Local mentionStr:String
				mentionStr=server.nickname+" was mentioned by "
				mentionStr+=message.fromUser+" in "
				mentionStr+=container.name
				
				ShowHint( mentionStr, New Vec2i( 0, -GetStyle( "Hint" ).Font.Height*4 ), _consolesTabView, 20000 )
				
			Endif
			
		Else
			
			If _ircNotifyIcon<=0 Then _ircNotifyIcon=1
			
		Endif
		
	End
	
	Method UpdateIrcIcon()
		If _ircNotifyIcon<=0 Then Return
		
		Local time:Int=Int(Millisecs()*0.0025)
		
		If time=_ircIconBlink Then Return
		_ircIconBlink=time
		
		If time Mod 2 Then
			Select _ircNotifyIcon
				
				Case 1
					_consolesTabView.SetTabIcon( _ircView, App.Theme.OpenImage( "irc/notice.png" ) )
					
				Case 2
					_consolesTabView.SetTabIcon( _ircView, App.Theme.OpenImage( "irc/important.png" ) )
			End
		Else
			_consolesTabView.SetTabIcon( _ircView, App.Theme.OpenImage( "irc/blink.png" ) )
		Endif
		
	End
	
	Method LoadState( jobj:JsonObject )
	
		If jobj.Contains( "browserSize" )
			_browsersSize=Int( jobj.GetNumber( "browserSize" ) )
			_contentView.SetViewSize( _browsersTabView,_browsersSize )
		Endif
		If jobj.Contains( "browserVisible" ) _browsersTabView.Visible=jobj.GetBool( "browserVisible" )
		If jobj.Contains( "browserTab" ) SetBrowsersTabByString( jobj.GetString( "browserTab" ) )
		
		If jobj.Contains( "consoleSize" )
			_consolesSize=Int( jobj.GetNumber( "consoleSize" ) )
			_contentView.SetViewSize( _consolesTabView,_consolesSize )
		Endif
		If jobj.Contains( "consoleVisible" ) _consolesTabView.Visible=jobj.GetBool( "consoleVisible" )
		If jobj.Contains( "consoleTab" ) SetConsolesTabByString( jobj.GetString( "consoleTab" ) )
		
		If jobj.Contains( "recentFiles" )
			For Local file:=Eachin jobj.GetArray( "recentFiles" )
				Local path:=file.ToString()
				If GetFileType( path )<>FileType.File Continue
				_recentFiles.Push( path )
			Next
		End
		
		If jobj.Contains( "recentProjects" )
			For Local file:=Eachin jobj.GetArray( "recentProjects" )
				Local path:=file.ToString()
				If GetFileType( path )<>FileType.Directory Continue
				_recentProjects.Push( path )
			Next
		End
		
		If jobj.Contains( "theme" ) ThemeName=jobj.GetString( "theme" )
		
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
		
		UpdateRecentFilesMenu()
		UpdateRecentProjectsMenu()
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
					_consoleVisibleCounter+=1
				Endif
			Case Key.Keypad1
			End
		End
	End
	
	Method OnWindowEvent( event:WindowEvent ) Override

		Select event.Type
			
			Case EventType.WindowClose
				OnAppClose()
			
			Case EventType.WindowResized
				OnResized()
			
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
	Field _saveItem:MultiIconToolButton
	Field _saveAllItem:MultiIconToolButton
	Field _docsManager:DocumentManager
	Field _fileActions:FileActions
	Field _editActions:EditActions
	Field _findActions:FindActions
	Field _buildActions:BuildActions
	Field _helpActions:HelpActions
	Field _viewActions:ViewActions
	
	Field _ircView:IRCView
	Field _buildConsole:ConsoleExt
	Field _buildErrorsList:ListViewExt
	Field _buildConsoleView:DockingView
	Field _outputConsole:ConsoleExt
	Field _outputConsoleView:DockingView
	Field _helpView:HtmlViewExt
	Field _helpConsole:DockingView
	Field _findConsole:TreeViewExt
	
	Field _projectView:ProjectView
	Field _docBrowser:DockingView
	Field _debugView:DebugView
	Field _helpTree:HelpTreeView
	
	'Field _ircTabView:TabView
	Field _docsTabView:TabViewExt
	Field _consolesTabView:TabView
	Field _browsersTabView:TabView
	
	Field _ircNotifyIcon:Int
	Field _ircIconBlink:Int
	
	Field _forceStop:Action

	Field _tabMenu:Menu
	Field _templateFiles:MenuExt
	Field _fileMenu:MenuExt
	Field _editMenu:MenuExt
	Field _findMenu:MenuExt
	Field _viewMenu:MenuExt
	Field _buildMenu:MenuExt
	Field _windowMenu:MenuExt
	Field _helpMenu:MenuExt
	Field _menuBar:MenuBarExt
	Field _editorMenu:MenuExt
	Field _themesMenu:MenuExt
	
	Field _theme:="default"
	Field _themeScale:=1.0
	
	Field _contentView:DockingView
	Field _contentLeftView:DockingView
	Field _contentRightView:DockingView

	Field _recentFiles:=New StringStack
	Field _recentProjects:=New StringStack
	
	Field _recentFilesMenu:MenuExt
	Field _recentProjectsMenu:MenuExt
	Field _closeProjectMenu:MenuExt
	Field _statusBar:StatusBarView
	Field _ovdMode:=False
	Field _storedConsoleVisible:Bool
	Field _consoleVisibleCounter:=0
	Field _isTerminating:Bool
	Field _enableSaving:Bool
	Field _resized:Bool
	Field _browsersSize:=0,_consolesSize:=0

	
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
		
		If _recentFiles.Length>20 Then _recentFiles.Resize( 20 )
		
		UpdateRecentFilesMenu()
	End
	
	Method AddRecentProject( path:String )
	
		_recentProjects.Remove( path )
		_recentProjects.Insert( 0,path )
	
		If _recentProjects.Length>10 Then _recentProjects.Resize( 10 )
		
		UpdateRecentProjectsMenu()
		UpdateCloseProjectMenu( path )
	End
	
	Method UpdateRecentFilesMenu()
	
		_recentFilesMenu.Clear()
		
		Local recents:=New StringStack
		
		For Local path:=Eachin _recentFiles
			If GetFileType( path )<>FileType.File Continue
		
			_recentFilesMenu.AddAction( path ).Triggered=Lambda()
				_docsManager.OpenDocument( path,True )
			End
			
			recents.Add( path )
		Next
		
		_recentFiles=recents
	End
	
	Method UpdateRecentProjectsMenu()
	
		_recentProjectsMenu.Clear()
	
		Local recents:=New StringStack
	
		For Local path:=Eachin _recentProjects
			If GetFileType( path )<>FileType.Directory Continue
	
			_recentProjectsMenu.AddAction( path ).Triggered=Lambda()
				_projectView.OpenProject( path )
			End
	
			recents.Add( path )
		Next
	
		_recentProjects=recents
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
	
	Method AddZoomActions( menu:MenuExt )
		
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
	
	Method CreateThemesMenu:MenuExt( text:String )
	
		Local menu:=New MenuExt( text )
		
		Local themes:=JsonObject.Load( "theme::themes.json" )
		If Not themes Return menu
		
		For Local it:=Eachin themes
			Local name:=it.Key
			Local value:=it.Value.ToString()
			menu.AddAction( name ).Triggered=Lambda()
				
				If value=ThemeName Return
				
				ThemeName=value
				
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
	
		_saveItem.SetIcon( _fileActions.save.Enabled ? 1 Else 0 )
		_saveAllItem.SetIcon( _fileActions.saveAll.Enabled ? 1 Else 0 )
		
		App.Idle+=OnAppIdle
		
		GCCollect()	'thrash that GC!
	End
	
	Method GetConsolesTabAsString:String()
		
		Select _consolesTabView.CurrentView
			Case _outputConsoleView
				Return "output"
			Case _buildConsoleView
				Return "build"
			Case _helpConsole
				Return "docs"
			Case _findConsole
				Return "find"
		End
		Return ""
	End
	
	Method SetConsolesTabByString( value:String )
		
		Local view:View
		Select value
			Case "output"
				view=_outputConsoleView
			Case "build"
				view=_buildConsoleView
			Case "docs"
				view=_helpConsole
			Case "find"
				view=_findConsole
		End
		If view Then _consolesTabView.CurrentView=view
	End
	
	Method GetBrowsersTabAsString:String()
	
		Select _browsersTabView.CurrentView
			Case _projectView
				Return "project"
			Case _docBrowser
				Return "source"
			Case _debugView
				Return "debug"
			Case _helpTree
				Return "help"
		End
		Return ""
	End
	
	Method SetBrowsersTabByString( value:String )
	
		Local view:View
		Select value
			Case "project"
				view=_projectView
			Case "source"
				view=_docBrowser
			Case "debug"
				view=_debugView
			Case "help"
				view=_helpTree
		End
		If view Then _browsersTabView.CurrentView=view
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
