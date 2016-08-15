
Namespace mojox

#rem monkeydoc Runs a simple 'alert' dialog.

If this function is called from the main fiber, a new fiber is created to the alert on.

#end
Function Alert( message:String,title:String="Alert!" )

	Local alert:=Lambda()
		TextDialog.Run( title,message,New String[]( "Okay" ),0,0 )
	End
	
	If Fiber.Current()=Fiber.Main()
		New Fiber( alert )
	Else
		alert()
	End
End

#rem monkeydoc Runs a simple 'okay/cancel' dialog.

Returns true if the user selects 'Okay', else false.

This function must not be called from the main fiber.

#end
Function RequestOkay:Bool( message:String="Are you sure you want to do this?",title:String="Okay?" )
	Assert( Fiber.Current<>Fiber.Main,"RequestOkay cannot be used from the main fiber" )

	Return TextDialog.Run( title,message,New String[]( "Okay","Cancel" ),0,1 )=0
End

#rem monkeydoc Runs a simple string dialog.

Returns the string typed by the user.

This function must not be called from the main fiber.


#end
Function RequestString:String( message:String="Enter a string:",title:String="String requester" )
	Assert( Fiber.Current<>Fiber.Main,"RequestString cannot be used from the main fiber" )

	Local future:=New Future<String>
	
	Local textField:=New TextField
	
	Local label:=New Label( message )
	label.AddView( textField )
	
	Local dialog:=New Dialog( title )
	
	dialog.MaxSize=New Vec2i( 320,0 )
	
	dialog.ContentView=label
	
	Local okay:=dialog.AddAction( "Okay" )
	okay.Triggered=Lambda()
		future.Set( textField.Text )
	End
	
	Local cancel:=dialog.AddAction( "Cancel" )
	cancel.Triggered=Lambda()
		future.Set( "" )
	End
	
	textField.Entered=okay.Trigger
	textField.Escaped=cancel.Trigger
	
	dialog.Open()
	
	textField.MakeKeyView()
	
	App.BeginModal( dialog )

	Local str:=future.Get()

	App.EndModal()
		
	dialog.Close()
	
	Return str
End

