
Namespace ted2go


Class TreeViewExt Extends TreeView

	Method New()
		Super.New()
		
		NodeClicked+=Lambda( node:TreeView.Node )
			Selected=node
		End
		
		_selColor=App.Theme.GetColor( "panel" )
		App.ThemeChanged+=Lambda()
			_selColor=App.Theme.GetColor( "panel" )
		End
		
	End
	
	Property Selected:TreeView.Node()
		Return _sel
	Setter( value:TreeView.Node )
		_sel = value
		EnsureVisible( _sel )
	End
	
	
	Protected
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		If _sel <> Null
			canvas.Color=_selColor
			Local r:=_sel.Rect
			' make selection whole line
			r.Left=Rect.Left
			r.Right=Rect.Right
			canvas.DrawRect( r )
		Endif
	
		Super.OnRenderContent( canvas )
		
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
			
			Case EventType.MouseWheel
				' make scroll little faster
				Scroll-=New Vec2i( 0,RenderStyle.Font.Height*event.Wheel.Y*2 )
				Return
		
		End
		
		Super.OnContentMouseEvent( event )
		
	End
	
	
	Private
	
	Field _sel:TreeView.Node
	Field _selColor:Color
	
	Method EnsureVisible( node:TreeView.Node )
		
		Local n:=node
		While n
			n.Expanded=True
			n=n.Parent
		Wend
		
		' scroll Y only 
		Local sx:=Scroll.x
		Local scroll:=Scroll
		Super.EnsureVisible( node.Rect )
		scroll.Y=Scroll.y
		Scroll=scroll
	End
	
End


Class NodeWithData<T> Extends TreeView.Node

	Field data:T
	
	Method New( text:String,parent:TreeView.Node=Null,index:Int=-1 )
		
		Super.New( text,parent,index )
	End
	
End


Struct FileJumpData

	Field path:String
	Field pos:Int
	Field len:Int
	Field line:Int
	
End
