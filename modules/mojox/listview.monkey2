
Namespace mojox

Class ListView Extends ScrollableView

	#rem monkeydoc Invoked when an item is clicked.
	#end
	Field ItemClicked:Void( item:Item )
	
	#rem monkeydoc Invoked when an item is double clicked.
	#end
	Field ItemDoubleClicked:Void( item:Item )

	Class Item Extends ViewCell
	
		Method New( text:String,icon:Image,list:ListView )
			Super.New( text,icon )
			_list=list
		End
		
		Private
		
		Field _list:ListView
		Field _rect:Recti
	
	End

	#rem monkeydoc Creates a new list view.
	#end
	Method New()	
		Style=GetStyle( "ListView" )
		ContentView.Style=GetStyle( "ListViewContent" )
	End

	#rem monkeydoc Adds an item to the list view.
	#end
	Method AddItem:Item( text:String,icon:Image=Null )
	
		Return InsertItem( _items.Length,text,icon )
	End
	
	#rem monkeydoc Inserts an item to the list view at a given index.
	#end
	Method InsertItem:Item( index:Int,text:String,icon:Image=Null )
		
		Local item:=New Item( text,icon,Self )
		_items.Insert( index,item )
		
		RequestRender()
		
		Return item
	End
	
	#rem monkeydoc Removes an item from the list view.
	#end
	Method RemoveItem( index:Int )
		
		_items.Erase( index )
		
		RequestRender()
	End
	
	#rem monkeydoc Removes an item from the list view.
	#end
	Method RemoveItem( item:Item )
	
		RemoveItem( IndexOfItem( item ) )
	End

	#rem monkeydoc Removes a sequence of items from the list view.
	#end	
	Method RemoveItems( index1:Int,index2:Int )
	
		_items.Erase( index1,index2 )
		
		RequestRender()
	End
	
	#rem monkeydoc Removes all items from the list view.
	#end
	Method RemoveAllItems()
	
		_items.Clear()
		
		RequestRender()
	End
	
	#rem monkeydoc Returns the index of a given item in the list view.
	#end
	Method IndexOfItem:Int( item:Item )

		For Local i:=0 Until _items.Length
			If _items[i]=item Return i
		Next
		
		Return -1
	End
	
	#rem monkeydoc Returns the item at a point in the list view.
	#end
	Method ItemAtPoint:Item( point:Vec2i )

		For Local item:=Eachin _items
			If item._rect.Contains( point ) Return item
		Next
		
		Return Null
	End
	
	Protected
	
	#rem monkeydoc @hidden
	#end
	Method OnMeasureContent:Vec2i() Override
	
		Local w:=0,h:=0
		
		For Local item:=Eachin _items
		
			Local size:=item.Measure( RenderStyle )
			
			item._rect=New Recti( 0,h,size.x,h+size.y )
			
			w=Max( w,size.x )
			h+=size.y
		Next
		
		Return New Vec2i( w,h )

	End
	
	#rem monkeydoc @hidden
	#end
	Method OnRenderContent( canvas:Canvas ) Override
	
		Local x:=0,y:=0
	
		For Local item:=Eachin _items
		
			item.Render( canvas,item._rect,RenderStyle,New Vec2f( 0,.5 ) )
		Next			
	End
	
	#rem monkeydoc @hidden
	#end
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseClick
			Local item:=ItemAtPoint( event.Location )
			If item ItemClicked( item )
		Case EventType.MouseDoubleClick
			Local item:=ItemAtPoint( event.Location )
			If item ItemDoubleClicked( item )
		End
	
	End

	Private
	
	Field _items:=New Stack<Item>
End
