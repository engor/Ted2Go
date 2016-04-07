
Namespace mojo2.glutil

Private

Using lib.gles20

Global tmpi:Int

Public

Function glCheck()
	Local err:=glGetError()
	If err=GL_NO_ERROR Return
	Mojo2Error( "GL ERROR! err="+err )
End

Function glPushTexture2d:Void( tex:Int )
	glGetIntegerv( GL_TEXTURE_BINDING_2D,Varptr tmpi )
	glBindTexture( GL_TEXTURE_2D,tex )
End

Function glPopTexture2d:Void()
	glBindTexture( GL_TEXTURE_2D,tmpi )
End

Function glPushFramebuffer:Void( framebuf:Int )
	glGetIntegerv( GL_FRAMEBUFFER_BINDING,Varptr tmpi )
	glBindFramebuffer( GL_FRAMEBUFFER,framebuf )
End

Function glPopFramebuffer:Void()
	glBindFramebuffer( GL_FRAMEBUFFER,tmpi )
End

Function glCompile:Int( type:Int,source:String )

	#If __TARGET__="emscripten"	Or (__TARGET__="desktop" And __HOSTOS__="windows")
'	#If TARGET<>"glfw" Or GLFW_USE_ANGLE_GLES20
		source="precision mediump float;~n"+source
	#Endif
	
	Local shader:=glCreateShader( type )
	glShaderSourceEx( shader,source )
	glCompileShader( shader )
	glGetShaderiv( shader,GL_COMPILE_STATUS,Varptr tmpi )
	If Not tmpi
		Print "Failed to compile fragment shader:"+glGetShaderInfoLogEx( shader )
		Print source
'		Local lines:=source.Split( "~n" )
'		For Local i:=0 Until lines.Length
'			Print (i+1)+":~t"+lines[i]
'		Next
		Mojo2Error( "Compile fragment shader failed" )
	Endif
	Return shader
End

Function glLink:Void( program:Int )
	glLinkProgram( program )
	glGetProgramiv( program,GL_LINK_STATUS,Varptr tmpi )
	If Not tmpi Mojo2Error( "Failed to link program:"+glGetProgramInfoLogEx( program ) )
End
