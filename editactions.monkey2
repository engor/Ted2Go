
Namespace ted2go


Class EditActions

	Field undo:Action
	Field redo:Action
	Field cut:Action
	Field copy:Action
	Field paste:Action
	Field selectAll:Action
	
	Method New( docs:DocumentManager )
	
		_docs=docs
		
		undo=New Action( "Undo" )
		undo.Triggered=OnUndo
		undo.HotKey=Key.Z
		undo.HotKeyModifiers=Modifier.Menu
		
		redo=New Action( "Redo" )
		redo.Triggered=OnRedo
		redo.HotKey=Key.Y
		redo.HotKeyModifiers=Modifier.Menu

		cut=New Action( "Cut" )
		cut.Triggered=OnCut
		cut.HotKey=Key.X
		cut.HotKeyModifiers=Modifier.Menu
		
		copy=New Action( "Copy" )
		copy.Triggered=OnCopy
		copy.HotKey=Key.C
		copy.HotKeyModifiers=Modifier.Menu
		
		paste=New Action( "Paste" )
		paste.Triggered=OnPaste
		paste.HotKey=Key.V
		paste.HotKeyModifiers=Modifier.Menu
		
		selectAll=New Action( "Select All" )
		selectAll.Triggered=OnSelectAll
		selectAll.HotKey=Key.A
		selectAll.HotKeyModifiers=Modifier.Menu
		
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
	
	Method OnUndo()

		Local tv:=Cast<TextView>( App.KeyView )
		
		If tv tv.Undo()
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

End
