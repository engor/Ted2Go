
Namespace mojo2

Using std

Using mojo2.math3d

Private

Class LayerData
	Field matrix:=Mat4New()
	Field invMatrix:=Mat4New()
	Field drawList:DrawList
End

Global lvector:=New Float[4]
Global tvector:=New Float[4]

Public

Interface ILight

	Method LightMatrix:Float[]()
	Method LightType:Int()
	Method LightColor:Float[]()
	Method LightRange:Float()
	Method LightImage:Image()
	
End

Interface ILayer

	Method LayerMatrix:Float[]()
	Method LayerFogColor:Float[]()
	Method LayerLightMaskImage:Image()
	Method EnumLayerLights:Void( lights:Stack<ILight> )
	Method OnRenderLayer:Void( drawLists:Stack<DrawList> )
	
End

Class Renderer

	Method SetClearMode:Void( clearMode:Int )
		_clearMode=clearMode
	End
	
	Method SetClearColor:Void( clearColor:Float[] )
		_clearColor=clearColor
	End
	
	Method SetAmbientLight:Void( ambientLight:Float[] )
		_ambientLight=ambientLight
	End
	
	Method SetCameraMatrix:Void( cameraMatrix:Float[] )
		_cameraMatrix=cameraMatrix
	End
	
	Property Layers:Stack<ILayer>()
		Return _layers
	End
	
	Method Render:Void( dcanvas:Canvas )
	
		Local canvas:=dcanvas
		
		_canvas=canvas
		
		_viewport=canvas.Viewport
		
		_projectionMatrix=canvas.ProjectionMatrix
	
		Local vwidth:=_viewport[2],vheight:=_viewport[3]
		
		If vwidth<=0 Or vheight<=0 Return
		
