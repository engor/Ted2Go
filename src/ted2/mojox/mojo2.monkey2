

Class Image

	Property Vertices:Vertex2f[]()
	
End

Class Light

	Property Color:Color()
	
End

Class Vertex2f
	Field x:Float
	Field y:Float
	Field u:Float
	Field v:Float
	Field tx:Float
	Field ty:Float
	Field rgba:UInt
End

Enum BlendMode
	Opaque
	Alpha
	Multiply
	Additive
End

Class RenderOp
	Field shader:Shader
	Field material:Material
	Field blendMode:BlendMode
	Field geom:Int
	Field first:Int
	Field count:Int
End

Class DrawList

	Property Color:Color()
	
	Property Matrix:AffineMat3f()
	
	Property BlendMode:BlendMode()
	
	Property DefaultMaterial:Material()
	
	Method AddLight( light:Light )
	
	Method AddShadowCaster( shadowCaster:ShadowCaster )
	
	Method DrawImage( image:Image )
	
	Method DrawCircle( tx:Float,ty:Float,radius:Float,material:Material=Null )
	
	Method DrawPolygons( vertices:Vertex2f,geom:Int,count:Int,material:Material=Null )

	Private
	
	Field _color:Color
	Field _matrix:Matrix
	Field _lights:=New Stack<Light>
	Field _casters:=New Stack<ShadowCaster>
	Field _vertices:=New Stack<Vertex2f>
	Field _renderOps:=New Stack<RenderOp>
	
	Field _currentOp:RenderOp
	
	Method AddRenderOp:Int( material:Material,geom:Int,count:Int )
		If _currentOp.material=material And _currentOp.geom=geom And _currentOp.blendMode=_blendMode
			_currentOp.count+=count
			Local i:=_vertices.Length
			_vertices.Resize( i+count )
			Return i
		End
		_currentOp=New RenderOp
		_currentOp.blendMode=_blendMode
		_currentOp.material=material
		_currentOp.geom=geom
		_currentOp.first=_vertices.Length
		_currentOp.count=count*geom
		_vertices.Resize( _currentOp.first+_currentOp.count )
		Return _currentOp.first
	End
	
End
