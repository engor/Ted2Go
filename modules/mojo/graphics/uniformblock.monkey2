
Namespace mojo.graphics

#rem monkeydoc The UniformBlock class.
#end
Class UniformBlock Extends Resource

	#rem monkeydoc Sets a scalar uniform.
	#end
	Method SetScalar( uniform:String,scalar:Float )
		Local id:=GetUniformId( uniform )
		_scalars[id]=scalar
		_seq=_gseq
		_gseq+=1
	End
	
	#rem monkeydoc Gets a scalar uniform.
	#end
	Method GetScalar:Float( uniform:String )
		Local id:=GetUniformId( uniform )
		Return _scalars[id]
	End

	Method GetScalar:Float( id:Int )
		Return _scalars[id]
	End
	
	#rem monkeydoc Sets a vector uniform.
	#end
	Method SetVector( uniform:String,color:Color )
		Local id:=GetUniformId( uniform )
		_vectors[id]=New Vec4f( color.r,color.g,color.b,color.a )
		_seq=_gseq
		_gseq+=1
	End

	Method SetVector( uniform:String,vector:Vec2f )
		Local id:=GetUniformId( uniform )
		_vectors[id]=New Vec4f( vector.x,vector.y,0,0 )
		_seq=_gseq
		_gseq+=1
	End

	Method SetVector( uniform:String,vector:Vec3f )
		Local id:=GetUniformId( uniform )
		_vectors[id]=New Vec4f( vector.x,vector.y,vector.z,0 )
		_seq=_gseq
		_gseq+=1
	End
	
	Method SetVector( uniform:String,vector:Vec4f )
		Local id:=GetUniformId( uniform )
		_vectors[id]=vector
		_seq=_gseq
		_gseq+=1
	End
	
	#rem monkeydoc Gets a vector uniform.
	#end
	Method GetVector:Vec4f( uniform:String )
		Local id:=GetUniformId( uniform )
		Return _vectors[id]
	End
	
	Method GetVector:Vec4f( id:Int )
		Return _vectors[id]
	End
	
	#rem monkeydoc @hidden
	#end	
	Method GetVector4fv:Float Ptr( id:Int )
		Return Varptr _vectors[id].x
	End
	
	#rem monkeydoc Sets a matrix uniform.
	#end
	Method SetMatrix( uniform:String,matrix:Mat4f )
		Local id:=GetUniformId( uniform )
		_matrices[id]=matrix
		_seq=_gseq
		_gseq+=1
	End
	
	#rem monkeydoc Gets a matrix uniform.
	#end
	Method GetMatrix:Mat4f( uniform:String )
		Local id:=GetUniformId( uniform )
		Return _matrices[id]
	End
	
	Method GetMatrix:Mat4f( id:Int )
		Return _matrices[id]
	End

	#rem monkeydoc @hidden
	#end	
	Method GetMatrix4fv:Float Ptr( id:Int )
		Return Varptr _matrices[id].i.x
	End

	#rem monkeydoc Set a texture uniform.
	#end	
	Method SetTexture( uniform:String,texture:Texture )
		Local id:=GetUniformId( uniform )
		If texture texture.Retain()
		If _textures[id] _textures[id].Release()
		_textures[id]=texture
		_seq=_gseq
		_gseq+=1
	End

	#rem monkeydoc Gets a texture uniform.
	#end	
	Method GetTexture:Texture( uniform:String )
		Local id:=GetUniformId( uniform )
		Return _textures[id]
	End
	
	Method GetTexture:Texture( id:Int )
		Return _textures[id]
	End

	#rem monkeydoc Gets the id of a uniform name.
	#end	
	Function GetUniformId:Int( uniform:String )
		Init()
		Local id:=_uniformIds[uniform]
		If Not id
			id=_uniformIds.Count()+1
			_uniformIds[uniform]=id
		Endif
		Return id
	End

	#rem monkeydoc @hidden
	#end	
	Property Seq:Int()
		Return _seq
	End
	
	#rem monkeydoc @hidden
	#end	
	Function BindUniformsToBlockId( uniforms:String[],index:Int )
		For Local uniform:=Eachin uniforms
			_blockIds[ GetUniformId( uniform ) ]=index
		Next
	End
	
	#rem monkeydoc @hidden
	#end	
	Function GetUniformBlockId:Int( uniform:String )
		Return _blockIds[ GetUniformId( uniform ) ]
	End
	
	Protected
	
	Method OnDiscard() Override
	
		For Local t:=Eachin _textures
			If t t.Release()
		Next
	End
	
	Private
	
	Field _seq:Int
	Global _gseq:Int

	Field _scalars:=New Float[MaxUniforms]
	Field _vectors:=New Vec4f[MaxUniforms]
	Field _matrices:=New Mat4f[MaxUniforms]
	Field _textures:=New Texture[MaxUniforms]
	
	Global _uniformIds:=New StringMap<Int>
	Global _blockIds:=New Int[MaxUniforms]

	Const MaxUniforms:=32

	Function Init()
		Global inited:=False
		If inited Return	
		inited=True
	
		UniformBlock.BindUniformsToBlockId( New String[]( "mx2_ViewportSize","mx2_ViewportOrigin","mx2_ViewportClip" ),0 )
		UniformBlock.BindUniformsToBlockId( New String[]( "mx2_AmbientLight" ),0 )
		UniformBlock.BindUniformsToBlockId( New String[]( "mx2_ModelViewProjectionMatrix" ),0 )
		UniformBlock.BindUniformsToBlockId( New String[]( "mx2_GBuffer0","GBuffer1","GBufferScale" ),0 )

		UniformBlock.BindUniformsToBlockId( New String[]( "mx2_ImageTexture0","mx2_ImageTexture1" ),1 )
		UniformBlock.BindUniformsToBlockId( New String[]( "mx2_ImageColor","mx2_LightDepth" ),1 )
	End

End
