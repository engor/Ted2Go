
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
		#If __TARGET__="macos"
		textDeleteLine.HotKey=Key.K
		textDeleteLine.HotKeyModifiers=Modifier.Control|Modifier.Shift
		#Else
		textDeleteLine.HotKey=Key.E
		textDeleteLine.HotKeyModifiers=Modifier.Control
		#Endif
		
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
	
	Property CurrentCodeDocument:CodeDocumentView()
		
		Return Cast<CodeDocumentView>( App.KeyView )
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
	
End
