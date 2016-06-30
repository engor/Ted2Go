
Namespace mojox

Class TextField Extends TextView

	Field EnterHit:Void()
	
	Field TabHit:Void()

	Method New()
		Style=Style.GetStyle( "mojo.TextField" )
		Local scroller:=Cast<ScrollView>( Container )
		scroller.ScrollBarsVisible=False
		scroller.Layout="fill-x"
	End
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		Select event.Type
		Case EventType.KeyDown
			Select event.Key
			Case Key.Enter
'				SelectText( 0,0 )
				EnterHit()
				Return
			Case Key.Tab
'				SelectText( 0,0 )
				TabHit()
				Return
			End
		End
		
		Super.OnKeyEvent( event)
	
	End
	
End
