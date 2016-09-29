
Namespace mojo3d

#Import "<std>"
#Import "<gles20>"
#Import "<mojo>"
#Import "<mojox>"

Using std..
Using gles20..

Using mojo.app
Using mojo.input
Using mojox

#Import "glutil"
#Import "texture"
#Import "uniformblock"
#Import "shader"
#Import "vertex"
#Import "vertexbuffer"
#Import "indexbuffer"
#Import "graphicsdevice"
#Import "shadowcaster"
#Import "image"
#Import "font"
#import "fontloader"
#Import "canvas"

#Import "Monkey2-logo-48.png"
#Import "trans_heart.png"
#Import "assets/"

Class SettingsView Extends TableView

	Method New()
		AddColumn( "Setting" )
		AddColumn( "Value" )
	End

	Method AddRow( label:String,view:View )
		Local row:=NumRows
		AddRows( 1 )
		Self[0,row]=New Label( label )
		Self[1,row]=view
	End
	
	Method AddText:TextField( label:String,text:String,changed:Void( text:String ) )
	
		Local view:=New TextField( text )
		view.Entered+=Lambda()
			changed( view.Text )
		End
		
		AddRow( label,view )
		Return view
	End
	
	Method AddCheck:CheckButton( label:String,value:String,checked:Bool,changed:Void( checked:Bool ) )
	
		Local view:=New CheckButton( value )
		view.Checked=checked
		view.Clicked+=Lambda()
			changed( view.Checked )
		End
		
		AddRow( label,view )
		Return view
	End
	
	Method AddFilePath:FilePathField( label:String,path:String,changed:Void( path:String ) )
	
		Local view:=New FilePathField( path )
		view.FilePathChanged+=Lambda()
			changed( view.FilePath )
		End
		
		AddRow( label,view )
		Return view
	End
	
	Method AddOptions:OptionsField( label:String,options:String[],current:Int,changed:Void( current:Int ) )
	
		Local view:=New OptionsField( options )
		view.CurrentChanged+=Lambda()
			changed( view.Current )
		End
		
		AddRow( label,view )
		Return view
	End

End

