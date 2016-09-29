
Namespace myapp

#Import "<std>"
#Import "<mojo>"

#Import "Slate Tiles II_D.png"
#Import "Slate Tiles II_N.png"
#Import "Slate Tiles II_S.png"
#Import "pointlight_light.png"
#Import "Monkey2-logo-48.png"

Using std..
Using mojo..

Class MyWindow Extends Window

	Field _floor:Image
	
	Field _light:Image
	
	Field _logo:Image
	
	Method New()
	
		ClearColor=Color.Black
	
		_floor=Image.LoadBump( "asset::Slate Tiles II_D.png","asset::Slate Tiles II_N.png","asset::Slate Tiles II_S.png",.5,True )
		
		_light=Image.LoadLight( "asset::pointlight_light.png" )
		
		_light.Handle=New Vec2f( .5 )
	
		_light.Scale=New Vec2f( 3 )
		
		_logo=Image.Load( "asset::Monkey2-logo-48.png" )
		
		_logo.Handle=New Vec2f( .5 )
		
		_logo.ShadowCaster=New ShadowCaster( _logo.Width/2,20 )
		
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		App.RequestRender()
		
		canvas.AmbientLight=Color.DarkGrey
		
		canvas.BeginLighting()
		
		canvas.AddLight( _light,Mouse.X,Mouse.Y )
		
		For Local x:=0 Until Width Step _floor.Width

			For Local y:=0 Until Height Step _floor.Height

				canvas.DrawImage( _floor,x,y )

			Next

		Next
		
		For Local an:=0.0 Until TwoPi Step TwoPi/8.0
		
			canvas.DrawImage( _logo,Width/2+Cos( an ) * Width/4,Height/2 + Sin( an ) * Height/4 )
		
		Next
		
		canvas.EndLighting()
		
		canvas.DrawText( App.FPS,Width/2,0,.5,0 )
	End
	
End

Function Main()

	New AppInstance
	
	New MyWindow
	
	App.Run()
End
