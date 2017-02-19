
Namespace ted2go


Class ViewActions
	
	Field goBack:Action
	Field goForward:Action
	Field comment:Action
	Field uncomment:Action
	
	Method New( docs:DocumentManager )
		
		_docs=docs
		
		goBack=New Action( "Go back" )
		goBack.Triggered=OnGoBack
		goBack.HotKey=Key.Left
		goBack.HotKeyModifiers=Modifier.Alt
		
		goForward=New Action( "Go forward" )
		goForward.Triggered=OnGoForward
		goForward.HotKey=Key.Right
		goForward.HotKeyModifiers=Modifier.Alt
		
		comment=New Action( "Comment block" )
		comment.Triggered=OnComment
#If __TARGET__="macos"
		comment.HotKey=Key.Slash
#Else
		comment.HotKey=Key.Apostrophe
#Endif
		comment.HotKeyModifiers=Modifier.Menu
		
		uncomment=New Action( "Uncomment block" )
		uncomment.Triggered=OnUncomment
#If __TARGET__="macos"
		uncomment.HotKey=Key.Slash
#Else
		uncomment.HotKey=Key.Apostrophe
#Endif
		uncomment.HotKeyModifiers=Modifier.Menu|Modifier.Shift
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
	
	Method OnComment()
	
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		If Not doc Return
	
		doc.Comment()
	End
	
	Method OnUncomment()
	
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		If Not doc Return
	
		doc.Uncomment()
	End
End
