
Namespace ted2go


Class ToolButtonExt Extends ToolButton

	Method New( action:Action, hint:String=Null )
		Super.New( action )
		PushButtonMode=True
		_hint=hint
	End
	
	Property Hint:String()
		Return _hint
	End
	
	
	Protected
	
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
	
	
	Private
	
	Field _hint:String
	
End


Class ToolBarExt Extends ToolBar

	Method New()
		
		Super.New()
		MinSize=New Vec2i( 0,42 )
		Style.BackgroundColor=New Color( 50.0/255.0,50.0/255.0,50.0/255.0 )
		Style.Border=New Recti( 0,0,0,1 )
		Style.Padding=New Recti( 0,0,0,5 )
	End
	
	Method AddIconicButton:ToolButton( icon:Image, trigger:Void(), hint:String=Null )
		
		Local act:=New Action( Null,icon )
		act.Triggered=trigger
		Local b:=New ToolButtonExt( act,hint )
		AddView( b )
		Return b
	End
	
End

