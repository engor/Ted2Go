
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
	
	Method Format( view:CodeTextView, all:Bool )
	
		Local doc:=view.Document
		Local cursor:=view.Cursor
		
		'ignore comments...
		'
		Local state:=doc.LineState( doc.FindLine( cursor ) )
		If state & 255 <> 255 Return
		
		Local text:=doc.Text
		Local start:=cursor
		Local term:=all ? text.Length Else start

		'find start of ident
		'		
		While start And IsIdent( text[start-1] )
			start-=1
		Wend
		While start<cursor And IsDigit( text[start] )
			start+=1
		Wend
		If start>=term Or Not IsIdent( text[start] ) Return
		
		'only capitalize keywords and idents
		'
		Local color:=doc.Colors[start]
		If color<>Highlighter.COLOR_KEYWORD And color<>Highlighter.COLOR_IDENT
			'
			If color<>Highlighter.COLOR_PREPROC Return
			'
			'only do first ident on preproc line
			'
			Local i:=start
			While i And text[i-1]<=32
				i-=1
			Wend
			If Not i Or text[i-1]<>35 Return
			i-=1
			While i And text[i-1]<>10
				i-=1
				If text[i]>32 Return
			Wend
			'
		Endif

		'find end of ident
		Local ends:=start
		'
		While ends<term And IsIdent( text[ends] ) And text[ends]<>10
			ends+=1
		Wend
		If ends=start return

		Local ident:=text.Slice( start,ends )

		Local kw:=view.Keywords.Get( ident )
		
		If kw=ident Return
		
		doc.ReplaceText( start,ends,kw )
	End

End
