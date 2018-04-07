
Namespace ted2go


Class GotoActions
	
	Field goBack:Action
	Field goForward:Action
	Field gotoLine:Action
	Field gotoDeclaration:Action
	
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
		gotoDeclaration.HotKey=Key.F12
	End
	
	
	Private
	
	Field _docs:DocumentManager
	
	Method OnGoBack()
		
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		If Not doc Return
		
		doc.GoBack()
	End
	
	Method OnGoForward()
	
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		If Not doc Return
	
		doc.GoForward()
	End
	
	Method OnGotoLine()
	
		MainWindow.GotoLine()
	End
	
	Method OnGotoDeclaration()
	
		MainWindow.GotoDeclaration()
	End
	
End
