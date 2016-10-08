
Namespace mojo.graphics

Using std.resource

#rem monkeydoc Texture flags.

| TextureFlags	| Description
|:--------------|:-----------
| Dynamic		| Texture is frequently updated. This flag should be set if the texture contents are regularly updated and don't need to be preserved.

#end
Enum TextureFlags

	WrapS=			$0001			'wrap works, but hidden for now...
	WrapT=			$0002
	Unmanaged=		$0004
	DisableMipmap=	$0008
	RenderTarget=	$0010
	
	WrapST=			WrapS|WrapT
	Dynamic=		Unmanaged|RenderTarget|DisableMipmap
	
End

#rem monkeydoc Texture filters.

| TextureFlags	| Description
|:--------------|:-----------
| Nearest		| Textures are not filtered.
| Linear		| Textures are filtered when magnified.
| Mipmap		| Textures are filtered when magnified and minified.

#end
Enum TextureFilter

	None=0
	Nearest=1
	Linear
	Mipmap
	
End

#rem monkeydoc @hidden
#end
Class Texture Extends Resource

	Method New( pixmap:Pixmap,flags:TextureFlags )
	
#If Not __DESKTOP_TARGET__
		Local tw:=Log2( pixmap.Width ),th:=Log2( pixmap.Height )
		If tw<>Round( tw ) Or th<>Round( th ) flags|=TextureFlags.DisableMipmap
#Endif
		_rect=New Recti( 0,0,pixmap.Width,pixmap.Height )
		_format=pixmap.Format
		_flags=flags
		_filter=Null

		If _flags & TextureFlags.Unmanaged
			PastePixmap( pixmap,0,0 )
		Else
			AddDependancy( pixmap )
			_managed=pixmap
		Endif
		
	End
	
	Method New( width:Int,height:Int,format:PixelFormat,flags:TextureFlags )
	
#If Not __DESKTOP_TARGET__
		Local tw:=Log2( width ),th:=Log2( height )
		If tw<>Round( tw ) Or th<>Round( th ) flags|=TextureFlags.DisableMipmap
