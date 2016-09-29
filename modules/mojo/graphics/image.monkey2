
Namespace mojo.graphics

#rem monkeydoc The Image class.

An image is a rectangular array of pixels that can be drawn using one of the [[Canvas.DrawImage]] methods.

You can load an image from a file using one of the [[Load]], [[LoadBump]] or [[LoadLight]] functions.

#end
Class Image

	#rem monkeydoc Invoked after image has ben discarded.
	#end
	Field OnDiscarded:Void()
	
	#rem monkeydoc Creates a new Image.
	
	New( pixmap,... ) Creates an image from an existing pixmap.
	
	New( width,height,... ) Creates an image that can be rendered to using a canvas.
	
	New( image,... ) Creates an image from within an 'atlas' image.
	
	Note: `textureFlags` should be null for static images or TextureFlags.Dynamic for dynamic images.

	@param pixmap Source image.
	
	@param textureFlags Image texture flags. 
	
	@param shader Image shader.
	
	@param image Source pixmap.
	
	@param rect Source rect.
	
	@param x,y,width,height Source rect
	
	@param width,height Image size.
	
	#end	
	Method New( pixmap:Pixmap,textureFlags:TextureFlags=Null,shader:Shader=Null )
	
		Local texture:=New Texture( pixmap,textureFlags )
		
		Init( texture,texture.Rect,shader )
		
		OnDiscarded+=Lambda()
			texture.Discard()
		End
	End

	Method New( width:Int,height:Int,textureFlags:TextureFlags=Null,shader:Shader=Null )
	
		Local texture:=New Texture( width,height,PixelFormat.RGBA32,textureFlags )
		
		Init( texture,texture.Rect,shader )
		
		OnDiscarded+=Lambda()
			texture.Discard()
		End
	End

	Method New( image:Image )
	
		Init( image._textures[0],image._rect,image._shader )
		
		For Local i:=1 Until 4
			SetTexture( i,image.GetTexture( i ) )
		Next
		
		BlendMode=image.BlendMode
		TextureFilter=image.TextureFilter
		LightDepth=image.LightDepth
		Handle=image.Handle
		Scale=image.Scale
		Color=image.Color
	End
	
	Method New( image:Image,rect:Recti )
	
		Init( image._textures[0],rect+image._rect.Origin,image._shader )
		
		For Local i:=1 Until 4
			SetTexture( i,image.GetTexture( i ) )
		Next
		
		BlendMode=image.BlendMode
		TextureFilter=image.TextureFilter
		LightDepth=image.LightDepth
		Handle=image.Handle
		Scale=image.Scale
		Color=image.Color
	End
	
	Method New( image:Image,x:Int,y:Int,width:Int,height:Int )
	
		Self.New( image,New Recti( x,y,x+width,y+height ) )
	End
	
	#rem monkeydoc @hidden
	#end
	Method New( texture:Texture,shader:Shader=Null )

		Init( texture,texture.Rect,shader )
	End
	
	#rem monkeydoc @hidden
	#end
	Method New( texture:Texture,rect:Recti,shader:Shader=Null )
		Init( texture,rect,shader )
	End
	
	#rem monkeydoc The image's primary texture.
	#end	
	Property Texture:Texture()
	
		Return _textures[0]
	
	Setter( texture:Texture )
	
		SetTexture( 0,texture )
	End

	#rem monkeydoc The image's texture rect.
	
	Describes the rect the image occupies within its primary texture.
	
	#end
	Property Rect:Recti()
	
		Return _rect
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
	
	For images with a constant scale, Scaling an image this way is faster than using one of the 'scale' parameters of [[Canvas.DrawImage]].
	
	#end
	Property Scale:Vec2f()
	
		Return _scale
	
	Setter( scale:Vec2f )
	
		_scale=scale
		
		UpdateVertices()
	End

	#rem monkeydoc The image blend mode.
	
	The blend mode used to draw the image.
	
	If set to BlendMode.None, the canvas blend mode is used instead.
	
	Defaults to BlendMode.None.
	
	#end	
	Property BlendMode:BlendMode()
	
		Return _blendMode
		
	Setter( blendMode:BlendMode )
	
		_blendMode=blendMode
	End
	
	#rem monkeydoc The image texture filter.
	
	The texture flags used to draw the image.
	
	If set to TextureFilter.None, the canvas texture filter is used instead.
	
	Defaults to TextureFilter.None
	
	#end	
	Property TextureFilter:TextureFilter()
	
		Return _textureFilter
		
	Setter( filter:TextureFilter )
	
		_textureFilter=filter
	End
	
	#rem monkeydoc The image color.
	
	The color used to draw the image.
	
	Image color is multiplied by canvas color to achieve the final rendering color.
	
	Defaults to white.
	
	#end	
	Property Color:Color()
	
		Return _color
	
	Setter( color:Color )
	
		_color=color
		
		_material.SetVector( "mx2_ImageColor",_color )
	End

	#rem monkeydoc The image light depth.
	#end
	Property LightDepth:Float()
	
		Return _lightDepth
	
	Setter( depth:Float )
	
		_lightDepth=depth
		
		_material.SetScalar( "mx2_LightDepth",_lightDepth )
	End

	#rem monkeydoc Shadow caster attached to image.
	#end	
	Property ShadowCaster:ShadowCaster()
	
		Return _shadowCaster
		
	Setter( shadowCaster:ShadowCaster )
	
		_shadowCaster=shadowCaster
	End

	#rem monkeydoc The image bounds.
	
	The bounds rect represents the actual image vertices used when the image is drawn.
	
	Image bounds are affected by [[Scale]] and [[Handle]], and can be used for simple collision detection.
	
	#end
	Property Bounds:Rectf()
	
		Return _bounds
	End

	#rem monkeydoc Image bounds width.
	#end	
	Property Width:Float()
	
		Return _bounds.Width
	End
	
	#rem monkeydoc Image bounds height.
	#end	
	Property Height:Float()
	
		Return _bounds.Height
	End

	#rem monkeydoc Image bounds radius.
	#end
	Property Radius:Float()
	
		Return _radius
	End

	#rem monkeydoc Image shader.
	#end
	Property Shader:Shader()
	
		Return _shader
	End
	
	#rem monkeydoc Image material.
	#end
	Property Material:UniformBlock()
	
		Return _material
	End

	#rem monkeydoc @hidden Image vertices.
	#end	
	Property Vertices:Rectf()
	
		Return _vertices
	End
	
	#rem monkeydoc @hidden Image texture coorinates.
	#end	
	Property TexCoords:Rectf()
	
		Return _texCoords
	End

	#rem monkeydoc @hidden Sets an image texture.
	#end	
	Method SetTexture( index:Int,texture:Texture )
	
		_textures[index]=texture
		
		_material.SetTexture( "mx2_ImageTexture"+index,texture )
	End
	
	#rem monkeydoc @hidden gets an image texture.
	#end	
	Method GetTexture:Texture( index:Int )
	
		Return _textures[index]
	End
	
	#rem monkeydoc Discards the image.
	
	Discards the image and releases any resources held by the image.
	
	#end
	Method Discard()
		If _discarded Return
		_discarded=True
		OnDiscarded()
	End
	
	#rem monkeydoc Loads an image from file.
	#end
	Function Load:Image( path:String,shader:Shader=Null )
	
		If Not shader shader=mojo.graphics.Shader.GetShader( "sprite" )
	
		Local texture:=mojo.graphics.Texture.Load( path,Null )
		If Not texture Return Null
		
		Return New Image( texture,shader )
	End
	
	#rem monkeydoc Loads a bump image from file(s).
	
	`diffuse`, `normal` and `specular` are filepaths of the diffuse, normal and specular image files respectively.
	
	`specular` can be null, in which case `specularScale` is used for the specular component. Otherwise, `specularScale` is used to modulate the specular components of the 
	specular texture.
	
	#end
	Function LoadBump:Image( diffuse:String,normal:String,specular:String,specularScale:Float=1,flipNormalY:Bool=True,shader:Shader=Null )
	
		If Not shader shader=mojo.graphics.Shader.GetShader( "bump" )

		Local pdiff:=Pixmap.Load( diffuse )
		Local pnorm:=Pixmap.Load( normal )
		Local pspec:=Pixmap.Load( specular )
		
		If pdiff
			pdiff.PremultiplyAlpha()
		Else
			pdiff=New Pixmap( pnorm.Width,pnorm.Height,PixelFormat.I8 )
			pdiff.Clear( std.graphics.Color.White )
		Endif
		
		Local yxor:=flipNormalY ? $ff00 Else 0
		
		If pspec And pspec.Width=pnorm.Width And pspec.Height=pnorm.Height
			For Local y:=0 Until pnorm.Height
				For Local x:=0 Until pnorm.Width
					Local n:=pnorm.GetPixelARGB( x,y ) ~ yxor
					Local s:=(pspec.GetPixelARGB( x,y ) Shr 16) & $ff
					n=n & $ffffff00 | Clamp( Int( specularScale * s ),1,255 )
					pnorm.SetPixelARGB( x,y,n )
				Next
			Next
			pspec.Discard()
		Else
			Local g:=Clamp( Int( specularScale * 255.0 ),1,255 )
			For Local y:=0 Until pnorm.Height
				For Local x:=0 Until pnorm.Width
					Local n:=pnorm.GetPixelARGB( x,y ) ~ yxor
					n=n & $ffffff00 | g
					pnorm.SetPixelARGB( x,y,n )
				Next
			Next
			If pspec pspec.Discard()
		Endif
		
		Local texture0:=New Texture( pdiff,Null )
		Local texture1:=New Texture( pnorm,Null )
		
		Local image:=New Image( texture0,texture0.Rect,shader )
		image.SetTexture( 1,texture1 )
		
		image.OnDiscarded+=Lambda()
			texture0.Discard()
			texture1.Discard()
			pdiff.Discard()
			pnorm.Discard()
		End
	
		Return image
	End
	
	#rem monkeydoc Loads a light image from file.
	#end
	Function LoadLight:Image( path:String,shader:Shader=Null )
	
		Local pixmap:=Pixmap.Load( path )
		If Not pixmap Return Null
		
		If Not shader shader=mojo.graphics.Shader.GetShader( "light" )
	
		Select pixmap.Format
		Case PixelFormat.IA16,PixelFormat.RGBA32
		
			pixmap.PremultiplyAlpha()
			
		Case PixelFormat.A8

			Local tpixmap:=pixmap
			pixmap=pixmap.Convert( PixelFormat.IA16 )
			tpixmap.Discard()

			'Copy A->I
			For Local y:=0 Until pixmap.Height
				Local p:=pixmap.PixelPtr( 0,y )
				For Local x:=0 Until pixmap.Width
					p[0]=p[1]
					p+=2
				Next
			Next

		Case PixelFormat.I8
		
			Local tpixmap:=pixmap
			pixmap=pixmap.Convert( PixelFormat.IA16 )
			tpixmap.Discard()
			
			'Copy I->A
			For Local y:=0 Until pixmap.Height
				Local p:=pixmap.PixelPtr( 0,y )
				For Local x:=0 Until pixmap.Width
					p[1]=p[0]
					p+=2
				Next
			Next

		Case PixelFormat.RGB24
		
			Local tpixmap:=pixmap
			pixmap=pixmap.Convert( PixelFormat.RGBA32 )
			tpixmap.Discard()
			
			'Copy R->A
			For Local y:=0 Until pixmap.Height
				Local p:=pixmap.PixelPtr( 0,y )
				For Local x:=0 Until pixmap.Width
					p[3]=p[0]
					p+=4
				Next
			Next
		
		End
		
		Local texture:=New Texture( pixmap,Null )
		
		Local image:=New Image( texture,shader )
		
		image.OnDiscarded+=Lambda()
			pixmap.Discard()
		End
		
		Return image
	End

	Private
	
	Field _shader:Shader
	Field _material:UniformBlock

	Field _discarded:Bool
	
	Field _textures:=New Texture[4]
	Field _blendMode:BlendMode
	Field _textureFilter:TextureFilter
	Field _color:Color
	Field _lightDepth:Float
	Field _shadowCaster:ShadowCaster
	
	Field _rect:Recti
	Field _handle:Vec2f
	Field _scale:Vec2f
	
	Field _vertices:Rectf
	Field _texCoords:Rectf
	Field _bounds:Rectf
	Field _radius:Float
	
	Method Init( texture:Texture,rect:Recti,shader:Shader )
	
		If Not shader shader=Shader.GetShader( "sprite" )
	
		_rect=rect
		_shader=shader
		_material=New UniformBlock
		
		SetTexture( 0,texture )
		
		BlendMode=BlendMode.None
		TextureFilter=TextureFilter.None
		Color=Color.White
		LightDepth=100
		Handle=New Vec2f( 0 )
		Scale=New Vec2f( 1 )
		
		UpdateVertices()
		UpdateTexCoords()
	End
	
	Method UpdateVertices()
		_vertices.min.x=Float(_rect.Width)*(0-_handle.x)*_scale.x
		_vertices.min.y=Float(_rect.Height)*(0-_handle.y)*_scale.y
		_vertices.max.x=Float(_rect.Width)*(1-_handle.x)*_scale.x
		_vertices.max.y=Float(_rect.Height)*(1-_handle.y)*_scale.y
		_bounds.min.x=Min( _vertices.min.x,_vertices.max.x )
		_bounds.max.x=Max( _vertices.min.x,_vertices.max.x )
		_bounds.min.y=Min( _vertices.min.y,_vertices.max.y )
		_bounds.max.y=Max( _vertices.min.y,_vertices.max.y )
		_radius=_bounds.min.x*_bounds.min.x+_bounds.min.y*_bounds.min.y
		_radius=Max( _radius,_bounds.max.x*_bounds.max.x+_bounds.min.y*_bounds.min.y )
		_radius=Max( _radius,_bounds.max.x*_bounds.max.x+_bounds.max.y*_bounds.max.y )
		_radius=Max( _radius,_bounds.min.x*_bounds.min.x+_bounds.max.y*_bounds.max.y )
		_radius=Sqrt( _radius )
	End
	
	Method UpdateTexCoords()
		_texCoords.min.x=Float(_rect.min.x)/_textures[0].Width
		_texCoords.min.y=Float(_rect.min.y)/_textures[0].Height
		_texCoords.max.x=Float(_rect.max.x)/_textures[0].Width
		_texCoords.max.y=Float(_rect.max.y)/_textures[0].Height
	End
	
End
