
Namespace mojo.graphics

#Import "assets/shader_sprite.glsl@/mojo"
#Import "assets/shader_phong.glsl@/mojo"
#Import "assets/shader_font.glsl@/mojo"
#Import "assets/shader_null.glsl@/mojo"

Private

Function BindUniforms( uniforms:Uniform[],params:ParamBuffer,filter:Bool )

	For Local u:=Eachin uniforms
	
		Local p:=params._params[u.id]
		
		Select u.type
		Case GL_FLOAT
			glUniform1f( u.location,p.scalar )
		Case GL_FLOAT_VEC4
			glUniform4fv( u.location,1,Varptr p.vector.x )
		Case GL_FLOAT_MAT4
			glUniformMatrix4fv( u.location,1,False,Varptr p.matrix.i.x )
		Case GL_SAMPLER_2D
			Local tex:=p.texture
			DebugAssert( tex,"Can't bind shader texture uniform '"+u.name+"' - no texture!" )
			glActiveTexture( GL_TEXTURE0+u.texunit )
			glBindTexture( GL_TEXTURE_2D,tex.GLTexture )
			If (tex.Flags & TextureFlags.Filter) And filter
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR )
			Else
				glTexParameteri( GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST )
			Endif
			glUniform1i( u.location,u.texunit )
		Default
			Assert( False,"Unsupported uniform type for param:"+u.name )
		End

	Next
	
	glActiveTexture( GL_TEXTURE0 )
End

Class Uniform

	Field name:String
	Field id:Int
	Field location:Int
	Field texunit:Int
	Field size:Int
	Field type:Int
	
	Method New( name:String,location:Int,texunit:Int,size:Int,type:Int )
		Self.name=name
		Self.id=ShaderParam.ParamId( Self.name )
		Self.texunit=texunit
		Self.location=location
		Self.size=size
		Self.type=type
	End
	
End

Class ShaderProgram

	Method New( sources:String[] )

		_sources=sources
	End
	
	Property Sources:String[]()

		Return _sources
	End
	
	Property EnvUniforms:Uniform[]()
	
		Return _envUniforms
	End
	
	Property Uniforms:Uniform[]()

		Return _uniforms
	End
	
	Property GLProgram:GLuint()
	
		If _seq=glGraphicsSeq
			Return _glProgram
		Endif
		
		BuildProgram()

		EnumUniforms()
		
		_seq=glGraphicsSeq
		
		Return _glProgram
	End
	
	Private
	
	Field _sources:String[]
	
	Field _seq:Int
	Field _glProgram:GLuint
	Field _envUniforms:Uniform[]
	Field _uniforms:Uniform[]
		
	Method BuildProgram()

		Local csource:=""
		Local vsource:=""
		Local fsource:=""
		
		For Local source:=Eachin _sources
			Local i0:=source.Find( "//@vertex" )
			If i0=-1 
				Print "Shader source:~n"+source
				Assert( False,"Can't find //@vertex chunk" )
			Endif
			Local i1:=source.Find( "//@fragment" )
			If i1=-1
				Print "Shader source:~n"+source
				Assert( False,"Can't find //@fragment chunk" )
			Endif
			
			csource+=source.Slice( 0,i0 )+"~n"
			vsource+=source.Slice( i0,i1 )+"~n"
			fsource+=source.Slice( i1 )+"~n"
		Next
		
		vsource=csource+vsource
		fsource=csource+fsource
		
		Local vshader:=glCompile( GL_VERTEX_SHADER,vsource )
		Local fshader:=glCompile( GL_FRAGMENT_SHADER,fsource )
		
		_glProgram=glCreateProgram()
	
		glAttachShader( _glProgram,vshader )
		glAttachShader( _glProgram,fshader )
		glDeleteShader( vshader )
		glDeleteShader( fshader )
		
		glBindAttribLocation( _glProgram,0,"mx2_VertexPosition" )
		glBindAttribLocation( _glProgram,1,"mx2_VertexTexCoord0" )
		glBindAttribLocation( _glProgram,2,"mx2_VertexTangent" )
		glBindAttribLocation( _glProgram,3,"mx2_VertexColor" )
		
		glLink( _glProgram )
	End
	
	Method EnumUniforms()

		Local envUniforms:=New Stack<Uniform>
		Local uniforms:=New Stack<Uniform>
		
		Local n:Int
		glGetProgramiv( _glProgram,GL_ACTIVE_UNIFORMS,Varptr n )

		Local size:Int,type:UInt,length:Int,nameBuf:=New Byte[256],texunit:=0
		
		For Local i:=0 Until n
		
			glGetActiveUniform( _glProgram,i,nameBuf.Length,Varptr length,Varptr size,Varptr type,Cast<GLchar Ptr>( Varptr nameBuf[0] ) )
			
			Local name:=String.FromCString( nameBuf.Data )
			
			Local location:=glGetUniformLocation( _glProgram,name )
			If location=-1 Continue  'IE fix...
			
