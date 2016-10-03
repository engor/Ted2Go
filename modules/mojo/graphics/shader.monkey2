
Namespace mojo.graphics

#Import "shaders/@/shaders"

Private

Class GLUniform

	Field name:String
	Field location:Int
	Field texunit:Int
	Field size:Int
	Field type:Int
	Field uniformId:Int
	Field blockId:Int

	Method New( name:String,location:Int,texunit:Int,size:Int,type:Int )
		Self.name=name
		Self.location=location
		Self.texunit=texunit
		Self.size=size
		Self.type=type
		
		Self.uniformId=UniformBlock.GetUniformId( name )
		Self.blockId=UniformBlock.GetUniformBlockId( name )
	End
	
End

Class GLProgram

	Field _glprogram:GLuint
	Field _uniforms:=New GLUniform[4][]
	Field _textures:=New GLUniform[4][]
	Field _ublockSeqs:=New Int[4]

	Method New( glprogram:GLuint )

		_glprogram=glprogram
		
		Local uniforms:=New Stack<GLUniform>[4]
		Local textures:=New Stack<GLUniform>[4]
		For Local i:=0 Until 4
			uniforms[i]=New Stack<GLUniform>
			textures[i]=New Stack<GLUniform>
		Next
			
		Local n:Int
		glGetProgramiv( _glprogram,GL_ACTIVE_UNIFORMS,Varptr n )
			
		Local size:Int,type:UInt,length:Int,nameBuf:=New Byte[256],texunit:=0
			
		For Local i:=0 Until n
			
			glGetActiveUniform( _glprogram,i,nameBuf.Length,Varptr length,Varptr size,Varptr type,Cast<GLchar Ptr>( nameBuf.Data ) )
	
			Local name:=String.FromCString( nameBuf.Data )
				
			Local location:=glGetUniformLocation( _glprogram,name )
			If location=-1 Continue  'IE fix...
			
			Local uniform:=New GLUniform( name,location,texunit,size,type )
			
			uniforms[uniform.blockId].Push( uniform )
			
			Select type
			Case GL_SAMPLER_2D
				textures[uniform.blockId].Push( uniform )
				texunit+=1
			End
			
		Next
		
		For Local i:=0 Until 4
			_uniforms[i]=uniforms[i].ToArray()
			_textures[i]=textures[i].ToArray()
			_ublockSeqs[i]=-1
		Next
	End
	
	Property GLProgram:GLuint()
	
		Return _glprogram
	End

	Method ValidateUniforms( ublocks:UniformBlock[],textureFilter:TextureFilter )

		For Local i:=0 Until 4

			Local ublock:=ublocks[ i ]
			
			If Not ublock Or ublock.Seq=_ublockSeqs[i] Continue
			
			_ublockSeqs[i]=ublock.Seq
			
			For Local u:=Eachin _uniforms[i]
			
				Select u.type
				Case GL_FLOAT
				
					glUniform1f( u.location,ublock.GetScalar( u.uniformId ) )
					
				Case GL_FLOAT_VEC2
				
					glUniform2fv( u.location,1,ublock.GetVector4fv( u.uniformId ) )
					
				Case GL_FLOAT_VEC3
				
					glUniform3fv( u.location,1,ublock.GetVector4fv( u.uniformId ) )
					
				Case GL_FLOAT_VEC4
				
					glUniform4fv( u.location,1,ublock.GetVector4fv( u.uniformId ) )
					
				Case GL_FLOAT_MAT4
				
					glUniformMatrix4fv( u.location,1,False,ublock.GetMatrix4fv( u.uniformId ) )
					
				Case GL_SAMPLER_2D
				
					glUniform1i( u.location,u.texunit )
				
				End
			
			Next
		
		Next
		
		For Local i:=0 Until 4
		
			If Not _textures[i] Continue
			
			For Local u:=Eachin _textures[i]

				Local tex:=ublocks[i].GetTexture( u.uniformId )
				If tex
					tex.Bind( u.texunit,textureFilter )
				Else
					Print( "Can't bind shader texture uniform '"+u.name+"' - no texture!" )
				Endif
			
			Next
		
		Next
		
		glActiveTexture( GL_TEXTURE0 )
	
	End

End

Public

