
Namespace ted2go


Class Monkey2KeyEventFilter Extends TextViewKeyEventFilter

	Property Name:String() Override
		Return "Monkey2KeyEventFilter"
	End
	
	
	Protected

	Method OnFilterKeyEvent( event:KeyEvent,textView:TextView ) Override
		
		Local ctrl:=(event.Modifiers & Modifier.Control)
		Local shift:=(event.Modifiers & Modifier.Shift)
		
		Select event.Type
		Case EventType.KeyDown
			
			Select event.Key
				
				Case Key.F1
					
					MainWindow.ShowHelp( "",ctrl )
					event.Eat()
					
				Case Key.F2
				
					MainWindow.GotoDeclaration()
					event.Eat()
				
'				Case Key.F10
'				
'					Print "works"
'					Local doc:=MainWindow.DocsManager.CurrentDocument
'					If Not doc Return
'					
'					New Fiber( Lambda()
'						
'						Local cmd:=Monkey2Parser.GetParseCommand( doc.Path )
'						
'						Local str:=LoadString( "process::"+cmd )
'						Local i:=str.Find( "{" )
'						If i=-1 Return
'						str=str.Slice( i )
'						
'						Local jobj:=JsonObject.Parse( str )
'						If Not jobj Return
'						
'						Local jsonTree:=New JsonTreeView( jobj )
'						
'						Local dialog:=New Dialog( "ParseInfo",jsonTree )
'						dialog.AddAction( "Close" ).Triggered=dialog.Close
'						dialog.MinSize=New Vec2i( 512,600 )
'						
'						dialog.Open()
'						
'					End )
			End
			
			
		Case EventType.KeyChar
			
			Select event.Key
				
				Case Key.Apostrophe 'ctrl+' - comment / uncomment block
				
					If  shift And ctrl 'uncomment
				
						OnCommentUncommentBlock( textView,CommentType.Uncomment )
						event.Eat()
				
					Elseif ctrl 'comment
				
						OnCommentUncommentBlock( textView,CommentType.Comment )
						event.Eat()
				
					Elseif textView.CanCopy 'try to com/uncom selection
				
						OnCommentUncommentBlock( textView,CommentType.Inverse )
						event.Eat()
				
					End
			End
			
		End
		
	End
	
	
	Private
	
	Method New()
		Super.New()
		_types=New String[]( ".monkey2" ) 
	End
	 
	Global _instance:=New Monkey2KeyEventFilter

	Method OnCommentUncommentBlock( tv:TextView,type:CommentType )
		
		Local doc:=tv.Document
		Local i1:=Min( tv.Cursor,tv.Anchor )
		Local i2:=Max( tv.Cursor,tv.Anchor )
		Local line1:=doc.FindLine( i1 )
		Local line2:=doc.FindLine( i2 )
		
		If type=CommentType.Inverse
			Local allCommented:=True
			For Local line:=line1 To line2
				Local s:= doc.GetLine( line )
				If s.Trim()="" Continue
				If Not s.StartsWith( "'" )
					allCommented=False
					Exit
				Endif
			Next
			type=allCommented ? CommentType.Uncomment Else CommentType.Comment
		Endif
		
		Local comment:=(type=CommentType.Comment)
		Local result:=""
		Local made:=False
		For Local line:=line1 To line2
			Local s:= doc.GetLine( line )
			If comment
				s="'"+s
				made=True
			Elseif s.StartsWith( "'" )
				s=s.Slice( 1 )
				made=True
			Endif
			If result Then result+="~n" 
			result+=s
		Next
		' if have changes
		If made
			i1=doc.StartOfLine( line1 )
			i2=doc.EndOfLine( line2 )
			tv.SelectText( i1,i2 )
			tv.ReplaceText( result )
			' select commented / uncommented lines
			tv.SelectText( i1,i1+result.Length )
		Endif
	End
	
	
	Enum CommentType
		Comment,
		Uncomment,
		Inverse
	End
	
End
