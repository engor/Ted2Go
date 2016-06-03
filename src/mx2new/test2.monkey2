
#Import "<std>"
#Import "<mojo>"

Using std..
Using mojo..

Class MyWindow Extends Window
	Field t:Test
	
	Method New(title:String, width:Int, height:Int)
		Super.New(title, width, height, WindowFlags.Resizable)
		ClearColor = Color.Black
		SwapInterval=1
		t = New Test()		
	End
	
	Method OnRender( canvas:Canvas ) Override
		App.RequestRender()
		canvas.DrawText( "Hello World!",Width/2,Height/2,.5,.5 )
		Local x:=t.Hop()
	End
End

Class Test
	Method Hop()
		Print "Hop"
	End
End

Function Main()
	New AppInstance
	New MyWindow("Hello World", 640, 480)
	App.Run()
End