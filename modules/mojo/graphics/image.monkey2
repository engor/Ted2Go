
Namespace mojo.graphics

#rem monkeydoc The Image class.
#end
Class Image

	Method New( pixmap:Pixmap,shader:Shader=Null )
	
		Local texture:=New Texture( pixmap )
		
		Init( Null,texture,texture.Rect,shader )
	End
	
	Method New( width:Int,height:Int,shader:Shader=Null )
	
		Local texture:=New Texture( width,height )
		
		Init( Null,texture,texture.Rect,shader )
	End
	
	Method New( image:Image,rect:Recti )
	
		Init( image._material,image._texture,rect,Null )
	End

	#rem monkeydoc @hidden
	#end
	Method New( texture:Texture,shader:Shader=Null )
	
		Init( Null,texture,texture.Rect,shader )
	End
	
	#rem monkeydoc @hidden
	#end
	Method New( material:Material,texture:Texture,rect:Recti )
	
		Init( material,texture,rect,Null )
	End
	
	#rem monkeydoc @hidden
	#end
	Property Material:Material()
	
		Return _material
	End
	
	#rem monkeydoc @hidden
	#end
	Property Texture:Texture()
	
		Return _texture
	End
	
	#rem monkeydoc @hidden
	#end
	Property RenderRect:Recti()
	
		Return _renderRect
	End
	
	Property Handle:Vec2f()
	
		Return _handle
		
	Setter( handle:Vec2f )
	
		_handle=handle
		
		UpdateVertices()
	End
	
	Property Scale:Vec2f()
	
		Return _scale
	
	Setter( scale:Vec2f )
	
		_scale=scale
		
		UpdateVertices()
	End
	
	Property Width:Float()
	
		Return _x1-_x0
	End
	
	Property Height:Float()
	
		Return _y1-_y0
	End
	
	Property Radius:Float()
	
		Return _radius
	End
	
	Property X0:Float()
	
		Return _x0
	End
	
	Property Y0:Float()
	
		Return _y0
	End
	
	Property X1:Float()
	
		Return _x1
	End
	
	Property Y1:Float()
	
		Return _y1
	End
	
	Property S0:Float()
	
		Return _s0
	End
	
	Property T0:Float()
	
		Return _t0
	End
	
	Property S1:Float()
	
		Return _s1
	End
	
	Property T1:Float()
	
		Return _t1
	End
	
	Function Load:Image( path:String,shader:Shader=Null )
	
		Local texture:=mojo.graphics.Texture.Load( path )
		If Not texture Return Null
		
		Local file:=StripExt( path )
		Local ext:=ExtractExt( path )
		
		Local specular:=mojo.graphics.Texture.Load( file+"_SPECULAR"+ext )
		Local normal:=mojo.graphics.Texture.Load( file+"_NORMALS"+ext )
		
		If Not shader shader=Shader.GetShader( "sprite" )
		
		Local material:=New Material( shader )
		
		material.SetTexture( "u_Texture0",texture )
		If specular material.SetTexture( "u_Texture1",specular )
		If normal material.SetTexture( "u_Texture2",normal )
		
		Return New Image( material,texture,texture.Rect )
	End
	
	Private
	
	Field _material:Material
	Field _texture:Texture
	Field _renderRect:Recti
	
	Field _handle:=New Vec2f( 0,0 )
	Field _scale:=New Vec2f( 1,1 )
	Field _radius:Float
	Field _x0:Float
	Field _y0:Float
	Field _x1:Float
	Field _y1:Float
	Field _s0:Float
	Field _t0:Float
	Field _s1:Float
	Field _t1:Float
	
	Method Init( material:Material,texture:Texture,rect:Recti,shader:Shader )
		
		If Not material
			If Not shader shader=Shader.GetShader( "sprite" )
			material=New Material( shader )
			material.SetTexture( "u_Texture0",texture )
		Endif
		
		_material=material
		_texture=texture
		_renderRect=rect
		
		UpdateVertices()
		UpdateTexCoords()
	End
	
	Method UpdateVertices()
		_x0=Float(_renderRect.Width)*(0-_handle.x)*_scale.x
		_y0=Float(_renderRect.Height)*(0-_handle.y)*_scale.y
		_x1=Float(_renderRect.Width)*(1-_handle.x)*_scale.x
		_y1=Float(_renderRect.Height)*(1-_handle.y)*_scale.y
		_radius=_x0*_x0+_y0*_y0
		_radius=Max( _radius,_x1*_x1+_y0*_y0 )
		_radius=Max( _radius,_x1*_x1+_y1*_y1 )
		_radius=Max( _radius,_x0*_x0+_y1*_y1 )
		_radius=Sqrt( _radius )
	End
	
	Method UpdateTexCoords()
		_s0=Float(_renderRect.min.x)/_texture.Width
		_t0=Float(_renderRect.min.y)/_texture.Height
		_s1=Float(_renderRect.max.x)/_texture.Width
		_t1=Float(_renderRect.max.y)/_texture.Height
	End
	
End
