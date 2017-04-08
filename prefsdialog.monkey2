Namespace ted2go


Class PrefsDialog Extends DialogExt

	Field Apply:Void()
	
	Method New()
		
		Title="Prefs"
		
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
		
		_acNewLineByEnter=New CheckButton( "Add new line (by Enter)" )
		_acNewLineByEnter.Checked=Prefs.AcNewLineByEnter
		
		_editorToolBarVisible=New CheckButton( "ToolBar visible" )
		_editorToolBarVisible.Checked=Prefs.EditorToolBarVisible
		
		_editorGutterVisible=New CheckButton( "Gutter visible" )
		_editorGutterVisible.Checked=Prefs.EditorGutterVisible
		
		_mainToolBarVisible=New CheckButton( "ToolBar visible" )
		_mainToolBarVisible.Checked=Prefs.MainToolBarVisible
		_mainProjectRight=New CheckButton( "Project view position:left/right" )
		_mainProjectRight.Checked=Prefs.MainProjectRight
		
		_editorShowWhiteSpaces=New CheckButton( "Whitespaces visible" )
		_editorShowWhiteSpaces.Checked=Prefs.EditorShowWhiteSpaces
		
		_editorFontName=New TextField( Prefs.EditorFontName )
		_editorFontSize=New TextField( Prefs.EditorFontSize )
		
		Local font:=New DockingView
		font.AddView( New Label( "Font" ),"left" )
		font.AddView( _editorFontName,"left" )
		font.AddView( _editorFontSize,"left","45" )
		
		Local after:=New DockingView
		after.AddView( New Label( "Show after" ),"left" )
		after.AddView( _acShowAfter,"left" )
		
		Local docker:=New DockingView
		docker.AddView( New Label( "[Main]" ),"top" )
		docker.AddView( _mainToolBarVisible,"top" )
		docker.AddView( _mainProjectRight,"top" )
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( New Label( "[Code Editor]" ),"top" )
		docker.AddView( _editorToolBarVisible,"top" )
		docker.AddView( _editorGutterVisible,"top" )
		docker.AddView( _editorShowWhiteSpaces,"top" )
		docker.AddView( font,"top" )
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( New Label( "[Completion]" ),"top" )
		docker.AddView( _acEnabled,"top" )
		docker.AddView( after,"top" )
		docker.AddView( _acUseTab,"top" )
		docker.AddView( _acUseEnter,"top" )
		docker.AddView( _acNewLineByEnter,"top" )
		docker.AddView( _acUseSpace,"top" )
		docker.AddView( _acKeywordsOnly,"top" )
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( New Label( "(Restart IDE to see all changes)" ),"top" )
		docker.AddView( New Label( " " ),"top" )
		
		ContentView=docker
		
		Local apply:=AddAction( "Apply" )
		apply.Triggered=OnApply
		
		_acShowAfter.Activated+=_acShowAfter.MakeKeyView
		
		Deactivated+=MainWindow.UpdateKeyView
	End
	
	
	Private
	
	Field _acEnabled:CheckButton
	Field _acUseTab:CheckButton
	Field _acUseEnter:CheckButton
	Field _acUseSpace:CheckButton
	Field _acNewLineByEnter:CheckButton
	Field _acKeywordsOnly:CheckButton
	Field _acShowAfter:TextField
	
	Field _editorToolBarVisible:CheckButton
	Field _editorGutterVisible:CheckButton
	Field _editorShowWhiteSpaces:CheckButton
	Field _editorFontName:TextField
	Field _editorFontSize:TextField
	
	Field _mainToolBarVisible:CheckButton
	Field _mainProjectRight:CheckButton
	
	Method OnApply()
	
		Prefs.AcEnabled=_acEnabled.Checked
		Prefs.AcUseTab=_acUseTab.Checked
		Prefs.AcUseEnter=_acUseEnter.Checked
		Prefs.AcUseSpace=_acUseSpace.Checked
		Prefs.AcNewLineByEnter=_acNewLineByEnter.Checked
		Prefs.AcKeywordsOnly=_acKeywordsOnly.Checked
		Local count:=Max( 1,Int( _acShowAfter.Text ) )
		Prefs.AcShowAfter=count
		
		Prefs.EditorToolBarVisible=_editorToolBarVisible.Checked
		Prefs.EditorGutterVisible=_editorGutterVisible.Checked
		Prefs.EditorShowWhiteSpaces=_editorShowWhiteSpaces.Checked
		Prefs.EditorFontName=_editorFontName.Text
		Prefs.EditorFontSize=Int(_editorFontSize.Text)
		If Int(Prefs.EditorFontSize)<=0 Then Prefs.EditorFontSize=""
		
		Prefs.MainToolBarVisible=_mainToolBarVisible.Checked
		Prefs.MainProjectRight=_mainProjectRight.Checked
		
		App.ThemeChanged()
		
		Hide()
		Apply()
	End
	
End
