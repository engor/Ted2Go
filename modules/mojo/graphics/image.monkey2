
Namespace mojo.graphics

#rem monkeydoc The Image class.
#end
Class Image

	#rem monkeydoc @hidden
	#end
	Field OnDiscarded:Void()

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
	
	Property Rect:Recti()
	
		Return _rect
	End
	
	Property Width:Int()
	
		Return _rect.Width
	End
	
	Property Height:Int()
	
		Return _rect.Height
	End

	Property Handle:Vec2f()
	
		Return _handle
		
	Setter( handle:Vec2f )
	
		_handle=handle
		
		UpdateVertices()
	End
	
	Property Scale:Vec2f()
	
		Return _scale
	
	Setter( scale:Vec2f )
	
		_scale=scale
		
		UpdateVertices()
	End
	
	Property Bounds:Rectf()
	
		Return _vertices
	End

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
	
	#rem monkeydoc Release the image and any resource it uses.
	#end
	Method Discard()
		If _discarded Return
		_discarded=True
		OnDiscarded()
	End
	
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
