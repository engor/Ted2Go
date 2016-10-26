
Namespace mojo.graphics

#rem monkeydoc The Canvas class.

Canvas objects are used to perform rendering to either a mojo [[app.View]] or an 'off screen' [[mojo.graphics.Image]].

To draw to a canvas, use one of the 'Draw' methods. Drawing is affected by a number of draw states, including:

* [[Color]] - the current drawing color. This is combined with the current alpha to produce the final rendering color and alpha values.
* [[Alpha]] - the current drawing alpha level.
* [[Matrix]] - the current drawing matrix. All drawing coordinates are multiplied by this matrix before rendering.
* [[BlendMode]] - the blending mode for drawing, eg: opaque, alpha, additive, multiply.
* [[Viewport]] - the current viewport. All drawing coordinates are relative to the top-left of the viewport.
* [[Scissor]] - the current scissor rect. All rendering is clipped to the union of the viewport and the scissor rect.
* [[Font]] - The current font to use when drawing text with [[DrawText]].

Drawing does not occur immediately. Drawing commands are 'buffered' to reduce the overhead of sending lots of draw calls to the lower level graphics API. You can force all drawing commands in the buffer to actually render using [[Flush]].

#end
Class Canvas

	#rem monkeydoc Creates a canvas that renders to an image.
	#end
	Method New( renderTarget:Image )
		Init( renderTarget,New GraphicsDevice )
		
		Local texture:=renderTarget.Texture
		
		BeginRender( New Recti( 0,0,texture.Rect.Size ),AffineMat3f.Translation( texture.Rect.Origin ) )
	End
	
	#rem monkeydoc @hidden Creates a canvas that renders to the backbuffer.
	#end	
	Method New( width:Int,height:Int )
		Init( Null,New GraphicsDevice( width,height ) )
	End

	#rem monkeydoc @hidden Resizes a canvas that renders to the backbuffer.
	#end	
	Method Resize( size:Vec2i )
		_device.Resize( size )
	End

	#rem monkeydoc @hidden
	#end	
	Method BeginRender( bounds:Recti,matrix:AffineMat3f )
	
		Flush()
		
		_rmatrixStack.Push( _rmatrix )
		_rboundsStack.Push( _rbounds )
		
		_rmatrix*=matrix
		_rbounds&=TransformRecti( bounds,_rmatrix )

		Viewport=bounds
		Scissor=New Recti( 0,0,bounds.Size )
		AmbientLight=Color.Black
		BlendMode=BlendMode.Alpha
		TextureFilter=graphics.TextureFilter.Mipmap
		PointSize=1
		LineWidth=1
		
		ClearMatrix()
	End
	
	#rem monkeydoc @hidden
	#end	
	Method EndRender()
	
		If _lighting EndLighting() 
		
		Flush()
		
		_rbounds=_rboundsStack.Pop()
		_rmatrix=_rmatrixStack.Pop()
	End
	
	#rem monkeydoc @hidden
	#end	
	Property Device:GraphicsDevice()
	
		Return _device
	End

	#rem monkeydoc The current render target.
	#end	
	Property RenderTarget:Image()
	
		Return _rtarget
	End
	
	#rem monkeydoc The current viewport.
	
	The viewport describes the rect within the render target that rendering occurs in.
	
	All rendering is relative to the top-left of the viewport, and is clipped to the intersection of the viewport and scissor rects.
	
	This property must not be modified if the canvas is in lighting mode.
		
	#end
	Property Viewport:Recti()
	
		Return _viewport
	
	Setter( viewport:Recti )
		DebugAssert( Not _lighting,"Canvas.Viewport property cannot be modified while lighting" )
		If _lighting return

		Flush()
			
		_viewport=viewport
		
		_dirty|=Dirty.Viewport|Dirty.Scissor
	End

	#rem monkeydoc The current scissor rect.
	
	The scissor rect is a rect within the viewport that can be used for additional clipping.
	
	Scissor rect coordinates are relative to the current viewport rect, but are not affected by the current drawing matrix.
	
	This property must not be modified if the canvas is in lighting mode.
		
	#end
	Property Scissor:Recti()
	
		Return _scissor
	
	Setter( scissor:Recti )
		DebugAssert( Not _lighting,"Canvas.Scissor property cannot be modified while lighting" )
		If _lighting return
	
		Flush()
	
		_scissor=scissor
		
		_dirty|=Dirty.Scissor
	End
	
	#rem monkeydoc Ambient light color for lighting mode.
	
	Sets the ambient light color for lighting.
	
	This property cannot be modified if the canvas is already in lighting mode.
		
	#end
	Property AmbientLight:Color()
	
		Return _ambientLight
	
	Setter( ambient:Color )
		DebugAssert( Not _lighting,"Canvas.AmbientLight property cannot be modified while lighting" )
		If _lighting return
	
		_ambientLight=ambient
	End
	
	#rem monkeydoc The current drawing blend mode.
	#end	
	Property BlendMode:BlendMode()
	
		Return _blendMode
	
	Setter( blendMode:BlendMode )
	
		_blendMode=blendMode
	End
	
	#rem monkeydoc The current texture filter.
	#end
	Property TextureFilter:TextureFilter()
	
		Return _textureFilter
	
	Setter( filter:TextureFilter )
	
		_textureFilter=filter
	End

	#rem monkeydoc Deprecated - use TextureFilter instead.
	
	Use TextureFilter instead.
	
	#end	
	Property TextureFilteringEnabled:Bool()
	
		Return TextureFilter=TextureFilter.Mipmap
	
	Setter( enabled:Bool )
	
		TextureFilter=enabled ? TextureFilter.Mipmap Else TextureFilter.Nearest

	End
	
	#rem monkeydoc The current point size for use with DrawPoint.
	#end
	Property PointSize:Float()
	
		Return _pointSize
	
	Setter( pointSize:Float )
	
		_pointSize=pointSize
	End

	#rem monkeydoc The current line width for use with DrawLine.
	#end	
	Property LineWidth:Float()

		Return _lineWidth
	
	Setter( lineWidth:Float )
	
		_lineWidth=lineWidth
	End
	
	#rem monkeydoc The current font for use with DrawText.
	
	Set font to null to use the default mojo font.
	
	#end	
	Property Font:Font()
	
		Return _font
	
	Setter( font:Font )
	
		If Not font font=_defaultFont
	
		_font=font
	End
	
	#rem monkeydoc The current drawing alpha level.
	
	Note that [[Alpha]] and the alpha component of [[Color]] are multiplied together to produce the final alpha value for rendering. 
	
	This allows you to use [[Alpha]] as a 'master' alpha level.

	#end	
	Property Alpha:Float()
	
		Return _alpha
		
	Setter( alpha:Float )
	
		_alpha=alpha
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End
	
	#rem monkeydoc The current drawing color.
	
	Note that [[Alpha]] and the alpha component of [[Color]] are multiplied together to produce the final alpha value for rendering. 
	
	This allows you to use [[Alpha]] as a 'master' alpha level.

	#end
	Property Color:Color()
	
		Return _color
	
	Setter( color:Color )
	
		_color=color
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End
	
	#rem monkeydoc The current drawing matrix.
	
	All coordinates passed to draw methods are multiplied by this matrix for rendering.
	
	#end
	Property Matrix:AffineMat3f()
	
		Return _matrix
	
	Setter( matrix:AffineMat3f )
	
		_matrix=matrix
		
		_tanvec=_matrix.i.Normalize()
	End
	
	#rem monkeydoc Pushes the drawing matrix onto the internal matrix stack.
	
	#end
	Method PushMatrix()
	
		_matrixStack.Push( _matrix )
	End
	
	#rem monkeydoc Pops the drawing matrix off the internal matrix stack.
	
	#end
	Method PopMatrix()
	
		_matrix=_matrixStack.Pop()
	End
	
	#rem monkeydoc Clears the internal matrix stack and sets the drawing matrix to the identitity matrix.
	#end
	Method ClearMatrix()
	
		_matrixStack.Clear()
		_matrix=New AffineMat3f
	End
	
	#rem monkeydoc Translates the drawing matrix.
	
	Translates the drawing matrix. This has the effect of translating all drawing coordinates by `tx` and `ty`.
	
	@param tx X translation.
	
	@param ty Y translation.
	
	@param tv X/Y translation.
	
	#end
	Method Translate( tx:Float,ty:Float )
	
		Matrix=Matrix.Translate( tx,ty )
	End
	
	Method Translate( tv:Vec2f )
	
		Matrix=Matrix.Translate( tv )
	End

	#rem monkeydoc Rotates the drawing matrix.
	
	Rotates the drawing matrix. This has the effect of rotating all drawing coordinates by the angle `rz'.
	
	@param rz Rotation angle in radians.
	
	#end
	Method Rotate( rz:Float )
	
		Matrix=Matrix.Rotate( rz )
	End

	#rem monkeydoc Scales the drawing matrix.
	
	Scales the drawing matrix. This has the effect of scaling all drawing coordinates by `sx` and `sy`.
	
	@param sx X scale factor.
	
	@param sy Y scale factor.
	
	@param sv X/Y scale factor.
	
	#end
	Method Scale( sx:Float,sy:Float )
	
		Matrix=Matrix.Scale( sx,sy )
	End
	
	Method Scale( sv:Vec2f )
	
		Matrix=Matrix.Scale( sv )
	End
	
	#rem monkeydoc Draws a point.
	
	Draws a point in the current [[Color]] using the current [[BlendMode]].
	
	The point coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
	
	@param x Point x coordinate.
	
	@param y Point y coordinate.
	
	@param v Point coordinates.
	
	#end
	Method DrawPoint( x:Float,y:Float )
		If _pointSize<=1
			AddDrawOp( _shader,_material,_blendMode,_textureFilter,1,1 )
			AddVertex( x+.5,y+.5,0,0 )
			Return
		Endif
		
		Local d:=_pointSize/2
		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
		AddVertex( x-d,y-d,0,0 )
		AddVertex( x+d,y-d,1,0 )
		AddVertex( x+d,y+d,1,1 )
		AddVertex( x-d,y+d,0,1 )
	End
	
	Method DrawPoint( v:Vec2f )
		DrawPoint( v.x,v.y )
	End
	
	#rem monkeydoc Draws a line.

	Draws a line in the current [[Color]] using the current [[BlendMode]].
	
	The line coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
	
	@param x0 X coordinate of first endpoint of the line.
	
	@param y0 Y coordinate of first endpoint of the line.
	
	@param x1 X coordinate of first endpoint of the line.
	
	@param y1 Y coordinate of first endpoint of the line.
	
	@param v0 First endpoint of the line.
	
	@param v1 Second endpoint of the line.
	
	#end
	Method DrawLine( x0:Float,y0:Float,x1:Float,y1:Float )

		If _lineWidth<=1
			AddDrawOp( _shader,_material,_blendMode,_textureFilter,2,1 )
			AddVertex( x0+.5,y0+.5,0,0 )
			AddVertex( x1+.5,y1+.5,1,1 )
			Return
		Endif
		
		Local dx:=y0-y1,dy:=x1-x0
		Local sc:=0.5/Sqrt( dx*dx+dy*dy )*_lineWidth
		dx*=sc;dy*=sc
		
		If _blendMode=BlendMode.Opaque
			AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
			AddVertex( x0-dx,y0-dy,0,0 )
			AddVertex( x0+dx,y0+dy,0,0 )
			AddVertex( x1+dx,y1+dy,0,0 )
			AddVertex( x1-dx,y1-dy,0,0 )
			Return
		End
		
		Local pmcolor:=_pmcolor
		
		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,2 )

		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,0,0 )
		_pmcolor=0
		AddVertex( x1-dx,y1-dy,0,0 )
		AddVertex( x0-dx,y0-dy,0,0 )

		AddVertex( x0+dx,y0+dy,0,0 )
		AddVertex( x1+dx,y1+dy,0,0 )
		_pmcolor=pmcolor
		AddVertex( x1,y1,0,0 )
		AddVertex( x0,y0,0,0 )
	End
	
	Method DrawLine( v0:Vec2f,v1:Vec2f )
		DrawLine( v0.x,v0.y,v1.x,v1.y )
	End
	
	#rem monkeydoc Draws a triangle.

	Draws a triangle in the current [[Color]] using the current [[BlendMode]].
	
	The triangle vertex coordinates are also transform by the current [[Matrix]].

	#End
	Method DrawTriangle( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float )
		AddDrawOp( _shader,_material,_blendMode,_textureFilter,3,1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
	End
	
	Method DrawTriangle( v0:Vec2f,v1:Vec2f,v2:Vec2f )
		DrawTriangle( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y )
	End

	#rem monkeydoc Draws a quad.

	Draws a quad in the current [[Color]] using the current [[BlendMode]].
	
	The quad vertex coordinates are also transform by the current [[Matrix]].

	#end
	Method DrawQuad( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float,x3:Float,y3:Float )
		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
		AddVertex( x3,y3,0,1 )
	End

	Method DrawQuad( v0:Vec2f,v1:Vec2f,v2:Vec2f,v3:Vec2f )
		DrawQuad( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y,v3.x,v3.y )
	End

	#rem monkeydoc Draws a rectangle.

	Draws a rectangle in the current [[Color]] using the current [[BlendMode]].
	
	The rectangle vertex coordinates are also transform by the current [[Matrix]].

	#end
	Method DrawRect( x:Float,y:Float,w:Float,h:Float )
	
		Local x0:=x,y0:=y,x1:=x+w,y1:=y+h
		
		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
		
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y0,1,0 )
		AddVertex( x1,y1,1,1 )
		AddVertex( x0,y1,0,1 )
	End
	
	Method DrawRect( rect:Rectf )
		DrawRect( rect.X,rect.Y,rect.Width,rect.Height )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image )
		Local tc:=srcImage.TexCoords
		AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,srcImage.TextureFilter,4,1 )
		AddVertex( rect.min.x,rect.min.y,tc.min.x,tc.min.y )
		AddVertex( rect.max.x,rect.min.y,tc.max.x,tc.min.y )
		AddVertex( rect.max.x,rect.max.y,tc.max.x,tc.max.y )
		AddVertex( rect.min.x,rect.max.y,tc.min.x,tc.max.y )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image )
		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image,srcRect:Recti )
		Local s0:=Float(srcImage.Rect.min.x+srcRect.min.x)/srcImage.Texture.Width
		Local t0:=Float(srcImage.Rect.min.y+srcRect.min.y)/srcImage.Texture.Height
		Local s1:=Float(srcImage.Rect.min.x+srcRect.max.x)/srcImage.Texture.Width
		Local t1:=Float(srcImage.Rect.min.y+srcRect.max.y)/srcImage.Texture.Height
		AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,srcImage.TextureFilter,4,1 )
		AddVertex( rect.min.x,rect.min.y,s0,t0 )
		AddVertex( rect.max.x,rect.min.y,s1,t0 )
		AddVertex( rect.max.x,rect.max.y,s1,t1 )
		AddVertex( rect.min.x,rect.max.y,s0,t1 )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int )
		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+width,srcY+height ) )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int,srcWidth:Int,srcHeight:Int )
		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+srcWidth,srcY+srcHeight ) )
	End
	
	#rem monkeydoc Draws an oval.

	Draws an oval in the current [[Color]] using the current [[BlendMode]].
	
	The oval vertex coordinates are also transform by the current [[Matrix]].

	@param x Top left x coordinate for the oval.

	@param y Top left y coordinate for the oval.

	@param width Width of the oval.

	@param height Height of the oval.

	#end
	Method DrawOval( x:Float,y:Float,width:Float,height:Float )
		Local xr:=width/2.0,yr:=height/2.0
		
		Local dx_x:=xr*_matrix.i.x
		Local dx_y:=xr*_matrix.i.y
		Local dy_x:=yr*_matrix.j.x
		Local dy_y:=yr*_matrix.j.y
		Local dx:=Sqrt( dx_x*dx_x+dx_y*dx_y )
		Local dy:=Sqrt( dy_x*dy_x+dy_y*dy_y )

		Local n:=Max( Int( dx+dy ),12 ) & ~3
		
		Local x0:=x+xr,y0:=y+yr
		
		AddDrawOp( _shader,_material,_blendMode,_textureFilter,n,1 )
		
		For Local i:=0 Until n
			Local th:=i*Pi*2/n
			Local px:=x0+Cos( th ) * xr
			Local py:=y0+Sin( th ) * yr
			AddVertex( px,py,0,0 )
		Next
	End
	
	#rem monkeydoc Draws an ellipse.

	Draws an ellipse in the current [[Color]] using the current [[BlendMode]].
	
	The ellipse is also transformed by the current [[Matrix]].

	@param x Center x coordinate for the ellipse.

	@param y Center y coordinate for the ellipse.

	@param xRadius X axis radius for the ellipse.

	@param yRadius Y axis radius for the ellipse.

	#end
	Method DrawEllipse( x:Float,y:Float,xRadius:Float,yRadius:Float )
		DrawOval( x-xRadius,y-yRadius,xRadius*2,yRadius*2 )
	End
	
	#rem monkeydoc Draws a circle.

	Draws a circle in the current [[Color]] using the current [[BlendMode]] and transformed by the current [[Matrix]].

	@param x Center x coordinate for the circle.

	@param y Center y coordinate for the circle.

	@param radius The circle radius.

	#end
	Method DrawCircle( x:Float,y:Float,radius:Float )
		DrawOval( x-radius,y-radius,radius*2,radius*2 )
	End

	#rem monkeydoc Draws a polygon.

	Draws a polygon using the current [[Color]], [[BlendMode]] and [[Matrix]].

	@param vertices Array of x/y vertex coordinate pairs.

	#end
	Method DrawPoly( vertices:Float[] )
		Local order:=vertices.Length/2
		DebugAssert( order>0,"Invalid polygon" )
		
		AddDrawOp( _shader,_material,_blendMode,_textureFilter,order,1 )
		
		For Local i:=0 Until order*2 Step 2
			AddVertex( vertices[i],vertices[i+1],0,0 )
		Next
	End
	
	#rem monkeydoc Draws a sequence of polygons.

	Draws a sequence of polygons using the current [[Color]], [[BlendMode]] and [[Matrix]].

	@param order The type of polygon: 1=points, 2=lines, 3=triangles, 4=quads, >4=n-gons.

	@param count The number of polygons.
	
	@param vertices Array of x/y vertex coordinate pairs.
	
	#end
	Method DrawPolys( order:Int,count:Int,vertices:Float[] )
		DebugAssert( order>0 And count>0 And order*count<=vertices.Length,"Invalid polyon" )

		AddDrawOp( _shader,_material,_blendMode,_textureFilter,order,count )
		
		For Local i:=0 Until order*count*2 Step 2
			AddVertex( vertices[i],vertices[i+1],0,0 )
		Next
	End
	
	#rem monkeydoc Draws a sequence of primtives.

	Draws a sequence of convex primtives using the current [[Color]], [[BlendMode]] and [[Matrix]].
	
	@param order The type of primitive: 1=points, 2=lines, 3=triangles, 4=quads, >4=n-gons.
	
	@param count The number of primitives to draw.
	
	@param vertices Pointer to the first vertex x,y pair.
	
	@param verticesPitch Number of bytes from one vertex x,y pair to the next. Set to 8 for 'tightly packed' vertices.
	
	@param texCoords Pointer to the first texCoord s,t pair. This can be null.
	
	@param texCoordsPitch Number of bytes from one texCoord s,y to the next. Set to 8 for 'tightly packed' texCoords.
	
	@param colors Pointer to the first RGBA uint color value. This can be null.
	
	@param colorsPitch Number of bytes from one RGBA color to the next. Set to 4 for 'tightly packed' colors.
	
	@param image Source image for rendering. This can be null.
	
	@param indices Pointer to sequence of integer indices for indexed drawing. This can by null for non-indexed drawing.
	
	#end
	Method DrawPrimitives( order:Int,count:Int,vertices:Float Ptr,verticesPitch:Int,texCoords:Float Ptr,texCoordsPitch:Int,colors:UInt Ptr,colorsPitch:Int,image:Image,indices:Int Ptr )
		DebugAssert( order>0 And count>0,"Illegal primitive" )

		If image
			AddDrawOp( image.Shader,image.Material,image.BlendMode,image.TextureFilter,order,count )
		Else		
			AddDrawOp( _shader,_material,_blendMode,_textureFilter,order,count )
		Endif
		
		Local n:=order*count
		
		If indices
			If texCoords And colors
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( texCoords )+j*colorsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
				Next
			Else If texCoords
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1] )
				Next
			Else If colors
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( texCoords )+j*colorsPitch )
					AddVertex( vp[0],vp[1],0,0,cp[0] )
				Next
			Else
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					AddVertex( vp[0],vp[1],0,0 )
				Next
			Endif
		Else
			If texCoords And colors
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( texCoords )+i*colorsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
				Next
			Else If texCoords
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1] )
				Next
			Else If colors
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( texCoords )+i*colorsPitch )
					AddVertex( vp[0],vp[1],0,0,cp[0] )
				Next
			Else
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					AddVertex( vp[0],vp[1],0,0 )
				Next
			Endif
		Endif
	End
	
	#rem monkeydoc Draws an image.

	Draws an image using the current [[Color]], [[BlendMode]] and [[Matrix]].

	@param tx X coordinate to draw image at.

	@param ty Y coordinate to draw image at.

	@param tv X/Y coordinates to draw image at.

	@param rz Rotation angle, in radians, for drawing.

	@param sx X axis scale factor for drawing.

	@param sy Y axis scale factor for drawing.

	@param sv X/Y scale factor for drawing.
 
	#end	
	Method DrawImage( image:Image,tx:Float,ty:Float )
	
		Local vs:=image.Vertices
		Local ts:=image.TexCoords
		
		AddDrawOp( image.Shader,image.Material,image.BlendMode,image.TextureFilter,4,1 )
		
		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
		
		If _lighting And image.ShadowCaster
			AddShadowCaster( image.ShadowCaster,tx,ty )
		Endif
	End
	
	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		DrawImage( image,0,0 )
		Matrix=matrix
	End

	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		DrawImage( image,0,0 )
		Matrix=matrix
	End

	Method DrawImage( image:Image,tv:Vec2f )
		DrawImage( image,tv.x,tv.y )
	End
	
	Method DrawImage( image:Image,tv:Vec2f,rz:Float )
		DrawImage( image,tv.x,tv.y,rz )
	End
	
	Method DrawImage( image:Image,tv:Vec2f,rz:Float,sv:Vec2f )
		DrawImage( image,tv.x,tv.y,rz,sv.x,sv.y )
	End
	
	#rem monkeydoc Draws text.

	Draws text using the current [[Color]], [[BlendMode]] and [[Matrix]].

	@param text The text to draw.

	@param tx X coordinate to draw text at.

	@param ty Y coordinate to draw text at.

	@param handleX X handle for drawing.

	@param handleY Y handle for drawing.

	#end
	Method DrawText( text:String,tx:Float,ty:Float,handleX:Float=0,handleY:Float=0 )
	
		If Not text.Length Return
	
		tx-=_font.TextWidth( text ) * handleX
		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float,sy:Float
		Local tw:Float,th:Float
		
		Local i0:=0
		
		while i0<text.Length
		
			Local i1:=i0+1
			Local page:GlyphPage
			
			While i1<text.Length
			
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:=gpage.image
			sx=image.Rect.min.x;sy=image.Rect.min.y
			tw=image.Texture.Width;th=image.Texture.Height
			AddDrawOp( image.Shader,image.Material,image.BlendMode,image.TextureFilter,4,i1-i0 )
			
			For Local i:=i0 Until i1
			
				Local g:=_font.GetGlyph( text[i] )
			
				Local s0:=Float(g.rect.min.x+sx)/tw
				Local t0:=Float(g.rect.min.y+sy)/th
				Local s1:=Float(g.rect.max.x+sx)/tw
				Local t1:=Float(g.rect.max.y+sy)/th
				
				Local x0:=Round( tx+g.offset.x )
				Local y0:=Round( ty+g.offset.y )
				Local x1:=x0+g.rect.Width
				Local y1:=y0+g.rect.Height
	
				AddVertex( x0,y0,s0,t0 )
				AddVertex( x1,y0,s1,t0 )
				AddVertex( x1,y1,s1,t1 )
				AddVertex( x0,y1,s0,t1 )
				
				tx+=g.advance
			Next
			
			gpage=page
			
			i0=i1
		Wend

	End
	
	#rem monkeydoc Adds a light to the canvas.
	
	This method must only be called while the canvas is in lighting mode, ie: between calls to [[BeginLighting]] and [[EndLighting]].
	
	#end
	Method AddLight( light:Image,tx:Float,ty:Float )
		DebugAssert( _lighting,"Canvas.AddLight() can only be used while lighting" )
		If Not _lighting Return
		
		Local lx:=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		Local ly:=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		
		_vp=_lightVB.AddVertices( 4 )
		If Not _vp Return

		Local op:=New LightOp
		op.light=light
		op.lightPos=New Vec2f( lx,ly )
		op.textureFilter=light.TextureFilter<>TextureFilter.None ? light.TextureFilter Else _textureFilter
		op.primOffset=_lightVB.Length-4
		_lightOps.Push( op )
		
		Local vs:=light.Vertices
		Local ts:=light.TexCoords
		
		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y,lx,ly,_pmcolor )
		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y,lx,ly,_pmcolor )
		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y,lx,ly,_pmcolor )
		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y,lx,ly,_pmcolor )
	End
	
	Method AddLight( light:Image,tx:Float,ty:Float,rz:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		AddLight( light,0,0 )
		Matrix=matrix
	End
	
	Method AddLight( light:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		AddLight( light,0,0 )
		Matrix=matrix
	End
	
	Method AddLight( light:Image,tv:Vec2f )
		AddLight( light,tv.x,tv.y )
	End
	
	Method AddLight( light:Image,tv:Vec2f,rz:Float )
		AddLight( light,tv.x,tv.y,rz )
	End
	
	Method AddLight( light:Image,tv:Vec2f,rz:Float,sv:Vec2f )
		AddLight( light,tv.x,tv.y,rz,sv.x,sv.y )
	End
	
	#rem monkeydoc Adds a shadow caster to the canvas.
	
	This method must only be called while the canvas is in lighting mode, ie: between calls to [[BeginLighting]] and [[EndLighting]].
	
	#end
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float )
		DebugAssert( _lighting,"Canvas.AddShadowCaster() can only be used while lighting" )
		If Not _lighting Return
	
		Local op:=New ShadowOp
		op.caster=caster
		op.firstVert=_shadowVerts.Length
		_shadowOps.Push( op )
		
		Local tv:=New Vec2f( tx,ty )
		
		For Local sv:=Eachin caster.Vertices
			sv+=tv
			Local lv:=New Vec2f(
			_matrix.i.x * sv.x + _matrix.j.x * sv.y + _matrix.t.x,
			_matrix.i.y * sv.x + _matrix.j.y * sv.y + _matrix.t.y )
			_shadowVerts.Push( lv )
		Next
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float,rz:float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		AddShadowCaster( caster,0,0 )
		Matrix=matrix
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		AddShadowCaster( caster,0,0 )
		Matrix=matrix
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f )
		AddShadowCaster( caster,tv.x,tv.y )
	End

	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f,rz:Float )
		AddShadowCaster( caster,tv.x,tv.y,rz )
	End

	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f,rz:Float,sv:Vec2f )
		AddShadowCaster( caster,tv.x,tv.y,rz,sv.x,sv.y )
	End
	
	#rem monkeydoc Copies a pixmap from the rendertarget.

	This method must not be called while the canvas is in lighting mode.

	@param rect The rect to copy.

	#end
	Method CopyPixmap:Pixmap( rect:Recti )
		DebugAssert( Not _lighting,"Canvas.CopyPixmap() cannot be used while lighting" )
		If _lighting Return Null
	
		Flush()
		
		rect=TransformRecti( rect,_rmatrix ) & _rbounds
		
		Local pixmap:=_device.CopyPixmap( rect )
		
		Return pixmap
	End
	
	#rem monkeydoc Clears the viewport.
	
	Clears the current viewport to `color`.
	
	This method must not be called while the canvas is in lighting mode.

	@param color Color to clear the viewport to.
	
	#end
	Method Clear( color:Color )
		DebugAssert( Not _lighting,"Canvas.Clear() cannot be used while lighting" )
		If _lighting Return
		
		Flush()
			
		_device.Clear( color )
	End
	
	#rem monkeydoc Flushes drawing commands.
	
	Flushes any outstanding drawing commands in the draw buffer.
	
	This is only generally necessary if you are drawing to an image.
	
	#end
	Method Flush()
	
		Validate()
		
		If _drawOps.Empty Return
		
		'Render ambient
		'		
		RenderDrawOps( 0 )
		
		If _lighting

			'render diffuse gbuffer
			'
			_device.RenderTarget=_gbuffers[0]
			
			RenderDrawOps( 1 )
			
			'render normal gbuffer
			'
			_device.RenderTarget=_gbuffers[1]
			
			RenderDrawOps( 2 )

			'back to rendertarget
			'			
			_device.RenderTarget=_rtarget ? _rtarget.Texture Else Null
		
		Endif
		
		_drawVB.Clear()
		_drawOps.Clear()
		_drawOp=New DrawOp
	End
	
	#rem monkeydoc True if canvas is in lighting mode.
	#end
	Property IsLighting:Bool()
	
		Return _lighting
	End
	
	#rem monkeydoc Puts the canvas into lighting mode.
	
	While in lighting mode, you can add lights and shadow casters to the cavas using [[AddLight]] and [[AddShadowCaster]]. Lights and shadows
	are later rendered by calling [[EndLighting]].
	
	Each call to BeginLighting must be matched with a corresponding call to EndLighting.
	
	The following properties must not be modified while in lighting mode: [[Viewport]], [[Scissor]], [[AmbientLight]]. Attempting to
	modify these properties while in lighting mode will result in a runtime error in debug builds.
	
	The following methods must not be called in lighting mode: [[Clear]], [[BeginLighting]]. Attepting to call these methods while in
	lighting mode will result in a runtime error in debug builds.
	
	#end
	Method BeginLighting()
		DebugAssert( Not _lighting,"Already lighting" )
		If _lighting Return
		
		_lighting=True
		
		If Not _gbuffers[0]

			Local gbufferSize:=New Vec2i( 1920,1080 )
			Local gbufferScale:=New Vec2f( 1 )/Cast<Vec2f>( gbufferSize )
		
			_gbuffers[0]=New Texture( gbufferSize.x,gbufferSize.y,PixelFormat.RGBA32,TextureFlags.Dynamic )
			_gbuffers[1]=New Texture( gbufferSize.x,gbufferSize.y,PixelFormat.RGBA32,TextureFlags.Dynamic )

			_uniforms.SetVector( "mx2_GBufferScale",gbufferScale )
			_uniforms.SetTexture( "mx2_GBuffer0",_gbuffers[0] )
			_uniforms.SetTexture( "mx2_GBuffer1",_gbuffers[1] )
			
		Endif
		
		Validate()
		
		_uniforms.SetVector( "mx2_AmbientLight",_ambientLight )
		
		_device.RenderTarget=_gbuffers[0]
		_device.Clear( Color.Black )
			
		_device.RenderTarget=_gbuffers[1]
		_device.Clear( New Color( .5,.5,1 ) )
		
		_device.RenderTarget=_rtarget ? _rtarget.Texture Else Null
	End
	
	#rem monkeydoc Renders lighting and ends lighting mode.
	
	Renders any lights and shadows casters added to the canvas through calls to [[AddLight]] and [[AddShadowCaster]] and ends lighting mode.
	
	Any lights and shadow casters added to the canvas are also removed and must be added again later if you want to render them again.
	
	This method must be called while the canvas is in lighting mode.
	
	#end
	Method EndLighting()
		DebugAssert( _lighting,"Not lighting" )
		If Not _lighting Return
		
		Flush()
		
		RenderLighting()
	
		_lightVB.Clear()
		_lightOps.Clear()
		
		_shadowOps.Clear()
		_shadowVerts.Clear()
	
		_lighting=False
	End
	
	Private
	
	Enum Dirty
		GBuffer=1
		Viewport=2
		Scissor=4
	End
	
	Class DrawOp
		Field shader:Shader
		Field material:UniformBlock
		Field blendMode:BlendMode
		Field textureFilter:TextureFilter
		Field primOrder:Int
		Field primCount:Int
		Field primOffset:Int
	End
	
	Class LightOp
		Field light:Image
		Field lightPos:Vec2f
		Field textureFilter:TextureFilter
		Field primOrder:Int
		Field primOffset:Int
	End
	
	Class ShadowOp
		Field caster:ShadowCaster
		Field firstVert:Int
	End
	
	Global _quadIndices:IndexBuffer
	Global _defaultFont:Font
	Global _shadowVB:VertexBuffer

	Global _lighting:Bool=False
	Global _gbuffers:=New Texture[2]

	Field _rtarget:Image
	Field _device:GraphicsDevice
	Field _uniforms:UniformBlock
	
	Field _shader:Shader
	Field _material:UniformBlock
	
	Field _viewport:Recti
	Field _scissor:Recti
	Field _ambientLight:Color
	
	Field _blendMode:BlendMode
	Field _textureFilter:TextureFilter
	Field _font:Font
	Field _alpha:Float
	Field _color:Color
	Field _pmcolor:UInt=~0
	Field _pointSize:Float=1
	Field _lineWidth:Float=1
	Field _matrix:=New AffineMat3f
	Field _tanvec:Vec2f=New Vec2f( 1,0 )
	Field _matrixStack:=New Stack<AffineMat3f>
	
	Field _rmatrix:=New AffineMat3f
	Field _rbounds:=New Recti( 0,0,$40000000,$40000000 )
	Field _rmatrixStack:=New Stack<AffineMat3f>
	Field _rboundsStack:=New Stack<Recti>
	
	Field _dirty:Dirty
	Field _projMatrix:Mat4f
	Field _rviewport:Recti
	Field _rviewportClip:Vec2i
	Field _rscissor:Recti
	
	Field _vp:Vertex2f Ptr

	Field _drawVB:VertexBuffer
	Field _drawOps:=New Stack<DrawOp>
	Field _drawOp:=New DrawOp

	Field _lightVB:VertexBuffer
	Field _lightOps:=New Stack<LightOp>
	
	Field _shadowOps:=New Stack<ShadowOp>
	Field _shadowVerts:=New Stack<Vec2f>
	
	Const MaxVertices:=65536
	Const MaxShadowVertices:=16384
	Const MaxLights:=1024
	
	Function Init2()
		Global inited:=False
		If inited Return
		inited=True

		Local nquads:=MaxVertices/4
		_quadIndices=New IndexBuffer( nquads*6 )
		Local ip:=_quadIndices.AddIndices( nquads*6 )
		For Local i:=0 Until nquads*4 Step 4
			ip[0]=i
			ip[1]=i+1
			ip[2]=i+2
			ip[3]=i
			ip[4]=i+2
			ip[5]=i+3
			ip+=6
		Next
		
		_shadowVB=New VertexBuffer( MaxShadowVertices )

		_defaultFont=mojo.graphics.Font.Load( "font::DejaVuSans.ttf",16 )
	End
	
	Method Init( rtarget:Image,device:GraphicsDevice )
		Init2()
		
		_rtarget=rtarget
		_device=device

		_device.RenderTarget=_rtarget ? _rtarget.Texture Else Null
		
		_uniforms=New UniformBlock
		_device.SetUniformBlock( 0,_uniforms )

		_drawVB=New VertexBuffer( MaxVertices )
		_lightVB=New VertexBuffer( MaxLights*4 )
		_shadowVB=New VertexBuffer( 65536 )
		
		_device.IndexBuffer=_quadIndices

		_shader=Shader.GetShader( "null" )
		_material=New UniformBlock
		
		_viewport=New Recti( 0,0,640,480 )
		_ambientLight=Color.Black
		_blendMode=BlendMode.Alpha
		
		_font=_defaultFont
		
		_alpha=1
		_color=Color.White
		_pmcolor=$ffffffff
		
		_matrix=New AffineMat3f
	End

	'Vertices
	'
	#rem
	Method AddVertex( x:Float,y:Float,s0:Float,t0:Float,s1:Float,t1:Float,color:UInt )
		_vp->position.x=x
		_vp->position.y=y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color
		_vp+=1
	End
	#end

	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float,s1:Float,t1:Float,color:UInt )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color
		_vp+=1
	End

	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float,color:UInt )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=_tanvec.x
		_vp->texCoord1.y=_tanvec.y
		_vp->color=color
		_vp+=1
	End
	
	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=_tanvec.x
		_vp->texCoord1.y=_tanvec.y
		_vp->color=_pmcolor
		_vp+=1
	End
	
	'Drawing
	'	
	Method AddDrawOp( shader:Shader,material:UniformBlock,blendMode:BlendMode,textureFilter:TextureFilter,primOrder:int,primCount:Int )
	
		If _drawVB.Length+primCount*primOrder>_drawVB.Capacity
			Flush()
		Endif
		
		If blendMode=BlendMode.None blendMode=_blendMode
		
		If textureFilter=TextureFilter.None textureFilter=_textureFilter
		
		If shader<>_drawOp.shader Or material<>_drawOp.material Or blendMode<>_drawOp.blendMode Or textureFilter<>_drawOp.textureFilter Or primOrder<>_drawOp.primOrder
		
			'pad quads so primOffset always on a 4 vert boundary
			If primOrder=4 And _drawVB.Length & 3 _drawVB.AddVertices( 4-(_drawVB.Length&3) )
			
			_drawOp=New DrawOp
			_drawOp.shader=shader
			_drawOp.material=material
			_drawOp.blendMode=blendMode
			_drawOp.textureFilter=textureFilter
			_drawOp.primOrder=primOrder
			_drawOp.primCount=primCount
			_drawOp.primOffset=_drawVB.Length
			_drawOps.Push( _drawOp )
		Else
			_drawOp.primCount+=primCount
		Endif
		
		_vp=_drawVB.AddVertices( primOrder*primCount )
	End
	
	Method Validate()
	
		If _dirty & Dirty.Viewport

			Local tviewport:=TransformRecti( _viewport,_rmatrix )
			
			_rviewport=tviewport & _rbounds
			
			_rviewportClip=tviewport.Origin-_rviewport.Origin
	
			Local rmatrix:=New Mat4f
			rmatrix.i.x=_rmatrix.i.x
			rmatrix.j.y=_rmatrix.j.y
			rmatrix.t.x=_rviewportClip.x
			rmatrix.t.y=_rviewportClip.y
			
			If _rtarget
				_projMatrix=Mat4f.Ortho( 0,_rviewport.Width,0,_rviewport.Height,-1,1 ) * rmatrix
			Else
				_projMatrix=Mat4f.Ortho( 0,_rviewport.Width,_rviewport.Height,0,-1,1 ) * rmatrix
			Endif
			
			_uniforms.SetMatrix( "mx2_ModelViewProjectionMatrix",_projMatrix )
			
			_uniforms.SetVector( "mx2_ViewportOrigin",_rviewport.Origin )
			
			_uniforms.SetVector( "mx2_ViewportSize",_rviewport.Size )
	
			_uniforms.SetVector( "mx2_ViewportClip",_rviewportClip )
			
			_device.Viewport=_rviewport
		
		Endif
		
		If _dirty & Dirty.Scissor

			_rscissor=TransformRecti( _scissor+_viewport.Origin,_rmatrix ) & _rviewport
			
			_device.Scissor=_rscissor
		Endif
		
		_dirty=Null
		
	End
	
	Method RenderDrawOps( rpass:Int )
	
		_device.RenderPass=rpass
		
		_device.VertexBuffer=_drawVB
		
		Local rpassMask:=1 Shl rpass
		
		For Local op:=Eachin _drawOps
		
			Local shader:=op.shader
			If Not (shader.RenderPassMask & rpassMask) Continue
		
			_device.Shader=shader
			_device.BlendMode=op.blendMode
			_device.TextureFilter=op.textureFilter
			_device.SetUniformBlock( 1,op.material )

			Select op.primOrder
			Case 4
				_device.RenderIndexed( 3,op.primCount*2,op.primOffset/4*6 )
			Default
				_device.Render( op.primOrder,op.primCount,op.primOffset )
			End

'			_device.Render( op.primOrder,op.primCount,op.primOffset )

		Next
	End
	
	'Shadows
	'
	Method DrawShadows( lightOp:LightOp )
	
		Const EXTRUDE:=1024.0
		
		Local lv:=lightOp.lightPos

		_shadowVB.Clear()
		
		For Local op:=Eachin _shadowOps
		
			Local vert0:=op.firstVert
			Local nverts:=op.caster.Vertices.Length
			
			Local tv:=_shadowVerts[vert0+nverts-1]
			
			For Local iv:=0 Until nverts
			
				Local pv:=tv
				tv=_shadowVerts[vert0+iv]
				
				Local dv:=tv-pv
				Local nv:=dv.Normal.Normalize()
				Local pd:=-pv.Dot( nv )
				
				Local d:=lv.Dot( nv )+pd
				If d<0 Continue
				
				Local tp:=_shadowVB.AddVertices( 9 )
				If Not tp Exit
			
				Local hv:=(pv+tv)/2
				
				Local pv2:=pv + (pv-lv).Normalize() * EXTRUDE
				Local tv2:=tv + (tv-lv).Normalize() * EXTRUDE
				Local hv2:=hv + (hv-lv).Normalize() * EXTRUDE
				
				tp[0].position=tv;tp[1].position=tv2;tp[2].position=hv2
				tp[3].position=tv;tp[4].position=hv2;tp[5].position=pv
				tp[6].position=hv2;tp[7].position=pv2;tp[8].position=pv
				
				tp+=9
			Next
			
		Next
		
	End
		
	'Lighting
	'
	Method RenderLighting()
	
		_device.BlendMode=BlendMode.Additive
		_device.VertexBuffer=_lightVB
		
		For Local op:=Eachin _lightOps
		
			DrawShadows( op )
			
			If _shadowVB.Length
#rem
				_device.RenderTarget=Null
				_device.BlendMode=BlendMode.Opaque
				_device.ColorMask=ColorMask.All
				_device.VertexBuffer=_shadowVB
				_device.Shader=Shader.GetShader( "shadow" )
				_device.Clear( Color.Blue )
				_device.Render( 3,_shadowVB.Length/3,0 )
				Continue
#end				
				_device.RenderPass=4
				_device.RenderTarget=_gbuffers[0]
				_device.BlendMode=BlendMode.Opaque
				_device.ColorMask=ColorMask.Alpha
				_device.VertexBuffer=_shadowVB
				_device.Shader=Shader.GetShader( "shadow" )

				_device.Clear( Color.White )
				_device.Render( 3,_shadowVB.Length/3,0 )
				
				_device.RenderPass=5				
				_device.RenderTarget=_rtarget ? _rtarget.Texture Else Null
				_device.BlendMode=BlendMode.Additive
				_device.ColorMask=ColorMask.All
				_device.VertexBuffer=_lightVB
				
			Else
				_device.RenderPass=4
			Endif
			
			Local light:=op.light
			
			_device.Shader=light.Shader
			_device.TextureFilter=op.textureFilter
			_device.SetUniformBlock( 1,light.Material )
			
			_device.Render( 4,1,op.primOffset )
		
		Next
		
	End

End
