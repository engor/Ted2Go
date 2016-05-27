
Namespace spacechimps

#Import "<std>"
#Import "<mojo>"

#Import "assets/bang.wav"
#Import "assets/spaceship.png"

Using std..
Using mojo..

Class MyWindow Extends Window

	Field timer:Timer
	Field laser:Sound
	Field image:Image
	Field pos:=New Vec2f
	Field vel:=New Vec2f
	Field rot:Float

	Method New( title:String,width:Int,height:Int )
	
		'Call super class constructor - this just passes the arguments 'up' to the Window class constructor.
		'
		Super.New( title,width,height,WindowFlags.Resizable )
		
		'Black 'coz we're in space!
		'
		ClearColor=Color.Black

		'Load laser sound effecy
		'		
		laser=Sound.Load( "asset::bang.wav" )
		
		If Not laser Print "Couldn't load laser"
		
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
		
		'Start update timer
		'
'		timer=New Timer( 60,OnUpdate )

		'Vwait always recommended...
		'	
		SwapInterval=1
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
		Select event.Type
		Case EventType.KeyDown
			Select event.Key
			Case Key.S
				SwapInterval=1-SwapInterval
'#If __TARGET__<>"emscripten"
			Case Key.T
				If timer
					timer.Cancel()
					timer=Null
					App.RequestRender()
				Else
					timer=New Timer( 60,OnUpdate )
				Endif
'#Endif
			End
		End
	End

	Method OnWindowEvent( event:WindowEvent ) Override
	
		Select event.Type
		Case EventType.WindowMoved
		Case EventType.WindowResized
			App.RequestRender()
		Case EventType.WindowGainedFocus
			If timer timer.Suspended=False
		Case EventType.WindowLostFocus
			If timer timer.Suspended=True
		Default
			Super.OnWindowEvent( event )
		End
	End
	
	Method OnUpdate()
	
		App.RequestRender()
		
		'rotate
		'
		If Keyboard.KeyDown( Key.Left )
			rot+=.1
		Else If Keyboard.KeyDown( Key.Right )
			rot-=.1
		Endif
		
		'wrap rot to [-Pi,Pi)
		'
		rot=(rot+Pi*3) Mod TwoPi-Pi

		'calc forward vector..
		'
		Local dir:=New Vec2f( Cos( rot ),-Sin( rot ) )

		'thrust
		'
		If Keyboard.KeyDown( Key.Up )
			vel+=(dir * 5 - vel) *.025	'arcadey thruster
'			vel+=dir * .03				'realistic...
		Else
			vel*=.999
		End
		
		'add velocity to position
		'
		pos+=vel
		
		'wrap pos to [0,size)
		'
		pos.x=(pos.x+Width) Mod Width
		pos.y=(pos.y+Height) Mod Height
		
		If Keyboard.KeyPressed( Key.Space )
			laser.Play()
'			Print "Fire!"
		End

		If Keyboard.KeyReleased( Key.Space )
'			Print "UnFire!"
		End
		
	End
	
	Field ms:=0
	
	Method OnRender( canvas:Canvas ) Override
	
		Local e:=App.Millisecs-ms	'ideally, e should be 16,17,17,16,17,17 ie: 16.6666...
'		If e<>16 And e<>17 Print "elapsed="+e	'show glitches
		ms+=e
		
		If Not timer OnUpdate()
		
		'Title text
		'	
		canvas.DrawText( "FPS="+App.FPS,Width/2,8,.5,0 )
		canvas.DrawText( "Arrow keys to fly",Width/2,24,.5,0 )
		canvas.DrawText( "Swap interval="+SwapInterval +" ('S' to toggle)",Width/2,40,.5,0 )
'#If __TARGET__="emscripten"
'		canvas.Color=Color.Grey
'#Endif
		canvas.DrawText( "Timer sync="+(timer ? "true" Else "false")+" ('T' to toggle)",Width/2,56,.5,0 )
		canvas.Color=Color.White
		
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
