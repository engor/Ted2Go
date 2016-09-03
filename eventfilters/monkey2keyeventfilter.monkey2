
Namespace ted2go


Class Monkey2KeyEventFilter Extends TextViewKeyEventFilter

	Property Name:String() Override
		Return "Monkey2KeyEventFilter"
	End
	
	Method GetFileTypes:String[]() Override
		Return _types
	End
	
	Method GetMainFileType:String() Override
		Return "monkey2"
	End
	
		
	Protected
	
	Method OnFilterKeyEvent( event:KeyEvent,textView:TextView ) Override
	
		Local codeView := Cast<CodeTextView>(textView)
		
		Select event.Type
		Case EventType.KeyDown, EventType.KeyRepeat
			
			Local ctrl := (event.Modifiers & Modifier.Control)
			
			Select event.Key
						
				Case Key.F1
					Local ident := codeView.IdentAtCursor()
					If ident Then MainWindow.ShowQuickHelp( ident )
				
				Case Key.Apostrophe 'ctrl+' - comment / uncomment block
					If ctrl
						
						
					End
										
				Case Key.Enter 'ctrl+enter - smart ending of expression
					If ctrl And Not codeView.CanCopy And codeView.IsCursorAtTheEndOfLine()
						Local ident := codeView.FirstIdentInLine(codeView.Cursor)
						Print "ident: "+ident
						ident = ident.ToLower()
						Select ident
							Case "method","function","class","interface","if","select"
								'need to add 'End' keyword here for rapid coding
								event.Eat()
						End
					Endif
			End
		End
		
	End
	
	
	Private
	
	Global _types := New String[]("monkey2")
	Global _instance := New Monkey2KeyEventFilter

End
