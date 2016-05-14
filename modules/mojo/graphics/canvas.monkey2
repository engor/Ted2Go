
Namespace mojo.graphics

#Import "assets/shaderenv_ambient.glsl@/mojo"
#Import "assets/RobotoMono-Regular.ttf@/mojo"

#rem monkeydoc @hidden
#end	
Class DrawOp
	Field blendMode:BlendMode
	Field material:Material
	Field order:Int
	Field count:Int
End

#rem monkeydoc The Canvas class.
#end
Class Canvas

	Method New( image:Image )
	
		Init( image.Texture,image.Texture.Rect.Size,image.RenderRect )
	End
	
	#rem monkeydoc @hidden
	#end
	Method New( texture:Texture )
	
		Init( texture,texture.Rect.Size,New Recti( 0,0,texture.Rect.Size ) )
	End

	#rem monkeydoc @hidden
	#end
	Method New( width:Int,height:Int )
	
		Init( Null,New Vec2i( width,height ),New Recti( 0,0,width,height ) )
	End
	
	Property Viewport:Recti()
	
		Return _viewport
		
	Setter( viewport:Recti )
	
		Flush()
		
		_viewport=viewport
		
		_dirty|=Dirty.Scissor|Dirty.EnvParams
	End
	
	Property Scissor:Recti()
	
		Return _scissor
	
	Setter( scissor:Recti )
	
		Flush()
		
		_scissor=scissor
		
		_dirty|=Dirty.Scissor
	End
	
	#rem monkeydoc @hidden
	#end	
	Property ViewMatrix:Mat4f()
	
		Return _viewMatrix
	
	Setter( viewMatrix:Mat4f )
	
		Flush()
	
		_viewMatrix=viewMatrix
		
		_dirty|=Dirty.EnvParams
	End
	
	#rem monkeydoc @hidden
	#end	
	Property ModelMatrix:Mat4f()
	
		Return _modelMatrix
	
	Setter( modelMatrix:Mat4f )
	
		Flush()
	
		_modelMatrix=modelMatrix
		
		_dirty|=Dirty.EnvParams
	End
	
	#rem monkeydoc @hidden
	#end	
	Property AmbientLight:Color()
	
		Return _ambientLight

	Setter( ambientLight:Color )
	
		Flush()
	
		_ambientLight=ambientLight
		
		_dirty|=Dirty.EnvParams
	End
	
	#rem monkeydoc @hidden
	#end	
	Property RenderColor:Color()
	
		Return _renderColor
	
	Setter( renderColor:Color )

		Flush()
			
		_renderColor=renderColor
		
		_dirty|=Dirty.EnvParams
	End
	
	#rem monkeydoc @hidden
	#end	
	Property RenderMatrix:AffineMat3f()
	
		Return _renderMatrix
		
	Setter( renderMatrix:AffineMat3f )
	
		Flush()
		
		_renderMatrix=renderMatrix
		
		_dirty|=Dirty.Scissor|Dirty.EnvParams
	End
	
	#rem monkeydoc @hidden
	#end	
	Property RenderBounds:Recti()
	
		Return _renderBounds
		
	Setter( renderBounds:Recti )
	
		Flush()
		
		_renderBounds=renderBounds
				
		_dirty|=Dirty.Scissor
	End
	
	#rem monkeydoc @hidden
	#end	
	Method Resize( size:Vec2i )
	
		Flush()
		
		_targetSize=size
		
		_targetRect=New Recti( 0,0,size )
		
		_dirty|=Dirty.Target
	End
	
	Method Clear( color:Color )

		Flush()
		
		_device.Clear( color )
	End
	
	#rem monkeydoc @hidden
	#end	
	Method BeginRender()
	
		DebugAssert( Not _rendering )
		
		_rendering=True
	
		_device.ShaderEnv=_ambientEnv
		
		_dirty=Dirty.All
	End
	
	#rem monkeydoc @hidden
	#end	
	Method EndRender()
	
		Flush()
		
		_rendering=False
	End
	
	Method Flush()
	
		If Not _rendering Return
		
		Validate()
		
		RenderDrawOps()
		
		ClearDrawOps()
	End
	
	'***** DrawList *****
	
	Property Font:Font()
	
		Return _font
	
	Setter( font:Font )
	
		If Not font font=_defaultFont
	
		_font=font
	End
	
	Property Alpha:Float()
	
		Return _alpha
		
	Setter( alpha:Float )
	
		_alpha=alpha
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End
	
	Property Color:Color()
	
		Return _color
	
	Setter( color:Color )
	
		_color=color
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End
	
	Property Matrix:AffineMat3f()
	
		Return _matrix
	
	Setter( matrix:AffineMat3f )
	
		_matrix=matrix
	End
	
	Property BlendMode:BlendMode()
	
		Return _blendMode
	
	Setter( blendMode:BlendMode )
	
		_blendMode=blendMode
	End
	
	#rem monkeydoc @hidden
	#end
	Property PointMaterial:Material()
	
		Return _pointMaterial
	
	Setter( pointMaterial:Material )
	
		_pointMaterial=pointMaterial
	End
	
	#rem monkeydoc @hidden
	#end
	Property LineMaterial:Material()
	
		Return _lineMaterial
		
	Setter( lineMaterial:Material )
	
		_lineMaterial=lineMaterial
	End
	
	#rem monkeydoc @hidden
	#end
	Property TriangleMaterial:Material()
	
		Return _triangleMaterial
	
	Setter( triangleMaterial:Material )
	
		_triangleMaterial=triangleMaterial
	End
	
	#rem monkeydoc @hidden
	#end
	Property QuadMaterial:Material()

		Return _quadMaterial

	Setter( quadMaterial:Material )

		_quadMaterial=quadMaterial
	End
	
	Method PushMatrix()
	
		_matrixStack.Push( Matrix )
	End
	
	Method PopMatrix()
	
		Matrix=_matrixStack.Pop()
	End
	
	Method ClearMatrix()
	
		_matrixStack.Clear()
		
		Matrix=New AffineMat3f
	End
	
	Method Translate( tx:Float,ty:Float )
	
		Matrix=Matrix.Translate( tx,ty )
	End
	
	Method Rotate( rz:Float )
	
		Matrix=Matrix.Rotate( rz )
	End
	
	Method Scale( sx:Float,sy:Float )
	
		Matrix=Matrix.Scale( sx,sy )
	End
	
	Method DrawPoint( v0:Vec2f )
		AddDrawOp( _pointMaterial,1,1 )
		AddVertex( v0.x+.5,v0.y+.5,0,0 )
	End
	
	Method DrawPoint( x0:Float,y0:Float )
		AddDrawOp( _pointMaterial,1,1 )
		AddVertex( x0+.5,y0+.5,0,0 )
	End
	
	Method DrawLine( v0:Vec2f,v1:Vec2f )
		AddDrawOp( _lineMaterial,2,1 )
		AddVertex( v0.x+.5,v0.y+.5,0,0 )
		AddVertex( v1.x+.5,v1.y+.5,1,1 )
	End
	
	Method DrawLine( x0:Float,y0:Float,x1:Float,y1:Float )
		AddDrawOp( _lineMaterial,2,1 )
		AddVertex( x0+.5,y0+.5,0,0 )
		AddVertex( x1+.5,y1+.5,1,1 )
	End
	
	Method DrawTriangle( v0:Vec2f,v1:Vec2f,v2:Vec2f )
		AddDrawOp( _triangleMaterial,3,1 )
		AddVertex( v0.x,v0.y,.5,0 )
		AddVertex( v1.x,v1.y,1,1 )
		AddVertex( v2.x,v2.y,0,1 )
	End
	
	Method DrawTriangle( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float )
		AddDrawOp( _triangleMaterial,3,1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
	End
	
	Method DrawQuad( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float,x3:Float,y3:Float )
		AddDrawOp( _quadMaterial,4,1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
		AddVertex( x3,y3,0,1 )
	End
	
	Method DrawRect( rect:Rectf )
		AddDrawOp( _quadMaterial,4,1 )
		AddVertex( rect.min.x,rect.min.y,0,0 )
		AddVertex( rect.max.x,rect.min.y,1,0 )
		AddVertex( rect.max.x,rect.max.y,1,1 )
		AddVertex( rect.min.x,rect.max.y,0,1 )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float )
		DrawRect( New Rectf( x,y,x+width,y+height ) )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image )
		Local tc:=srcImage.TexCoords
		AddDrawOp( srcImage.Material,4,1 )
		AddVertex( rect.min.x,rect.min.y,tc.min.x,tc.min.y )
		AddVertex( rect.max.x,rect.min.y,tc.max.x,tc.min.y )
		AddVertex( rect.max.x,rect.max.y,tc.max.x,tc.max.y )
		AddVertex( rect.min.x,rect.max.y,tc.min.x,tc.max.y )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image )
		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image,srcRect:Recti )
		Local s0:=Float(srcImage.RenderRect.min.x+srcRect.min.x)/srcImage.Texture.Width
		Local t0:=Float(srcImage.RenderRect.min.y+srcRect.min.y)/srcImage.Texture.Height
		Local s1:=Float(srcImage.RenderRect.min.x+srcRect.max.x)/srcImage.Texture.Width
		Local t1:=Float(srcImage.RenderRect.min.y+srcRect.max.y)/srcImage.Texture.Height
		AddDrawOp( srcImage.Material,4,1 )
		AddVertex( rect.min.x,rect.min.y,s0,t0 )
		AddVertex( rect.max.x,rect.min.y,s1,t0 )
		AddVertex( rect.max.x,rect.max.y,s1,t1 )
		AddVertex( rect.min.x,rect.max.y,s0,t1 )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int,srcWidth:Int,srcHeight:Int )
		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+srcWidth,srcY+srcHeight ) )
	End
	
	Method DrawImage( image:Image,tx:Float,ty:Float )
		Local vs:=image.Vertices
		Local tc:=image.TexCoords
		AddDrawOp( image.Material,4,1 )
		AddVertex( vs.min.x+tx,vs.min.y+ty,tc.min.x,tc.min.y )
		AddVertex( vs.max.x+tx,vs.min.y+ty,tc.max.x,tc.min.y )
		AddVertex( vs.max.x+tx,vs.max.y+ty,tc.max.x,tc.max.y )
		AddVertex( vs.min.x+tx,vs.max.y+ty,tc.min.x,tc.max.y )
	End
	
	Method DrawImage( image:Image,trans:Vec2f )
		DrawImage( image,trans.x,trans.y )
	End

	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float )
		Local matrix:=_matrix
		Translate( tx,ty )
		Rotate( rz )
		DrawImage( image,0,0 )
		_matrix=matrix
	End

	Method DrawImage( image:Image,trans:Vec2f,rz:Float )
		DrawImage( image,trans.x,trans.y,rz )
	End

	
	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=_matrix
		Translate( tx,ty )
		Rotate( rz )
		Scale( sx,sy )
		DrawImage( image,0,0 )
		_matrix=matrix
	End

	Method DrawImage( image:Image,trans:Vec2f,rz:Float,scale:Vec2f )
		DrawImage( image,trans.x,trans.y,rz,scale.x,scale.y )
	End
	
	Method DrawText( text:String,tx:Float,ty:Float,handleX:Float=0,handleY:Float=0 )
	
		tx-=_font.TextWidth( text ) * handleX
		ty-=_font.Height * handleY
	
		Local image:=_font.Image
		Local sx:=image.RenderRect.min.x,sy:=image.RenderRect.min.y
		Local tw:=image.Texture.Width,th:=image.Texture.Height
		
		AddDrawOp( image.Material,4,text.Length )
		
		For Local char:=Eachin text
		
			Local g:=_font.GetGlyph( char )
			
			Local s0:=Float(g.rect.min.x+sx)/tw
			Local t0:=Float(g.rect.min.y+sy)/th
			Local s1:=Float(g.rect.max.x+sx)/tw
			Local t1:=Float(g.rect.max.y+sy)/th

			Local x0:=tx+g.offset.x,x1:=x0+g.rect.Width
			Local y0:=ty+g.offset.y,y1:=y0+g.rect.Height
			
			'Integerize font coods!
			x0=Round( x0 );y0=Round( y0 );x1=Round( x1 );y1=Round( y1 )
			
			AddVertex( x0,y0,s0,t0 )
			AddVertex( x1,y0,s1,t0 )
			AddVertex( x1,y1,s1,t1 )
			AddVertex( x0,y1,s0,t1 )
			
			tx+=g.advance
		Next
	End
	
	Private
	
	Enum Dirty
		Target=1
		Scissor=2
		EnvParams=4
		All=7
	End
	
	Global _ambientEnv:ShaderEnv
	Global _nullShader:Shader
	Global _defaultFont:Font

	Field _dirty:Dirty
	Field _rendering:Bool
	Field _target:Texture
	Field _targetSize:Vec2i
	Field _targetRect:Recti
	Field _envParams:ParamBuffer
	Field _device:GraphicsDevice
	
	Field _viewport:Recti
	Field _scissor:Recti
	Field _viewMatrix:Mat4f
	Field _modelMatrix:Mat4f
	Field _ambientLight:Color
	Field _renderColor:Color
	
	Field _renderMatrix:AffineMat3f
	Field _renderBounds:Recti
	
	Field _font:Font
	Field _alpha:Float
	Field _color:Color
	Field _pmcolor:UInt
	Field _matrix:AffineMat3f
	Field _blendMode:BlendMode
	Field _matrixStack:=New Stack<AffineMat3f>
	
	Field _ops:=New Stack<DrawOp>
	Field _op:=New DrawOp
	
	Field _vertices:=New Stack<Vertex2f>
	Field _vertexData:Vertex2f[]
	Field _vertex:Int
	
	Field _pointMaterial:Material
	Field _lineMaterial:Material
	Field _triangleMaterial:Material
	Field _quadMaterial:Material
	
	Method Init( target:Texture,size:Vec2i,viewport:Recti )
	
		If Not _device
			_ambientEnv=New ShaderEnv( stringio.LoadString( "asset::mojo/shaderenv_ambient.glsl" ) )
			_defaultFont=Font.Load( "asset::mojo/RobotoMono-Regular.ttf",16 )
			_nullShader=Shader.GetShader( "null" )
		Endif

		_target=target
		_targetSize=size
		_targetRect=viewport
		
		_envParams=New ParamBuffer
		_device=New GraphicsDevice
		_rendering=False
		
		_viewport=New Recti( 0,0,_targetRect.Width,_targetRect.Height )
		_scissor=New Recti( 0,0,16384,16384 )
		_viewMatrix=New Mat4f
		_modelMatrix=New Mat4f
		_ambientLight=Color.Black
		_renderColor=Color.White
		_renderMatrix=New AffineMat3f
		_renderBounds=New Recti( 0,0,_targetRect.Width,_targetRect.Height )
		
		Font=Null
		Alpha=1
		Color=Color.White
		Matrix=New AffineMat3f
		BlendMode=BlendMode.Alpha
		PointMaterial=New Material( _nullShader )
		LineMaterial=New Material( _nullShader )
		TriangleMaterial=New Material( _nullShader )
		QuadMaterial=New Material( _nullShader )
		
		BeginRender()
	End
	
	Method Validate()

		If Not _dirty Return
		
		If _dirty & Dirty.Target

			Local projMatrix:Mat4f
			Local viewport:=_targetRect
	
			If _target
				projMatrix=Mat4f.Ortho( 0,viewport.Width,0,viewport.Height,-1,1 )
			Else
				viewport.min.y=_targetSize.y-viewport.max.y
				viewport.max.y=viewport.min.y+viewport.Height
				projMatrix=Mat4f.Ortho( 0,viewport.Width,viewport.Height,0,-1,1 )
			Endif
		
			_device.RenderTarget=_target
			_device.Viewport=_targetRect
			_envParams.SetMatrix( "mx2_ProjectionMatrix",projMatrix )
			
			_dirty|=Dirty.EnvParams
			
		Endif
		
		If _dirty & Dirty.Scissor
		
