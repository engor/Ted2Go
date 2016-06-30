
Namespace test

#Import "<std>"
#Import "<mojo>"

#Import "../mojox/mojox"

Using std..
Using mojo..
Using mojox..

Class MyWindow Extends Window

	Method New()
	
		Local dialog:=New Dialog
	
		Local docker:=New DockingView
		docker.AddView( New Label( "Find..." ),"top" )
		docker.AddView( New Label( "Replace..." ),"top" )
		docker.AddView( New Label( "Case sensitive" ),"top" )

		dialog.Title="Find"
		dialog.ContentView=docker
		dialog.AddAction( "Find Next" )
		dialog.AddAction( "Close" )
		
'		dialog.MinSize=New Vec2i( 320,240 )
		
		dialog.Open()
	End

End

Function Main()

	New AppInstance

	New Theme
		
	New MyWindow
	
	App.Run()
End
