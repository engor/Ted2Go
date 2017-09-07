
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
		
		If Keyboard.KeyDown( Key.Up )
			model.RotateX( 3 )
		Else If Keyboard.KeyDown( Key.Down )
			model.RotateX( -3 )
		Endif
		
		If Keyboard.KeyDown( Key.Left )
			model.RotateY( 3,True )
		Else If Keyboard.KeyDown( Key.Right )
			model.RotateY( -3,True )
		Endif

		If Keyboard.KeyDown( Key.A )
			_doc.Camera.MoveZ( .1 )
		Else If Keyboard.KeyDown( Key.Z )
			_doc.Camera.MoveZ( -.1 )
		Endif
		
		_doc.Scene.Render( canvas,_doc.Camera )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		If event.Type=EventType.KeyDown
			Select event.Key
			Case Key.R
				_doc.Camera.Position=New Vec3f(0,0,-2.5)
				_doc.Model.Rotation=New Vec3f(0,0,0)
			Case Key.S
				_doc.Light.ShadowsEnabled=Not _doc.Light.ShadowsEnabled
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
		_camera.Near=.1
		_camera.Far=100
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

		If _model
			
			_model.Mesh.FitVertices( New Boxf( -1,1 ) )
			
		Endif
	
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
		
		Extensions=New String[]( ".b3d",".3ds",".obj",".dae",".fbx",".blend",".x" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
		
		Return New SceneDocument( path )
	End
	
	Private
	
	Global _instance:=New SceneDocumentType
	
End
