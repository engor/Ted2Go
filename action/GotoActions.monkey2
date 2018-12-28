
Namespace ted2go


Class GotoActions
	
	Field goBack:Action
	Field goForward:Action
	Field gotoLine:Action
	Field gotoDeclaration:Action
	Field prevScope:Action
	Field nextScope:Action
	
	Method New( docs:DocumentManager )
		
		_docs=docs
		
		goBack=New Action( "Jump back" )
		goBack.Triggered=OnGoBack
		goBack.HotKey=Key.Left
		goBack.HotKeyModifiers=Modifier.Alt|Modifier.Menu
		
		goForward=New Action( "Jump forward" )
		goForward.Triggered=OnGoForward
		goForward.HotKey=Key.Right
		goForward.HotKeyModifiers=Modifier.Alt|Modifier.Menu
		
		gotoLine=New Action( "Goto line" )
		gotoLine.Triggered=OnGotoLine
		gotoLine.HotKey=Key.G
		gotoLine.HotKeyModifiers=Modifier.Menu
		
		gotoDeclaration=New Action( "Goto definition" )
		gotoDeclaration.Triggered=OnGotoDeclaration
		#If __TARGET__="macos"
		gotoDeclaration.HotKey=Key.B
		gotoDeclaration.HotKeyModifiers=Modifier.Menu
		#Else
		gotoDeclaration.HotKey=Key.F12
		#Endif
		
		prevScope=New Action( "Previous scope" )
		prevScope.Triggered=OnPrevScope
		prevScope.HotKey=Key.Up
		#If __TARGET__="macos"
		prevScope.HotKeyModifiers=Modifier.Alt|Modifier.Control
		#Else
		prevScope.HotKeyModifiers=Modifier.Alt
		#Endif
		
		nextScope=New Action( "Next scope" )
		nextScope.Triggered=OnNextScope
		nextScope.HotKey=Key.Down
		#If __TARGET__="macos"
		nextScope.HotKeyModifiers=Modifier.Alt|Modifier.Control
		#Else
		nextScope.HotKeyModifiers=Modifier.Alt
		#Endif
		
		
	End
	
	
	Private
	
	Field _docs:DocumentManager
	
	Method OnGoBack()
		
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		doc?.GoBack()
	End
	
	Method OnGoForward()
	
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		doc?.GoForward()
	End
	
	Method OnGotoLine()
	
		MainWindow.GotoLine()
	End
	
	Method OnGotoDeclaration()
	
		MainWindow.GotoDeclaration()
	End
	
	Method OnPrevScope()
		
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		doc?.JumpToPreviousScope()
	End
	
	Method OnNextScope()
		
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		doc?.JumpToNextScope()
	End
	
End
