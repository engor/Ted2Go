
Namespace ted2go


Class TextViewExt Extends TextView

	Method New()
		Super.New()
		
		CursorColor=New Color( 1,1,1,0.6 )
		SelectionColor=New Color( .4,.4,.4 )
		CursorBlinkRate=2.5
		BlockCursor=False
		
	End
	
	
	Protected
	
	Property CurrentTextLine:TextLine()
		Return GetTextLine( Cursor,True,False )
	End
			
	Method OnKeyEvent( event:KeyEvent ) Override
		
		Select event.Type
			Case EventType.KeyDown,EventType.KeyRepeat
				
				Local ctrl:=event.Modifiers & Modifier.Control
				Local shift:=event.Modifiers & Modifier.Shift
				
				Select event.Key
				
					Case Key.Insert 'shift+insert - paste
						If shift
							Paste()
						Elseif ctrl And CanCopy
							Copy()
						Endif
					
					Case Key.KeyDelete
						
						If shift 'shift+del - cut selected
							If CanCopy Then Cut()
						Else
							If Anchor = Cursor And Cursor < Document.Text.Length Then SelectText( Cursor,Cursor+1 )
							ReplaceText( "" )
						Endif
						
					Case Key.Tab
						
						If Cursor = Anchor 'has no selection
							
							ReplaceText( "~t" )
							
						Else 'block tab/untab
						
							Local minPos:=Min( Cursor,Anchor )
							Local maxPos:=Max( Cursor,Anchor )
							Local min:=Document.FindLine( minPos )
							Local max:=Document.FindLine( maxPos )
														
							Local lines:=New StringStack
								
							For Local i:=min To max
								lines.Push( Document.GetLine( i ) )
							Next
								
							Local go:=True
							Local shiftFirst:=0,shiftLast:=0
							
							If shift
								
								Local changes:=0
								For Local i:=0 Until lines.Length
									If lines[i].StartsWith( "~t" )
										lines[i]=lines[i].Slice( 1 )+"~n"
										changes+=1
										If i=0
											shiftFirst=-1
										Elseif i=lines.Length-1
											shiftLast=-1
										Endif
									Else
										lines[i]+="~n"
									Endif
								Next
								
								go=(changes > 0)
							Else
								shiftFirst=1
								shiftLast=1
								For Local i:=0 Until lines.Length
									lines[i]="~t"+lines[i]+"~n"
								Next
							Endif
								
							If go
								Local start:=Document.StartOfLine( max )
								Local p1:=minPos+shiftFirst 'absolute pos
								Local p2:=maxPos-start+shiftLast 'pos in line
								SelectText( Document.StartOfLine( min ),Document.EndOfLine( max )+1 )
								ReplaceText( lines.Join( "" ) )
								p2+=Document.StartOfLine( max )
								SelectText( p1,p2 )
							Endif
								
						Endif
							
					Case Key.Enter,Key.KeypadEnter
						
						ReplaceText( "~n" )
					
					Case Key.Home
				
						Local newPos:=Document.StartOfLine( Document.FindLine( Cursor ) )
							
						If shift 'selection
							SelectText( Anchor,newPos )
						Else
							if ctrl Then newPos=0
							SelectText( newPos,newPos )
						Endif
					
					Case Key.X 'ctrl+x - cut selected
						If ctrl And CanCopy
							Cut()
						Endif
						
					Case Key.C,Key.Insert 'ctrl+c/insert - copy selected
						If ctrl And CanCopy
							Copy()
						Endif
					
					Default 'for keydown
						Super.OnKeyEvent( event )
					
				End
				
			Default 'for other types
				Super.OnKeyEvent( event )
					
		End
		
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Select event.Type
			
			Case EventType.MouseWheel 'little faster scroll
		
				Scroll-=New Vec2i( 0,RenderStyle.Font.Height*event.Wheel.Y*3 )
				Return
				
		End

		Super.OnContentMouseEvent( event )
					
	End
	
	#Rem
	Method SelectWordUnderCursor()
		Local text:=Text
		Local n:=Cursor
		If (Not IsIdent(text[n]))
			SelectText(n,n+1)
			Return
		Endif
		While (n And IsIdent(text[n]))
			n-=1
		Wend
		Local start:=n+1
		Local len:=Document.TextLength
		n=Cursor
		While (n < len And IsIdent(text[n]))
			n+=1
		Wend
		Local ends:=n
		SelectText(start,ends)
	End
	#End
	
	Method GetTextLine:TextLine( cursor:Int,getText:Bool=False,useCached:Bool=True )
		If useCached
			If _lineInfo = Null Then _lineInfo=New TextLine( Document )
			Return _lineInfo.Refresh( cursor,getText )
		Else
			Return New TextLine( Document ).Refresh( cursor,getText )
		Endif
	End
	
	
	Private
	
	Field _animatedCursor:Bool
	Field _lineInfo:TextLine
	
	
End


'helper for lines

Struct TextLine
	
	Method New( doc:TextDocument )
		_doc=doc
	End
	
	Method Refresh:TextLine( cursor:Int,getText:Bool=False )
		Self.cursor=cursor
		line=_doc.FindLine( cursor )
		posStart=_doc.StartOfLine( line )
		posEnd=_doc.EndOfLine( line )
		posInLine=cursor-posStart
		If getText
			text=_doc.GetLine( line )
		Else
			text=Null
		Endif
		Return Self
	End

	Field posStart:Int
	Field posEnd:Int
	Field posInLine:Int
	Field text:String
	Field line:Int
	Field cursor:Int
	
	Private
	
	Field _doc:TextDocument
End
