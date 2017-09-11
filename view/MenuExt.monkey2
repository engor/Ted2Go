
Namespace ted2go

Class MenuExt Extends DockingView

	#rem monkeydoc Creates a new menu.
	#end
	Method New( text:String="" )
		
		Style=GetStyle( "Menu" )
		Visible=False
		Layout="float"
		Gravity=New Vec2f( 0,0 )
		
		_text=text
	End
	
	#rem monkeydoc Menu text
	#end
	Property Text:String()
		Return _text
	End

	#rem monkeydoc Clears all items from the menu.
	#end
	Method Clear()
		Super.RemoveAllViews()
	End

	#rem monkeydoc Adds a view to the menu.
	#end	
	Method AddView( view:View )
	
		AddView( view,"top" )
	End
	
	#rem monkeydoc Adds an action to the menu.
	#end	
	Method AddAction( action:Action )
	
		Local button:=New MenuButtonExt( action )
		
		button.Clicked=Lambda()
		
			CloseAll()
			'
			'a bit gnarly, but makes sure menu is *really* closed...
			'
			App.RequestRender()
			App.Idle+=action.Trigger
		End
		
		AddView( button )
	End
	
	Method AddAction:Action( text:String )
		
		Local action:=New Action( text )
		AddAction( action )
		Return action
	End
	
	#rem monkeydoc Adds a separator to the menu.
	#end
	Method AddSeparator()
		
		AddView( New MenuSeparator,"top" )
	End
	
	#rem monkeydoc Adds a submenu to the menu.
	#end
	Method AddSubMenu( menu:MenuExt )
	
		Local button:=New MenuButtonExt( menu.Text )
		button.HasSubmenu=True
		
		_subs[button]=menu
		
		button.Clicked=Lambda()
			If menu.Visible
				If Not Prefs.SiblyMode
					menu.Close()
				Endif
			Else
				Local location:=New Vec2i( button.Bounds.Right,button.Bounds.Top )
				menu.Open( location,button,Self )
			Endif
		End
		
		AddView( button,"top" )
	End
	
	#rem monkeydoc Opens the menu.
	#end
	Method Open()
	
		Open( App.MouseLocation,App.ActiveWindow,Null )
	End
	
	#rem monkeydoc @hidden
	#end
	Method Open( location:Vec2i,view:View,owner:View )
	
		If Visible Return
		
		While Not _open.Empty And _open.Top<>owner
			_open.Top.Close()
		Wend
		
		If _open.Empty
			_filter=App.MouseEventFilter
			App.MouseEventFilter=MouseEventFilter
		Endif
		
		Local window:=view.Window
		location=view.TransformPointToView( location,window )
		
		window.AddChildView( Self )
		Offset=location
		Visible=True
		
		_owner=owner

		_open.Push( Self )
	End
	
	#rem monkeydoc @hidden
	#end	
	Method Close()
	
		If Not Visible Return
		
		While Not _open.Empty
		
			Local menu:=_open.Pop()
			menu.Parent.RemoveChildView( menu )
			menu.Visible=False
			menu._owner=Null
			
			If menu=Self Exit
		Wend
		
		If Not _open.Empty Return
		
		App.MouseEventFilter=_filter

		_filter=Null
	End
	
	Private
	
	Field _subs:=New Map<View,MenuExt>
	Field _text:String
	Field _owner:View
	Global _hovered:View
	Global _timer:Timer
	Global _sub:MenuExt
	
	Global _open:=New Stack<MenuExt>
	
	Global _filter:Void( MouseEvent )
	
	Function CloseAll()
		
		_open[0].Close()
	End
	
	Function MouseEventFilter( event:MouseEvent )
	
		If event.Eaten Return
		
		Local view:=event.View
			
		For Local menu:=Eachin _open
		
			If view.IsChildOf( menu )
				
				If event.Type=EventType.MouseMove
					
					' auto-expand sub menus
					'
					If view=_hovered Return
					_hovered=view
					If _timer Then _timer.Cancel()
					
					Local sub:=menu._subs[view]
					
					If Not Prefs.SiblyMode
						If _sub And menu<>_sub
							_sub.Close()
							_sub=Null
						Endif
					Endif
					
					If sub
						_timer=New Timer( 1.8,Lambda()
							Local location:=New Vec2i( view.Bounds.Right,view.Bounds.Top )
							
							If Prefs.SiblyMode
								If _sub And menu<>_sub
									_sub.Close()
									_sub=Null
								Endif
							Endif
							
							If sub.Visible Then sub.Close()
							sub.Open( location,view,menu )
							_sub=sub
							_timer.Cancel()
							_timer=Null
						End )
					Endif
				Endif
				
				Return
			Endif
		Next
		
		_hovered=Null
		If _timer Then _timer.Cancel()
		
		' auto-expand root menus in menu bar
		'
		If event.Type=EventType.MouseMove
			
			Local bar:=Cast<MenuBarExt>( _open[0]._owner )
			If bar
				Local window:=view.Window
				Local location:=view.TransformPointToView( event.Location,window )
				Local v:=bar.FindViewAtWindowPoint( location )
				If v<>bar.Opened
					Local b:=Cast<MenuButton>( v )
					If b Then b.Clicked()
				Endif
			Endif
		Endif
		
		' we are interesting to mousedown only
		'
		If event.Type<>EventType.MouseDown Return
		
		If _open[0]._owner
		
			If view<>_open[0]._owner And view.IsChildOf( _open[0]._owner ) Return
			
			CloseAll()
		Else
			
			CloseAll()
		Endif
	End
	
