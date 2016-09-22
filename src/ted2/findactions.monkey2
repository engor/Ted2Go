
Namespace ted2

Class FindActions

	Field find:Action
	Field findNext:Action
	field findPrevious:Action
	Field replace:Action
	Field replaceAll:Action
	
	Method New( docs:DocumentManager )
		
		_docs=docs
		
		find=New Action( "Find" )
		find.Triggered=OnFind
		find.HotKey=Key.F
		find.HotKeyModifiers=Modifier.Menu
		
		findNext=New Action( "Find next" )
		findNext.Triggered=OnFindNext
		findNext.HotKey=Key.F3
		
		findPrevious=New Action( "Find previous" )
		findPrevious.Triggered=OnFindPrevious
		findPrevious.HotKey=Key.F3
		findPrevious.HotKeyModifiers=Modifier.Shift
		
		replace=New Action( "Replace" )
		replace.Triggered=OnReplace
		
		replaceAll=New Action( "Replace all" )
		replaceAll.Triggered=OnReplaceAll
		
		_findDialog=New FindDialog( Self )
	End
	
	Method Update()
	
		Local tv:=_docs.CurrentTextView
		findNext.Enabled=tv
		findPrevious.Enabled=tv
		replace.Enabled=tv
		replaceAll.Enabled=tv
	End
	
	Private
	
	Field _docs:DocumentManager
	
	Field _findDialog:FindDialog
	
	Method OnFind()
	
		_findDialog.Open()
	End
	
	Method OnFindNext()
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return
		
		Local text:=_findDialog.FindText
		If Not text Return
		
		Local tvtext:=tv.Text
		Local cursor:=Max( tv.Anchor,tv.Cursor )
		
		If Not _findDialog.CaseSensitive
			tvtext=tvtext.ToLower()
			text=text.ToLower()
		Endif
		
		Local i:=tvtext.Find( text,cursor )
		If i=-1
			i=tvtext.Find( text )
			If i=-1 Return
		Endif
		
		tv.SelectText( i,i+text.Length )
	End
	
	Method OnFindPrevious()
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return

		Local text:=_findDialog.FindText
		If Not text Return

		Local tvtext:=tv.Text
		Local cursor:=Min( tv.Anchor,tv.Cursor )
		
		If Not _findDialog.CaseSensitive
			tvtext=tvtext.ToLower()
			text=text.ToLower()
		Endif
		
		Local i:=tvtext.Find( text )
		If i=-1 Return
		
		If i>=cursor
			i=tvtext.FindLast( text )
		Else
			Repeat
				Local n:=tvtext.Find( text,i+text.Length )
				If n>=cursor Exit
				i=n
			Forever
		End
		
		tv.SelectText( i,i+text.Length )
	End
	
	Method OnReplace()
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return
		
		Local text:=_findDialog.FindText
		If Not text Return
		
		Local min:=Min( tv.Anchor,tv.Cursor )
		Local max:=Max( tv.Anchor,tv.Cursor )
		
		Local tvtext:=tv.Text.Slice( min,max )

		If Not _findDialog.CaseSensitive
			tvtext=tvtext.ToLower()
			text=text.ToLower()
		Endif
		
		If tvtext<>text Return
		
		tv.ReplaceText( _findDialog.ReplaceText )
		
		OnFindNext()

	End
	
	Method OnReplaceAll()
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return
		
		Local text:=_findDialog.FindText
		If Not text Return
		
		Local rtext:=_findDialog.ReplaceText
		
		Local tvtext:=tv.Text

		If Not _findDialog.CaseSensitive
			tvtext=tvtext.ToLower()
			text=text.ToLower()
		Endif
		
		Local anchor:=tv.Anchor
		Local cursor:=tv.Cursor
		
		Local i:=0,t:=0
		Repeat
		
			Local i:=tvtext.Find( text,i )
			If i=-1 Exit
			
			tv.SelectText( i+t,i+text.Length+t )
			tv.ReplaceText( rtext )
			
			t+=rtext.Length-text.Length
			i+=text.Length
			
		Forever
		
		tv.SelectText( anchor,cursor )
		
	End
	
End
