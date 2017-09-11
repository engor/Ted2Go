
Namespace ted2go

#Import "<mojo3d>"
#Import "<mojo3d-loaders>"

Using mojo3d..

Class SceneDocumentView Extends View

	Method New( doc:SceneDocument )
		_doc=doc
		
		Layout="fill"
	End
	
	Protected
	
	Method OnRender( canvas:Canvas ) Override
	
		For Local x:=0 Until Width Step 64
			For Local y:=0 Until Height Step 64
				canvas.Color=(x~y) & 64 ? New Color( .1,.1,.1 ) Else New Color( .05,.05,.05 )
				canvas.DrawRect( x,y,64,64 )
			Next
		Next
		
		Local model:=_doc.Model
		If Not model
			canvas.Clear( Color.Sky )
			Return
		Endif
		
		RequestRender()
		
		Global _anim:Float=0
		
		If Keyboard.KeyDown( Key.A )
			If _doc.Model.Animator
				_anim+=12.0/60.0
				_doc.Model.Animator.Animate( 0,_anim )
			Endif
		Else
			_anim=0
		Endif
		
		_doc.Scene.Render( canvas,_doc.Camera )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
		
		If Not _doc.Model Return
		
		Global _v:Vec2i
		Global _f:Bool
		
		Select event.Type
		Case EventType.MouseDown
			_v=event.Location
			_f=True
		Case EventType.MouseMove
			If _f
				Local dv:=event.Location-_v
				Local rx:=Float(dv.x)/Height * +180.0
				Local ry:=Float(dv.y)/Height * -180.0
				_doc.Model.Rotate( ry,rx,0 )
				_v=event.Location
			Endif
		Case EventType.MouseUp
			_f=False
		Case EventType.MouseWheel
			_doc.Camera.MoveZ( Float(event.Wheel.y)*-.1 )
		End
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		If event.Type=EventType.KeyDown
			Select event.Key
			Case Key.R
				_doc.Camera.Position=New Vec3f(0,0,-2.5)
				_doc.Model.Rotation=New Vec3f(0,0,0)
			Case Key.S
				_doc.Light.CastsShadow=Not _doc.Light.CastsShadow
			Case Key.A
				
			End
		Endif
		
	End
	
	Private

	Field _doc:SceneDocument
End

Class SceneDocument Extends Ted2Document
	
	Method New( path:String )
		Super.New( path )
		
		_view=New SceneDocumentView( Self )
		
		_scene=New Scene
		
		Scene.SetCurrent( _scene )
		
		_camera=New Camera
		_camera.Near=.01
		_camera.Far=10
		_camera.MoveZ( -2.5 )
			
		_light=New Light
		_light.RotateX( Pi/2 )
		
		_model=null
		
		Scene.SetCurrent( Null )
	End
	
	Property Scene:Scene()
		
		Return _scene
	End
	
	Property Camera:Camera()
		
		Return _camera
	End
	
	Property Light:Light()
		
		Return _light
	End
	
	Property Model:Model()
	
		Return _model
	End
	
	Protected
	
	Method OnLoad:Bool() Override
		
		If _model _model.Destroy()
		
		Print "Loading model:"+Path

		Scene.SetCurrent( _scene )
		
		_model=Model.Load( Path )
		
		Scene.SetCurrent( Null )

		If _model _model.Mesh.FitVertices( New Boxf( -1,1 ) )
	
		Return True
	End
	
	Method OnSave:Bool() Override

		Return False
	End
	
	Method OnClose() Override
		
		_scene.DestroyAllEntities()
		
	End
	
	Method OnCreateView:SceneDocumentView() Override
	
		Return _view
	End
	
	Private
	
	Field _view:SceneDocumentView
	
	Field _scene:Scene
	
	Field _camera:Camera
	
	Field _light:Light
	
	Field _model:Model
End

Class SceneDocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".gltf",".b3d",".3ds",".obj",".dae",".fbx",".blend",".x" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
		
		Return New SceneDocument( path )
	End
	
	Private
	
	Global _instance:=New SceneDocumentType
	
End
