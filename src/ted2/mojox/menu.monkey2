
Namespace mojox

Class MenuButton Extends Button

	Method New( text:String )
		Super.New( text )
		
		Layout="fill"
		Style=Style.GetStyle( "mojo.MenuButton" )
		TextGravity=New Vec2f( 0,.5 )

'		MinSize=New Vec2i( 128,0 )
	End
	
	Method New( action:Action )
		Super.New( action )
		
		Layout="fill"
		Style=Style.GetStyle( "mojo.MenuButton" )
		TextGravity=New Vec2f( 0,.5 )
		
		MinSize=New Vec2i( 160,0 )

		_action=action
	End
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=Super.OnMeasure()
		
		If _action
			Local hotKey:=_action.HotKeyLabel
			If hotKey size.x+=Style.DefaultFont.TextWidth( "         "+hotKey )
		Endif
		
		Return size
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		Super.OnRender( canvas )
		
		If _action
			Local hotKey:=_action.HotKeyLabel
			If hotKey
				Local w:=Style.DefaultFont.TextWidth( hotKey )
				Local tx:=(Width-w)
				Local ty:=(Height-MeasuredSize.y) * TextGravity.y
				canvas.DrawText( hotKey,tx,ty )
			Endif
		Endif
	
	End
	
	Field _action:Action

End

Class Menu Extends DockingView

	Method New( label:String )
		_label=label
		Visible=False
		Style=mojo.app.Style.GetStyle( "mojo.Menu" )
		Layout="float"
		Gravity=New Vec2f( 0,0 )
	End
	
	Property Label:String()
		Return _label
	End
	
	Method Clear()
		Super.ClearViews()
	End
	
	Method AddAction( action:Action )
		Local button:=New MenuButton( action )
		button.Clicked+=Lambda()
			_open[0].Close()
		End
		AddView( button,"top",0 )
	End
	
	Method AddAction:Action( label:String )
		Local action:=New Action( label )
		AddAction( action )
		Return action
	End
	
	Method AddSeparator()
		AddView( New Separator,"top",0 )
	End
	
	Method AddSubMenu( menu:Menu )
	
		Local label:=New MenuButton( menu.Label )

		label.Clicked=Lambda()
			If menu.Visible
				menu.Close()
			Else
				Local location:=New Vec2i( label.Bounds.Right,label.Bounds.Top )
				menu.Open( location,label,Self )
			Endif
		End
		
		AddView( label,"top",0 )
	End
	
	Method Open( location:Vec2i,view:View,owner:View )
	
		Assert( Not Visible )
		
		While Not _open.Empty And _open.Top<>owner
			_open.Top.Close()
		Wend
		
		If _open.Empty
			_filter=App.MouseEventFilter
			App.MouseEventFilter=MouseEventFilter
		Endif
		
		Local window:=view.FindWindow()
		location=view.TransformPointToView( location,window )
		
		window.AddChild( Self )
		Offset=location
		Visible=True
		
		_owner=owner
		_open.Push( Self )
	End
	
	Method Close()
	
		Assert( Visible )
		
		While Not _open.Empty
		
			Local menu:=_open.Pop()
			menu.Parent.RemoveChild( menu )
			menu.Visible=False
			menu._owner=Null
			
			If menu=Self Exit
		Wend
		
		If Not _open.Empty Return
		
		App.MouseEventFilter=_filter
		_filter=Null
	End
	
	Private
	
	Field _label:String
	Field _owner:View
	
	Global _open:=New Stack<Menu>
	Global _filter:Void( MouseEvent )
	
	Function MouseEventFilter( event:MouseEvent )
	
		If event.Eaten Return
		
		Local view:=event.View
		
		If view<>_open[0]._owner
			
			For Local menu:=Eachin _open
				If view.IsChildOf( menu ) Return
			Next
		
			If view.IsChildOf( _open[0]._owner ) Return

		Endif
		
		If event.Type<>EventType.MouseDown
			event.Eat()
			Return
		Endif
		
		event.Eat()
		
		_open[0].Close()
	End
		
End

Class MenuBar Extends DockingView

	Method New()
		Style=Style.GetStyle( "mojo.MenuBar" )
		Layout="fill"
	End
	
	Method AddMenu( menu:Menu )
	
		Local label:=New MenuButton( menu.Label )

		label.Clicked=Lambda()
		
			If Not menu.Visible
				Local location:=New Vec2i( label.Bounds.Left,label.Bounds.Bottom )
				menu.Open( location,label,Self )
			Else
				menu.Close()
				Return
			Endif
		End
		
		AddView( label,"left",0 )
	End
	
End
