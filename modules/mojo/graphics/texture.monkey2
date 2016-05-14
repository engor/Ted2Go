
Namespace mojo.graphics

#rem monkeydoc Texture flags.

| TextureFlags	| Description
|:--------------|:-----------
| Filter		| Filter texture.
| Mipmap		| Mipmap texture.
| ClampS		| Clamp texture S coordinate.
| ClampT		| Clamp texture T coordinate.
| Clamp			| Clamp texture coordinates.
| Managed		| Managed by mojo.
| RenderTarget	| Texture can be used as a render target.
| DefaultFlags	| Use default flags.

#end
Enum TextureFlags

	Filter=			$0001
	Mipmap=			$0002
	ClampS=			$0004
	ClampT=			$0008
	Managed=		$0010
	RenderTarget=	$0020
	ClampST=		ClampS|ClampT

	DefaultFlags=	$ffff
End

Class Texture

	Method New( pixmap:Pixmap,flags:TextureFlags=TextureFlags.DefaultFlags )

		If flags=TextureFlags.DefaultFlags 
			flags=TextureFlags.Filter|TextureFlags.Mipmap|TextureFlags.ClampST|TextureFlags.Managed
		Endif
		
		_rect=New Recti( 0,0,pixmap.Width,pixmap.Height )
		_format=pixmap.Format
		_flags=flags
		
		If _flags & TextureFlags.Managed
			_managed=pixmap
		Endif
	End
	
	Method New( width:Int,height:Int,format:PixelFormat=PixelFormat.RGBA32,flags:TextureFlags=TextureFlags.DefaultFlags )
	
		If flags=TextureFlags.DefaultFlags 
			flags=TextureFlags.Filter|TextureFlags.ClampST|TextureFlags.RenderTarget
		Endif

		_rect=New Recti( 0,0,width,height )
		_format=format
		_flags=flags
		
		If _flags & TextureFlags.Managed
			_managed=New Pixmap( Width,Height,_format )
			_managed.Clear( Color.Magenta )
		Endif
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
	
	Property Format:PixelFormat()
		Return _format
	End
	
	Property Flags:TextureFlags()
		Return _flags
	End
	
	Function Load:Texture( path:String,flags:TextureFlags=TextureFlags.DefaultFlags )
	
		Local pixmap:=Pixmap.Load( path )
		If Not pixmap Return Null
		
		pixmap.PremultiplyAlpha()
		
		Return New Texture( pixmap,flags )
	End

	Function ColorTexture:Texture( color:Color )
		Local texture:=_colorTextures[color]
		If Not texture
			Local pixmap:=New Pixmap( 1,1 )
			pixmap.Clear( color )
			texture=New Texture( pixmap )
			_colorTextures[color]=texture
		Endif
		Return texture
	End

	#rem monkeydoc @hidden
	#end	
	Property GLTexture:GLuint()
	
		If _texSeq=glGraphicsSeq 
			Return _glTexture
		Endif
		
		glGenTextures( 1,Varptr _glTexture )
		
		glPushTexture2d( _glTexture )
		
		If _flags & TextureFlags.Filter
			glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR )
		Else
			glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST )
		Endif
		
		If (_flags & TextureFlags.Mipmap) And (_flags & TextureFlags.Filter)
			glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR )
		Else If _flags & TextureFlags.Mipmap
			glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST_MIPMAP_NEAREST )
		Else If _flags & TextureFlags.Filter
			glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR )
		Else
			glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST )
		Endif

		If _flags & TextureFlags.ClampS glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE )
		If _flags & TextureFlags.ClampT glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE )
		
		If _managed
		
			If True'_managed.Pitch & 4
			
				glTexImage2D( GL_TEXTURE_2D,0,glFormat( _format ),Width,Height,0,glFormat( _format ),GL_UNSIGNED_BYTE,Null )
				
				For Local y:=0 Until Height
					glTexSubImage2D( GL_TEXTURE_2D,0,0,y,Width,1,glFormat( _format ),GL_UNSIGNED_BYTE,_managed.PixelPtr( 0,y ) )
				Next
			Else
				glTexImage2D( GL_TEXTURE_2D,0,glFormat( _format ),Width,Height,0,glFormat( _format ),GL_UNSIGNED_BYTE,_managed.Data )
			Endif
			
			glFlush()	'macos nvidia bug!
		
			If _flags & TextureFlags.Mipmap glGenerateMipmap( GL_TEXTURE_2D )

		Else
		
			glTexImage2D( GL_TEXTURE_2D,0,glFormat( _format ),Width,Height,0,glFormat( _format ),GL_UNSIGNED_BYTE,Null )
		
		Endif
		
		glPopTexture2d()
		
		_texSeq=glGraphicsSeq
		
		Return _glTexture
	End
	
	#rem monkeydoc @hidden
	#end	
	Property GLFramebuffer:GLuint()
	
		If _fbSeq=glGraphicsSeq Return _glFramebuffer
		
		glGenFramebuffers( 1,Varptr _glFramebuffer )
			
		glPushFramebuffer( _glFramebuffer )
			
		glBindFramebuffer( GL_FRAMEBUFFER,_glFramebuffer )
		glFramebufferTexture2D( GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,GLTexture,0 )
			
		If glCheckFramebufferStatus( GL_FRAMEBUFFER )<>GL_FRAMEBUFFER_COMPLETE Assert( False,"Incomplete framebuffer" )
			
		glPopFramebuffer()
		
		_fbSeq=glGraphicsSeq

		Return _glFramebuffer
	End
	
	Private
	
	Field _rect:Recti
	Field _format:PixelFormat
	Field _flags:TextureFlags
	Field _managed:Pixmap
	
	Field _texSeq:Int
	Field _glTexture:GLuint
	Field _fbSeq:Int
	Field _glFramebuffer:GLuint
	
	Global _colorTextures:Map<Color,Texture>
	
End
