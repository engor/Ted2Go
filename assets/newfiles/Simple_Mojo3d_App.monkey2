Namespace myapp3d

#Import "<std>"
#Import "<mojo>"
#Import "<mojo3d>"

Using std..
Using mojo..
Using mojo3d..

Class MyWindow Extends Window
	
	Field _scene:Scene
	
	Field _camera:Camera
	
	Field _light:Light
	
	Field _ground:Model
	
	Field _donut:Model
	
	Method New( title:String="Simple mojo3d app",width:Int=640,height:Int=480,flags:WindowFlags=WindowFlags.Resizable )

		Super.New( title,width,height,flags )
		
		'create (current) scene
		'
		_scene=New Scene
		_scene.ShadowAlpha=.75
		
		'create camera
		'
		_camera=New Camera( Self )
		_camera.AddComponent<FlyBehaviour>()
		_camera.Move( 0,10,-5 )
		
		'create light
		'
		_light=New Light
		_light.CastsShadow=True
		_light.RotateX( 90 )
		
		'create ground
		'
		Local groundBox:=New Boxf( -50,-1,-50,50,0,50 )
		Local groundMaterial:=New PbrMaterial( Color.Green )
		_ground=Model.CreateBox( groundBox,1,1,1,groundMaterial )
		_ground.CastsShadow=False
		
		'create dount
		'		
		Local donutMaterial:=New PbrMaterial( Color.Brown )
		_donut=Model.CreateTorus( 2,.5,48,24,donutMaterial )
		_donut.Move( 0,10,0 )
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		RequestRender()
		
		_donut.Rotate( .2,.4,.6 )

		_scene.Update()
		
		_camera.Render( canvas )
		
		canvas.DrawText( "FPS="+App.FPS,0,0 )
	End
	
End

Function Main()

	New AppInstance
	
	New MyWindow
	
	App.Run()
End
