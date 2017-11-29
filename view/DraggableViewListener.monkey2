
Namespace ted2go


Interface IDraggableItem<THolder>
	
	Property Detachable:Bool()
	
	Property PossibleHolders:THolder[]()
	Setter( value:THolder[] )
	
	Property CurrentHolder:THolder()
	
End

Interface IDraggableHolder
	
	Method Attach( item:Object,eventLocation:Vec2i )
	Method Detach:View( item:Object )
	
	Method OnDragStarted() 	' highlight holder here (if needed)
	Method OnDragEnded() 	' reset highlighting
	
End

#Rem Call order: Detach -> OnDragStarted -> Attach -> OnDragEnded

#End
Class DraggableViewListener<TItem,THolder>
	
	Method GetItem:TItem( eventView:View,eventLocation:Vec2i ) Abstract
	Method GetHolder:THolder( view:View ) Abstract
	
	Method New()
		
		_window=Window.AllWindows()[0]
		
		App.MouseEventFilter+=OnMouseEvent
	End
	
	Property DragThreshold:Float()
		Return _threshold
	Setter( value:Float )
		_threshold=value
	End
	
	
	Private
	
	Field _threshold:=10.0
	Field _item:TItem
	Field _view:View
	Field _pressedPos:Vec2i
	Field _detached:Bool
	Field _window:Window
	
	Method OnMouseEvent( event:MouseEvent )
	
		Select event.Type
			
			Case EventType.MouseDown
				
				_item=GetItem( event.View,event.Location )
				If Not _item Return
				
				If Not _item.Detachable
					_item=Null
					Return
				Endif
				
				_pressedPos=Mouse.Location
				
			
			Case EventType.MouseMove
			
				If Not _item Return
				
				If _detached
					Local r:=_view.Frame
					Local sz:=r.Size
					r.TopLeft=Mouse.Location+New Vec2i( 0,-10 )
					r.BottomRight=r.TopLeft+sz
					_view.Frame=r
					App.RequestRender()
					Return
				Endif
				
				Local dy:Float=Abs(Mouse.Y-_pressedPos.y)
				
				If dy>=_threshold*App.Theme.Scale.y
					Detach()
				Endif
				
			
			Case EventType.MouseUp
				
				If Not _detached 
					_item=Null
					Return
				Endif
				
				_window.RemoveChildView( _view )
				
				Local holder:=GetHolder( App.ActiveViewAtMouseLocation() )
				
				If Not CanAttach( _item,holder ) Then holder=_item.CurrentHolder
				
				holder.Attach( _item,event.Location )
				
				_item.CurrentHolder.OnDragEnded()
				If _item.PossibleHolders
					For Local i:=Eachin _item.PossibleHolders
						If i=_item.CurrentHolder Continue
						i.OnDragEnded()
					Next
				Endif
				
				_item=Null
				_detached=False
				
				event.Eat()
				
		End
	
	End
	
	Method Detach()
		
		_detached=True
		
		Local holder:=GetHolder( _item.View )
		_view=holder.Detach( _item )
		
		_window.AddChildView( _view )
		
		_item.CurrentHolder.OnDragStarted()
		
		If Not _item.PossibleHolders Return
		
		For Local i:=Eachin _item.PossibleHolders
			If i=_item.CurrentHolder Continue
			i.OnDragStarted()
		Next
		
	End
	
	Function CanAttach:Bool( item:TItem,holder:THolder )
		
		If Not holder Return False
		If Not item.PossibleHolders Return False
		
		For Local i:=Eachin item.PossibleHolders
			
			If i=holder Return True
		Next
		
		Return False
	End
	
End