'			Local viewport:=TransformRecti( _viewport & _scissor,_renderMatrix )
			Local viewport:=TransformRecti( _viewport & (_scissor+_viewport.Origin),_renderMatrix )
			
			Local scissor:=(viewport & _renderBounds)+_targetRect.Origin
			
			If Not _target
				Local h:=scissor.Height
				scissor.min.y=_targetSize.y-scissor.max.y
				scissor.max.y=scissor.min.y+h
			Endif
			
			_device.Scissor=scissor
		
		Endif
		
		If _dirty & Dirty.EnvParams
		
			Local renderMatrix:=_renderMatrix.Translate( New Vec2f( _viewport.X,_viewport.Y ) )

			Local modelViewMatrix:=_viewMatrix * _modelMatrix * New Mat4f( renderMatrix )
			
			_envParams.SetMatrix( "mx2_ModelViewMatrix",modelViewMatrix )
			_envParams.SetColor( "mx2_AmbientLight",_ambientLight )
			_envParams.SetColor( "mx2_RenderColor",_renderColor )

			_device.EnvParams=_envParams
		Endif
		
		_dirty=Null
	End
	
	Method RenderDrawOps()
	
		Local p:=_vertexData.Data
	
		For Local op:=Eachin _ops
			_device.BlendMode=op.blendMode
			_device.Shader=op.material.Shader
			_device.Params=op.material.Params
			_device.Render( p,op.order,op.count )
			p=p+op.order*op.count
		Next
	
	End
	
	Method ClearDrawOps()
		_ops.Clear()
		_vertices.Clear()
		_vertexData=_vertices.Data
		_op=New DrawOp
		_vertex=0
	End
	
	Method AddDrawOp( material:Material,order:Int,count:Int )
	
		_vertices.Resize( _vertex+order*count )
		_vertexData=_vertices.Data
		
		If _blendMode=_op.blendMode And material=_op.material And order=_op.order
			_op.count+=count
			Return
		End
		
		_op=New DrawOp
		_op.blendMode=_blendMode
		_op.material=material
		_op.order=order
		_op.count=count
		_ops.Add( _op )
	End
	
	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float )
	
		_vertexData[_vertex].x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vertexData[_vertex].y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vertexData[_vertex].s0=s0
		_vertexData[_vertex].t0=t0
		_vertexData[_vertex].ix=_matrix.i.x
		_vertexData[_vertex].iy=_matrix.i.y
		_vertexData[_vertex].color=_pmcolor

		_vertex+=1
	End

End
