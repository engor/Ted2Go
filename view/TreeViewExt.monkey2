
Namespace ted2go


Class TreeViewExt Extends TreeView
	
	Field NodeClicked:Void( node:Node )
	Field NodeRightClicked:Void( node:Node )
	Field NodeDoubleClicked:Void( node:Node)
	Field NodeExpanded:Void( node:Node )
	Field NodeCollapsed:Void( node:Node )
	Field SelectedChanged:Void( selNode:Node )
	
	Method New()
		
		Super.New()
		
		Super.NodeClicked+=Lambda( node:Node )
			
			If _singleClickExpanding
				If TrySwitchExpandingState( node ) Return
			Endif
			
			OnSelect( node )
			NodeClicked( node )
		End
		
		Super.NodeDoubleClicked+=Lambda( node:Node )
			
			If TrySwitchExpandingState( node ) Return
			
			OnSelect( node )
			NodeDoubleClicked( node )
		End
		
		Super.NodeRightClicked+=Lambda( node:Node )
			
			OnSelect( node )
			NodeRightClicked( node )
		End
		
		Super.NodeExpanded+=Lambda( node:Node )
			
			_expander.Store( node )
			OnSelect( node )
			NodeExpanded( node )
		End
		
		Super.NodeCollapsed+=Lambda( node:Node )
			
			_expander.Store( node )
			OnSelect( node )
			NodeCollapsed( node )
		End
		
		_selColor=App.Theme.GetColor( "panel" )
	End
	
	Property Selected:TreeView.Node()
	
		Return _sel
		
	Setter( value:TreeView.Node )
		
		If _sel=value Return
		_sel=value
		SelectedChanged( _sel )
		
		EnsureVisible( _sel )
		
		RequestRender()
	End
	
	Property SingleClickExpanding:Bool()
	
		Return _singleClickExpanding
	
	Setter( value:Bool )
	
		_singleClickExpanding=value
		
	End
	
	Method SaveState( jobj:JsonObject,jkey:String )
		
		_expander.SaveState( RootNode,jobj,jkey )
	End
	
	Method LoadState( jobj:JsonObject,jkey:String )
		
		_expander.LoadState( jobj,jkey )
	End
	
	Method FindSubNode:TreeView.Node( text:String,whereNode:TreeView.Node,recursive:Bool=False )
		
		Return FindSubNode( whereNode,
						recursive,
						Lambda:Bool( n:TreeView.Node )
							Return n.Text=text
						End )
	End
	
	Method FindSubNode:TreeView.Node( whereNode:TreeView.Node,recursive:Bool,findCondition:Bool(n:TreeView.Node) )
	
		If findCondition( whereNode ) Return whereNode
	
		For Local i:=Eachin whereNode.Children
			If findCondition( i ) Return i
			If recursive And i.Children
				Local n:=FindSubNode( i,recursive,findCondition )
				If n Return n
			Endif
		Next
	
		Return Null
	End
	
	Method RemoveNode( node:Node )
		
		node.Remove()
		If node=Selected Then Selected=Null
	End
	
	Method SelectByPath( path:String )
		
		Local n:=FindSubNode( RootNode,
						True,
						Lambda:Bool( n:TreeView.Node )
							Return GetNodePath( n )=path
						End )
		
		If n Then Selected=n
	End
	
	
	Protected
	
	Field _expander:=New TreeViewExpander
	
	Method OnThemeChanged() Override
		
		_selColor=App.Theme.GetColor( "panel" )
	End
	
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
	Field _singleClickExpanding:Bool
	
	Method TrySwitchExpandingState:Bool( node:TreeView.Node )
		
		If node.Children.Length=0 Return False
		
		node.Expanded=Not node.Expanded
		If node.Expanded
			Super.NodeExpanded( node )
		Else
			Super.NodeCollapsed( node )
		Endif
		
		Return True
	End
	
	Method OnSelect( node:TreeView.Node )
		
		Selected=node
		Self.MakeKeyView()
		
		RequestRender()
	End
	
	Method EnsureVisible( node:TreeView.Node )
		
		If Not node Return
		
		Local n:=node.Parent
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


Class TreeViewExpander
	
	Method Store( node:TreeView.Node,recurse:Bool=False )
	
		Local key:=GetNodePath( node )
	
		If node.Expanded
			_expands[key]=True
		Else
			_expands.Remove( key )
		Endif
		
		If Not recurse Return
		
		For Local i:=Eachin node.Children
			Store( i,True )
		Next
	End
	
	Method Restore( node:TreeView.Node,recurse:Bool=False )
	
		Local key:=GetNodePath( node )
		
		node.Expanded = _expands.Contains( key ) ? True Else False
		
		If Not recurse Return
		
		For Local i:=Eachin node.Children
			Restore( i,True )
		Next
	End
	
	Method SaveState( rootNode:TreeView.Node,jobj:JsonObject,jkey:String )
	
		Store( rootNode,True ) '
		
		Local jarr:=New JsonArray
		For Local key:=Eachin _expands.Keys
			If Not key Continue
			jarr.Add( New JsonString( key ) )
		Next
		jobj[jkey]=jarr
	End
	
	Method LoadState( jobj:JsonObject,jkey:String )
		
		_expands.Clear()
		
		If Not jobj.Contains( jkey ) Return
		Local jarr:=jobj[jkey].ToArray()
		For Local key:=Eachin jarr
			_expands[key.ToString()]=True
		Next
	End
	
	Private
	
	Field _expands:=New StringMap<Bool>
	
End


Class NodeWithData<T> Extends TreeView.Node

	Field data:T
	
	Method New( text:String,parent:TreeView.Node=Null,index:Int=-1 )
		
		Super.New( text,parent,index )
	End
	
End


Class FileJumpData

	Field path:String
	Field pos:Int
	Field len:Int
	Field line:Int
	Field posInLine:Int
	
End


Function GetNodePath:String( node:TreeView.Node )
	
	If Not node Return ""
	
	Local s:=node.Text
	Local i:=node.Parent
	While i <> Null
		s=i.Text+"\"+s
		i=i.Parent
	Wend
	Return s
End
