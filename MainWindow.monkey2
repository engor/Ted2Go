
Namespace ted2go


#Import "assets/about.html@/ted2"
#Import "assets/aboutTed2Go.html@/ted2"

#Import "assets/themes/@/themes"

#Import "assets/newfiles/@/ted2/newfiles"

#Import "assets/fonts/@/fonts"


Global MainWindow:MainWindowInstance

Class MainWindowInstance Extends Window
	
	Field SizeChanged:Void()
	Field Rendered:Void( canvas:Canvas )
	
	Method New( title:String,rect:Recti,flags:WindowFlags,jobj:JsonObject )
		Super.New( title,rect,flags )
		
		MainWindow=Self
		
		UpdateToolsPaths()
		
		LiveTemplates.Load()
		
		_tabsWrap=New DraggableTabs
		
		_docsTabView=Di.Resolve<DocsTabView>()
		
		_recentFilesMenu=New MenuExt( "Recent files" )
		_recentProjectsMenu=New MenuExt( "Recent projects" )
		_closeProjectMenu=New MenuExt( "Close project" )
		
		_docBrowser=Di.Resolve<DocBrowserView>()
		
		_docsManager=Di.Resolve<DocumentManager>()

		_docsManager.CurrentDocumentChanged+=Lambda()
			
			UpdateKeyView()
			CodeDocument.HideAllPopups()
			
			Local doc:=Cast<CodeTextView>( _docsManager.CurrentTextView )
			Local mode:=doc ? doc.OverwriteMode Else False
			OverwriteTextMode=mode
			
			_findReplaceView.CodeView=Cast<CodeTextView>( _docsManager.CurrentTextView )
			
			If _fullscreenState=FullscreenState.Editor
				SwapFullscreenEditor( False,1 )
			Endif
			
		End
		
		_docsManager.DocumentDoubleClicked+=Lambda( doc:Ted2Document )
		
			_docsManager.LockBuildFile()
		End
		
		App.FileDropped+=Lambda( path:String )
			
			OnFileDropped( path )
		End
		
		_docsManager.DocumentAdded+=Lambda( doc:Ted2Document )
			
			AddRecentFile( doc.Path )
			
			Local codeDoc:=Cast<CodeDocument>( doc )
			If codeDoc
				codeDoc.AnalyzeIndentation()
				If _projectView.ActiveProject?.MainFilePath=codeDoc.Path
					_docsManager.SetAsMainFile( codeDoc.Path,True )
				Endif
			Endif
			
			SaveState()
		End
		
		_docsManager.DocumentRemoved+=Lambda( doc:Ted2Document )
			
			If IsTmpPath( doc.Path ) DeleteFile( doc.Path )
			SaveState()
		End
		
		_recentViewedFiles=New RecentFiles( _docsManager )
		
		
		'Build tab
		
		_buildConsole=Di.Resolve<BuildConsole>()
		' jump to errors etc.
		_buildConsole.RequestJumpToFile+=Lambda( path:String,line:Int )
			
			' emulate build error
			Local err:=New BuildError( path,line,"" )
			_buildActions.GotoError( err )
		End
		
		'Output tab
		
		_outputConsole=Di.Resolve<OutputConsole>()
		Local bar:=New ToolBarExt
		bar.MaxSize=New Vec2i( 300,30 )
		
		Local label:=New Label( "Filter:" )
		bar.AddView( label,"left" )
		Local editFilter:=New TextFieldExt
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
		
		Local tbAct:=New Action( " \r " )
		tbAct.Triggered+=Lambda()
			_outputConsole.ProcessingRtChar=Not _outputConsole.ProcessingRtChar
		End
		Local tb:=New ToolButtonExt( tbAct,"Processing \r char at the beginning of lines" )
		tb.ToggleMode=True
		bar.AddView( tb )
		
		_outputConsoleView=New DockingView
		_outputConsoleView.AddView( bar,"top" )
		_outputConsoleView.ContentView=_outputConsole
		
		
		'Find tab
		
		_findConsole=New TreeViewExt
		_findConsole.SingleClickExpanding=True
		_findConsole.NodeClicked+=Lambda( node:TreeView.Node )
		
			Local n:=Cast<NodeWithData<FileJumpData>>( node )
			If Not n Return
			
			Local data:=n.data
			Local pos:=New Vec2i( data.line,data.posInLine )
			GotoCodePosition( data.path,pos,data.len )
		End
		
		'Help tab
		
		_helpView=Di.Resolve<HelpView>()
		_docsConsole=New DockingView
		bar=New ToolBarExt
		bar.MaxSize=New Vec2i( 300,30 )
		
		_helpSwitcher=New ToolButtonExt( New Action( ">" ) )
		bar.AddView( _helpSwitcher,"left" )
		bar.AddView( New SpacerView( 30,0 ),"left" ) ' right offset
		
		_helpSwitcher.Clicked=Lambda()
		
			_helpTree.Visible=Not _helpTree.Visible
			_helpSwitcher.Text=_helpTree.Visible ? "<" Else ">"
			_helpSwitcher.Hint=_helpTree.Visible ? "Hide docs index" Else "Show docs index"
		End
		
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
		Local explorerAct:=New Action( " [*] " )
		explorerAct.Triggered+=Lambda()
			Local url:=_helpView.Url
			OpenInExplorer( url )
		End
		Local explorerBtn:=New ToolButtonExt( explorerAct,GetShowInExplorerTitle() )
		bar.AddView( explorerBtn )
		
		bar.AddSeparator()
		bar.AddSeparator()
		label=New Label
		label.Style=App.Theme.GetStyle( "HelpPageAddress" )
		
		bar.ContentView=label
		
		_helpView.Navigated+=Lambda( url:String )
			
			label.Text=url
		End
		
		_helpTree=Di.Resolve<HelpTreeView>()
		_docsConsole.AddView( _helpTree,"left",200,True )
		
		_docsConsole.AddView( bar,"top" )
		_docsConsole.ContentView=_helpView
		
		_helpTree.Visible=False
		_helpSwitcher.Clicked() 'show at startup
		
		_helpView.Navigate( AboutPagePath )
		
		
		_debugView=Di.Resolve<DebugView>()
		
		_buildActions=Di.Resolve<BuildActions>()
		_buildActions.ErrorsOccured+=Lambda( errors:BuildError[] )
			
			ShowBuildConsole( True )
			_buildActions.GotoError( errors[0] )
		End
		
		' ExamplesView
		'
		_examplesView=Di.Resolve<ExamplesView>()
		
		' ProjectView
		'
		_projectView=Di.Resolve<ProjectView>()
		' project opened
		_projectView.ProjectOpened+=Lambda( path:String )
			AddRecentProject( path )
			SaveState()
		End
		' project closed
		_projectView.ProjectClosed+=OnProjectClosed
		' find in folder
		_projectView.RequestedFindInFolder+=Lambda( folder:String )
			_findActions.FindInFiles( folder )
		End
		
		_codeParsing=Di.Resolve<CodeParsing>()
		
		_projectView.MainFileChanged+=Lambda( path:String,prevPath:String )
			
			_docsManager.SetAsMainFile( prevPath,False )
			_docsManager.SetAsMainFile( path,True )
		End
		
		_projectView.FileRenamed+=Lambda( path:String,prevPath:String )
			
			Local doc:=_docsManager.FindDocument( prevPath )
			If doc Then _docsManager.RenameDocument( doc,path )
		End
		
		_projectView.FolderRenamed+=Lambda( path:String,prevPath:String )
			
			Local docs:=_docsManager.OpenDocuments
			For Local doc:=Eachin docs
				If doc.Path.StartsWith( prevPath )
					_docsManager.RenameDocument( doc,doc.Path.Replace( prevPath,path ) )
				Endif
			Next
		End
		
		_fileActions=New FileActions( _docsManager )
		_editActions=New EditActions( _docsManager )
		_findActions=New FindActions( _docsManager,_projectView,_findConsole )
		_helpActions=New HelpActions
		_gotoActions=New GotoActions( _docsManager )
		_tabActions=New TabActions( _tabsWrap.AllDocks )
		
		_tabMenu=New Menu
		_tabMenu.AddAction( _fileActions.close )
		_tabMenu.AddAction( _fileActions.closeOthers )
		_tabMenu.AddAction( _fileActions.closeToRight )
		_tabMenu.AddAction( _fileActions.closeAll )
		_tabMenu.AddSeparator()
		_tabMenu.AddAction( _fileActions.save )
		_tabMenu.AddAction( _fileActions.saveAs )
		_tabMenu.AddSeparator()
		_tabMenu.AddAction( _buildActions.lockBuildFile )
		_tabMenu.AddAction( _projectView.setMainFile )
		_tabMenu.AddSeparator()
		_tabMenu.AddAction( GetShowInExplorerTitle() ).Triggered=Lambda()
			
			Local path:=_docsManager.CurrentDocument?.Path
			If path
				OpenInExplorer( ExtractDir( path ) )
			Endif
		End
		_tabMenu.AddAction( "Copy path" ).Triggered=Lambda()
		
			Local path:=_docsManager.CurrentDocument?.Path
			If path
				App.ClipboardText=path
			Endif
		End
		
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
				OpenDocument( path,True )
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
		_fileMenu.AddAction( _projectView.openProjectFolder )
		_fileMenu.AddAction( _projectView.openProjectFile )
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
		_editMenu.AddAction( _editActions.expandSelection )
		_editMenu.AddSeparator()
		' Edit -- Text
		Local subText:=New MenuExt( "Text" )
		subText.AddAction( _editActions.textDeleteWordForward )
		subText.AddAction( _editActions.textDeleteWordBackward )
		subText.AddAction( _editActions.textDeleteLine )
		subText.AddAction( _editActions.textDeleteToEnd )
		subText.AddAction( _editActions.textDeleteToBegin )
		_editMenu.AddSubMenu( subText )
		' Edit -- Comment
		Local subComment:=New MenuExt( "Comment" )
		subComment.AddAction( _editActions.comment )
		subComment.AddAction( _editActions.uncomment )
		
		_editMenu.AddSubMenu( subComment )
		' Edit -- Convert case
		Local subCase:=New MenuExt( "Convert case" )
		subCase.AddAction( _editActions.textUppercase )
		subCase.AddAction( _editActions.textLowercase )
		subCase.AddAction( _editActions.textSwapCase )
		_editMenu.AddSubMenu( subCase )
		'
		_editMenu.AddSeparator()
		_editMenu.AddAction( _editActions.wordWrap )
		
		
		'Find menu
		'
		_findMenu=New MenuExt( "Find" )
		_findMenu.AddAction( _findActions.find )
		_findMenu.AddAction( _findActions.replace )
		_findMenu.AddAction( _findActions.findNext )
		_findMenu.AddAction( _findActions.findPrevious )
		_findMenu.AddSeparator()
		_findMenu.AddAction( _findActions.findInFiles )
		
		'Goto menu
		'
		_gotoMenu=New MenuExt( "Goto" )
		_gotoMenu.AddAction( _gotoActions.gotoLine )
		_gotoMenu.AddAction( _gotoActions.gotoDeclaration )
		_gotoMenu.AddSeparator()
		_gotoMenu.AddAction( _gotoActions.goBack )
		_gotoMenu.AddAction( _gotoActions.goForward )
		_gotoMenu.AddSeparator()
		_gotoMenu.AddAction( _gotoActions.prevScope )
		_gotoMenu.AddAction( _gotoActions.nextScope )
		
		'View menu
		'
		_viewMenu=New MenuExt( "View" )
		Local m:=New MenuExt( "Docks" )
		TabActions.CreateMenu( m )
		_viewMenu.AddSubMenu( m )
		_viewMenu.AddSeparator()
		m=New MenuExt( "Folding" )
		Local foldActions:=New FoldingActions
		m.AddAction( foldActions.foldCurrent )
		m.AddAction( foldActions.unfoldCurrent )
		m.AddSeparator()
		m.AddAction( foldActions.foldScope )
		m.AddAction( foldActions.unfoldScope )
		m.AddSeparator()
		m.AddAction( foldActions.foldAll )
		m.AddAction( foldActions.unfoldAll )
		_viewMenu.AddSubMenu( m )
		_viewMenu.AddSeparator()
		Local showRecent:=New Action( "Recently viewed files...")
		showRecent.Triggered=Lambda()
			Local path:=_recentViewedFiles.ShowDialog()
			If path Then OpenDocument( path )
		End
		showRecent.HotKey=Key.E
		#If __TARGET__="macos"
		showRecent.HotKeyModifiers=Modifier.Menu
		#Else
		showRecent.HotKeyModifiers=Modifier.Control
		#Endif
		_viewMenu.AddAction( showRecent )
		
		'Build menu
		'
		_forceStop=_buildActions.forceStop
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
		Local windowActions:=New WindowActions( _docsManager )
		_windowMenu=New MenuExt( "Window" )
		_windowMenu.AddAction( windowActions.nextTab )
		_windowMenu.AddAction( windowActions.prevTab )
		_windowMenu.AddSeparator()
		_windowMenu.AddAction( windowActions.fullscreenWindow )
		_windowMenu.AddAction( windowActions.fullscreenEditor )
		_windowMenu.AddSeparator()
		_windowMenu.AddAction( windowActions.zoomIn )
		_windowMenu.AddAction( windowActions.zoomOut )
		_windowMenu.AddAction( windowActions.zoomDefault )
		_windowMenu.AddSeparator()
		_themesMenu=CreateThemesMenu( "Themes" )
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
		_helpMenu.AddAction( _helpActions.joinCommunity )
		
		'Menu bar
		'
		_menuBar=New MenuBarExt
		_menuBar.AddMenu( _fileMenu )
		_menuBar.AddMenu( _editMenu )
		_menuBar.AddMenu( _findMenu )
		_menuBar.AddMenu( _gotoMenu )
		_menuBar.AddMenu( _viewMenu )
		_menuBar.AddMenu( _buildMenu )
		_menuBar.AddMenu( _windowMenu )
		_menuBar.AddMenu( _helpMenu )
		

		_buildConsoleView=New DockingView
		_buildConsoleView.ContentView=_buildConsole
		
		_statusBar=New StatusBarView( "Stop process ("+_forceStop.HotKeyText+")" )
		
		_contentView=New DockingView
		_contentView.AddView( _menuBar,"top" )
		
		ArrangeElements()
		
		'_helpTree.QuickHelp( "" )
		
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
		
		For Local doc:=Eachin _docsManager.OpenDocuments
			doc.TextView?.TabStop=Prefs.EditorTabSize
		Next
		
		PrefsChanged()
		
		_projectView.SingleClickExpanding=Prefs.MainProjectSingleClickExpanding
	End
	
	Method GainFocus()
		
		'Local event:=New WindowEvent( EventType.WindowGainedFocus,Self )
		'OnWindowEvent( event )
		
		'SendWindowEvent( event )
		'SDL_RaiseWindow( SDLWindow )
	End
	
	Method OnFileDropped( path:String )
	
		New Fiber( Lambda()
	
			Local ok:=_projectView.OnFileDropped( path )
			If Not ok And FileExists( path ) 'file
				_docsManager.OpenDocument( path,True )
			Endif
	
		End )
	End
	
	Method HideFindPanel:Bool()
		
		If Not _findReplaceView.Visible Return False
		
		_findReplaceView.CodeView=Null
		_findReplaceView.Visible=False
		UpdateKeyView()
		
		Return True
	End
	
	Method ShowFind( what:String="" )
		
		_findReplaceView.CodeView=Cast<CodeTextView>( _docsManager.CurrentTextView )
		
		Local arr:=what.Split( "~n" )
		If arr.Length>1
			what=""
		Endif
		
		If _findReplaceView.Visible And Not what
			what=_findReplaceView.FindText
		Endif
		_findReplaceView.Visible=True
		_findReplaceView.FindText=what
		_findReplaceView.Mode=FindReplaceView.Kind.Find
		_findReplaceView.Activate()
	End
	
	Method ShowReplace( what:String="" )
		
		ShowFind( what )
		_findReplaceView.Mode=FindReplaceView.Kind.Replace
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
		Endif
		_debugView.KillApp()
		HideStatusBarProgress()
		RestoreConsoleVisibility()
		If _outputConsole.Running
			_outputConsole.Terminate()
		Endif
	End
	
	Method OnDocumentLinesModified( doc:Ted2Document,first:Int,removed:Int,inserted:Int )
		
		Local res:=_findActions.lastFindResults
		If Not res Return
		
		res.ProcessLinesModified( doc.Path,first,removed,inserted )
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
		
		Local doc:=Cast<CodeTextView>( _docsManager.CurrentTextView )
		If doc
			doc.OverwriteMode=_ovdMode
		Else
			_ovdMode=False
		Endif
		
		SetStatusBarInsertMode( Not _ovdMode )
	End
	
	Property DocsManager:DocumentManager()
	
		Return _docsManager
	End
	
	Property ProjView:ProjectView()
	
		Return _projectView
	End
	
	Property LockedDocument:CodeDocument()
	
		Return _docsManager.LockedDocument
	End
	
	Property IsTerminating:Bool()
		
		Return _isTerminating
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
		
		' waiting for started processes if any
		ParsersManager.DisableAll()
		Local future:=New Future<Bool>
		New Fiber( Lambda()
			ProcessReader.WaitingForStopAll( future )
		End )
		future.Get()
		
		CodeParsing.DeleteTempFiles()
		
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
	
	Method SwapFullscreenWindow()
		
		If _fullscreenState=FullscreenState.Editor
			SwapFullscreenEditor()
			Return
		Endif
		
		If Not _fullscreen
			_storedSize=Frame
			_storedMaximized=Maximized
		Endif
		
		_fullscreen=Not _fullscreen
		_fullscreenState=_fullscreen ? FullscreenState.Window Else FullscreenState.None
		
		UpdateFullscreenMode()
		
	End
	
	' customState: -1 - make windowed, 1 - make fullscreen
	'
	Method SwapFullscreenEditor( justStarted:Bool=False,customState:Int=0 )
		
		If Not justStarted And _docsManager.CurrentDocument=Null
			Alert( "There is no editor to be fullscreened!","Fullscreen" )
			Return
		Endif
		
		If Not _fullscreen
			_storedSize=Frame
			_storedMaximized=Maximized
		Endif
		
		' restore
		If _fullscreenHelper.storedContentView<>Null
			Local view:=_fullscreenHelper.editorContainer.ContentView
			view.Layout="fill"
			_fullscreenHelper.editorContainer.ContentView=Null
			_fullscreenHelper.statusContainer.ContentView=Null
			_statusBarContainer.ContentView=_statusBar
			ContentView=_fullscreenHelper.storedContentView
			_docsTabView.SetTabView( _fullscreenHelper.storedTabIndex,view )
			_docsTabView.EnsureVisibleCurrentTab()
			_docsManager.UpdateCurrentTabLabel()
			_docsManager.CurrentDocument?.DirtyChanged-=_fullscreenHelper.UpdateTitle
			_fullscreenHelper.storedContentView=Null
		Endif
		
		' stay in fullscreen
		If _fullscreenPrevState=FullscreenState.Window
			_fullscreenState=FullscreenState.Window
			_fullscreenPrevState=FullscreenState.None
			Return
		Endif
		
		_fullscreenPrevState=_fullscreenState
		
		Local state:=Not _fullscreen
		
		If customState<>0 Then state=(customState > 0)
		If _fullscreenState<>FullscreenState.Window Then _fullscreen=state
		
		_fullscreenState=_fullscreen ? FullscreenState.Editor Else FullscreenState.None
		
		UpdateFullscreenMode()
		
		If _fullscreen
			_fullscreenHelper.storedContentView=ContentView
			_fullscreenHelper.storedTabIndex=_docsTabView.CurrentIndex
			_docsTabView.SetTabView( _fullscreenHelper.storedTabIndex,Null )
			Local view:=_docsManager.CurrentView
			view.Layout="fill-y"
			view.Gravity=New Vec2f( .5,0 )
			Local sz:=New Vec2i( Int(App.DesktopSize.x*.7),100000 )
			view.MaxSize=sz
			view.MinSize=sz
			_fullscreenHelper.editorContainer.ContentView=view
			_fullscreenHelper.titleLabel.Text=_docsManager.CurrentDocumentLabel
			_docsManager.CurrentDocument?.DirtyChanged+=_fullscreenHelper.UpdateTitle
			' status bar
			_statusBarContainer.ContentView=Null
			_fullscreenHelper.statusContainer.ContentView=_statusBar
			'
			ContentView=_fullscreenHelper.editorContainer
			
			_docsManager.CurrentTextView?.MakeKeyView()
			
		Endif
	End
	
	Method StoreConsoleVisibility()
	
		'If Prefs.SiblyMode return
		
		'_storedConsoleVisible=_consolesTabView.Visible
		'_consoleVisibleCounter=0
	End
	
	Method RestoreConsoleVisibility()
	
		'If Prefs.SiblyMode Return
	
		'If _consoleVisibleCounter > 0 Return
		'_consolesTabView.Visible=_storedConsoleVisible
		'RequestRender()
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
	
	Method GetFindDock:DockingView()
		
		If _findReplaceView Return _findReplaceView
		
		_findReplaceView=New FindReplaceView( _findActions )
		
		_findReplaceView.RequestedFind+=Lambda( opt:FindOptions )
			
			_findActions.options=opt
			If opt.goNext
				_findActions.findNext.Triggered()
			Else
				_findActions.findPrevious.Triggered()
			Endif
		End
		
		_findReplaceView.RequestedReplace+=Lambda( opt:FindOptions )
		
			_findActions.options=opt
			If opt.all
				_findActions.replaceAll.Triggered()
			Else
				_findActions.replaceNext.Triggered()
			Endif
		End
		
		Return _findReplaceView
	End
	
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
		Local goBackTitle:=GetActionTextWithShortcut( _gotoActions.goBack )
		Local goForwTitle:=GetActionTextWithShortcut( _gotoActions.goForward )
		
		_toolBar = New ToolBarExt( Prefs.MainToolBarSide ? Axis.Y Else Axis.X )
		_toolBar.Style = GetStyle( "MainToolBar" )
		
		If Not Prefs.MainToolBarSimple Then
			
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/back.png" ),_gotoActions.goBack.Triggered,goBackTitle )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/forward.png" ),_gotoActions.goForward.Triggered,goForwTitle )
			_toolBar.AddSeparator()
		Endif
		
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/new_file.png" ),_fileActions.new_.Triggered,newTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/open_file.png" ),_fileActions.open.Triggered,openTitle )
		If Not Prefs.MainToolBarSimple Then _toolBar.AddIconicButton( ThemeImages.Get( "toolbar/open_project.png" ),_projectView.openProjectFolder.Triggered,"Open project..." )
		Local icons:=New Image[]( ThemeImages.Get( "toolbar/save.png" ),ThemeImages.Get( "toolbar/save_dirty.png" ) )
		_saveItem=_toolBar.AddIconicButton( icons,_fileActions.save.Triggered,saveTitle )
		
		If Not Prefs.MainToolBarSimple Then
			
			icons=New Image[]( ThemeImages.Get( "toolbar/save_all.png" ),ThemeImages.Get( "toolbar/save_all_dirty.png" ) )
			_saveAllItem=_toolBar.AddIconicButton( icons,_fileActions.saveAll.Triggered,saveAllTitle )
		Endif
		
		_toolBar.AddSeparator()
		
		If Not Prefs.MainToolBarSimple Then
			
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/cut.png" ),_editActions.cut.Triggered,cutTitle )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/copy.png" ),_editActions.copy.Triggered,copyTitle )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/paste.png" ),_editActions.paste.Triggered,pasteTitle )
			_toolBar.AddSeparator()
		
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/undo.png" ),_editActions.undo.Triggered,undoTitle )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/redo.png" ),_editActions.redo.Triggered,redoTitle )
			_toolBar.AddSeparator()
		Endif
		
		If Not Prefs.MainToolBarSimple Then
			
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/check.png" ),_buildActions.semant.Triggered,checkTitle )
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/build.png" ),_buildActions.build.Triggered,buildTitle )
		Endif
		
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/run.png" ),_buildActions.buildAndRun.Triggered,runTitle )
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/debug.png" ),_buildActions.debugApp.Triggered,debugTitle )
		_toolBar.AddSeparator()
		
		Local act:=Lambda()
			_buildActions.targetMenu.Open()
		End
		_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/options.png" ),act,"Target settings" )
		
		If Not Prefs.MainToolBarSimple Then
			
			_toolBar.AddSeparator()
			_toolBar.AddIconicButton( ThemeImages.Get( "toolbar/find.png" ),_findActions.find.Triggered,findTitle )
		Endif
		
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
		
		_tabsWrap.tabs["Project"].Activate()
	End
	
	Method ShowDebugView()
		
		_tabsWrap.tabs["Debug"].Activate()
	End
	
	Method ShowBuildConsole( vis:Bool=True )
		
		Local tab:=_tabsWrap.tabs["Build"]
		tab.Activate()
		If vis tab.CurrentHolder.Visible=True
	End
	
	Method ShowOutputConsole( vis:Bool=True )
		
		Local tab:=_tabsWrap.tabs["Output"]
		tab.Activate()
		If vis tab.CurrentHolder.Visible=True
	End
	
	Method ShowDocsView( expandTree:Bool=False )
		
		Local tab:=_tabsWrap.tabs["Docs"]
		tab.Activate()
		tab.CurrentHolder.Visible=True
		
		If expandTree
			_helpTree.Visible=False
			_helpSwitcher.Clicked()
		Endif
	End
	
	Method ShowFindResults()
		
		Local tab:=_tabsWrap.tabs["Find"]
		tab.Activate()
		tab.CurrentHolder.Visible=True
	End
	
	Method RebuildDocs()
		
		_buildActions.rebuildHelp.Trigger()
	End
	
	Method ShowHelp( url:String="",searchMode:Bool=False )
		
		' direct jump
		If url
			_helpView.Navigate( url )
			_helpView.Scroll=New Vec2i( 0,0 )
			ShowDocsView()
			Return
		Endif
		
		Local view:=Cast<CodeDocumentView>( _docsManager.CurrentTextView )
		If Not view Return
		
		' don't check with parser, just find in docs tree
		If searchMode
			Local ident:=view.WordAtCursor
			_helpTree.QuickHelp( ident )
			ShowDocsView( True )
			Return
		Endif
		
		Local ident:=view.IdentBeforeCursor( True,True )
		
		If Not ident Return
		Local parser:=ParsersManager.Get( view.FileType )
		Local item:=parser.ItemAtScope( ident,view.FilePath,GetCursorPos( view ) )
		
		If item
			
			ident=item.Ident
			
			Local pathTemplate:=Prefs.MonkeyRootPath+"docs/modules/{mod-name}/module/{path-to-ident}.html"
			Local modName:=item.ModuleName
			
			Local pathToIdent:=(item.Namespac+"."+item.Scope).Replace( ".","-" )
			Local path:=pathTemplate.Replace( "{mod-name}",modName ).Replace( "{path-to-ident}",pathToIdent )
			
			Global _prevPath:=""
			
			If path=_prevPath
				
				If modName ' show docs for modules members
					
					_helpTree.QuickHelp( ident )
					
					_helpView.Navigate( path )
					_helpView.Scroll=New Vec2i( 0,0 )
					
					_helpTree.Selected=_helpTree.FindByText( ident )
					
					ShowDocsView( True )
					
				Else ' or jump to non modules members
					
					GotoCodePosition( item.FilePath,item.ScopeStartPos )
					
				Endif
			Else
				
				Local parentIdent:=""
				If item.Parent
					If item.Parent.IsLikeClass
						parentIdent=item.Parent.Ident
					Endif
				Endif
				
				Local nmspace:=item.Namespac
				If parentIdent Then nmspace+="."+parentIdent
				Local ext:=item.IsExtension ? "(ext) " Else ""
				ShowStatusBarText( ext+"("+item.KindStr+") "+item.Text+"    |  "+nmspace+"  |  "+StripDir( item.FilePath )+"  |  line "+(item.ScopeStartPos.x+1) )
			
			Endif
			
			_prevPath=path
			
		Elseif KeywordsManager.Get( view.FileType ).Contains( ident )
			
			ShowStatusBarText( "(keyword) "+ident )
		
		Else
			
			ShowHelp( "",True ) ' try to search ident
			
		Endif
		
	End
	
	Method ShowEditorMenu( tv:TextView )
		
		If Not tv Then tv=_docsManager.CurrentTextView
		If Not tv Return
		
		If Not _editorMenu
			_editorMenu=New MenuExt
			_editorMenu.AddAction( _gotoActions.gotoDeclaration )
			_editorMenu.AddSeparator()
			_editorMenu.AddAction( _editActions.cut )
			_editorMenu.AddAction( _editActions.copy )
			_editorMenu.AddAction( _editActions.paste )
			_editorMenu.AddSeparator()
			_editorMenu.AddAction( _editActions.comment )
			_editorMenu.AddAction( _editActions.uncomment )
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
	
	Method UpdateFullscreenMode()
		
		If _fullscreen
			
			Local bounds:SDL_Rect
			SDL_GetDisplayBounds( SDL_GetWindowDisplayIndex(Window.SDLWindow),Varptr bounds )
			
			If _storedMaximized Then Restore()
			
			SDL_SetWindowSize( Window.SDLWindow,bounds.w,bounds.h )
			SDL_SetWindowPosition( Window.SDLWindow,bounds.x,bounds.y )
			
			' Frame=... doesn't work here
		Else
			
			SDL_SetWindowSize( Window.SDLWindow,_storedSize.Width,_storedSize.Height )
			SDL_SetWindowPosition( Window.SDLWindow,_storedSize.Left,_storedSize.Top )
			
			If _storedMaximized Then Maximize()
			
		End
		
		SendWindowEvent( New WindowEvent( EventType.WindowResized,Self ) )
	End
	
	Method GotoCodePosition( docPath:String,pos:Vec2i,lenToSelect:Int=0 )
		
		Local doc:=Cast<CodeDocument>( _docsManager.OpenDocument( docPath,True ) )
		If Not doc Return
		
		Local tv := Cast<CodeTextView>( doc.TextView )
		If Not tv Return
		
		UpdateWindow( False )
		
		tv.GotoPosition( pos,lenToSelect )
		tv.MakeKeyView()
	End
	
	Method GotoDeclaration()
	
		Local doc:=_docsManager.CurrentCodeDocument
		If Not doc Return
		
		doc.GotoDeclaration()
		doc.TextView.MakeKeyView()
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
		
		Local state:=_fullscreenState
		If state=FullscreenState.None Then _storedSize=Frame
		
		jobj["windowRect"]=ToJson( _storedSize )
		jobj["windowState"]=New JsonNumber( Int(state) )
		
		SaveUndockTabsState( jobj )
		If _isTerminating UndockWindow.RestoreUndock()
		
		SaveTabsState( jobj )
		
		Local jdocs:=New JsonObject
		jobj["docsTab"]=jdocs
		
		jdocs["indexerVisible"]=New JsonBool( _helpTree.Visible )
		jdocs["indexerSize"]=New JsonString( _docsConsole.GetViewSize( _helpTree ) )
		
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
		
		jobj["theme"]=New JsonString( ThemesInfo.ActiveThemePath )
		
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
		If lockIt Then _docsManager.LockBuildFile()
		UpdateWindow( True )
	End
	
	Method OpenProject( path:String )
		
		_projectView.OpenProject( path )
	End
	
	Method GetActionFind:Action()
	
		Return _findActions.find
	End
	
	Method GetActionComment:Action()
	
		Return _editActions.comment
	End
	
	Method GetActionUncomment:Action()
	
		Return _editActions.uncomment
	End
	

	Private
	
	Method OnRender( canvas:Canvas ) Override
		
		Global __inited:=False
		If Not __inited
			__inited=True
			OnInit()
		Endif
		
		Super.OnRender( canvas )
		
		If _resized
			_resized=False
			SizeChanged()
		Endif
		
		Rendered( canvas )
		
	End
	
	Method OnInit()
		
		' need to make visible after layout
		_docsTabView.EnsureVisibleCurrentTab()
	End
	
	Method OnAppClose()
		
		_fileActions.quit.Trigger()
	End
	
	Method OnPreBuild()
		
		OnForceStop()
	End
	
	Method OnPreSemant()
	
	End
	
	Method OnPreBuildModules()
	
	End
	
	Method OnProjectClosed( dir:String )
		
		UpdateCloseProjectMenu()
		
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
	
	Method InitTabs()
		
		If Not _tabsWrap.tabs.Empty Return
		
		_tabsWrap.AddTab( "Project",_projectView )
		_tabsWrap.AddTab( "Debug",_debugView )
		_tabsWrap.AddTab( "Source",_docBrowser )
		_tabsWrap.AddTab( "Build",_buildConsoleView )
		_tabsWrap.AddTab( "Output",_outputConsoleView )
		_tabsWrap.AddTab( "Docs",_docsConsole )
		_tabsWrap.AddTab( "Find",_findConsole )
		_tabsWrap.AddTab( "Examples",_examplesView )
		
		' load examples when user open Examples tab
		Local tab:=_tabsWrap.tabs["Examples"]
		tab.ActiveChanged+=Lambda()
			If tab.IsActive
				_examplesView.Init()
			Endif
		End
	End
	
	Method ArrangeElements()
		
		InitTabs()
		
		_contentView.RemoveView( _toolBar )
		_contentView.RemoveView( _statusBarContainer )
		_contentView.RemoveView( _findReplaceView )
		
		_tabsWrap.DetachFromParent()
		
		If Not _statusBarContainer
			_statusBarContainer=New DockingView
			_statusBarContainer.ContentView=_statusBar
		Endif
		_contentView.AddView( _statusBarContainer,"bottom" )
		
		If Prefs.MainToolBarVisible Then
			
			_toolBar = Null
			_toolBar = GetMainToolBar()
			_contentView.AddView( _toolBar, Prefs.MainToolBarSide ? "left" Else "top" )
		Endif
		
		
		_tabsWrap.AttachToParent( _contentView )
		
		Local d:=GetFindDock()
		d.Visible=False
		_contentView.AddView( d,"bottom" )
		
		_contentView.ContentView=_docsTabView
		
	End
	
	Method LoadTabsState( jobj:JsonObject )
		
		Global places:=New StringMap<StringStack>
		' defaults
		Local s:="Source"
		places["left"]=New StringStack( s.Split( "," ) )
		s="Project,Debug,Examples"
		places["right"]=New StringStack( s.Split( "," ) )
		s="Build,Output,Docs,Find"
		places["bottom"]=New StringStack( s.Split( "," ) )
		
		Global actives:=New StringMap<String>
		' defaults
		actives["left"]="Source"
		actives["right"]="Project"
		actives["bottom"]="Docs"
		
		Local edges:=DraggableTabs.Edges
		
		' put views
		For Local edge:=Eachin edges
			Local val:=Json_FindValue( jobj.Data,"tabsDocks/"+edge+"Tabs" )
			Local vistabs:=Json_FindValue( jobj.Data,"tabsDocks/"+edge+"TabsVisible" )
			If val And val<>JsonValue.NullValue
				For Local v:=Eachin val.ToArray().All()
					Local key:=v.ToString()
					' remove from defaults
					For Local e:=Eachin edges
						places[e].Remove( key )
					Next
					'
					Local tab:=_tabsWrap.tabs[key]
					If tab Then
						_tabsWrap.docks[edge].AddTab( tab )
						'set view visible
						If vistabs And vistabs<>JsonValue.NullValue
							For Local vt:=Eachin vistabs.ToArray().All()
								If key=vt.ToString() Then tab.Visible=True; Exit
								tab.Visible=False
							Next
						End
					End
				Next
			Endif
		Next
		
		' put default if any
		For Local edge:=Eachin edges
			For Local name:=Eachin places[edge]
				Local tab:=_tabsWrap.tabs[name]
				If tab Then _tabsWrap.docks[edge].AddTab( tab )
			Next
		Next
		
		For Local edge:=Eachin edges
			' set active
			Local val:=Json_FindValue( jobj.Data,"tabsDocks/"+edge+"Active" )
			If val
				actives[edge]=val.ToString()
			Endif
			Local tab:=_tabsWrap.tabs[actives[edge]]
			If tab Then tab.Activate()
			' set sizes
			Local sz:=Json_FindValue( jobj.Data,"tabsDocks/"+edge+"Size" )
			If sz
				_tabsWrap.sizes[edge]=sz.ToString()
			Endif
			Local dock:=_tabsWrap.docks[edge]
			_contentView.SetViewSize( dock,_tabsWrap.sizes[edge] )
			' set visibility
			Local vis:=Json_FindValue( jobj.Data,"tabsDocks/"+edge+"Visible" )
			If vis
				dock.Visible=vis.ToBool()
			Endif
			dock.Visible=dock.Visible And (dock.NumTabs>0)
		Next
		
		Local val:=Json_FindValue( jobj.Data,"tabsDocks/sourcesInnerListHeight" )
		If val
			Local size:=Max( 50,Int(val.ToNumber()) )
			_docBrowser.PropertiesViewHeight=size
		Endif
	End
	
	Method SaveTabsState( jobj:JsonObject )
	
		Local jj:=New JsonObject
		jobj["tabsDocks"]=jj
		
		Local edges:=DraggableTabs.Edges
		
		For Local edge:=Eachin edges
			Local dock:=_tabsWrap.docks[edge]
			jj[edge+"Tabs"]=JsonArray.FromStrings( dock.TabsNames )
			jj[edge+"TabsVisible"]=JsonArray.FromStrings( dock.TabsVisible )
			jj[edge+"Active"]=New JsonString( dock.ActiveName )
			jj[edge+"Visible"]=New JsonBool( dock.Visible )
			jj[edge+"Size"]=New JsonString( _tabsWrap.GetDockSize( dock ) )
		Next
		
		jj["sourcesInnerListHeight"]=New JsonNumber( _docBrowser.PropertiesViewHeight )
	End
	
	Method LoadUndockTabsState( jobj:JsonObject )
		
		Local edges:=DraggableTabs.Edges
		For Local edge:=Eachin edges
			Local dock:=_tabsWrap.docks[edge]
			For Local i:=Eachin dock.TabsNames
				Local val:=Json_FindValue( jobj.Data,"undockTabs/"+i )
				If val
					Local _undockWindow:=UndockWindow.NewUndock( _tabsWrap.tabs[i] )
					_undockWindow.SetUndockFrame( ToRecti( val ) )
				End
			Next
		Next
	End
	
	Method SaveUndockTabsState( jobj:JsonObject )
		
		If( UndockWindow._undockWindows.Length )
			Local jj:=New JsonObject
			jobj["undockTabs"]=jj
			For Local i:=Eachin UndockWindow._undockWindows
				If i._visible jj[i.Title]=ToJson( i.Frame )
			Next
		End
	End
	
	Method LoadState( jobj:JsonObject )
		
		LoadTabsState( jobj )
		
		LoadUndockTabsState( jobj )
		
		If jobj.Contains( "docsTab" )
			Local jdocs:=jobj.GetObject( "docsTab" )
			Local size:=jdocs.GetString( "indexerSize" )
			_docsConsole.SetViewSize( _helpTree,size )
			Local vis:=jdocs.GetBool( "indexerVisible" )
			_helpTree.Visible=Not vis
			_helpSwitcher.Clicked()
		Endif
		
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
		
		If jobj.Contains( "theme" ) ThemesInfo.ActiveThemePath=jobj.GetString( "theme" )
		
		If jobj.Contains( "themeScale" )
			Local sc:=jobj.GetNumber( "themeScale" )
			App.Theme.Scale=New Vec2f( sc )
		Endif
		
		If jobj.Contains( "mx2ccDir" )
			_mx2ccDir=jobj.GetString( "mx2ccDir" )
			If Not _mx2ccDir.EndsWith( "/" ) _mx2ccDir+="/"
			_mx2cc=_mx2ccDir+StripDir( _mx2cc )
		Endif
		
		App.Idle+=Lambda() 'delay execution
			
			_buildActions.LoadState( jobj )
			_projectView.LoadState( jobj )
			_docsManager.LoadState( jobj )
		 	
			If Not _projectView.HasOpenedProjects Then _projectView.OpenProject( CurrentDir() )
			
			UpdateRecentFilesMenu()
			UpdateRecentProjectsMenu()
			UpdateCloseProjectMenu()
			
			DeleteTmps()
			
			' enter fullscreen mode
			Local state:=Json_GetInt( jobj.Data,"windowState",0 )
			If state=1
				SwapFullscreenWindow()
			Elseif state=2
				SwapFullscreenEditor( True )
			Endif
			
		End
	End
	
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		Select event.Type
		Case EventType.KeyDown
			
			Select event.Key
			Case Key.Escape
				
				If CodeDocument.HideParamsHint()
					Return
				Endif
				
				If _fullscreenState=FullscreenState.Editor
					SwapFullscreenEditor()
					Return
				Endif
					
				' hide find / replace panel
				If HideFindPanel()
					Return
				Endif
				
				Local dock:TabViewExt
				' show / hide left & right docks
				If event.Modifiers & Modifier.Shift
					
					dock=_tabsWrap.docks["left"]
					If dock.NumTabs>0 And dock.VisibleTabs Then dock.Visible=Not dock.Visible
					
					dock=_tabsWrap.docks["right"]
					If dock.NumTabs>0 And dock.VisibleTabs Then dock.Visible=Not dock.Visible
					
				Else ' bottom dock
					
					dock=_tabsWrap.docks["bottom"]
					If dock.NumTabs>0 And dock.VisibleTabs Then dock.Visible=Not dock.Visible
					
					_consoleVisibleCounter+=1
				Endif
				
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
	Field _gotoActions:GotoActions
	Field _tabActions:TabActions
	
	Field _buildConsole:ConsoleExt
	Field _buildConsoleView:DockingView
	Field _outputConsole:ConsoleExt
	Field _outputConsoleView:DockingView
	Field _helpView:HtmlViewExt
	Field _docsConsole:DockingView
	Field _findConsole:TreeViewExt
	Field _examplesView:ExamplesView
	
	Field _projectView:ProjectView
	Field _docBrowser:DocBrowserView
	Field _debugView:DebugView
	Field _helpTree:HelpTreeView
	Field _helpSwitcher:ToolButtonExt
	
	Field _docsTabView:TabViewExt
	Field _consolesTabView2:TabView
	Field _browsersTabView2:TabView
	
	Field _forceStop:Action

	Field _tabMenu:Menu
	Field _templateFiles:MenuExt
	Field _fileMenu:MenuExt
	Field _editMenu:MenuExt
	Field _findMenu:MenuExt
	Field _gotoMenu:MenuExt
	Field _viewMenu:MenuExt
	Field _buildMenu:MenuExt
	Field _windowMenu:MenuExt
	Field _helpMenu:MenuExt
	Field _menuBar:MenuBarExt
	Field _editorMenu:MenuExt
	Field _themesMenu:MenuExt
	
	Field _contentView:DockingView
	
	Field _recentFiles:=New StringStack
	Field _recentProjects:=New StringStack
	
	Field _recentFilesMenu:MenuExt
	Field _recentProjectsMenu:MenuExt
	Field _closeProjectMenu:MenuExt
	Field _statusBar:StatusBarView
	Field _statusBarContainer:DockingView
	Field _ovdMode:=False
	Field _storedConsoleVisible:Bool
	Field _consoleVisibleCounter:=0
	Field _isTerminating:Bool
	Field _enableSaving:Bool
	Field _resized:Bool
	Field _findReplaceView:FindReplaceView
	Field _tabsWrap:=New DraggableTabs
	
	Field _fullscreen:Bool
	Field _fullscreenState:=FullscreenState.None,_fullscreenPrevState:=FullscreenState.None
	Field _fullscreenHelper:= New FullscreenHelper
	Field _storedSize:Recti,_storedMaximized:Bool
	
	Field _recentViewedFiles:RecentFiles
	Field _codeParsing:CodeParsing
	
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
		UpdateCloseProjectMenu()
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
			_recentProjectsMenu.AddAction( path ).Triggered=Lambda()
				_projectView.OpenProject( path )
			End
			recents.Add( path )
		Next
		
		_recentProjects=recents
	End
	
	Method UpdateCloseProjectMenu()
		
		_closeProjectMenu.Clear()
		
		For Local proj:=Eachin _projectView.OpenProjects
			
			Local path:=proj.Path
			_closeProjectMenu.AddAction( path ).Triggered=Lambda()
			
				_projectView.CloseProject( path )
				UpdateCloseProjectMenu()
			End
			
		Next
	End
	
	Method ThemeScaleMouseFilter( event:MouseEvent )
		
		If event.Eaten Return
		
		If event.Type=EventType.MouseWheel And event.Modifiers & Modifier.Menu
			
			Local sc:=App.Theme.Scale.x
			If event.Wheel.y>0
				If sc<4 sc+=0.125
			Else
				If sc>.5 sc-=0.125
			Endif
			
			App.Theme.Scale=New Vec2f( sc )
			
			event.Eat()
			
		Else If event.Type=EventType.MouseDown And event.Button=MouseButton.Middle And event.Modifiers & Modifier.Menu
			
			App.Theme.Scale=New Vec2f( 1 )
			
			event.Eat()
		Endif
		
	End
	
	Method CreateThemesMenu:MenuExt( text:String )
	
		Local menu:=New MenuExt( text )
		
		For Local i:=0 Until ThemesInfo.GetCount()
			Local name:=ThemesInfo.GetNameAt( i )
			Local path:=ThemesInfo.GetPathAt( i )
			menu.AddAction( name ).Triggered=Lambda()
				
				If path=ThemesInfo.ActiveThemePath Return
				
				ThemesInfo.ActiveThemePath=path
				Local sc:=App.Theme.Scale.x
				
				App.Theme.Load( path,New Vec2f( sc ) )
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
		
		If _saveItem ' when toolbar is visible
			_saveItem.SetIcon( _fileActions.save.Enabled ? 1 Else 0 )
			If _saveAllItem Then _saveAllItem.SetIcon( _fileActions.saveAll.Enabled ? 1 Else 0 )
		Endif
		
		App.Idle+=OnAppIdle
		
	End
	
