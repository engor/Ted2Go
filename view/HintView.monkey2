
Namespace ted2go


Function ShowHint( hint:String,location:Vec2i,sender:View,duration:Int=3000 )

	If Not _hint Then InitHint()
	
	_hint.Show( hint,location,sender )
	_time=Millisecs()
	_duration=duration
End

Function HideHint()

	If Not _hint Return
	_hint.Hide()
	_time=0
End


Private

Global _hint:HintView
Global _timer:Timer
Global _time:Long
Global _duration:Int

Function InitHint()

	_hint=New HintView
	_timer=New Timer( 1, Lambda()
		If _time > 0 And Millisecs() >= _time+_duration
			HideHint()
		End
	End )
End


Class HintView Extends TextView

	Method New()
		
		Style=GetStyle( "Hint" )
		ReadOnly=True
		Visible=False
		Layout="float"
		Gravity=New Vec2f( 0,0 )
	End
	
	Method Show( text:String,location:Vec2i,sender:View )
		
		Hide()
		
		Text=text
		MainWindow.AddChildView( Self )
		Visible=True
		
		Local window:=sender.Window
		
		location=sender.TransformPointToView( location,window )
		Local dy:=New Vec2i( 0,10 )
		
		' fit into window area
		Local size:=MeasureLayoutSize()
		Local dx:=location.x+size.x-window.Bounds.Right
		If dx>0
			location=location-New Vec2i( dx,0 )
		Endif
		If location.y+size.y+dy.y>window.Bounds.Bottom
			location=location-New Vec2i( 0,size.y )
			dy=-dy
		Endif
		Offset=location+dy
		
	End
	
	Method Hide()
		
		If Not Visible Return
		
		If Parent = MainWindow
			MainWindow.RemoveChildView( Self )
		Endif
		Visible=False
	End
	
End
