
Namespace spacechimps

#Import "<std>"
#Import "<mojo>"

Using std..
Using mojo..

#Import "assets/spaceship.png"

Class MyWindow Extends Window

	Field image:Image
	
	Field pos:Vec2f
	Field vel:Vec2f
	Field rot:Float

	Method New( title:String,width:Int,height:Int )
	
		'Call super class constructor - this just passes the arguments 'up' to the Window class constructor.
		'
		Super.New( title,width,height )

		
		'Black 'coz we're in space!
		'
		ClearColor=Color.Black
		
		
		'Load and setup our image...
		'
		'Note: Scaling image here is faster than scaling in DrawImage.
		'
		image=Image.Load( "asset::spaceship.png" )
		
		image.Handle=New Vec2f( .5,.5 )
		
		image.Scale=New Vec2f( .125,.125 )
		
		
		'Set initial image pos
		'
		pos=New Vec2f( width/2,height/2 )
	
	End

	Method OnRender( canvas:Canvas ) Override
	
		'This is necessary for 'continuous' rendering.
		'
		'Without it, OnRender will only be called when necessary, eg: when the window is resized.
		'
		App.RequestRender()
		
		
		'Gamey stuff below
		'
		If App.KeyDown( Key.Left )
			rot+=.1
		Else If App.KeyDown( Key.Right )
			rot-=.1
		Endif
		
		'wrap rot to [-Pi,Pi)
		rot=(rot+Pi*3) Mod TwoPi-Pi

		'calc forward vector..
		Local dir:=New Vec2f( Cos( rot ),-Sin( rot ) )
		
		If App.KeyDown( Key.Up )
			vel+=(dir * 5 - vel) *.025	'arcadey thruster
'			vel+=dir * .03				'realistic...
		Else
			vel*=.999
		End
		
		'add velocity to position
		pos+=vel
		
		'wrap pos to [0,size)
		pos.x=(pos.x+Width) Mod Width
		pos.y=(pos.y+Height) Mod Height

		canvas.DrawText( "Arrow keys to fly",Width/2,8,.5,0 )
		
		'Draw image
		'
		Local r:=rot-Pi/2
		canvas.DrawImage( image,pos,r )
		
		'Draw wrap around(s)
		'
		If pos.x-image.Radius<0 canvas.DrawImage( image,pos.x+Width,pos.y,r )
		If pos.x+image.Radius>Width canvas.DrawImage( image,pos.x-Width,pos.y,r )
		
		If pos.y-image.Radius<0 canvas.DrawImage( image,pos.x,pos.y+Height,r )
		If pos.y+image.Radius>Height canvas.DrawImage( image,pos.x,pos.y-Height,r )

	End
	
End

Function Main()

	New AppInstance
	
	New MyWindow( "Chimps in Space!",App.DesktopSize.x/2,App.DesktopSize.y/2 )
	
	App.Run()
End
