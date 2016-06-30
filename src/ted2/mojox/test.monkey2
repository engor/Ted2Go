
Namespace ted

#Import "mojox"

Using std..
Using mojo..
Using mojo2..

Class MainWindow Extends Window

	Method New( title:String,rect:Recti,flags:WindowFlags )
		Super.New( title,rect,flags )
		
		Style=New Style( Style )
		Style.BackgroundColor=Color.Magenta
		
		App.RequestRender()
		
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		canvas.DrawText( "Hello World",0,0 )
		
		App.RequestRender()
		
		GCCollect()
	End

End

Function Main()

	New AppInstance
	
	New MainWindow( "Ted2",New Recti( 16,16,640+16,640+16 ),WindowFlags.Resizable )
	
	App.Run()
	
End
