Namespace ted2go


Class PrefsDialog Extends DialogExt

	Field Apply:Void()
	
	Method New()
		
		Title="Preferences"
		
		_acShowAfter=New TextField( ""+Prefs.AcShowAfter )
		
		_acEnabled=New CheckButton( "Enabled" )
		_acEnabled.Checked=Prefs.AcEnabled
		
		_acKeywordsOnly=New CheckButton( "Keywords only" )
		_acKeywordsOnly.Checked=Prefs.AcKeywordsOnly
		
		_acUseTab=New CheckButton( "Choose by Tab" )
		_acUseTab.Checked=Prefs.AcUseTab
		
		_acUseEnter=New CheckButton( "Choose by Enter" )
		_acUseEnter.Checked=Prefs.AcUseEnter
		
		_acUseSpace=New CheckButton( "Choose by Space" )
		_acUseSpace.Checked=Prefs.AcUseSpace
		
		_acUseDot=New CheckButton( "Choose by Dot (.)" )
		_acUseDot.Checked=Prefs.AcUseDot
		
		_acNewLineByEnter=New CheckButton( "Add new line (by Enter)" )
		_acNewLineByEnter.Checked=Prefs.AcNewLineByEnter
		
		_editorToolBarVisible=New CheckButton( "ToolBar visible" )
		_editorToolBarVisible.Checked=Prefs.EditorToolBarVisible
		
		_editorGutterVisible=New CheckButton( "Gutter visible" )
		_editorGutterVisible.Checked=Prefs.EditorGutterVisible
		
		_mainToolBarVisible=New CheckButton( "ToolBar visible" )
		_mainToolBarVisible.Checked=Prefs.MainToolBarVisible
		
		_mainProjectTabsRight=New CheckButton( "Project tabs on the right side" )
		_mainProjectTabsRight.Checked=Prefs.MainProjectTabsRight
		
		_mainProjectIcons=New CheckButton( "Project file type icons" )
		_mainProjectIcons.Checked=Prefs.MainProjectIcons
		
		_editorShowWhiteSpaces=New CheckButton( "Whitespaces visible" )
		_editorShowWhiteSpaces.Checked=Prefs.EditorShowWhiteSpaces
		
		_editorShowEvery10LineNumber=New CheckButton( "Every 10th line number" )
		_editorShowEvery10LineNumber.Checked=Prefs.EditorShowEvery10LineNumber
		
		_editorCodeMapVisible=New CheckButton( "CodeMap visible" )
		_editorCodeMapVisible.Checked=Prefs.EditorCodeMapVisible
		
		Local path:=Prefs.EditorFontPath
		If Not path Then path=_defaultFont
		_editorFontPath=New TextField( path )
		_editorFontSize=New TextField( ""+Prefs.EditorFontSize )
		
		Local chooseFont:=New Action( "..." )
		chooseFont.Triggered+=Lambda()
			
			Local initDir:=RealPath( AssetsDir() )
			
			Local path:=MainWindow.RequestFile( "Choose Font",initDir,False,"Font files:ttf;Any files:*" )
			If Not path Return
			
			path=RealPath( path )
			path=path.Replace( initDir,"" )
			
			_editorFontPath.Text=path
		End
		Local btnChooseFont:=New PushButton( chooseFont )
		
		Local font:=New DockingView
		font.AddView( New Label( "Font" ),"left" )
		font.AddView( _editorFontPath,"left" )
		font.AddView( btnChooseFont,"left" )
		font.AddView( _editorFontSize,"left","45" )
		
		Local after:=New DockingView
		after.AddView( New Label( "Show after" ),"left" )
		after.AddView( _acShowAfter,"left" )
		
		' monkey path
		'
		_monkeyRootPath=New TextField( Prefs.MonkeyRootPath )
		_monkeyRootPath.Enabled=False
		Local chooseMonkeyPath:=New Action( "..." )
		chooseMonkeyPath.Triggered+=Lambda()
		
			Local initDir:=Prefs.MonkeyRootPath
		
			Local path:=MainWindow.RequestDir( "Choose Monkey2 root folder",initDir )
			If Not path Return
			
			' check path
			Local real:=SetupMonkeyRootPath( path,False )
			If real
				_monkeyRootPath.Text=path
				Prefs.MonkeyRootPath=path
				MainWindow.UpdateToolsPaths()
				Return
			Else
				' restore current
				ChangeDir( initDir )
			Endif
			
		End
		Local btnChooseMonkeyPath:=New PushButton( chooseMonkeyPath )
		
		Local monkeyPathDock:=New DockingView
		monkeyPathDock.AddView( New Label( "Monkey2 root folder" ),"left" )
		monkeyPathDock.AddView( _monkeyRootPath,"left" )
		monkeyPathDock.AddView( btnChooseMonkeyPath,"left" )
		
		'----------------------------
		' put into the form
		'----------------------------
		Local docker:=New DockingView
		
		docker.AddView( monkeyPathDock,"top" )
		
		docker.AddView( New Label( "------ Main:" ),"top" )
		docker.AddView( _mainProjectTabsRight,"top" )
		docker.AddView( _mainProjectIcons,"top" )
		docker.AddView( _mainToolBarVisible,"top" )
		docker.AddView( New Label( " " ),"top" )
		
		docker.AddView( New Label( "------ Code Editor:" ),"top" )
		docker.AddView( _editorToolBarVisible,"top" )
		docker.AddView( _editorGutterVisible,"top" )
		docker.AddView( _editorShowWhiteSpaces,"top" )
		docker.AddView( font,"top" )
		docker.AddView( _editorShowEvery10LineNumber,"top" )
		docker.AddView( _editorCodeMapVisible,"top" )
		docker.AddView( New Label( " " ),"top" )
		
		docker.AddView( New Label( "------ Completion:" ),"top" )
		docker.AddView( _acEnabled,"top" )
		docker.AddView( after,"top" )
		docker.AddView( _acUseTab,"top" )
		docker.AddView( _acUseEnter,"top" )
		docker.AddView( _acNewLineByEnter,"top" )
		docker.AddView( _acUseSpace,"top" )
		docker.AddView( _acUseDot,"top" )
		docker.AddView( _acKeywordsOnly,"top" )
		docker.AddView( New Label( " " ),"top" )
		'docker.AddView( New Label( "(Restart IDE to see all changes)" ),"top" )
		'docker.AddView( New Label( " " ),"top" )
		
		ContentView=docker
		
		Local apply:=AddAction( "Apply" )
		apply.Triggered=OnApply
		
		_acShowAfter.Activated+=_acShowAfter.MakeKeyView
		
		Deactivated+=MainWindow.UpdateKeyView
	End
	
	
	Private
	
	Const _defaultFont:="(default)"
	Field _acEnabled:CheckButton
	Field _acUseTab:CheckButton
	Field _acUseEnter:CheckButton
	Field _acUseSpace:CheckButton
	Field _acUseDot:CheckButton
	Field _acNewLineByEnter:CheckButton
	Field _acKeywordsOnly:CheckButton
	Field _acShowAfter:TextField
	
	Field _editorToolBarVisible:CheckButton
	Field _editorGutterVisible:CheckButton
	Field _editorShowWhiteSpaces:CheckButton
	Field _editorFontPath:TextField
	Field _editorFontSize:TextField
	Field _editorShowEvery10LineNumber:CheckButton
	Field _editorCodeMapVisible:CheckButton
	
	Field _mainToolBarVisible:CheckButton
	Field _mainProjectTabsRight:CheckButton
	Field _mainProjectIcons:CheckButton
	
	Field _monkeyRootPath:TextField
	
	Method OnApply()
	
		Prefs.AcEnabled=_acEnabled.Checked
		Prefs.AcUseTab=_acUseTab.Checked
		Prefs.AcUseEnter=_acUseEnter.Checked
		Prefs.AcUseSpace=_acUseSpace.Checked
		Prefs.AcUseDot=_acUseDot.Checked
		Prefs.AcNewLineByEnter=_acNewLineByEnter.Checked
		Prefs.AcKeywordsOnly=_acKeywordsOnly.Checked
		Local count:=Max( 1,Int( _acShowAfter.Text ) )
		Prefs.AcShowAfter=count
		
		Prefs.EditorToolBarVisible=_editorToolBarVisible.Checked
		Prefs.EditorGutterVisible=_editorGutterVisible.Checked
		Prefs.EditorShowWhiteSpaces=_editorShowWhiteSpaces.Checked
		Local path:=_editorFontPath.Text.Trim()
		If Not path Or path=_defaultFont Then path=""
		Prefs.EditorFontPath=path
		Local size:=_editorFontSize.Text.Trim()
		If Not size Then size="16" 'default
		Prefs.EditorFontSize=Int(size)
		Prefs.EditorShowEvery10LineNumber=_editorShowEvery10LineNumber.Checked
		Prefs.EditorCodeMapVisible=_editorCodeMapVisible.Checked
		
		Prefs.MainToolBarVisible=_mainToolBarVisible.Checked
		Prefs.MainProjectTabsRight=_mainProjectTabsRight.Checked
		Prefs.MainProjectIcons=_mainProjectIcons.Checked
		
		App.ThemeChanged()
		
		Hide()
		Apply()
		
		Prefs.SaveLocalState()
	End
	
End
