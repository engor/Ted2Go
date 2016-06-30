
Namespace mojox

Class TreeView Extends View

	Field NodeClicked:Void( node:Node,event:MouseEvent )

	Field NodeToggled:Void( node:Node,event:MouseEvent )

	Class Node
	
		Method New( label:String,parent:Node=Null,index:Int=-1 )
		
			If parent parent.AddChild( Self,index )
			
			Label=label
		End
		
		Property Label:String()
		
			Return _label
			
		Setter( label:String )
		
			_label=label
			
			Dirty()
		End

		Property Parent:Node()
		
			Return _parent
		End
		
		Property NumChildren:Int()
		
			Return _children.Length
		End
		
		Property Children:Node[]()
		
			Return _children.ToArray()
		End
	
		Property Expanded:Bool()
		
			Return _expanded
			
		Setter( expanded:Bool )
		
			_expanded=expanded
			
			Dirty()
		End
		
		Property Rect:Recti()
		
			Return _rect
		End
		
		Property Bounds:Recti()
		
			Return _bounds
		End
		
		Method AddChild( node:Node,index:Int=-1 )
		
			If node._parent Return
			
			If index=-1
				index=_children.Length
			Else
				Assert( index>=0 And index<=_children.Length )
			Endif
			
			node._parent=Self
			
			_children.Insert( index,node )
			
			node.Dirty()
		End
		
		Method RemoveChildren( index1:Int,index2:Int )
		
			Assert( index1>=0 And index2>=index1 And index1<=_children.Length And index2<=_children.Length )
		
			For Local i:=index1 Until index2
				_children[i]._parent=Null
			Next
			
			_children.Erase( index1,index2 )
			
			Dirty()
		End
		
		Method RemoveChild( node:Node )
		
			If node._parent<>Self Return
			
			_children.Remove( node )
			
			node._parent=Null
			
			Dirty()
		End
		
		Method RemoveChild( index:Int )
		
			RemoveChild( GetChild( index ) )
		End
		
		Method RemoveChildren( first:Int )
		
			RemoveChildren( first,_children.Length )
		End

		Method RemoveAllChildren()
		
			RemoveChildren( 0,_children.Length )
		End

		Method Remove()
		
			If _parent _parent.RemoveChild( Self )
		End
		
		Method GetChild:Node( index:Int )
		
			If index>=0 And index<_children.Length Return _children[index]
			
			Return Null
		End
		
		Private
		
		Field _parent:Node
		Field _children:=New Stack<Node>
		Field _label:String
		Field _expanded:Bool
		Field _bounds:Recti
		Field _rect:Recti
		Field _dirty:Bool
		
		Method Dirty()
			_dirty=True
			Local node:=_parent
			While node
				node._dirty=True
				node=node._parent
			Wend
		End
		
	End
	
	Method New()
		Layout="fill"
		Style=Style.GetStyle( "mojo.TreeView" )
		_rootNode=New Node( Null )
	End
	
	Property RootNode:Node()
	
		Return _rootNode
	
	Setter( node:Node)
	
		_rootNode=node
	End
	
	Property RootNodeVisible:Bool()
	
		Return _rootNodeVisible
	
	Setter( rootNodeVisible:Bool )
		
		_rootNodeVisible=rootNodeVisible
	End
	
	Method FindNodeAtPoint:Node( point:Vec2i )
	
		Return FindNodeAtPoint( _rootNode,point )
	End
	
	Property Container:View() Override
	
		If Not _scroller
			_scroller=New ScrollView( Self )
		Endif
		Return _scroller
	End
	
	Private
	
	Field _rootNode:Node
	Field _rootNodeVisible:=True
	Field _scroller:ScrollView
	
	Field _expandedIcon:Image
	Field _collapsedIcon:Image
	Field _nodeSize:Int
		
	Method FindNodeAtPoint:Node( node:Node,point:Vec2i )
	
		If node._rect.Contains( point ) Return node
	
		If node._expanded And node._bounds.Contains( point )
		
			For Local child:=Eachin node._children
			
				Local cnode:=FindNodeAtPoint( child,point )
				If cnode Return cnode

			Next

		Endif
		
		Return Null
	End
	
	Method MeasureNode( node:Node,origin:Vec2i,dirty:Bool )
	
		If Not node._dirty And Not dirty Return

		node._dirty=False
	
		Local size:Vec2i,nodeSize:=0
		
		If _rootNodeVisible Or node<>_rootNode
		
			size=New Vec2i( Style.DefaultFont.TextWidth( node.Label )+_nodeSize,_nodeSize )
			nodeSize=_nodeSize
			
		Endif
		
		Local rect:=New Recti( origin,origin+size )
		
		node._rect=rect
		
		If node._expanded
		
			origin.x+=nodeSize
		
			For Local child:=Eachin node._children
			
				origin.y=rect.Bottom
			
				MeasureNode( child,origin,True )
				
				rect|=child._bounds
			Next
		
		Endif
		
		node._bounds=rect
	End
	
	Method RenderNode( canvas:Canvas,node:Node )
	
		If Not node._bounds.Intersects( ClipRect ) return
	
		If _rootNodeVisible Or node<>_rootNode
		
			If node._children.Length
			
				Local icon:=_collapsedIcon
				If node._expanded icon=_expandedIcon
				
				Local x:=(_nodeSize-icon.Width)/2
				Local y:=(_nodeSize-icon.Height)/2
				
				canvas.Color=Color.White
				canvas.DrawImage( icon,node._rect.X+x,node._rect.Y+y )
				
			Endif
			
			canvas.Color=Style.DefaultColor
			canvas.DrawText( node._label,node._rect.X+_nodeSize,node._rect.Y )
		
		Endif
			
		If node._expanded

			For Local child:=Eachin node._children
			
				RenderNode( canvas,child )
				
			Next
		Endif
		
	End
	
	Method OnValidateStyle() Override
	
		_collapsedIcon=Style.GetImage( "node:collapsed" )
		_expandedIcon=Style.GetImage( "node:expanded" )
		
		_nodeSize=Style.DefaultFont.Height
		_nodeSize=Max( _nodeSize,Int( _expandedIcon.Height ) )
		_nodeSize=Max( _nodeSize,Int( _collapsedIcon.Height ) )
	End
	
	Method OnMeasure:Vec2i() Override
	
		If Not _rootNode Return New Vec2i( 0,0 )
		
		Local origin:Vec2i
		
		'If Not _rootNodeVisible origin=New Vec2i( -_nodeSize,-_nodeSize )
	
		MeasureNode( _rootNode,origin,false )
		
		Return _rootNode._bounds.Size
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		If Not _rootNode Return
	
		RenderNode( canvas,_rootNode )

'		Print "TreeView ClipRect="+ClipRect.ToString()

	End
	
	Method OnMouseEvent( event:MouseEvent) Override
	
		Select event.Type
		Case EventType.MouseDown
		
			Local node:=FindNodeAtPoint( event.Location )

			If node
			
				Local p:=event.Location-node._rect.Origin
				
				If p.x<_nodeSize And p.y<_nodeSize
					node.Expanded=Not node._expanded
					NodeToggled( node,event )
				Else
					NodeClicked( node,event )
				Endif
				
			Endif
			
		Case EventType.MouseWheel
		
			Super.OnMouseEvent( event )
			Return
		End
	
	End
	
End

