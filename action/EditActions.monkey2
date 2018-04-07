
Namespace ted2go


Class EditActions

	Field undo:Action
	Field redo:Action
	Field cut:Action
	Field copy:Action
	Field paste:Action
	Field selectAll:Action
	Field wordWrap:Action
	' Edit -- Text
	Field textDeleteWordForward:Action
	Field textDeleteWordBackward:Action
	Field textDeleteLine:Action
	Field textDeleteToEnd:Action
	Field textDeleteToBegin:Action
	Field textLowercase:Action
	Field textUppercase:Action
	Field textSwapCase:Action
	'
	Field comment:Action
	Field uncomment:Action
	
	Method New( docs:DocumentManager )
	
		_docs=docs
		
		undo=New Action( "Undo" )
		undo.Triggered=OnUndo
		undo.HotKey=Key.Z
		undo.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		redo=New Action( "Redo" )
		redo.Triggered=OnRedo
#If __TARGET__="macos"
		redo.HotKey=Key.Z
		redo.HotKeyModifiers=Modifier.Menu|Modifier.Ignore|Modifier.Shift
#Else
		redo.HotKey=Key.Y
		redo.HotKeyModifiers=Modifier.Menu|Modifier.Ignore
#Endif
		
		cut=New Action( "Cut" )
		cut.Triggered=OnCut
		cut.HotKey=Key.X
		cut.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		copy=New Action( "Copy" )
		copy.Triggered=OnCopy
		copy.HotKey=Key.C
		copy.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		paste=New Action( "Paste" )
		paste.Triggered=OnPaste
		paste.HotKey=Key.V
		paste.HotKeyModifiers=Modifier.Menu|Modifier.Ignore

		selectAll=New Action( "Select all" )
		selectAll.Triggered=OnSelectAll
		selectAll.HotKey=Key.A
		selectAll.HotKeyModifiers=Modifier.Menu|Modifier.Ignore
		
		wordWrap=New Action( "Toggle word wrap" )
		wordWrap.Triggered=OnWordWrap
		wordWrap.HotKey=Key.Z
		wordWrap.HotKeyModifiers=Modifier.Alt
		
		textDeleteLine=New Action( "Delete line" )
		textDeleteLine.Triggered=OnDeleteLine
		textDeleteLine.HotKey=Key.K
		textDeleteLine.HotKeyModifiers=Modifier.Control|Modifier.Shift
		
		textDeleteWordForward=New Action( "Delete word forward" )
		textDeleteWordForward.Triggered=OnDeleteWordForward
		textDeleteWordForward.HotKey=Key.KeyDelete
		textDeleteWordForward.HotKeyModifiers=Modifier.Control
		
		textDeleteWordBackward=New Action( "Delete word backward" )
		textDeleteWordBackward.Triggered=OnDeleteWordBackward
		textDeleteWordBackward.HotKey=Key.Backspace
		textDeleteWordBackward.HotKeyModifiers=Modifier.Control
		
		textDeleteToBegin=New Action( "Delete to beginning" )
		textDeleteToBegin.Triggered=OnDeleteToBegin
		textDeleteToBegin.HotKey=Key.Backspace
		#If __TARGET__="macos"
		textDeleteToBegin.HotKeyModifiers=Modifier.Menu
		#Else
		textDeleteToBegin.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		#Endif
		
		textDeleteToEnd=New Action( "Delete to end" )
		textDeleteToEnd.Triggered=OnDeleteToEnd
		#If __TARGET__="macos"
		textDeleteToEnd.HotKey=Key.K
		textDeleteToEnd.HotKeyModifiers=Modifier.Control
		#Else
		textDeleteToEnd.HotKey=Key.KeyDelete
		textDeleteToEnd.HotKeyModifiers=Modifier.Control|Modifier.Shift
		#Endif
		
		textLowercase=New Action( "lowercace" )
		textLowercase.Triggered=OnLowercase
		textLowercase.HotKey=Key.L
		textLowercase.HotKeyModifiers=Modifier.Control|Modifier.Shift
		
		textUppercase=New Action( "UPPERCASE" )
		textUppercase.Triggered=OnUppercase
		textUppercase.HotKey=Key.U
		textUppercase.HotKeyModifiers=Modifier.Control|Modifier.Shift
		
		textSwapCase=New Action( "Swap case" )
		textSwapCase.Triggered=OnSwapCase
		
		comment=New Action( "Comment block" )
		comment.Triggered=OnComment
		#If __TARGET__="macos"
		comment.HotKey=Key.Backslash
		#Else
		comment.HotKey=Key.Apostrophe
		#Endif
		comment.HotKeyModifiers=Modifier.Menu
		
		uncomment=New Action( "Uncomment block" )
		uncomment.Triggered=OnUncomment
		#If __TARGET__="macos"
		uncomment.HotKey=Key.Backslash
		#Else
		uncomment.HotKey=Key.Apostrophe
		#Endif
		uncomment.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		
	End
	
	Method Update()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		undo.Enabled=tv And tv.CanUndo
		redo.Enabled=tv And tv.CanRedo
		cut.Enabled=tv And tv.CanCut
		copy.Enabled=tv And tv.CanCopy
		paste.Enabled=tv And tv.CanPaste
		selectAll.Enabled=tv
	End
	
	Private
	
	Field _docs:DocumentManager
	
	Property CurrentCodeDocument:CodeTextView()
		
		Return Cast<CodeTextView>( App.KeyView )
	End
	
	Method OnDeleteLine()
		
		CurrentCodeDocument?.DeleteLineAtCursor()
	End
	
	Method OnDeleteWordForward()
		
		CurrentCodeDocument?.DeleteWordForward()
	End
	
	Method OnDeleteWordBackward()
		
		CurrentCodeDocument?.DeleteWordBackward()
	End
	
	Method OnDeleteToBegin()
		
		CurrentCodeDocument?.DeleteToBegin()
	End
	
	Method OnDeleteToEnd()
	
		CurrentCodeDocument?.DeleteToEnd()
	End
	
	Method OnLowercase()
	
		CurrentCodeDocument?.LowercaseSelection()
	End
	
	Method OnUppercase()
	
		CurrentCodeDocument?.UppercaseSelection()
	End
	
	Method OnSwapCase()
		
		CurrentCodeDocument?.SwapCaseSelection()
	End
	
	Method OnUndo()

		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Undo()
		
		'TODO
		' testing stuff here
		
	End
	
	Method OnRedo()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Redo()
	End
	
	Method OnCut()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Cut()
	End

	Method OnCopy()

		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Copy()
	End

	Method OnPaste()
		
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Paste()
	End
	
	Method OnSelectAll()
		
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.SelectAll()
	End
	
	Method OnWordWrap()
	
		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv
			Local cur:=tv.Cursor
			Local anc:=tv.Anchor
			Local sc:=tv.Scroll
			tv.WordWrap=Not tv.WordWrap
			tv.SelectText( cur,anc )
			tv.Scroll=sc
		Endif
	End
	
	Method OnComment()
	
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		If Not doc Return
	
		doc.Comment()
	End
	
	Method OnUncomment()
	
		Local doc:=Cast<CodeDocument>( _docs.CurrentDocument )
		If Not doc Return
	
		doc.Uncomment()
	End
	
End
