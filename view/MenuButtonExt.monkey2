
Namespace ted2go


'Class MenuExt Extends Menu
'	
'	Method New( text:String="" )
'		
'		Super.New( text )
'	End
'	
'	Method AddItem( item:MenuButtonExt )
'	
'		item.Clicked=Lambda()
'	
'			CloseAll()
'			'
'			'a bit gnarly, but makes sure menu is *really* closed...
'			'
'			App.RequestRender()
'			App.Idle+=item.acTrigger
'		End
'	
'		AddView( item )
'	End
'	
'End


Class MenuButtonExt Extends MenuButton
	
	Method New( action:Action )
	
		Super.New( action )
		_action=action
	End
	
	Method New( text:String )
	
		Super.New( text )
		_action=New Action( text )
		_action.Triggered=OpenSubMenu
	End
		
	Method AddSubMenu( menu:Menu )
		
		_subMenu=menu
		
		Clicked+=Lambda()
			Print "clicked"
		End
	End
	
	Property ClickAction:Action()
		
		Return _action
	End
	
	
	Protected
	
	Method OnMouseEvent( event:MouseEvent ) Override
		
		Print "mouse event"
		
		Select event.Type
			
			Case EventType.MouseEnter
			
				Print "MouseEnter"
			
			Case EventType.MouseLeave
			
				Print "MouseLeave"
			
		End
		
		Super.OnMouseEvent( event )
		
	End
	
	
	Private
	
	Field _subMenu:Menu
	Field _action:Action
	
	Method OpenSubMenu()
		
		Print "OpenSubMenu"
		If Not _subMenu Return
		
		If _subMenu.Visible
			_subMenu.Close()
		Else
			Local location:=New Vec2i( Bounds.Right,Bounds.Top )
			_subMenu.Open( location,Self,Self )
		Endif
	End
	
End
