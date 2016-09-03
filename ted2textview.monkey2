
Namespace ted2go


Class Ted2CodeTextView Extends CodeTextView

	Property FileType:String() 'where else we can store this type?
		return _type
	Setter(value:String)
		_type = value
		Keywords = KeywordsManager.Get(_type)
		Highlighter = HighlightersManager.Get(_type)
		Formatter = FormattersManager.Get(_type)
		Document.TextHighlighter = Highlighter.Painter
	End
	
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self,FileType )
		
		If Not event.Eaten
			Super.OnKeyEvent( event )
		Endif
		
	End

	private
	
	Field _type:String
	
End


Class Ted2TextView Extends TextView

	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self )
		
		If Not event.Eaten Super.OnKeyEvent( event )
	End

End

