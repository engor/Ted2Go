
Namespace ted2go


Class Ted2CodeTextView Extends CodeTextView

	Property FileType:String() 'where else we can store this type?
		return _type
	Setter( value:String )
		_type=value
		Keywords = KeywordsManager.Get(_type)
		Highlighter = HighlightersManager.Get(_type)
		Formatter = FormattersManager.Get(_type)
		Document.TextHighlighter = Highlighter.Painter
	End
	
	Property FilePath:String()
		return _path
	Setter(value:String)
		_path = value
	End
	
	Method LoadCode( path:String,type:String=".monkey2" )
		
		If Not type Then type=ExtractExt( path )
		FileType=type
		FilePath=path
		Text=LoadString( path )
	End
	
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self,FileType )
		
		If Not event.Eaten
			Super.OnKeyEvent( event )
		Endif
		
	End

	Private
	
	Field _type:String
	Field _path:String
	
End