'			Print "Uniform "+name+" location="+location
			
			Local u:=New Uniform( name,location,texunit,size,type )
			If name.StartsWith( "mx2_" )
				envUniforms.Push( u )
			Else
				uniforms.Push( u )
			Endif
			Select type
			Case GL_SAMPLER_2D
				texunit+=1
			End
		Next
		
		_envUniforms=envUniforms.ToArray()
		_uniforms=uniforms.ToArray()
	End
	
End

Public

#rem monkeydoc @hidden
#end
Struct ShaderParam

	Field scalar:Float
	Field vector:Vec4f
	Field matrix:Mat4f
	Field texture:Texture

	Function ParamId:Int( name:String )
		Local id:=_ids[name]
		If id Return id
		_nextId+=1
		_ids[name]=_nextId
'		Print "Shader param "+name+"="+_nextId
		Return _nextId
	End
	
	Private
	
	Global _nextId:Int
	Global _ids:=New StringMap<Int>
End

#rem monkeydoc @hidden
#end
Class ShaderEnv

	Method New( sourceCode:String )
		_source=sourceCode
		_id=_nextId
		_nextId+=1
	End
	
	Property SourceCode:String()
		Return _source
	End
	
	Property Id:Int()
		Return _id
	End
	
	Private
	
	Field _source:String
	Field _id:Int
	
	Global _nextId:=0
	
End

#rem monkeydoc @hidden
#end
Class ParamBuffer

	Method SetVector( name:String,value:Vec4f )
		_params[ ShaderParam.ParamId( name ) ].vector=value
	End

	Method SetMatrix( name:String,value:Mat4f )
		_params[ ShaderParam.ParamId( name ) ].matrix=value
	End

	Method SetTexture( name:String,value:Texture )
		_params[ ShaderParam.ParamId( name ) ].texture=value
	End

	Method SetColor( name:String,value:Color )
		_params[ ShaderParam.ParamId( name ) ].vector=New Vec4f( value.r,value.g,value.b,value.a )
	End

	Private
	
	Field _params:=New ShaderParam[32]
End

Class Shader

	Method New( sourceCode:String )
		_source=sourceCode
	End
	
	Property SourceCode:String()
		Return _source
	End
	
	#rem monkeydoc @hidden
	#end
	Method Bind( env:ShaderEnv )
	
		If _seq<>glGraphicsSeq
			_seq=glGraphicsSeq
			_bound=Null
		Endif
		
		Local p:=_programs[env.Id]
		If Not p
			p=New ShaderProgram( New String[]( env._source,_source ) )
			_programs[env.Id]=p
		Endif
		
		If _bound=p Return
		glUseProgram( p.GLProgram )
		_bound=p
	End
	
	#rem monkeydoc @hidden
	#end
	Method BindEnvParams( params:ParamBuffer )
	
		BindUniforms( _bound._envUniforms,params,True )
	End
	
	#rem monkeydoc @hidden
	#end
	Method BindParams( params:ParamBuffer,filter:Bool )
	
		BindUniforms( _bound._uniforms,params,filter )
	End
	
	#rem monkeydoc @hidden
	#end
	Function GetShader:Shader( name:String )

		If Not _shaders
			_shaders=New StringMap<Shader>
			_shaders["sprite"]=New Shader( stringio.LoadString( "asset::mojo/shader_sprite.glsl" ) )
			_shaders["phong"]=New Shader( stringio.LoadString( "asset::mojo/shader_phong.glsl" ) )
			_shaders["font"]=New Shader( stringio.LoadString( "asset::mojo/shader_font.glsl" ) )
			_shaders["null"]=New Shader( stringio.LoadString( "asset::mojo/shader_null.glsl" ) )
		Endif
		
		Return _shaders[name]
	End

	Private
	
	Field _source:String
	Field _programs:=New ShaderProgram[16]

	Global _seq:Int
	Global _bound:ShaderProgram
	
	Global _shaders:StringMap<Shader>

End