End


Class MenuButtonExt Extends Button
	
	Field HasSubmenu:Bool
	
	Method New( action:Action )
	
		Super.New( action )
		
		Style=GetStyle( "MenuButton" )
		TextGravity=New Vec2f( 0,.5 )
		Layout="fill-x"
		
		_action=action
		
		UpdateThemeColors()
	End
	
	Method New( text:String )
	
		Super.New( text )
		
		Style=GetStyle( "MenuButton" )
		TextGravity=New Vec2f( 0,.5 )
		Layout="fill-x"
		
		UpdateThemeColors()
	End
	
	
	Protected
	
	Method OnThemeChanged() Override
		
		UpdateThemeColors()
	End
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=Super.OnMeasure()
	
		If _action
			Local hotKey:=_action.HotKeyText
			If hotKey size.x+=RenderStyle.Font.TextWidth( "         "+hotKey )
		Endif
		If HasSubmenu
			size.x+=RenderStyle.Font.TextWidth( " >" )
		Endif
		Return size
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		Super.OnRender( canvas )
		
		If _action
			Local hotKey:=_action.HotKeyText
			If hotKey
				Local w:=RenderStyle.Font.TextWidth( hotKey )
				Local tx:=(Width-w)
				Local ty:=(Height-MeasuredSize.y) * TextGravity.y
				Local color:=canvas.Color
				canvas.Color=_shortCutColor
				canvas.DrawText( hotKey,tx,ty )
				canvas.Color=color
			Endif
		Endif
		
		If HasSubmenu
			Local tx:=Width
			Local ty:=(Height-MeasuredSize.y) * TextGravity.y
			canvas.DrawText( ">",tx,ty,1,0 )
		Endif
	End
	
	
	Private
	
	Field _action:Action
	Field _shortCutColor:Color
	
	Method UpdateThemeColors()
		
		_shortCutColor=App.Theme.GetColor( "menu-shortcut" )
	End
	
End


Class MenuBarExt Extends ToolBar

	Method New()
		Style=GetStyle( "MenuBar" )
		
		Layout="fill-x"
		Gravity=New Vec2f( 0,0 )
	End
	
	Method AddMenu( menu:MenuExt )
	
		Local button:=New MenuButton( menu.Text )

		button.Clicked=Lambda()
			_opened=Null
			If menu.Visible
				menu.Close()
			Else
				Local location:=New Vec2i( button.Bounds.Left,button.Bounds.Bottom )
				menu.Open( location,button,Self )
				_opened=button
			Endif
		End
		
		AddView( button )
	End
	
	Property Opened:MenuButton()
		Return _opened
	End
	
	
	Private
	
	Field _opened:MenuButton
	
End
