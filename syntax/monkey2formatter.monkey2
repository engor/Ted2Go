
Namespace ted2go


Class Monkey2CodeFormatter Extends CodeFormatterPlugin

	Property Name:String() Override
		Return "Monkey2CodeFormatter"
	End
	
	
	Private
	
	Global _instance:=New Monkey2CodeFormatter
	
	Method New()
		Super.New()
		_types=New String[](".monkey2")
	End
	
	Method Format(view:CodeTextView, row:Int=-1)
	
		Local doc:=view.Document
		Local cursor:=view.Cursor
		
		If row = -1 Then row=doc.FindLine( cursor )
		
		Local state:=doc.LineState( row )
		If state<>-1 Return
		
		Local text:=doc.Text
		Local start:=cursor
		While start And IsIdent( text[start-1] )
			start-=1
		Wend
		While start<text.Length And IsDigit( text[start] )
			start+=1
		Wend
		
		If start<text.Length 
			Local color:=doc.Colors[start]
			If color<>Highlighter.COLOR_KEYWORD And color<>Highlighter.COLOR_IDENT Return
		Endif
		
		Local ident:=text.Slice( start,cursor )
		If Not ident Return
		
		Local kw:=view.Keywords.Get( ident )
		If kw And kw<>ident Then doc.ReplaceText( cursor-ident.Length,cursor,kw )
		
	End

End