#rem monkeydoc The Shader class.
#end
Class Shader

	#rem monkeydoc Creates a new shader.
	#end
	Method New( name:String,source:String )
	
		Assert( Not _shaders.Contains( name ),"Shader with name '"+name+"' already exists" )
		
		_name=name
	
		_source=source
		
		_shaders[name]=Self
		
		EnumPasses()
	End
	
	#rem monkeydoc The shader name.
	#end
	Property Name:String()
	
		Return _name
	End
	
	#rem monkeydoc The shader source code.
	#end
	Property Source:String()
	
		Return _source
	End
	
	#rem monkeydoc @hidden The renderpasses the shader is involved in.
	#end
	Property RenderPasses:Int[]()
	
		Return _rpasses
	End
	
	#rem monkeydoc @hidden Renderpass bitmask.
	#end
	Property RenderPassMask:Int()
	
		Return _rpassMask
	End
	
	'***** INTERNAL *****
	
	#rem monkeydoc @hidden
	#end
	Method Bind( renderPass:Int )
	
		If _seq<>glGraphicsSeq
			_seq=glGraphicsSeq
			Rebuild()
		Endif
	
		glUseProgram( _programs[renderPass].GLProgram )
	End
	
	#rem monkeydoc @hidden
	#end
	Method ValidateUniforms( renderPass:Int,ublocks:UniformBlock[],textureFilter:TextureFilter )
	
		_programs[renderPass].ValidateUniforms( ublocks,textureFilter )
	End

	#rem monkeydoc Gets a shader with a given name.
	#end	
	Function GetShader:Shader( name:String )
	
		Local shader:=_shaders[name]
		If shader Return shader
		
		Local source:=LoadString( "asset::shaders/"+name+".glsl" )
		If Not source Return Null
		
		Return New Shader( name,source )
	End

	Private
	
	Global _shaders:=New StringMap<Shader>

	Field _name:String	
	Field _source:String
	Field _rpasses:Int[]
	Field _rpassMask:Int
	Field _programs:=New GLProgram[8]
	Field _seq:Int
	
	Method EnumPasses()

		Local tag:="//@renderpasses"
		Local tagi:=_source.Find( tag )
		If tagi=-1
			Print "Shader source:~n"+_source
			RuntimeError( "Can't find '"+tag+"' tag" )
		Endif
		tagi+=tag.Length
		Local tage:=_source.Find( "~n",tagi )
		If tage=-1 tage=_source.Length
		Local tagv:=_source.Slice( tagi,tage )
		Local rpasses:=tagv.Split( "," )
		If Not rpasses
			Print "Shader source:~n"+_source
			RuntimeError( "Invalid renderpasses value: '"+tagv+"'" )
		Endif
		_rpasses=New Int[rpasses.Length]
		For Local i:=0 Until rpasses.Length
			_rpasses[i]=Int( rpasses[i] )
			_rpassMask|=(1 Shl _rpasses[i])
		Next
		
	End
	
	Method Rebuild()
	
		'Get renderpasses
		'
		Local tag:="//@renderpasses"
		Local tagi:=_source.Find( tag )
		If tagi=-1
			Print "Shader source:~n"+_source
			RuntimeError( "Can't find '"+tag+"' tag" )
		Endif
		tagi+=tag.Length
		Local tage:=_source.Find( "~n",tagi )
		If tage=-1 tage=_source.Length
		Local tagv:=_source.Slice( tagi,tage )
		Local rpasses:=tagv.Split( "," )
		If Not rpasses
			Print "Shader source:~n"+_source
			RuntimeError( "Invalid renderpasses value: '"+tagv+"'" )
		Endif
		_rpasses=New Int[rpasses.Length]
		For Local i:=0 Until rpasses.Length
			_rpasses[i]=Int( rpasses[i] )
			_rpassMask|=(1 Shl _rpasses[i])
		Next
		
		'Find vertex/fragment chunks
		'
		Local i0:=_source.Find( "//@vertex" )
		If i0=-1 
			Print "Shader source:~n"+_source
			Assert( False,"Can't find //@vertex chunk" )
		Endif
		Local i1:=_source.Find( "//@fragment" )
		If i1=-1
			Print "Shader source:~n"+_source
			Assert( False,"Can't find //@fragment chunk" )
		Endif
			
		Local cs:=_source.Slice( 0,i0 )+"~n"
		Local vs:=cs+_source.Slice( i0,i1 )+"~n"
		Local fs:=cs+_source.Slice( i1 )+"~n"
		
		For Local rpass:=Eachin _rpasses
		
			Local defs:="#define MX2_RENDERPASS "+rpass+"~n"
			
			Local vshader:=glCompile( GL_VERTEX_SHADER,defs+vs )
			Local fshader:=glCompile( GL_FRAGMENT_SHADER,defs+fs )
				
			Local glprogram:=glCreateProgram()
			
			glAttachShader( glprogram,vshader )
			glAttachShader( glprogram,fshader )
			glDeleteShader( vshader )
			glDeleteShader( fshader )
				
			glBindAttribLocation( glprogram,0,"mx2_Vertex" )
			glBindAttribLocation( glprogram,1,"mx2_TexCoord0" )
			glBindAttribLocation( glprogram,2,"mx2_TexCoord1" )
			glBindAttribLocation( glprogram,3,"mx2_Color" )
			
			glLink( glprogram )
			
			Local program:=New GLProgram( glprogram )
			
			_programs[rpass]=program
		Next

	End

End