Class MyWindow Extends GLWindow

	Field _canvas:Canvas
	
	Field _logoImage:Image
	Field _logoCaster:ShadowCaster
	
	Field _heartImage:Image
		
	Field _bumpImage:Image
	Field _light:Image
	
	Field _imageSize:=512.0
	Field _imageRepeat:=1
	
	Field _diffPath:=""	'"Slate Tiles II_D.png"
	Field _normPath:="scale_normal.png"	'"Slate Tiles II_N.png"
	Field _specPath:=""	'"Slate Tiles II_S.png"
	Field _imageGloss:=0.5
	
	Field _lightPath:="pointlight2_light.png"
	Field _lightColor:=0
	Field _lightIntensity:=1.0
	Field _lightSize:=512.0
	Field _lightDepth:=100.0
	
	Field _ambient:Float=0.1
	
	Method UpdateImage()
	
		_bumpImage=Image.LoadBump( _diffPath,_normPath,_specPath,_imageGloss,True )
		
		Local size:=_imageSize/_imageRepeat
		
		_bumpImage.Scale=New Vec2f( size/_bumpImage.Width,size/_bumpImage.Height )
	End
	
	Method UpdateLight()
	
		Const _colors:=New Color[]( Color.White,Color.Red,Color.Green,Color.Blue )
		
		_light=Image.LoadLight( _lightPath )
	
		_light.Handle=New Vec2f( .5,.5 )
		_light.Scale=New Vec2f( _lightSize/_light.Width,_lightSize/_light.Height )
		_light.Color=_colors[_lightColor]*_lightIntensity
		_light.Depth=_lightDepth
		
	End

	Method New()
		Super.New( "Window",1024,768 )
	
		ChangeDir( AssetsDir() )
	
		Local _settings:=New SettingsView
		
		_settings.AddText( "Image size",_imageSize,Lambda( text:String )
			_imageSize=Float( text )
			UpdateImage()
		End )
		
		_settings.AddText( "Image repeat",_imageRepeat,Lambda( text:String )
			_imageRepeat=Int( text )
			UpdateImage()
		End )
		
		_settings.AddFilePath( "Image diffuse",_diffPath,Lambda( path:String )
			_diffPath=path
			UpdateImage()
		End )
		
		_settings.AddFilePath( "Image normal",_normPath,Lambda( path:String )
			_normPath=path
			UpdateImage()
		End )
		
		_settings.AddFilePath( "Image specular",_specPath,Lambda( path:String )
			_specPath=path
			UpdateImage()
		End )
		
		_settings.AddText( "Image gloss",_imageGloss,Lambda( text:String )
			_imageGloss=Float( text )
			UpdateImage()
		End )
		
		_settings.AddFilePath( "Light texture",_lightPath,Lambda( path:String )
			_lightPath=path
			UpdateLight()
		End )
		
		_settings.AddOptions( "Light color",New String[]( "White","Red","Green","Blue" ),_lightColor,Lambda( index:Int )
			_lightColor=index
			UpdateLight()
		End )
		
		_settings.AddText( "Light intensity",_lightIntensity,Lambda( text:String )
			_lightIntensity=Float( text )
			UpdateLight()
		End )
		
		_settings.AddText( "Light size",_lightSize,Lambda( text:String )
			_lightSize=Float( text )
			UpdateLight()
		End )
		
		_settings.AddText( "Light depth",_lightDepth,Lambda( text:String )
			_lightDepth=Float( text )
			UpdateLight()
		End )
		
		_settings.AddText( "Ambient light",_ambient,Lambda( text:String )
			_ambient=Float( text )
		End )
		
		Local dialog:=New Dialog( "Settings" )
		dialog.ContentView=_settings
		dialog.Open()
	
		BeginGL()
	
		_canvas=New Canvas
		
		_logoImage=Image.Load( "asset::monkey2-logo-48.png" )
		_logoImage.BlendMode=BlendMode.Alpha
		_logoImage.Handle=New Vec2f( .5,.5 )
		
		_logoCaster=New ShadowCaster( _logoImage.Width/2,24 )'_logoImage.Bounds )
		
		_heartImage=Image.Load( "asset::trans_heart.png" )
		_heartImage.BlendMode=BlendMode.Alpha'Additive
		_heartImage.Scale=New Vec2f( .25,.25 )
		_heartImage.Handle=New Vec2f( .5,.5 )
		
		UpdateImage()
		
		UpdateLight()
		
		EndGL()
	End
	
	Method OnRender( canvas:mojo.graphics.Canvas ) Override
	
		App.RequestRender()
	
		Super.OnRender( canvas )
		
		canvas.DrawText( "Hello World!",Width/2,0,.5,0 )
	End
	
	Method OnRenderGL() Override

		Global _rotz:=0.0
		
		Global _viewport:=New Recti( 32,32,1024-32,768-32 )
		
		If Keyboard.KeyDown( Key.Up )
			_viewport+=New Vec2i( 0,-3 )
		Else If Keyboard.KeyDown( Key.Down )
			_viewport+=New Vec2i( 0, 3 )
		Else If  Keyboard.KeyDown( Key.Left )
			_viewport+=New Vec2i( -3,0 )
		Else If  Keyboard.KeyDown( Key.Right )
			_viewport+=New Vec2i(  3,0 )
		Endif

		_canvas.AmbientLight=New Color( _ambient,_ambient,_ambient,1 )
		
		_canvas.Viewport=_viewport
		
		_canvas.Clear( Color.Blue )

		_canvas.PushMatrix()
		
		_canvas.Translate( Width/2,Height/2 )
		
		_canvas.Rotate( _rotz )

		_canvas.Translate( -Width/2,-Height/2 )
		
		For Local x:=0 Until _imageRepeat
			For Local y:=0 Until _imageRepeat
				_canvas.DrawImage( 
				_bumpImage,
				(Width-_imageRepeat*_bumpImage.Width)/2+x*_bumpImage.Width,
				(Height-_imageRepeat*_bumpImage.Height)/2+y*_bumpImage.Height )
			Next
		Next
		
		_canvas.PopMatrix()
		
		_canvas.DrawImage( _heartImage,Width/2,Height/3 )
		
		_canvas.DrawImage( _logoImage,Width/2,Height/2 )
		
		_canvas.Color=Color.Yellow
		
		_canvas.DrawText( "Hello World!",0,0 )
		
		_canvas.Color=Color.White
		
		_canvas.AddShadowCaster( _logoCaster,Width/2,Height/2 )

		_canvas.AddLight( _light,Mouse.X-_viewport.Origin.x,Mouse.Y-_viewport.Origin.y )
		
		_canvas.Flush()
	End

End

Function Main()

	New AppInstance
	
	New MyWindow
	
	App.Run()
	
End
