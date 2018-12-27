
Namespace ted2go


Class ToolBarExt Extends ToolBar

	Method New( axis:Axis = Null )
		
		Super.New( axis )
		Style=GetStyle( "ToolBarExt" )
	End
	
	Method AddIconicButton:ToolButtonExt( icon:Image,trigger:Void(),hint:String=Null )
		
		Local act:=New Action( Null,icon )
		act.Triggered=trigger
		Local b:=New ToolButtonExt( act,hint )
		AddView( b )
		Return b
	End
	
	Method AddIconicButton:MultiIconToolButton( icons:Image[],trigger:Void(),hint:String=Null )
		
		Local act:=New Action( Null )
		act.Triggered=trigger
		Local b:=New MultiIconToolButton( act,icons,hint )
		AddView( b )
		Return b
	End
	
End


Class ToolButtonExt Extends ToolButton

	Field Toggled:Void( state:Bool )
	
	Method New( action:Action,hint:String=Null )
		
		Super.New( action )
		
		Style=GetStyle( "ColoredToolButton" )
		
		PushButtonMode=True
		_hint=hint
		
		UpdateColors()
		
		Clicked+=Lambda()
			If ToggleMode Then IsToggled=Not IsToggled
		End
		
	End
	
	Property Hint:String()
		Return _hint
	Setter( value:String )
		_hint=value
	End
	
	Property IsToggled:Bool()
		Return _toggled
	Setter( value:Bool )
		If value = _toggled Return
		_toggled=value
		Toggled( _toggled )
	End
	
	Property ToggleMode:Bool()
		Return _toggleMode
	Setter( value:Bool )
		If value = _toggleMode Return
		_toggleMode=value
		If Not _toggleMode Then IsToggled=False
	End
		
		
	Protected
	
	Method OnThemeChanged() Override
		UpdateColors()
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
		
		If _hint <> Null
			If event.Type = EventType.MouseEnter
				ShowHint( _hint,event.Location,Self )
			Elseif event.Type = EventType.MouseLeave
				HideHint()
			Endif
		Endif
		
		Super.OnMouseEvent( event )
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		If _toggled
			canvas.Color=_selColor
			canvas.LineWidth=1
			Utils.DrawRect( canvas,Rect,True )
		Endif
		Super.OnRender( canvas )
	End
	
	
	Private
	
	Field _hint:String
	Field _selColor:Color
	Field _toggled:Bool,_toggleMode:Bool
	
	Method UpdateColors()
		
		_selColor=App.Theme.GetColor( "active" )
		
	End
	
End


Class MultiIconToolButton Extends ToolButtonExt
	
	Method New( action:Action,icons:Image[],hint:String=Null )
		
		Super.New( action,hint )
		
		_icns=icons
		Icon=icons[0]
	End
	
	Method SetIcon( index:Int )
		
		Icon=_icns[index]
	End
	
	
	Private
	
	Field _icns:Image[]
	
End

