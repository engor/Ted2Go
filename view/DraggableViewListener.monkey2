
Namespace ted2go


Interface IDraggableItem<THolder>
	
	Property Detachable:Bool()
	
	Property PossibleHolders:THolder[]()
	Setter( value:THolder[] )
	
	Property CurrentHolder:THolder()
	
End

Interface IDraggableHolder
	
	Method Attach( item:View )
	Method Detach:View( item:View )
	
	Method OnDragStarted() 	' highlight holder here (if needed)
	Method OnDragEnded() 	' reset highlighting
	
End


Class DraggableViewListener<TItem,THolder>
	
	Method New(  )
		
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
				
				_item=Cast<TItem>( event.View )
				If Not _item Return
				
				If Not _item.Detachable
					_item=Null
					Return
				Endif
				
				_pressedPos=Mouse.Location
				
			
			Case EventType.MouseMove
			
				If Not _item Return
				
				If _detached
					Local r:=_item.Frame
					Local sz:=r.Size
					r.TopLeft=Mouse.Location+New Vec2i( 0,-10 )
					r.BottomRight=r.TopLeft+sz
					_item.Frame=r
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
				
				holder.Attach( _item )
				
				If _item.PossibleHolders
					For Local i:=Eachin _item.PossibleHolders
						i.OnDragEnded()
					Next
				Endif
				
				_item=Null
				_detached=False
			
		End
	
	End
	
	Method Detach()
		
		_detached=True
		
		Local holder:=GetHolder( _item.View )
		_view=holder.Detach( _item )
		
		_window.AddChildView( _view )
		
		If Not _item.PossibleHolders Return
		
		For Local i:=Eachin _item.PossibleHolders
			i.OnDragStarted()
		Next
		
	End
	
	Method GetHolder:THolder( view:View )
		
		While view
			Local h:=Cast<THolder>( view )
			If h Return h
			view=view.Parent
		Wend
		Return Null
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