End


Private

Enum FullscreenState
	None=0
	Window=1
	Editor=2
End


Class FullscreenHelper
	
	Field state:FullscreenState
	Field frame:Recti
	Field storedContentView:View
	Field storedTabIndex:Int
	Field editorContainer:DockingView
	Field statusContainer:DockingView
	Field titleLabel:Label
	
	Method New()
		
		editorContainer=New DockingView
		
		titleLabel=New Label
		titleLabel.Gravity=New Vec2f( .5,0 )
		titleLabel.Layout="float"
		editorContainer.AddView( titleLabel,"top" )
		
		statusContainer=New DockingView
		editorContainer.AddView( statusContainer,"bottom" )
	End
	
	Method UpdateTitle()
		
		titleLabel.Text=MainWindow.DocsManager.CurrentDocumentLabel
	End
	
End


Class DraggableTabs
	
	Const Edges:=New String[]( "left","right","bottom" )
	
	Field tabs:=New StringMap<TabButtonExt>
	Field docks:=New StringMap<TabViewExt>
	Field sizes:=New StringMap<String>
	
	Method New()
		
		sizes["left"]="250"
		sizes["right"]="300"
		sizes["bottom"]="250"
		
		_docksArray=New TabViewExt[Edges.Length]
		Local i:=0
		For Local edge:=Eachin Edges
			docks[edge]=New TabViewExt
			_docksArray[i]=docks[edge]
			i+=1
		Next
	End
	
	Method AttachToParent( view:DockingView )
		
		For Local edge:=Eachin Edges
			view.AddView( docks[edge],edge,sizes[edge],True )
		Next
		_parent=view
	End
	
	Method DetachFromParent()
		
		If Not _parent Return
		
		For Local edge:=Eachin Edges
			_parent.RemoveView( docks[edge] )
		Next
	End
	
	Method AddTab( name:String,view:View )
		
		tabs[name]=TabViewExt.CreateDraggableTab( name,view,_docksArray )
		tabs[name].Undockable=True
	End
	
	Method GetDockSize:String( dock:TabViewExt )
		
		Return _parent.GetViewSize( dock )
	End
	
	Property AllDocks:TabViewExt[]()
		Return _docksArray
	End
	
	Private
	
	Field _docksArray:TabViewExt[]
	Field _parent:DockingView
	
End


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
