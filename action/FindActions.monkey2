
Namespace ted2go


Class FindActions

	Field find:Action
	Field findNext:Action
	field findPrevious:Action
	Field replace:Action
	Field replaceAll:Action
	Field findInFiles:Action
	Field findAllInFiles:Action
	
	Method New( docs:DocumentManager,projView:ProjectView,findConsole:TreeViewExt )
		
		_docs=docs
		_findConsole=findConsole
		
		find=New Action( "Find / Replace" )
		find.Triggered=OnFind
		find.HotKey=Key.F
		find.HotKeyModifiers=Modifier.Menu
		
		findNext=New Action( "Find next" )
		findNext.Triggered=Lambda()
			OnFindNext()
		End
		findNext.HotKey=Key.F3
		
		findPrevious=New Action( "Find previous" )
		findPrevious.Triggered=OnFindPrevious
		findPrevious.HotKey=Key.F3
		findPrevious.HotKeyModifiers=Modifier.Shift
		
		replace=New Action( "Replace" )
		replace.Triggered=OnReplace
		
		replaceAll=New Action( "Replace all" )
		replaceAll.Triggered=OnReplaceAll
		
		findInFiles=New Action( "Find in files..." )
		findInFiles.Triggered=OnFindInFiles
		findInFiles.HotKey=Key.F
		findInFiles.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		
		findAllInFiles=New Action( "Find all" )
		findAllInFiles.Triggered=OnFindAllInFiles
		
		_findDialog=New FindDialog( Self )
		_findInFilesDialog=New FindInFilesDialog( Self,projView )
	End
	
	Method Update()
	
		Local tv:=_docs.CurrentTextView
		findNext.Enabled=tv
		findPrevious.Enabled=tv
		replace.Enabled=tv
		replaceAll.Enabled=tv
	End
	
	Method FindByTextChanged()
		
		OnFindNext( False )
	End
	
	
	Private
	
	Field _docs:DocumentManager
	
	Field _findDialog:FindDialog
	Field _findInFilesDialog:FindInFilesDialog
	Field _findConsole:TreeViewExt
	Field _cursorPos:=0
	
	Method OnFind()
		
		_findDialog.Show()
		
		Local tv:=_docs.CurrentTextView
		If tv <> Null
			If tv.Cursor <> tv.Anchor
				Local min:=Min( tv.Cursor,tv.Anchor )
				Local max:=Max( tv.Cursor,tv.Anchor )
				Local s:=tv.Text.Slice( min,max )
				_findDialog.SetInitialText( s )
			Endif
			_cursorPos=Min( tv.Cursor,tv.Anchor )
		Endif
	End
	
	Method OnFindInFiles()
	
		_findInFilesDialog.Show()
	
		Local tv:=_docs.CurrentTextView
		If tv <> Null
			If tv.Cursor <> tv.Anchor
				Local min:=Min( tv.Cursor,tv.Anchor )
				Local max:=Max( tv.Cursor,tv.Anchor )
				Local s:=tv.Text.Slice( min,max )
				_findInFilesDialog.SetInitialText( s )
			Endif
		Endif
	End
	
	Method OnFindNext( changeCursorPos:Bool=True )
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return
		
		Local text:=_findDialog.FindText
		If Not text Return
		
		Local tvtext:=tv.Text
		Local cursor:=_cursorPos
		If changeCursorPos
			cursor=Max( tv.Anchor,tv.Cursor )
			_cursorPos=cursor
		Endif
		
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
	
	Method OnFindAllInFiles()
	
		If Not _findInFilesDialog.FindText Return
		
		If Not _findInFilesDialog.SelectedProject Return
		
		_findInFilesDialog.Hide()
		MainWindow.ShowFindResults()
		
		App.Idle+=Lambda()
			
			New Fiber( Lambda()
			
				FindInFilesInternal()
			End)
		End
		
	End
	
	Method FindInFilesInternal()
		
		Local what:=_findInFilesDialog.FindText
		If Not what Return
		
		Local proj:=_findInFilesDialog.SelectedProject
		If Not proj Return
		
		Local filter:=_findInFilesDialog.FilterText
		If Not filter Then filter="monkey2"
		
		Local exts:=filter.Split( "," )
		
		proj+="/"
		
		Local sens:=_findInFilesDialog.CaseSensitive
		
		If Not sens Then what=what.ToLower()
		
		Local files:=New Stack<String>
		Utils.GetAllFiles( proj,exts,files )
		
		Local root:=_findConsole.RootNode
		root.RemoveAllChildren()
		
		root.Text="Results for '"+what+"'"
		
		Local subRoot:TreeView.Node
		Local items:=New Stack<FileJumpData>
		Local len:=what.Length
		
		Local doc:=New TextDocument 'use it to get line number
		For Local f:=Eachin files
		
			Local text:=LoadString( f )
		
			If Not sens Then text=text.ToLower()
			text=text.Replace( "~r~n","~n" )
			text=text.Replace( "~r","~n" )
		
			doc.Text=text
		
			Local i:=0
			items.Clear()
		
			Repeat
				i=text.Find( what,i )
				If i=-1 Exit
		
				Local data:=New FileJumpData
				data.path=f
				data.pos=i
				data.len=len
				data.line=doc.FindLine( i )+1
		
				items.Add( data )
		
				i+=len
			Forever
		
			If Not items.Empty
		
				subRoot=New TreeView.Node( f.Replace( proj,"" )+" ("+items.Length+")",root )
		
				For Local d:=Eachin items
					Local node:=New NodeWithData<FileJumpData>( " at line "+d.line,subRoot )
					node.data=d
				Next
		
			Endif
		Next
		
		If root.NumChildren=0 Then New TreeView.Node( "not found :(",root )
		
		root.Expanded=True
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
		
			i=tvtext.Find( text,i )
			If i=-1 Exit
			
			tv.SelectText( i+t,i+text.Length+t )
			tv.ReplaceText( rtext )
			
			t+=rtext.Length-text.Length
			i+=text.Length
			
		Forever
		
		tv.SelectText( anchor,cursor )
		
	End
	
End
