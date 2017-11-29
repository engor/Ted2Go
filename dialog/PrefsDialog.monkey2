
Namespace ted2go


Class PrefsDialog Extends DialogExt

	Field Apply:Void()
	
	Method New()
		
		Title="Preferences"
		
		Local tabView:=New TabView
		Local docker:DockingView
		
		' Main
		'
		docker=GetMainDock()
		tabView.AddTab( "Common",docker,True )
		
		' Editor
		'
		docker=GetEditorDock()
		tabView.AddTab( "Editor",docker )
		
		' Completion
		'
		docker=GetCompletionDock()
		tabView.AddTab( "AutoComplete",docker )
		
		' Chat
		'
		docker=GetChatDock()
		tabView.AddTab( "IRC chat",docker )
		
		' Live Templates
		'
		docker=GetLiveTemplatesDock()
		tabView.AddTab( "CodeTemplates",docker )
		
		ContentView=tabView
		
		Local cancel:=AddAction( "Cancel" )
		cancel.Triggered=Hide
		SetKeyAction( Key.Escape,cancel )
		
		Local apply:=AddAction( "Apply changes" )
		apply.Triggered=OnApply
		
		_acShowAfter.Activated+=_acShowAfter.MakeKeyView
		
		Deactivated+=MainWindow.UpdateKeyView
		
		MinSize=New Vec2i( 550,500 )
		MaxSize=New Vec2i( 550,600 )
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
	Field _acShowAfter:TextFieldExt
	Field _acUseLiveTemplates:CheckButton
	
	Field _editorToolBarVisible:CheckButton
	Field _editorGutterVisible:CheckButton
	Field _editorShowWhiteSpaces:CheckButton
	Field _editorFontPath:TextFieldExt
	Field _editorFontSize:TextFieldExt
	Field _editorShowEvery10LineNumber:CheckButton
	Field _editorCodeMapVisible:CheckButton
	Field _editorAutoIndent:CheckButton
	Field _editorAutoPairs:CheckButton
	Field _editorSurround:CheckButton
	Field _editorShowParamsHint:CheckButton
	
	Field _mainToolBarVisible:CheckButton
	Field _mainProjectIcons:CheckButton
	Field _mainProjectSingleClickExpanding:CheckButton
	Field _mainPlaceDocsAtBegin:CheckButton
	
	Field _monkeyRootPath:TextFieldExt
	
	Field _chatNick:TextFieldExt
	Field _chatServer:TextFieldExt
	Field _chatPort:TextFieldExt
	Field _chatRooms:TextFieldExt
	Field _chatAutoConnect:CheckButton
	
	Field _codeView:Ted2CodeTextView
	Field _treeView:TreeViewExt
	
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
		Prefs.AcUseLiveTemplates=_acUseLiveTemplates.Checked
		
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
		Prefs.EditorAutoIndent=_editorAutoIndent.Checked
		Prefs.EditorAutoPairs=_editorAutoPairs.Checked
		Prefs.EditorSurroundSelection=_editorSurround.Checked
		Prefs.EditorShowParamsHint=_editorShowParamsHint.Checked
		
		Prefs.MainToolBarVisible=_mainToolBarVisible.Checked
		Prefs.MainProjectIcons=_mainProjectIcons.Checked
		Prefs.MainProjectSingleClickExpanding=_mainProjectSingleClickExpanding.Checked
		Prefs.MainPlaceDocsAtBegin=_mainPlaceDocsAtBegin.Checked
		
		Prefs.IrcNickname=_chatNick.Text
		Prefs.IrcServer=_chatServer.Text
		Prefs.IrcPort=Int(_chatPort.Text)
		Prefs.IrcRooms=_chatRooms.Text
		Prefs.IrcConnect=_chatAutoConnect.Checked
		
		App.ThemeChanged()
		
		Hide()
		Apply()
		
		Prefs.SaveLocalState()
		
		LiveTemplates.Save()
	End
	
	Method GetMainDock:DockingView()
		
		_mainToolBarVisible=New CheckButton( "ToolBar visible" )
		_mainToolBarVisible.Checked=Prefs.MainToolBarVisible
		
		_mainProjectIcons=New CheckButton( "Project file type icons" )
		_mainProjectIcons.Checked=Prefs.MainProjectIcons
		
		_mainProjectSingleClickExpanding=New CheckButton( "Project tree single-click mode" )
		_mainProjectSingleClickExpanding.Checked=Prefs.MainProjectSingleClickExpanding
		
		_mainPlaceDocsAtBegin=New CheckButton( "Place opened document to the left side" )
		_mainPlaceDocsAtBegin.Checked=Prefs.MainPlaceDocsAtBegin
		
		_monkeyRootPath=New TextFieldExt( Prefs.MonkeyRootPath )
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
		
		Local docker:=New DockingView
		Local monkeyPathDock:=New DockingView
		monkeyPathDock.AddView( New Label( "Monkey2 root folder" ),"left" )
		monkeyPathDock.AddView( _monkeyRootPath,"left" )
		monkeyPathDock.AddView( btnChooseMonkeyPath,"left" )
		
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( monkeyPathDock,"top" )
		
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( _mainProjectIcons,"top" )
		docker.AddView( _mainToolBarVisible,"top" )
		docker.AddView( _mainProjectSingleClickExpanding,"top" )
		docker.AddView( _mainPlaceDocsAtBegin,"top" )
		docker.AddView( New Label( " " ),"top" )
		
		Return docker
	End
	
	Method GetEditorDock:DockingView()
		
		_editorToolBarVisible=New CheckButton( "ToolBar visible" )
		_editorToolBarVisible.Checked=Prefs.EditorToolBarVisible
		
		_editorGutterVisible=New CheckButton( "Gutter visible" )
		_editorGutterVisible.Checked=Prefs.EditorGutterVisible
		
		_editorShowWhiteSpaces=New CheckButton( "Whitespaces visible" )
		_editorShowWhiteSpaces.Checked=Prefs.EditorShowWhiteSpaces
		
		_editorShowEvery10LineNumber=New CheckButton( "Every 10th line number" )
		_editorShowEvery10LineNumber.Checked=Prefs.EditorShowEvery10LineNumber
		
		_editorCodeMapVisible=New CheckButton( "CodeMap visible" )
		_editorCodeMapVisible.Checked=Prefs.EditorCodeMapVisible
		
		_editorAutoIndent=New CheckButton( "Auto indentation" )
		_editorAutoIndent.Checked=Prefs.EditorAutoIndent
		
		_editorAutoPairs=New CheckButton( "Auto pair quotes and brackets: ~q~q, (), []" )
		_editorAutoPairs.Checked=Prefs.EditorAutoPairs
		
		_editorSurround=New CheckButton( "Surround selected text with ~q~q, (), []" )
		_editorSurround.Checked=Prefs.EditorSurroundSelection
		
		_editorShowParamsHint=New CheckButton( "Show parameters hint" )
		_editorShowParamsHint.Checked=Prefs.EditorShowParamsHint
		
		Local path:=Prefs.EditorFontPath
		If Not path Then path=_defaultFont
		_editorFontPath=New TextFieldExt( "" )
		_editorFontPath.TextChanged+=Lambda()
		
			Local enabled:=(_editorFontPath.Text<>_defaultFont)
			_editorFontSize.Enabled=enabled
		End
		_editorFontSize=New TextFieldExt( ""+Prefs.EditorFontSize )
		_editorFontPath.Text=path
		_editorFontPath.ReadOnly=True
		
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
		
		Local resetFont:=New Action( "reset" )
		resetFont.Triggered+=Lambda()
		
			_editorFontPath.Text=_defaultFont
		End
		Local btnResetFont:=New PushButton( resetFont )
		
		Local font:=New DockingView
		font.AddView( New Label( "Font" ),"left" )
		font.AddView( _editorFontPath,"left" )
		font.AddView( _editorFontSize,"left","45" )
		font.AddView( btnChooseFont,"left" )
		font.AddView( btnResetFont,"left" )
		
		Local docker:=New DockingView
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( _editorToolBarVisible,"top" )
		docker.AddView( _editorGutterVisible,"top" )
		docker.AddView( _editorShowWhiteSpaces,"top" )
		docker.AddView( font,"top" )
		docker.AddView( _editorShowEvery10LineNumber,"top" )
		docker.AddView( _editorCodeMapVisible,"top" )
		docker.AddView( _editorAutoIndent,"top" )
		docker.AddView( _editorAutoPairs,"top" )
		docker.AddView( _editorSurround,"top" )
		docker.AddView( _editorShowParamsHint,"top" )
		docker.AddView( New Label( " " ),"top" )
		
		Return docker
	End
	
	Method GetCompletionDock:DockingView()
		
		_acShowAfter=New TextFieldExt( ""+Prefs.AcShowAfter )
		
		Local after:=New DockingView
		after.AddView( New Label( "Show after" ),"left" )
		after.AddView( _acShowAfter,"left" )
		
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
		
		_acUseLiveTemplates=New CheckButton( "Show live templates" )
		_acUseLiveTemplates.Checked=Prefs.AcUseLiveTemplates
		
		Local docker:=New DockingView
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( _acEnabled,"top" )
		docker.AddView( after,"top" )
		docker.AddView( _acUseTab,"top" )
		docker.AddView( _acUseEnter,"top" )
		docker.AddView( _acNewLineByEnter,"top" )
		docker.AddView( _acUseSpace,"top" )
		docker.AddView( _acUseDot,"top" )
		docker.AddView( _acKeywordsOnly,"top" )
		docker.AddView( _acUseLiveTemplates,"top" )
		docker.AddView( New Label( " " ),"top" )
		
		Return docker
	End
	
	Method GetChatDock:DockingView()
		
		Local chatTable:=New TableView( 2,6 )
		_chatNick=New TextFieldExt( Prefs.IrcNickname )
		_chatServer=New TextFieldExt( Prefs.IrcServer )
		_chatPort=New TextFieldExt( ""+Prefs.IrcPort )
		_chatRooms=New TextFieldExt( Prefs.IrcRooms )
		_chatAutoConnect=New CheckButton( "Auto connect at start" )
		_chatAutoConnect.Checked=Prefs.IrcConnect
		chatTable[0,0]=New Label( "Nickname" )
		chatTable[1,0]=_chatNick
		chatTable[0,1]=New Label( "Server" )
		chatTable[1,1]=_chatServer
		chatTable[0,2]=New Label( "Port" )
		chatTable[1,2]=_chatPort
		chatTable[0,3]=New Label( "Rooms" )
		chatTable[1,3]=_chatRooms
		chatTable[0,4]=_chatAutoConnect
		chatTable[0,5]=New Label( "" ) 'bottom padding hack
		
		Local docker:=New DockingView
		docker.AddView( New Label( " " ),"top" )
		docker.AddView( chatTable,"top" )
		
		Return docker
	End
	
	Method GetLiveTemplatesDock:DockingView()
	
		Local treeDock:=New DockingView
		Local tree:=New TreeViewExt
		_treeView=tree
		
		Local dockButtons:=New DockingView
		Local st:=dockButtons.Style.Copy()
		st.Margin=New Recti( 0,-5,0,0 )
		dockButtons.Style=st
		
		Local btn:=New ToolButtonExt( New Action( "Add" ),"Add new template" )
		btn.Clicked=Lambda()
			New Fiber( Lambda()
				Local name:=RequestString( "New template name:","" )
				name=name.Trim()
				If name AddTemplate( name )
			End )
		End
		dockButtons.AddView( btn,"right" )
		
		btn=New ToolButtonExt( New Action( "Clone" ),"Clone selected" )
		btn.Clicked=Lambda()
			New Fiber( Lambda()
				If Not TemplateSelName
					Alert( "Please, select an item to clone from!" )
					Return
				Endif
				Local name:=RequestString( "New template name:","" )
				name=name.Trim()
				If name CloneTemplate( name )
			End )
		End
		dockButtons.AddView( btn,"right" )
		
		btn=New ToolButtonExt( New Action( "Del" ),"Remove selected" )
		btn.Clicked=Lambda()
			RemoveTemplate()
		End
		dockButtons.AddView( btn,"right" )
		
		btn=New ToolButtonExt( New Action( "..." ),"Open containing folder (customTemplates.json)" )
		btn.Clicked=Lambda()
			OpenUrl( Prefs.IdeHomeDir )
		End
		dockButtons.AddView( btn,"right" )
		
		treeDock.ContentView=tree
		treeDock.AddView( dockButtons,"bottom" )
		
		Local docker1:=New DockingView
		docker1.AddView( treeDock,"left","170",True)
		
		_codeView=New Ted2CodeTextView
		_codeView.ShowWhiteSpaces=True
		_codeView.Document.TextChanged+=Lambda()
			
			Local name:=TemplateSelName
			If name Then LiveTemplates[TemplateSelLang,name]=_codeView.Text
		End
		docker1.ContentView=_codeView
		
		Local docker2:=New DockingView
		docker2.AddView( New Label( "Press 'Tab' in completion list or editor to insert template." ),"top" )
		docker2.ContentView=docker1
		
		PrepareTree( tree )
		
		Return docker2
	End
	
	Method ShowTemplate( lang:String,name:String )
		
		If _codeView.FileType<>lang Then _codeView.FileType=lang
		_codeView.Text=LiveTemplates[lang,name]
		_codeView.SelectText( 0,0 )
	End
	
	Method PrepareTree( tree:TreeViewExt)
		
		tree.RootNodeVisible=False
		tree.RootNode.Expanded=True
		tree.SelectedChanged+=Lambda( node:TreeView.Node )
		
			If Not node Return
		
			If node.Parent=tree.RootNode Return
		
			ShowTemplate( node.Parent.Text,node.Text )
		End
		
		For Local map:=Eachin LiveTemplates.All()
			Local node:=New TreeView.Node( map.Key,tree.RootNode )
			For Local i:=Eachin map.Value.All()
				New TreeView.Node( i.Key,node )
			Next
		Next
		
		Local n:=tree.RootNode
		If n.NumChildren > 0
			n=n.Children[0]
			If n.NumChildren > 0
				_treeView.Selected=n.Children[0]
			Endif
		Endif
	End
	
	Method AddTemplate( name:String )
		
		Local lang:=TemplateSelLang
		If LiveTemplates[lang,name]
			Alert( "Such name already exists!" )
			Return
		Endif
		AddTemplateInternal( lang,name,"" )
	End
	
	Method CloneTemplate( name:String )
	
		Local lang:=TemplateSelLang
		If LiveTemplates[lang,name]
			Alert( "Such name already exists!" )
			Return
		Endif
		AddTemplateInternal( lang,name,LiveTemplates[lang,TemplateSelName] )
	End
	
	Method RemoveTemplate()
		
		If Not TemplateSelName
			Alert( "Have no selected item to remove!" )
			Return
		Endif
		
		DebugStop()
		LiveTemplates[TemplateSelLang].Remove( TemplateSelName )
		_treeView.RemoveNode( _treeView.Selected )
		_codeView.Text=""
	End
	
	Method AddTemplateInternal( lang:String,name:String,value:String )
		
		LiveTemplates[lang,name]=value
		Local n:=_treeView.FindSubNode( lang,_treeView.RootNode )
		Local n2:=New TreeView.Node( name,n )
		_treeView.Selected=n2
		
		_codeView.MakeKeyView()
	End
	
	Property TemplateSelLang:String()
		
		Local sel:=_treeView.Selected
		If Not sel Return Null
		
		Return (sel.Parent=_treeView.RootNode) ? sel.Text Else sel.Parent.Text
	End
	
	Property TemplateSelName:String()
		
		Local sel:=_treeView.Selected
		If Not sel Return Null
		
		Return (sel.Parent=_treeView.RootNode) ? Null Else sel.Text
	End
	
End
