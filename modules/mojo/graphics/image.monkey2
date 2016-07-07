
Namespace mojo.graphics

#rem monkeydoc The Image class.

An image is a rectangular array of pixels that can be drawn using one of the [[Canvas.DrawImage]] methods.

You can load an image from a file using the [[Load]].

#end
Class Image

	#rem monkeydoc @hidden
	#end
	Field OnDiscarded:Void()

	#rem monkeydoc Creates a new image.
	
	New( pixmap,... ) allows you to create a new image from an existing pixmap.
	
	New( width,height,... ) allows you to create a new image that can be rendered to using a canvas. For images that will be frequently updated, use `TextureFlags.Filter|TextureFlags.Dynamic' for the best performance.
	
	New( image,rect,... ) allows you to create an image from within an 'atlas' image.
	
	@example
	
	Namespace myapp
	
	#Import "<std>"
	#Import "<mojo>"
	
	Using std..
	Using mojo..
	
	Class MyWindow Extends Window
	
		Field image1:Image
		Field image2:Image
		Field image3:Image
			
		Method New()
	
			'Create an image from a pixmap
			Local pixmap:=New Pixmap( 16,16 )
			pixmap.Clear( Color.Red )
			image1=New Image( pixmap )
			
			'Create an image and render something to it
			image2=New Image( 16,16 )
			Local icanvas:=New Canvas( image2 )
			icanvas.Color=Color.Yellow
			icanvas.DrawRect( 0,0,8,8 )
			icanvas.DrawRect( 8,8,8,8 )
			icanvas.Color=Color.LightGrey
			icanvas.DrawRect( 8,0,8,8 )
			icanvas.DrawRect( 0,8,8,8 )
			icanvas.Flush() 'Important!
			
			'Create a image from an atlas image
			image3=New Image( image2,New Recti( 4,4,12,12 ) )
			
		End
	
		Method OnRender( canvas:Canvas ) Override
		
			canvas.DrawText( "Image1",0,0 )
			canvas.DrawImage( image1,0,16 )
			
			canvas.DrawText( "Image2",0,40 )
			canvas.DrawImage( image2,0,56 )
	
			canvas.DrawText( "Image3",0,80 )
			canvas.DrawImage( image3,0,96 )
			
		End
		
	End
	
	Function Main()
	
		New AppInstance
		
		New MyWindow
		
		App.Run()
	End
	
	@end
	
	#end
	Method New( pixmap:Pixmap,textureFlags:TextureFlags=TextureFlags.Filter|TextureFlags.Mipmap,shader:Shader=Null )
	
		Local texture:=New Texture( pixmap,textureFlags )
		
		Init( Null,texture,texture.Rect,shader )
		
		OnDiscarded+=Lambda()
			texture.Discard()
		End
	End
	
	Method New( width:Int,height:Int,textureFlags:TextureFlags=TextureFlags.Filter|TextureFlags.Mipmap,shader:Shader=Null )
	
		Local textureFormat:PixelFormat=PixelFormat.RGBA32
		
		Local texture:=New Texture( width,height,textureFormat,textureFlags )
		
		Init( Null,texture,texture.Rect,shader )

		OnDiscarded+=Lambda()
			texture.Discard()
		End

	End
	
	Method New( image:Image,rect:Recti )
	
		Init( image._material,image._texture,rect,Null )
	End

	#rem monkeydoc @hidden
	#end
	Method New( texture:Texture,shader:Shader=Null )
	
		Init( Null,texture,texture.Rect,shader )
	End
	
	#rem monkeydoc @hidden
	#end
	Method New( material:Material,texture:Texture,rect:Recti )
	
		Init( material,texture,rect,Null )
	End
	
	#rem monkeydoc @hidden
	#end
	Property Material:Material()
	
		Return _material
	End
	
	#rem monkeydoc @hidden
	#end
	Property Texture:Texture()
	
		Return _texture
	End
	
	#rem monkeydoc @hidden The image's rect within its texture.
	#end
	Property Rect:Recti()
	
		Return _rect
	End
	
	#rem monkeydoc The width of the image's rect within its texture.
	#end
	Property Width:Int()
	
		Return _rect.Width
	End
	
	#rem monkeydoc The height of the image's rect within its texture.
	#end
	Property Height:Int()
	
		Return _rect.Height
	End

	#rem monkeydoc The image handle.
	
	Image handle values are fractional, where 0,0 is the top-left of the image and 1,1 is the bottom-right.

	#end
	Property Handle:Vec2f()
	
		Return _handle
		
	Setter( handle:Vec2f )
	
		_handle=handle
		
		UpdateVertices()
	End

	#rem monkeydoc The image scale.
	
	The scale property provides a simple way to 'pre-scale' an image.
	
	Scaling an image this way is faster than using one of the 'scale' parameters of [[Canvas.DrawImage]].
	
	#end
	Property Scale:Vec2f()
	
		Return _scale
	
	Setter( scale:Vec2f )
	
		_scale=scale
		
		UpdateVertices()
	End
	
	#rem monkeydoc The image bounds.
	
	The bounds rect represents the actual image vertices used when the image is drawn.
	
	Image bounds are affected by [[Scale]] and [[Handle]], and can be used for simple collision detection.
	
	#end
	Property Bounds:Rectf()
	
		Return _vertices
	End

	#rem monkeydoc Image radius.
	
	The radius property returns the radius of the [[Bounds]] rect.
	
	Image bounds are affected by [[Scale]] and [[Handle]], and can be used for simple collision detection.
	
	#end
	Property Radius:Float()
	
		Return _radius
	End
	
	#rem monkeydoc @hidden
	#end
	Property Vertices:Rectf()
	
		Return _vertices
	End
	
	#rem monkeydoc @hidden
	#end
	Property TexCoords:Rectf()
	
		Return _texCoords
	End
	
	#rem monkeydoc Releases the image and any resource it uses.
	#end
	Method Discard()
		If _discarded Return
		_discarded=True
		OnDiscarded()
	End
	
	#rem monkeydoc Loads an image from a file.
	#end
	Function Load:Image( path:String,textureFlags:TextureFlags=TextureFlags.Filter|TextureFlags.Mipmap,shader:Shader=Null )
	
		Local diffuse:=mojo.graphics.Texture.Load( path,textureFlags )
		If Not diffuse Return Null
		
		Local file:=StripExt( path )
		Local ext:=ExtractExt( path )
		
		Local specular:=mojo.graphics.Texture.Load( file+"_SPECULAR"+ext,textureFlags )
		Local normal:=mojo.graphics.Texture.Load( file+"_NORMALS"+ext,textureFlags )
		
		If specular Or normal
			If Not specular specular=mojo.graphics.Texture.ColorTexture( Color.Black )
			If Not normal normal=mojo.graphics.Texture.ColorTexture( New Color( .5,.5,.5 ) )
		Endif
		
		If Not shader
			If specular Or normal
				shader=Shader.GetShader( "phong" )
			Else
				shader=Shader.GetShader( "sprite" )
			Endif
		Endif
		
		Local material:=New Material( shader )
		
		If diffuse material.SetTexture( "DiffuseTexture",diffuse )
		If specular material.SetTexture( "SpecularTexture",specular )
		If normal material.SetTexture( "NormalTexture",normal )
		
		Local image:=New Image( material,diffuse,diffuse.Rect )
		
		image.OnDiscarded+=Lambda()
			If diffuse diffuse.Discard()
			If specular specular.Discard()
			If normal normal.Discard()
		End
		
		Return image
	End
	
	Private
	
	Field _material:Material
	Field _texture:Texture
	Field _rect:Recti
	Field _discarded:Bool
	Field _handle:=New Vec2f( 0,0 )
	Field _scale:=New Vec2f( 1,1 )
	Field _vertices:Rectf
	Field _texCoords:Rectf
	Field _radius:Float
	
	Method Init( material:Material,texture:Texture,rect:Recti,shader:Shader )
		
		If Not material
			If Not shader shader=Shader.GetShader( "sprite" )
			material=New Material( shader )
			material.SetTexture( "DiffuseTexture",texture )
		Endif
		
		_material=material
		_texture=texture
		_rect=rect
		
		UpdateVertices()
		UpdateTexCoords()
	End
	
	Method UpdateVertices()
		_vertices.min.x=Float(_rect.Width)*(0-_handle.x)*_scale.x
		_vertices.min.y=Float(_rect.Height)*(0-_handle.y)*_scale.y
		_vertices.max.x=Float(_rect.Width)*(1-_handle.x)*_scale.x
		_vertices.max.y=Float(_rect.Height)*(1-_handle.y)*_scale.y
		_radius=_vertices.min.x*_vertices.min.x+_vertices.min.y*_vertices.min.y
		_radius=Max( _radius,_vertices.max.x*_vertices.max.x+_vertices.min.y*_vertices.min.y )
		_radius=Max( _radius,_vertices.max.x*_vertices.max.x+_vertices.max.y*_vertices.max.y )
		_radius=Max( _radius,_vertices.min.x*_vertices.min.x+_vertices.max.y*_vertices.max.y )
		_radius=Sqrt( _radius )
	End
	
	Method UpdateTexCoords()
		_texCoords.min.x=Float(_rect.min.x)/_texture.Width
		_texCoords.min.y=Float(_rect.min.y)/_texture.Height
		_texCoords.max.x=Float(_rect.max.x)/_texture.Width
		_texCoords.max.y=Float(_rect.max.y)/_texture.Height
	End
	
End
