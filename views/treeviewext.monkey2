
Namespace ted2go


Class TreeViewExt Extends TreeView

	Method New()
		Super.New()
		
		NodeClicked += Lambda(node:TreeView.Node)
			SetSelected(node)
		End
		
	End
	
	
	Protected
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		If _sel <> Null
			canvas.Color = Color.DarkGrey
			Local r := _sel.Rect
			' make selection whole line
			r.Left = Rect.Left
			r.Right = Rect.Right
			canvas.DrawRect(r)
		Endif
	
		Super.OnRenderContent(canvas)
		
	End
	
	
	Private
	
	Field _sel:TreeView.Node
	
	Method SetSelected(node:TreeView.Node)
		_sel = node
	End
	
End