'		Print vwidth+","+vheight
		
		Mat4Inverse( _projectionMatrix,_invProjMatrix )

		lvector[0]=-1;lvector[1]=-1;lvector[2]=-1;lvector[3]=1
		Mat4Project( _invProjMatrix,lvector,tvector )
		Local px0:=tvector[0],py0:=tvector[1]

		lvector[0]=1;lvector[1]=1;lvector[2]=-1;lvector[3]=1
		Mat4Project( _invProjMatrix,lvector,tvector )
		Local px1:=tvector[0],py1:=tvector[1]
		
		Local twidth:=Int( px1-px0 ),theight:=Int( py1-py0 )
		
		If _timage=Null Or _timage.Width<>twidth Or _timage.Height<>theight
			If _timage _timage.Discard()
			_timage=New Image( twidth,theight,0,0 )
		End
		
		If _timage2=Null Or _timage2.Width<>twidth Or _timage2.Height<>theight
			If _timage2 _timage2.Discard()
			_timage2=New Image( twidth,theight,0,0 )
		End
		
		If Not _tcanvas
			_tcanvas=New Canvas( _timage )
		Endif
		
		_tcanvas.SetProjectionMatrix( _projectionMatrix )
		_tcanvas.SetViewport( 0,0,twidth,theight )
		_tcanvas.SetScissor( 0,0,twidth,theight )

		Mat4Inverse( _cameraMatrix,_viewMatrix )
		
		Local invProj:=False
		
		'Clear!
		Select _clearMode
		Case 1
			_canvas.Clear( _clearColor[0],_clearColor[1],_clearColor[2],_clearColor[3] )
		End
		
		For Local layerId:=0 Until _layers.Length
		
			Local layer:=_layers.Get( layerId )
			Local fog:=layer.LayerFogColor()
			
			Local layerMatrix:=layer.LayerMatrix()
			Mat4Inverse( layerMatrix,_invLayerMatrix )
			
			_drawLists.Clear()
			layer.OnRenderLayer( _drawLists )
			
			Local lights:=New Stack<ILight>
			layer.EnumLayerLights( lights )
			
			If Not lights.Length
			
				For Local i:=0 Until 4
					canvas.SetLightType( i,0 )
				Next
			
				canvas.SetShadowMap( Null )'_timage )
				canvas.SetViewMatrix( _viewMatrix )
				canvas.SetModelMatrix( layerMatrix )
				canvas.SetAmbientLight( _ambientLight[0],_ambientLight[1],_ambientLight[2],1 )
				canvas.SetFogColor( fog[0],fog[1],fog[2],fog[3] )
				
				canvas.SetColor( 1,1,1,1 )
				For Local i:=0 Until _drawLists.Length
					canvas.RenderDrawList( _drawLists.Get( i ) )
				End
				canvas.Flush()
				
				Continue
				
			Endif
			
			Local light0:=0
			
			Repeat
			
				Local numLights:=Min(lights.Length-light0,4)
				
				'Shadows
				'		
				canvas=_tcanvas
				canvas.SetRenderTarget( _timage )
				canvas.SetShadowMap( Null )
				canvas.SetViewMatrix( _viewMatrix )
				canvas.SetModelMatrix( layerMatrix )
				canvas.SetAmbientLight( 0,0,0,0 )
				canvas.SetFogColor( 0,0,0,0 )
				
				canvas.Clear( 1,1,1,1 )
				canvas.SetBlendMode( 0 )
				canvas.SetColor( 0,0,0,0 )

				canvas.SetDefaultMaterial( Shader.ShadowShader().DefaultMaterial )
				
				For Local i:=0 Until numLights
				
					Local light:=lights.Get(light0+i)
					
					Local matrix:=light.LightMatrix()
					
					Vec4Copy( matrix,lvector,12,0 )
					Mat4Transform( _invLayerMatrix,lvector,tvector )
					Local lightx:=tvector[0],lighty:=tvector[1]
					
					canvas.SetColorMask( i=0,i=1,i=2,i=3 )
					
					Local image:=light.LightImage()
					If image
						canvas.Clear( 0,0,0,0 )
						canvas.PushMatrix()
						canvas.SetMatrix( matrix[0],matrix[1],matrix[4],matrix[5],lightx,lighty )
						canvas.DrawImage( image )
						canvas.PopMatrix()
					Endif
		
					For Local j:=0 Until _drawLists.Length
						canvas.DrawShadows( lightx,lighty,_drawLists.Get( j ) )
					Next
				
				Next
				
				canvas.SetDefaultMaterial( Shader.FastShader().DefaultMaterial )
				canvas.SetColorMask( True,True,True,True )
				canvas.Flush()
				
				#rem
				'LightMask
				'
				Local lightMask:=layer.LayerLightMaskImage()
				If lightMask
				
					If Not invProj
						Mat4Inverse( _projectionMatrix,_invProjMatrix )
						Mat4Project( _invProjMatrix,[-1.0,-1.0,-1.0,1.0],_ptl )
						Mat4Project( _invProjMatrix,[ 1.0, 1.0,-1.0,1.0],_pbr )
					Endif
					
					Local fwidth:=(_pbr[0]-_ptl[0])
					Local fheight:=(_pbr[1]-_ptl[1])
					
					If _projectionMatrix[15]=0
						Local scz:=(layerMatrix[14]-_cameraMatrix[14])/_ptl[2]
						fwidth*=scz
						fheight*=scz
					Endif
				
					canvas.SetProjection2d( 0,fwidth,0,fheight )
					canvas.SetViewMatrix( Mat4Identity )
					canvas.SetModelMatrix( Mat4Identity )
					
					'test...
					'canvas.SetBlendMode 0
					'canvas.SetColor 1,1,1,1
					'canvas.DrawRect 0,0,fwidth,fheight
					
					canvas.SetBlendMode( 4 )
					
					Local w:Float=lightMask.Width
					Local h:Float=lightMask.Height
					Local x:=-w
					While x<fwidth+w
						Local y:=-h
						While y<fheight+h
							canvas.DrawImage( lightMask,x,y )
							y+=h
						Wend
						x+=w
					Wend
					
					canvas.Flush()
					
					canvas.SetProjectionMatrix( _projectionMatrix )
					
				Endif
				#end
				
				'Enable lights
				'
				canvas=_canvas
				If light0 canvas=_tcanvas
				
				For Local i:=0 Until numLights
				
					Local light:=lights.Get(light0+i)
					
					Local c:=light.LightColor()
					Local m:=light.LightMatrix()
					
					canvas.SetLightType( i,1 )
					canvas.SetLightColor( i,c[0],c[1],c[2],c[3] )
					canvas.SetLightPosition( i,m[12],m[13],m[14] )
					canvas.SetLightRange( i,light.LightRange() )
				Next
				For Local i:=numLights Until 4
					canvas.SetLightType( i,0 )
				Next
				
				If light0=0	'first pass?
				
					'render lights+ambient to output
					'
					canvas=_canvas
					canvas.SetShadowMap( _timage )
					canvas.SetViewMatrix( _viewMatrix )
					canvas.SetModelMatrix( layerMatrix )
					canvas.SetAmbientLight( _ambientLight[0],_ambientLight[1],_ambientLight[2],1 )
					canvas.SetFogColor( fog[0],fog[1],fog[2],fog[3] )
					
					canvas.SetColor( 1,1,1,1 )
					For Local i:=0 Until _drawLists.Length
						canvas.RenderDrawList( _drawLists.Get( i ) )
					End
					
					canvas.Flush()
					
				Else
				
					'render lights only
					'
					canvas=_tcanvas
					canvas.SetRenderTarget( _timage2 )
					canvas.SetShadowMap( _timage )
					canvas.SetViewMatrix( _viewMatrix )
					canvas.SetModelMatrix( layerMatrix )
					canvas.SetAmbientLight( 0,0,0,0 )
					canvas.SetFogColor( 0,0,0,fog[3] )
					
					canvas.Clear( 0,0,0,1 )
					canvas.SetColor( 1,1,1,1 )
					For Local i:=0 Until _drawLists.Length
						canvas.RenderDrawList( _drawLists.Get( i ) )
					End
					canvas.Flush()
					
					'add light to output
					'
					canvas=_canvas
					canvas.SetShadowMap( Null )
					canvas.SetViewMatrix( Mat4Identity )
					canvas.SetModelMatrix( Mat4Identity )
					canvas.SetAmbientLight( 0,0,0,1 )
					canvas.SetFogColor( 0,0,0,0 )
					
					canvas.SetBlendMode( 2 )
					canvas.SetColor( 1,1,1,1 )
					canvas.DrawImage( _timage2 )
'					canvas.DrawRect( 0,0,twidth,theight,_timage2,0,0,twidth,theight )

					canvas.Flush()
					
				Endif
				
				light0+=4
			
			Until light0>=lights.Length
			
		Next
	End
	
	Protected
	
	Field _canvas:Canvas
	Field _tcanvas:Canvas
	
	Field _timage:Image		'tmp lighting texture
	Field _timage2:Image	'another tmp lighting image for >4 lights

	Field _viewport:=New Int[]( 0,0,640,480 )
	Field _clearMode:Int=1
	Field _clearColor:=New Float[]( 0.0,0.0,0.0,1.0 )
	Field _ambientLight:=New Float[]( 1.0,1.0,1.0,1.0 )
	Field _projectionMatrix:=Mat4New()
	Field _cameraMatrix:=Mat4New()
	Field _viewMatrix:=Mat4New()
	
	Field _layers:=New Stack<ILayer>
	
	Field _invLayerMatrix:=New Float[16]
	Field _drawLists:=New Stack<DrawList>
	
	Field _invProjMatrix:=New Float[16]
	Field _ptl:=New Float[4]
	Field _pbr:=New Float[4]
		
End
