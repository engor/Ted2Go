
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
					
					MainWindow.ShowQuickHelp()
					event.Eat()
					
				Case Key.F2
				
					MainWindow.GotoDeclaration()
					event.Eat()
				
				Case Key.Apostrophe 'ctrl+' - comment / uncomment block
				
					If  shift And ctrl 'uncomment
						
						OnCommentUncommentBlock( textView,False )
						event.Eat()
						
					Elseif ctrl 'comment
					
						OnCommentUncommentBlock( textView,True )
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

	Method OnCommentUncommentBlock( textView:TextView,comment:Bool )
		
		Local doc:=textView.Document
		Local i1:=Min( textView.Cursor,textView.Anchor )
		Local i2:=Max( textView.Cursor,textView.Anchor )
		Local line1:=doc.FindLine( i1 )
		Local line2:=doc.FindLine( i2 )
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
			textView.SelectText( i1,i2 )
			textView.ReplaceText( result )
		Endif
	End
	
End
