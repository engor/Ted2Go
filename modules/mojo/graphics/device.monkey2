
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
	Opaque=0
	Alpha=1
	Additive=2
	Multiply=3
End

#rem monkeydoc @hidden
#end
Class GraphicsDevice

	Method New()
		RenderTarget=Null
		Viewport=New Recti( 0,0,640,480 )
		Scissor=New Recti( 0,0,16384,16384 )
		BlendMode=BlendMode.Alpha
	End
	
	Property RenderTarget:Texture()
	
		Return _target
	
	Setter( renderTarget:Texture )
	
		FlushTarget()
		
		_target=renderTarget
		
		_dirty|=Dirty.Target
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
	
	Property BlendMode:BlendMode()
	
		Return _blendMode
	
	Setter( blendMode:BlendMode )
	
		_blendMode=blendMode
		
		_dirty|=Dirty.BlendMode
	End
	
	Property ShaderEnv:ShaderEnv()
	
		Return _shaderEnv
	
	Setter( shaderEnv:ShaderEnv )
	
		_shaderEnv=shaderEnv
		
		_dirty|=Dirty.Shader|Dirty.EnvParams|Dirty.Params
	End
	
	Property EnvParams:ParamBuffer()
	
		Return _envParams
	
	Setter( envParams:ParamBuffer )
	
		_envParams=envParams
		
		_dirty|=Dirty.EnvParams
	End
	
	Property Shader:Shader()
	
		Return _shader
	
	Setter( shader:Shader )
	
		_shader=shader
		
		_dirty|=Dirty.Shader|Dirty.EnvParams|Dirty.Params
	End
	
	Property Params:ParamBuffer()
	
		Return _params
	
	Setter( params:ParamBuffer )
	
		_params=params
		
		_dirty|=Dirty.Params
	End
	
	Property FilteringEnabled:Bool()
	
		Return _filter
	
	Setter( filteringEnabled:Bool )
	
		If filteringEnabled=_filter Return
		
		_filter=filteringEnabled

		_dirty|=Dirty.Params
	End
	
	Method Clear( color:Color )
	
		Validate()
		
		If _rscissor<>_windowRect
			glEnable( GL_SCISSOR_TEST )
			glScissor( _rscissor.X,_rscissor.Y,_rscissor.Width,_rscissor.Height )
		Else
			glDisable( GL_SCISSOR_TEST )
		Endif
		
		glClearColor( color.r,color.g,color.b,color.a )

		glClear( GL_COLOR_BUFFER_BIT )
		
		If _rscissor<>_viewport
			glEnable( GL_SCISSOR_TEST )
			glScissor( _rscissor.X,_rscissor.Y,_rscissor.Width,_rscissor.Height )
		Else
			glDisable( GL_SCISSOR_TEST )
		Endif
		
		_modified=True
	End
	
	Method Render( vertices:Vertex2f Ptr,order:Int,count:Int )
	
		Validate()
		
		Local n:=order*count
		
		If n>_vertices.Length 
			_vertices=New Vertex2f[n]
			Local p:=Cast<UByte Ptr>( _vertices.Data )
			glEnableVertexAttribArray( 0 ) ; glVertexAttribPointer( 0,2,GL_FLOAT,False,BYTES_PER_VERTEX,p )
			glEnableVertexAttribArray( 1 ) ; glVertexAttribPointer( 1,2,GL_FLOAT,False,BYTES_PER_VERTEX,p+8 )
			glEnableVertexAttribArray( 2 ) ; glVertexAttribPointer( 2,2,GL_FLOAT,False,BYTES_PER_VERTEX,p+16 )
			glEnableVertexAttribArray( 3 ) ; glVertexAttribPointer( 3,4,GL_UNSIGNED_BYTE,True,BYTES_PER_VERTEX,p+24 )
		Endif

		libc.memcpy( _vertices.Data,vertices,n*BYTES_PER_VERTEX )
		
		Select order
		Case 1
			glDrawArrays( GL_POINTS,0,n )
		Case 2
			glDrawArrays( GL_LINES,0,n )
		Case 3
			glDrawArrays( GL_TRIANGLES,0,n )
		Case 4
			Local n:=count*6
			If n>_qindices.Length
				_qindices=New UShort[n]
				For Local i:=0 Until count
					_qindices[i*6+0]=i*4
					_qindices[i*6+1]=i*4+1
					_qindices[i*6+2]=i*4+2
					_qindices[i*6+3]=i*4
					_qindices[i*6+4]=i*4+2
					_qindices[i*6+5]=i*4+3
				Next
			Endif
			glDrawElements( GL_TRIANGLES,n,GL_UNSIGNED_SHORT,_qindices.Data )
		Default
			For Local i:=0 Until count
				glDrawArrays( GL_TRIANGLE_FAN,i*order,order )
			Next
		End
		
		_modified=True
	End
	
	Method CopyPixmap:Pixmap( rect:Recti )
	
		Validate()

		Local pixmap:=New Pixmap( rect.Width,rect.Height,PixelFormat.RGBA32 )
		
		glReadPixels( rect.X,rect.Y,rect.Width,rect.Height,GL_RGBA,GL_UNSIGNED_BYTE,pixmap.Data )
		
		Return pixmap
	End

	Private
	
	Enum Dirty
		Target=			$0001
		Viewport=		$0002
		Scissor=		$0004
		BlendMode=		$0008
		Shader=			$0010
		EnvParams=		$0020
		Params=			$0040
		All=			$007f
	End
	
	Field _dirty:Dirty=Dirty.All
	Field _modified:Bool
	Field _target:Texture
	Field _windowRect:Recti
	Field _viewport:Recti
	Field _scissor:Recti
	Field _blendMode:BlendMode
	Field _shaderEnv:ShaderEnv
	Field _envParams:ParamBuffer
	Field _shader:Shader
	Field _params:ParamBuffer
	Field _filter:Bool=True
	
	Field _rscissor:Recti

	Global _seq:Int
	Global _current:GraphicsDevice
	Global _defaultFbo:GLint
	
	Global _vertices:Vertex2f[]
	Global _qindices:UShort[]
	
	Const BYTES_PER_VERTEX:=28
	
	Function InitGLState()
		glDisable( GL_CULL_FACE )
		glDisable( GL_DEPTH_TEST )
		glGetIntegerv( GL_FRAMEBUFFER_BINDING,Varptr _defaultFbo )
	End
	
	Method FlushTarget()
		If Not _modified Return
		If _target _target.Modified( Self )
		_modified=False
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
		
		If _dirty & Dirty.Target
			If _target
				glBindFramebuffer( GL_FRAMEBUFFER,_target.GLFramebuffer )
			Else
				glBindFramebuffer( GL_FRAMEBUFFER,_defaultFbo )
			Endif
		Endif
		
		If _dirty & Dirty.Viewport
			glViewport( _viewport.X,_viewport.Y,_viewport.Width,_viewport.Height )
		Endif
		
		If _dirty & Dirty.Scissor
			_rscissor=_scissor & _viewport
			If _rscissor<>_viewport
				glEnable( GL_SCISSOR_TEST )
				glScissor( _rscissor.X,_rscissor.Y,_rscissor.Width,_rscissor.Height )
			Else
				glDisable( GL_SCISSOR_TEST )
			Endif
		Endif

		If _dirty & Dirty.BlendMode		
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
			End
		Endif
		
		If _shader And _shaderEnv And _envParams And _params
		
			If _dirty & Dirty.Shader
				_shader.Bind( _shaderEnv )
			Endif
			
			If _dirty & Dirty.EnvParams
				_shader.BindEnvParams( _envParams )
			Endif
			
			If _dirty & Dirty.Params
				_shader.BindParams( _params,_filter )
			End
			
		Endif
		
		_dirty=Null
		
	End

End
