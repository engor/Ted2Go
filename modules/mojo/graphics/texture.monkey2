
Namespace mojo.graphics

#rem monkeydoc Texture flags.

| TextureFlags	| Description
|:--------------|:-----------
| Filter		| Filter texture.
| Mipmap		| Mipmap texture.
| WrapS			| Wrap texture S coordinate.
| WrapT			| Wrap texture T coordinate.
| WrapST		| Wrap texture coordinates.
| Managed		| Managed by mojo.
| RenderTarget	| Texture can be used as a render target.
| DefaultFlags	| Use default flags.

#end
Enum TextureFlags

	Filter=			$0001
	Mipmap=			$0002
	WrapS=			$0004
	WrapT=			$0008
	Managed=		$0010
	RenderTarget=	$0020
	
	WrapST=			WrapS|WrapT

	DefaultFlags=	$ffff
End

Class Texture

	#rem monkeydoc @hidden
	#end
	Field OnDiscarded:Void()

	Method New( pixmap:Pixmap,flags:TextureFlags=TextureFlags.DefaultFlags )

		If flags=TextureFlags.DefaultFlags 
			flags=TextureFlags.Filter|TextureFlags.Mipmap
		Endif
		
		flags|=TextureFlags.Managed
		
#If __TARGET__<>"desktop"
		If flags & TextureFlags.Mipmap
			Local tw:=Log2( pixmap.Width ),th:=Log2( pixmap.Height )
			If tw<>Round( tw ) Or th<>Round( th ) flags&=~TextureFlags.Mipmap
		Endif
#Endif
		
		_rect=New Recti( 0,0,pixmap.Width,pixmap.Height )
		_format=pixmap.Format
		_flags=flags
		_managed=pixmap
	End
	
	Method New( width:Int,height:Int,format:PixelFormat=PixelFormat.RGBA32,flags:TextureFlags=TextureFlags.DefaultFlags )
	
		If flags=TextureFlags.DefaultFlags 
			flags=TextureFlags.Filter|TextureFlags.RenderTarget
		Endif

		_rect=New Recti( 0,0,width,height )
		_format=format
		_flags=flags
		
		If _flags & TextureFlags.Managed
			_managed=New Pixmap( width,height,format )
			_managed.Clear( Color.Magenta )
			OnDiscarded+=Lambda()
				_managed.Discard()
			End
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
	
	Method Discard()
		If _discarded Return
		If _texSeq=glGraphicsSeq glDeleteTextures( 1,Varptr _glTexture )
		If _fbSeq=glGraphicsSeq glDeleteFramebuffers( 1,Varptr _glFramebuffer )
		_discarded=True
		OnDiscarded()
	End
	
	Method PastePixmap( pixmap:Pixmap,x:Int,y:Int )
	
		If _managed

			_managed.Paste( pixmap,x,y )
			
		Else
		
			glPushTexture2d( GLTexture )
			
			glPixelStorei( GL_UNPACK_ALIGNMENT,1 )
			
			If pixmap.Pitch=pixmap.Width*pixmap.Depth
				glTexSubImage2D( GL_TEXTURE_2D,0,x,y,pixmap.Width,pixmap.Height,glFormat( _format ),GL_UNSIGNED_BYTE,pixmap.Data )
			Else
				For Local iy:=0 Until pixmap.Height
					glTexSubImage2D( GL_TEXTURE_2D,0,x,y+iy,pixmap.Width,1,glFormat( _format ),GL_UNSIGNED_BYTE,pixmap.PixelPtr( 0,iy ) )
				Next
			Endif
			
			glPopTexture2d()
		
		Endif
		
		_texDirty=True
	
	End
	
	Function Load:Texture( path:String,flags:TextureFlags=TextureFlags.DefaultFlags )
	
		Local pixmap:=Pixmap.Load( path )
		If Not pixmap Return Null
		
		pixmap.PremultiplyAlpha()
		
		Local texture:=New Texture( pixmap,flags )
		
		texture.OnDiscarded+=Lambda()
			pixmap.Discard()
		End
		
		Return texture
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
		DebugAssert( Not _discarded,"texture has been discarded" )
	
		If _texSeq=glGraphicsSeq And Not _texDirty Return _glTexture
		
		If _texSeq=glGraphicsSeq
		
			glPushTexture2d( _glTexture )
		
		Else
			_texSeq=glGraphicsSeq
		
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
			
			If _flags & TextureFlags.WrapS
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT )
			Else
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE )
			Endif
			
			If _flags & TextureFlags.WrapT
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT )
			Else
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE )
			Endif
		
			glTexImage2D( GL_TEXTURE_2D,0,glFormat( _format ),Width,Height,0,glFormat( _format ),GL_UNSIGNED_BYTE,Null )
			
		Endif
		
		If _managed
		
			glPixelStorei( GL_UNPACK_ALIGNMENT,1 )
		
			If _managed.Pitch=_managed.Width*_managed.Depth
				glTexSubImage2D( GL_TEXTURE_2D,0,0,0,_managed.Width,_managed.Height,glFormat( _format ),GL_UNSIGNED_BYTE,_managed.Data )
			Else
				For Local iy:=0 Until Height
					glTexSubImage2D( GL_TEXTURE_2D,0,0,iy,Width,1,glFormat( _format ),GL_UNSIGNED_BYTE,_managed.PixelPtr( 0,iy ) )
				Next
			Endif
			
			glFlush()	'macos nvidia bug!
		
			If _flags & TextureFlags.Mipmap glGenerateMipmap( GL_TEXTURE_2D )
			
		Endif
			
		glPopTexture2d()
		
		_texDirty=False
	
		Return _glTexture
	End
	
	#rem monkeydoc @hidden
	#end	
	Property GLFramebuffer:GLuint()
		DebugAssert( Not _discarded,"texture has been discarded" )
	
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
	Field _discarded:Bool
	
	Field _texSeq:Int
	Field _texDirty:Bool
	Field _glTexture:GLuint
	
	Field _fbSeq:Int
	Field _glFramebuffer:GLuint
	
	Global _colorTextures:Map<Color,Texture>
	
End
