
Namespace ted2go


Class FoldingActions
	
	Field foldCurrent:Action
	Field foldScope:Action
	Field foldAll:Action
	Field unfoldCurrent:Action
	Field unfoldScope:Action
	Field unfoldAll:Action
	
	Method New()
		
		foldCurrent=New Action( "Fold current" )
		foldCurrent.Triggered=OnFoldCurrent
		foldCurrent.HotKey=Key.Minus
		foldCurrent.HotKeyModifiers=Modifier.Alt
		
		foldScope=New Action( "Fold current & parents" )
		foldScope.Triggered=OnFoldScope
		foldScope.HotKey=Key.Minus
		foldScope.HotKeyModifiers=Modifier.Alt|Modifier.Shift
		
		foldAll=New Action( "Fold all" )
		foldAll.Triggered=OnFoldAll
		foldAll.HotKey=Key.Minus
		foldAll.HotKeyModifiers=Modifier.Alt|Modifier.Shift|Modifier.Control
		
		unfoldCurrent=New Action( "Unfold current" )
		unfoldCurrent.Triggered=OnUnfoldCurrent
		unfoldCurrent.HotKey=Key.Equals
		unfoldCurrent.HotKeyModifiers=Modifier.Alt
		
		unfoldScope=New Action( "Unfold current & children" )
		unfoldScope.Triggered=OnUnfoldScope
		unfoldScope.HotKey=Key.Equals
		unfoldScope.HotKeyModifiers=Modifier.Alt|Modifier.Shift
		
		unfoldAll=New Action( "Unfold all" )
		unfoldAll.Triggered=OnUnfoldAll
		unfoldAll.HotKey=Key.Equals
		unfoldAll.HotKeyModifiers=Modifier.Alt|Modifier.Shift|Modifier.Control
		
	End
	
	
	Private
	
	Property CurrentCodeDocument:CodeTextView()
		
		Return Cast<CodeTextView>( App.KeyView )
	End
	
	Method OnFoldCurrent()
		
		Local code:=CurrentCodeDocument
		If code
			code.FoldBlock( code.LineNumAtCursor,True,True )
		Endif
	End
	
	Method OnFoldScope()
		
		Local code:=CurrentCodeDocument
		If code
			Local f:=code.FindNearestFolding( code.LineNumAtCursor )
			If Not f Return
			While f And f.parent ' find root folding
				f=f.parent
			Wend
			Local all:=New Stack<CodeTextView.Folding>
			For Local i:=f.startLine Until f.endLine
				Local f2:=code.GetFolding( i )
				If f2 Then all.Add( f2 )
			Next
			For Local i:=all.Length-1 To 0 Step -1
				code.FoldBlock( all[i].startLine,(i=0) )
			Next
		Endif
	End
	
	Method OnFoldAll()
		
		CurrentCodeDocument?.FoldAll()
	End
	
	Method OnUnfoldCurrent()
		
		Local code:=CurrentCodeDocument
		If code
			code.UnfoldBlock( code.LineNumAtCursor,True,True )
		Endif
	End
	
	Method OnUnfoldScope()
		
		Local code:=CurrentCodeDocument
		If code
			Local f:=code.FindNearestFolding( code.LineNumAtCursor )
			If Not f Return
			While f And f.parent ' find root folding
				f=f.parent
			Wend
			Local all:=New Stack<CodeTextView.Folding>
			For Local i:=f.startLine Until f.endLine
				Local f2:=code.GetFolding( i )
				If f2 Then all.Add( f2 )
			Next
			For Local i:=0 Until all.Length
				code.UnfoldBlock( all[i].startLine,(i=all.Length-1) )
			Next
		Endif
	End
	
	Method OnUnfoldAll()
		
		CurrentCodeDocument?.UnfoldAll()
	End
	
End
