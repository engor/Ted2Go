
Namespace mojox

#rem monkeydoc The TreeView class.
#end
Class TreeView Extends ScrollableView

	#rem monkeydoc Invoked when a node is clicked.
	#end
	Field NodeClicked:Void( node:Node )

	#rem monkeydoc Invoked when a node is right clicked.
	#end
	Field NodeRightClicked:Void( node:Node )

	#rem monkeydoc Invoked when a node is double clicked.
	#end
	Field NodeDoubleClicked:Void( node:Node)
	
	#rem monkeydoc Invoked when a node is expanded.
	#end
	Field NodeExpanded:Void( node:Node )
	
	#rem monkeydoc Invoked when a node is collapsed.
	#end
	Field NodeCollapsed:Void( node:Node )

	Class Node

		#rem monkeydoc Creates a new node.
		#end
		Method New( text:String,parent:Node=Null,index:Int=-1 )
		
			If parent parent.AddChild( Self,index )
			
			Text=text
		End
		
		#rem monkeydoc Node style.
		
		If null, the node uses the tree view's style.
		
		#end
		Property Style:Style()
		
			Return _style
		
		Setter( style:Style )
		
			_style=style
			
			Dirty()
		End

		#rem monkeydoc Node text.
		#end		
		Property Text:String()
		
			Return _text
			
		Setter( text:String )
			If text=_text Return
		
			_text=text
			
			Dirty()
		End
		
		#rem monkeydoc Node icon.
		#end		
		Property Icon:Image()
		
			Return _icon
		
		Setter( icon:Image )
			If icon=_icon Return
		
			_icon=icon
			
			Dirty()
		End

		#rem monkeydoc Node parent.
		#end		
		Property Parent:Node()
		
			Return _parent
		End
		
		#rem monkeydoc Number of children.
		#end		
		Property NumChildren:Int()
		
			Return _children.Length
		End
		
		#rem monkeydoc Child nodes.
		#end		
		Property Children:Node[]()
		
			Return _children.ToArray()
		End

		#rem monkeydoc Node expanded state.
		#end	
		Property Expanded:Bool()
		
			Return _expanded
			
		Setter( expanded:Bool )
		
			_expanded=expanded
			
			Dirty()
		End
		
		#rem monkeydoc @hidden
		#end
		Property Rect:Recti()
		
			Return _rect
		End
		
		#rem monkeydoc @hidden
		#end
		Property Bounds:Recti()
		
			Return _bounds
		End
		
		#rem monkeydoc Expands this node and all child nodes.
		#end
		Method ExpandAll()
		
			Expanded=True
		
			For Local child:=Eachin _children
				child.ExpandAll()
			Next
		End
		
		#rem monkeydoc Collapses this node and all child nodes.
		#end
		Method CollapseAll()
		
			Expanded=False
			
			For Local child:=Eachin _children
				child.CollapseAll()
			Next
		End

		#rem monkeydoc @hidden
		#end
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

		#rem monkeydoc @hidden
		#end
		Method RemoveChildren( index1:Int,index2:Int )
		
			Assert( index1>=0 And index2>=index1 And index1<=_children.Length And index2<=_children.Length )
		
			For Local i:=index1 Until index2
				_children[i]._parent=Null
			Next
			
			_children.Erase( index1,index2 )
			
			Dirty()
		End
		
		#rem monkeydoc Removes a child node.
		#end
		Method RemoveChild( node:Node )
		
			If node._parent<>Self Return
			
			_children.Remove( node )
			
			node._parent=Null
			
			Dirty()
		End
		
		#rem monkeydoc Removes a child node.
		#end
		Method RemoveChild( index:Int )
		
			RemoveChild( GetChild( index ) )
		End
		
		#rem monkeydoc Removes children starting at an index.
		#end
		Method RemoveChildren( first:Int )
		
			RemoveChildren( first,_children.Length )
		End

		#rem monkeydoc Removes all children.
		#end
		Method RemoveAllChildren()
		
			RemoveChildren( 0,_children.Length )
		End

		#rem monkeydoc Removes this node from it's parent.
		#end
		Method Remove()
		
			If _parent _parent.RemoveChild( Self )
		End
		
		#rem monkeydoc Gets a child node by index.
		#end
		Method GetChild:Node( index:Int )
		
			If index>=0 And index<_children.Length Return _children[index]
			
			Return Null
		End
		
		Private
		
		Field _parent:Node
		Field _children:=New Stack<Node>	'should make on demand...
		Field _style:Style
		Field _text:String
		Field _icon:Image
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

	#rem monkeydoc Creates a new tree view.
	#end	
	Method New()
		Style=GetStyle( "TreeView" )
		Layout="fill"
		
		_rootNode=New Node( Null )
	End
	
	#rem monkeydoc Root node of tree.
	#end
	Property RootNode:Node()
	
		Return _rootNode
	
	Setter( node:Node )
		If node=_rootNode Return
	
		_rootNode=node
		
		App.RequestRender()
	End

	#rem monkeydoc Whether root node is visible.
	#end	
	Property RootNodeVisible:Bool()
	
		Return _rootNodeVisible
	
	Setter( rootNodeVisible:Bool )
		If rootNodeVisible=_rootNodeVisible Return
		
		_rootNodeVisible=rootNodeVisible
		
		App.RequestRender()
	End

	#rem monkeydoc @hidden
	#end	
	Method FindNodeAtPoint:Node( point:Vec2i )
	
		point=TransformPointToView( point,ContentView )
	
		Return FindNodeAtPoint( _rootNode,point )
	End
	
	Protected
	
	Method OnValidateStyle() Override
	
		Local style:=RenderStyle
	
		_collapsedIcon=style.Icons[0]
		_expandedIcon=style.Icons[1]
		
		_nodeSize=style.Font.Height
		_spcWidth=style.Font.TextWidth( " " )
	End
	
	Method OnMeasureContent:Vec2i() Override
	
		If Not _rootNode Return New Vec2i( 0,0 )
		
		Local origin:Vec2i
		
		'If Not _rootNodeVisible origin=New Vec2i( -_nodeSize,-_nodeSize )
	
		MeasureNode( _rootNode,origin,False )
		
		Return _rootNode._bounds.Size
	End
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		If Not _rootNode Return
	
		RenderNode( canvas,_rootNode )
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
	
		Local p:=event.Location
	
		Select event.Type
		Case EventType.MouseDown
		
			Return
			
		Case EventType.MouseClick
		
			Local node:=FindNodeAtPoint( _rootNode,p )

			If node
			
				p-=node._rect.Origin
				
				If p.x<_nodeSize And p.y<node.Rect.Height
				
					node.Expanded=Not node.Expanded
					
					App.RequestRender()
					
					If node.Expanded
						NodeExpanded( node )
					Else
						NodeCollapsed( node )
					Endif
					
				Else
				
					NodeClicked( node )
					
				Endif
				
			Endif
		
		Case EventType.MouseRightClick
		
			Local node:=FindNodeAtPoint( _rootNode,p )
			
			If node NodeRightClicked( node )
			 
		Case EventType.MouseDoubleClick
		
			Local node:=FindNodeAtPoint( _rootNode,p )
			
			If node NodeDoubleClicked( node )
			
		Case EventType.MouseWheel
		
			Return
		End
		
		event.Eat()
	
	End
	
	Private
	
	Field _spacing:=2
	
	Field _rootNode:Node
	Field _rootNodeVisible:=True
	
	Field _expandedIcon:Image
	Field _collapsedIcon:Image
	Field _nodeSize:Int
	Field _spcWidth:Int
		
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
		
		Local style:=node.Style
		If Not style style=RenderStyle
	
		Local size:Vec2i,nodeSize:=0
		
		If node<>_rootNode Or _rootNodeVisible
		
			Local w:=Int( style.Font.TextWidth( node._text ) )
			Local h:=Int( style.Font.Height )
			
			If node._icon
				w+=_spcWidth+node._icon.Width
				h=Max( h,Int( node._icon.Height ) )
			Endif
			
			size=New Vec2i( w+_nodeSize,Max( h,_nodeSize )+_spacing )
			
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
	
		Local clip:=VisibleRect
	
		If Not node._bounds.Intersects( clip ) Return
		
		If _rootNodeVisible Or node<>_rootNode
		
			If node._children.Length
			
				Local icon:=_collapsedIcon
				If node._expanded icon=_expandedIcon
				
				Local x:=(_nodeSize-icon.Width)/2
				Local y:=(node._rect.Height-icon.Height)/2
				
				RenderStyle.DrawIcon( canvas,icon,node._rect.X+x,node._rect.Y+y )
			Endif
			
			Local x:=node._rect.X+_nodeSize
			
			Local style:=node.Style
			If Not style style=RenderStyle
	
			If node._icon
				Local y:=(node._rect.Height-node._icon.Height)/2
				
				style.DrawIcon( canvas,node._icon,x,node._rect.Y+y )
				
				x+=node._icon.Width+_spcWidth
			Endif
			
			Local y:=(node._rect.Height-RenderStyle.Font.Height)/2
			
			style.DrawText( canvas,node._text,x,node._rect.Y+y )
		Endif
			
		If node._expanded

			For Local child:=Eachin node._children
			
				RenderNode( canvas,child )
				
			Next
		Endif
		
	End
	
End
