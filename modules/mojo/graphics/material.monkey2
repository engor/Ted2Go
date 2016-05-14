
Namespace mojo.graphics

Class Material

	Method New( shader:Shader )

		_shader=shader
	End
	
	Property Shader:Shader()
	
		Return _shader
	End
	
	#rem monkeydoc @hidden
	#end
	Property Params:ParamBuffer()
	
		Return _params
	End
	
	Method SetVector( name:String,value:Vec4f )
	
		_params.SetVector( name,value )
	End

	Method SetMatrix( name:String,value:Mat4f )
	
		_params.SetMatrix( name,value )
	End

	Method SetTexture( name:String,value:Texture )
	
		_params.SetTexture( name,value )
	End

	Method SetColor( name:String,value:Color )
	
		_params.SetColor( name,value )
	End
	
	Private
	
	Field _shader:Shader
	Field _params:=New ParamBuffer
	
End
