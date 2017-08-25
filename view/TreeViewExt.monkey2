
Namespace ted2go


Class TreeViewExt Extends TreeView

	Field SelectedChanged:Void( selNode:TreeView.Node )
	
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
		
		If _sel = value Return
		_sel = value
		SelectedChanged( _sel )
		
		EnsureVisible( _sel )
	End
	
	Method FindSubNode:TreeView.Node( text:String,whereNode:TreeView.Node,recursive:Bool=False )
		
		If whereNode.Text=text Return whereNode
		
		Local list:=whereNode.Children
		If Not list Return Null
		
		For Local i:=Eachin list
			If i.Text=text Return i
			If recursive And i.Children
				Local n:=FindSubNode( text,i,recursive )
				If n Return n
			Endif
		Next
		
		Return Null
	End
	
	Method RemoveNode( node:Node )
		
		node.Remove()
		If node=Selected Then Selected=Null
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
		
		If Not node Return
		
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
