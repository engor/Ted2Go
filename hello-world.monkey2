
#rem

Hello World!

A minimal monkey2 graphical app.

See /bananas directory for more examples.

#end

#Import "<std>"
#Import "<mojo>"

Using std..
Using mojo..

Class MyWindow Extends Window

	Method OnRender( canvas:Canvas ) Override
	
		canvas.DrawText( "Hello World!",Width/2,Height/2,.5,.5 )

	End
	
End

Function Main()

	Print "Hello World!"

	New AppInstance
	
	New MyWindow
	
	App.Run()
	
End
