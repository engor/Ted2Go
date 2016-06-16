
#Import "<std>"
#Import "<mojo>"

#Import "assets/t3.png"
#Import "assets/t3_SPECULAR.png"
#Import "assets/t3_NORMALS.png"

Using std..
Using mojo..

Class MyWindow Extends Window

	Field t3:Image
	
	Method New()
	
		t3=Image.Load( "asset::t3.png" )
		DebugAssert( t3 )
		
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		canvas.AmbientLight=Color.White
	
		canvas.DrawImage( t3,0,0 )
		
	End
	
End

Function Main()

	New AppInstance
	
	New MyWindow
	
	App.Run()
	
End