#Endif
		_rect=New Recti( 0,0,width,height )
		_format=format
		_flags=flags
		_filter=Null
		
		If Not (_flags & TextureFlags.Unmanaged)
			_managed=New Pixmap( width,height,format )
			_managed.Clear( Color.Magenta )
			AddDependancy( _managed )
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
	
	Method PastePixmap( pixmap:Pixmap,x:Int,y:Int )
	
		If _managed

			_managed.Paste( pixmap,x,y )
			
			_dirty|=Dirty.TexImage|Dirty.Mipmaps
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
			
			_dirty|=Dirty.Mipmaps
			
		Endif
	
	End

	Function Load:Texture( path:String,flags:TextureFlags )

		Local pixmap:=Pixmap.Load( path,,True )
		If Not pixmap Return Null
		
		Local texture:=New Texture( pixmap,flags )
		
		texture.OnDiscarded+=Lambda()
			pixmap.Discard()
		End
		
		Return texture
	End
	
	Function LoadNormal:Texture( path:String,textureFlags:TextureFlags,specular:String,specularScale:Float=1,flipNormalY:Bool=True )

		path=RealPath( path )
		specular=specular ? RealPath( specular ) Else ""

		Local pnorm:=Pixmap.Load( path,,True )
		If Not pnorm Return Null
		
		Local pspec:=Pixmap.Load( specular )
		
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
		Else
			Local g:=Clamp( Int( specularScale * 255.0 ),1,255 )
			For Local y:=0 Until pnorm.Height
				For Local x:=0 Until pnorm.Width
					Local n:=pnorm.GetPixelARGB( x,y ) ~ yxor
					n=n & $ffffff00 | g
					pnorm.SetPixelARGB( x,y,n )
				Next
			Next
		Endif
			
		If pspec pspec.Discard()
			
		Local texture:=New Texture( pnorm,Null )
		Return texture
		
	End
	
	Function ColorTexture:Texture( color:Color )
		Local texture:=_colorTextures[color]
		If Not texture
			Local pixmap:=New Pixmap( 1,1 )
			pixmap.Clear( color )
			texture=New Texture( pixmap,Null )
			_colorTextures[color]=texture
		Endif
		Return texture
	End

	#rem monkeydoc @hidden
	#end	
	Property GLTexture:GLuint()
	
		If _texSeq=glGraphicsSeq And Not _dirty Return _glTexture
		
		If _discarded Return 0
		
		If _texSeq=glGraphicsSeq
		
			glPushTexture2d( _glTexture )
		
		Else

			_texSeq=glGraphicsSeq
			_dirty=Dirty.All
		
			glGenTextures( 1,Varptr _glTexture )

			glPushTexture2d( _glTexture )
			
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
			
		Endif
		
		If _dirty & Dirty.Filter

			'mag filter		
			If _filter=TextureFilter.Mipmap Or _filter=TextureFilter.Linear
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR )
			Else
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST )
			Endif

			'min filter			
			If _filter=TextureFilter.Mipmap
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR )
			Else If _filter=TextureFilter.Linear
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR )
			Else
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST )
			Endif
		
		Endif
		
		If _dirty & Dirty.TexImage
		
			glTexImage2D( GL_TEXTURE_2D,0,glFormat( _format ),Width,Height,0,glFormat( _format ),GL_UNSIGNED_BYTE,Null )
			
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
				
			Else
				Local tmp:=New Pixmap( Width,1,Format )
				tmp.Clear( Color.Red )
				
				For Local iy:=0 Until Height
					glTexSubImage2D( GL_TEXTURE_2D,0,0,iy,Width,1,glFormat( _format ),GL_UNSIGNED_BYTE,tmp.Data )
				Next
				
				glFlush()	'macos nvidia bug!
				
				tmp.Discard()
			Endif

		Endif
		
		If _dirty & Dirty.Mipmaps
			If _filter=TextureFilter.Mipmap
				glGenerateMipmap( GL_TEXTURE_2D )
				_mipsDirty&=~Dirty.Mipmaps
			Else
				_mipsDirty|=Dirty.Mipmaps	'mipmap still dirty!
			Endif
		End
		
		_dirty=Null
		
		glPopTexture2d()
		
		Return _glTexture
	End
	
	#rem monkeydoc @hidden
	#end	
	Property GLFramebuffer:GLuint()
		If _discarded Return 0
	
		If _fbSeq=glGraphicsSeq Return _glFramebuffer
		
		glGenFramebuffers( 1,Varptr _glFramebuffer )
			
		glPushFramebuffer( _glFramebuffer )
			
		glBindFramebuffer( GL_FRAMEBUFFER,_glFramebuffer )
		glFramebufferTexture2D( GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,GLTexture,0 )
			
		If glCheckFramebufferStatus( GL_FRAMEBUFFER )<>GL_FRAMEBUFFER_COMPLETE RuntimeError( "Incomplete framebuffer" )
			
		glPopFramebuffer()
		
		_fbSeq=glGraphicsSeq

		Return _glFramebuffer
	End

	#rem monkeydoc @hidden
	#end	
	Method Bind( unit:Int,filter:TextureFilter )
	
		If _discarded Print "Binding discarded texture!"
	
		If _boundSeq<>glGraphicsSeq
			_boundSeq=glGraphicsSeq
			For Local i:=0 Until 8
				_bound[i]=0
			Next
		Endif
		
		If filter<>_filter
			If filter=TextureFilter.Mipmap And (_flags & TextureFlags.DisableMipmap) filter=TextureFilter.Linear
			If filter<>_filter
				If filter=TextureFilter.Mipmap _dirty|=_mipsDirty
				_dirty|=Dirty.Filter
				_filter=filter
			Endif
		Endif
		
		Local gltex:=GLTexture
		If gltex=_bound[unit] Return
		
		_bound[unit]=gltex
		
		glActiveTexture( GL_TEXTURE0+unit )
		glBindTexture( GL_TEXTURE_2D,gltex )
	End
	
	#rem monkeydoc @hidden
	#end
	Method Modified( r:Recti )
	
		If _managed
			glPixelStorei( GL_PACK_ALIGNMENT,1 )
			glReadPixels( r.X,r.Y,r.Width,r.Height,GL_RGBA,GL_UNSIGNED_BYTE,_managed.PixelPtr( r.X,r.Y ) )
		Endif
		
		_dirty|=Dirty.Mipmaps
	End
	
	Protected

	#rem monkeydoc @hidden
	#end	
	Method OnDiscard() Override
	
		If _texSeq=glGraphicsSeq
			For Local i:=0 Until 8
				If _bound[i]=_glTexture _bound[i]=0
			Next
			glDeleteTextures( 1,Varptr _glTexture )
		Endif
		
		If _fbSeq=glGraphicsSeq
			glDeleteFramebuffers( 1,Varptr _glFramebuffer )
		Endif
		
		_texSeq=0
		_fbSeq=0
		_glTexture=0
		_glFramebuffer=0
		_discarded=True
	End
	
	Private
	
	Enum Dirty
		Filter=		1
		TexImage=	2
		Mipmaps=	4
		All=		7
	End
	
	Global _boundSeq:Int
	Global _bound:=New GLuint[8]
	
	Field _rect:Recti
	Field _format:PixelFormat
	Field _flags:TextureFlags
	Field _managed:Pixmap
	Field _discarded:Bool
	
	Field _texSeq:Int
	Field _dirty:Dirty
	Field _mipsDirty:Dirty
	Field _filter:TextureFilter
	Field _glTexture:GLuint
	
	Field _fbSeq:Int
	Field _glFramebuffer:GLuint
	
	Global _colorTextures:Map<Color,Texture>
	
End

Class ResourceManager Extension

	Method OpenTexture:Texture( path:String,flags:TextureFlags=Null )

		Local slug:="Texture:name="+StripDir( StripExt( path ) )+"&flags="+Int( flags )
		
		Local texture:=Cast<Texture>( OpenResource( slug ) )
		If texture Return texture
		
		Local pixmap:=OpenPixmap( path,Null,True )
		If pixmap texture=New Texture( pixmap,flags )
				
		AddResource( slug,texture )
		Return texture
	End

End
