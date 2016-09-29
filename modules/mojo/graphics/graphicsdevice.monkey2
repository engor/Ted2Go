
Namespace mojo.graphics

#rem monkeydoc Blend modes.

Blend modes are used with the [[Canvas.BlendMode]] property.

| BlendMode	| Description
|:----------|:-----------
| Opaque	| Blending disabled.
| Alpha		| Alpha blending.
| Multiply	| Multiply blending.
| Additive	| Additive blending.

#end
Enum BlendMode
	None=0
	Opaque
	Alpha
	Additive
	Multiply
End

#rem monkeydoc @hidden Color mask values.

Color masks are used with the [[Canvas.ColorMask]] property.

| ColorMask	| Descripten
|:----------|:----------
| Red		| Red color mask.
| Green		| Green color mask.
| Blue		| Blue color mask.
| Alpha		| Alpha color mask.
#end
Enum ColorMask
	None=0
	Red=1
	Green=2
	Blue=4
	Alpha=8
	All=15
End

#rem monkeydoc @hidden
#end
Class GraphicsDevice

	Method New()
		Init()
	End

	Method New( width:Int,height:Int )
		Init()
		
		_deviceSize=New Vec2i( width,height )
		
		_rtargetSize=_deviceSize
	End
	
	Method Resize( size:Vec2i )
	
		_deviceSize=size
	
		If Not _rtarget _rtargetSize=size
	End
	
	Property RenderTargetSize:Vec2i()
	
		Return _rtargetSize
	End
	
	'***** PUBLIC *****
	
	Property RenderTarget:Texture()

		Return _rtarget
	
	Setter( renderTarget:Texture )

		FlushTarget()
	
		_rtarget=renderTarget
		
		_rtargetSize=_rtarget ? _rtarget.Rect.Size Else _deviceSize
		
		_dirty|=Dirty.RenderTarget|Dirty.Viewport|Dirty.Scissor
	End
	
	Property Viewport:Recti()
	
		Return _viewport
	
	Setter( viewport:Recti )
	
		FlushTarget()
	
		_viewport=viewport
		
		_dirty|=Dirty.Viewport|Dirty.Scissor
	End
	
	Property Scissor:Recti()
	
		Return _scissor
	
	Setter( scissor:Recti )
	
		FlushTarget()
	
		_scissor=scissor
		
		_dirty|=Dirty.Scissor
	End
	
	Property ColorMask:ColorMask()
	
		Return _colorMask
		
	Setter( colorMask:ColorMask )
	
		_colorMask=colorMask
		
		_dirty|=Dirty.ColorMask
	End
	
	Property BlendMode:BlendMode()
	
		Return _blendMode
	
	Setter( blendMode:BlendMode )
	
		_blendMode=blendMode
		
		_dirty2|=Dirty.BlendMode
	End
	
	Property TextureFilter:TextureFilter()
	
		return _textureFilter
	
	Setter( filter:TextureFilter )
	
		_textureFilter=filter
		
		_dirty2|=Dirty.TextureFilter
	End
	
	Property VertexBuffer:VertexBuffer()
	
		Return _vertexBuffer
		
	Setter( vbuffer:VertexBuffer )
	
		_vertexBuffer=vbuffer
		
		_dirty2|=Dirty.VertexBuffer
	End
	
	Property IndexBuffer:IndexBuffer()
	
		Return _indexBuffer
		
	Setter( ibuffer:IndexBuffer )
	
		_indexBuffer=ibuffer
		
		_dirty2|=Dirty.IndexBuffer
	End
	
	Property RenderPass:Int()
	
		Return _rpass
		
	Setter( rpass:Int )
	
		_rpass=rpass
		
		_dirty2|=Dirty.Shader
	End
	
	Property Shader:Shader()
	
		Return _shader

	Setter( shader:Shader )
	
		_shader=shader
		
		_dirty2|=Dirty.Shader
	End
	
	Method SetUniformBlock( id:Int,ublock:UniformBlock )
	
		_ublocks[id]=ublock
	End
	
	Method GetUniformBlock:UniformBlock( id:Int )
	
		Return _ublocks[id]
	End
	
	Method CopyPixmap:Pixmap( rect:Recti )
	
		Validate()

		Local pixmap:=New Pixmap( rect.Width,rect.Height,PixelFormat.RGBA32 )
		
		glReadPixels( rect.X,rect.Y,rect.Width,rect.Height,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.Data )
		
		If Not _rtarget pixmap.FlipY()
		
		Return pixmap
	End

	Method Clear( color:Color )
	
		Validate()
		
		glClearColor( color.r,color.g,color.b,color.a )
		
		If Not _scissorTest glEnable( GL_SCISSOR_TEST )
		
		glClear( GL_COLOR_BUFFER_BIT )
		
		If Not _scissorTest glDisable( GL_SCISSOR_TEST )
		
		_modified=true
	End
	
	Method Render( order:Int,count:Int,offset:Int=0 )
	
		Validate2()
	
		Local n:=order*count
	
		Select order
		Case 1 glDrawArrays( GL_POINTS,offset,n )
		Case 2 glDrawArrays( GL_LINES,offset,n )
		Case 3 glDrawArrays( GL_TRIANGLES,offset,n )
		Default
			For Local i:=0 Until count
				glDrawArrays( GL_TRIANGLE_FAN,offset+i*order,order )
			Next
		End
		
		_modified=true
	End
	
	Method RenderIndexed( order:Int,count:Int,offset:Int=0 )
	
		Validate2()

		Local n:=order*count

		Local p:=Cast<UShort Ptr>( offset*2 )
		
		Select order
		Case 1 glDrawElements( GL_POINTS,n,GL_UNSIGNED_SHORT,p )
		Case 2 glDrawElements( GL_LINES,n,GL_UNSIGNED_SHORT,p )
		Case 3 glDrawElements( GL_TRIANGLES,n,GL_UNSIGNED_SHORT,p )
		Default
			For Local i:=0 Until count
				glDrawElements( GL_TRIANGLE_FAN,order,GL_UNSIGNED_SHORT,p+i*order )
			Next
		End
		
		_modified=true
	End
	
	Private
	
	Enum Dirty
		'
		RenderTarget=		$0001
		Viewport=			$0002
		Scissor=			$0004
		ColorMask=			$0008
		'
		BlendMode=			$0010
		VertexBuffer=		$0020
		IndexBuffer=		$0040
		Shader=				$0080
		TextureFilter=		$0100
		All=				$01ff
		'
	End
	
	Field _dirty:Dirty
	Field _dirty2:Dirty
	Field _modified:Bool
	
	Field _rtarget:Texture
	Field _rtargetSize:Vec2i
	Field _deviceSize:Vec2i
	Field _viewport:Recti
	Field _scissor:Recti
	Field _scissorTest:Bool
	Field _colorMask:ColorMask
	Field _blendMode:BlendMode
	Field _textureFilter:TextureFilter
	Field _vertexBuffer:VertexBuffer
	Field _indexBuffer:IndexBuffer
	Field _ublocks:=New UniformBlock[4]
	Field _shader:Shader
	Field _rpass:Int
	
	Global _seq:Int
	Global _current:GraphicsDevice
	Global _defaultFbo:GLint
	
	Method Init()
		_colorMask=ColorMask.All
	End
	
	Function InitGLState()
		glDisable( GL_CULL_FACE )
		glDisable( GL_DEPTH_TEST )
		glGetIntegerv( GL_FRAMEBUFFER_BINDING,Varptr _defaultFbo )
	End
	
	Method FlushTarget()
		If Not _modified Return
		_modified=False
		If _rtarget
			Validate()
			_rtarget.Modified( _viewport & _scissor )
		Endif
	End
	
	Method Validate()

		If _seq<>glGraphicsSeq
			_seq=glGraphicsSeq
			_current=Null
			InitGLState()
		Endif
		
		If _current=Self 
			If Not _dirty Return
		Else
			If _current _current.FlushTarget()
			_current=Self
			_dirty=Dirty.All
		Endif
		
		If _dirty & Dirty.RenderTarget
		
			If _rtarget
				glBindFramebuffer( GL_FRAMEBUFFER,_rtarget.GLFramebuffer )
			Else
				glBindFramebuffer( GL_FRAMEBUFFER,_defaultFbo )
			Endif

		Endif
	
		If _dirty & Dirty.Viewport
		
			If _rtarget
				glViewport( _viewport.X,_viewport.Y,_viewport.Width,_viewport.Height )
			Else
				glViewport( _viewport.X,_rtargetSize.y-_viewport.Bottom,_viewport.Width,_viewport.Height )
			Endif
			
		Endif
		
		If _dirty & Dirty.Scissor
		
			Local scissor:=_scissor & _viewport
			
			_scissorTest=scissor<>_viewport
			If _scissorTest glEnable( GL_SCISSOR_TEST ) Else glDisable( GL_SCISSOR_TEST )
			
			If _rtarget
				glScissor( scissor.X,scissor.Y,scissor.Width,scissor.Height )
			Else
				glScissor( scissor.X,_rtargetSize.y-scissor.Bottom,scissor.Width,scissor.Height )
			Endif
		
		Endif
		
		If _dirty & Dirty.ColorMask
			
			Local r:=Bool( _colorMask & ColorMask.Red )
			Local g:=Bool( _colorMask & ColorMask.Green )
			Local b:=Bool( _colorMask & ColorMask.Blue )
			Local a:=Bool( _colorMask & ColorMask.Alpha )
			
			glColorMask( r,g,b,a )
		
		Endif
		
		_dirty=Null
	End
	
	Method Validate2()
	
		Validate()
		
		If _dirty2 & Dirty.BlendMode

			Select _blendMode
			Case BlendMode.Opaque
				glDisable( GL_BLEND )
			Case BlendMode.Alpha
				glEnable( GL_BLEND )
				glBlendFunc( GL_ONE,GL_ONE_MINUS_SRC_ALPHA )
			Case BlendMode.Additive
				glEnable( GL_BLEND )
				glBlendFunc( GL_ONE,GL_ONE )
			Case BlendMode.Multiply
				glEnable( GL_BLEND )
				glBlendFunc( GL_DST_COLOR,GL_ONE_MINUS_SRC_ALPHA )
			Default
				glDisable( GL_BLEND )
			End

		Endif
		
		If _dirty2 & Dirty.VertexBuffer
		
			 _vertexBuffer.Bind()
			
		Endif

		If _dirty2 & Dirty.IndexBuffer
		
			If _indexBuffer _indexBuffer.Bind()
			
		Endif
		
		If _dirty2 & Dirty.Shader
		
			_shader.Bind( _rpass )

		Endif
		
		_vertexBuffer.Validate()
		
		If _indexBuffer _indexBuffer.Validate()

		_shader.ValidateUniforms( _rpass,_ublocks,_textureFilter )
		
		_dirty2=Null
	End
	
End
