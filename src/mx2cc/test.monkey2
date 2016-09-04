
Namespace myapp

#Import "<std>"
#Import "<mojo>"

Using std..
Using mojo..

Class MyWindow Extends Window

	Method OnRender( canvas:Canvas ) Override
	
		canvas.DrawText( "Hello World",Width/2,Height/2,.5,.5 )
	
	End
	
End

Function Main()

	New AppInstance
	
	New MyWindow
	
	App.Run()
End
