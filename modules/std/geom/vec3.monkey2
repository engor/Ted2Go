
Namespace std.geom

#rem monkeydoc @hidden
#end
Alias Vec3f:Vec3<Float>

#rem monkeydoc @hidden
#end
Struct Vec3<T>

	Field x:T
	Field y:T
	Field z:T
	
	Method New()
	End
	
	Method New( t:T )
		x=t;y=t;z=t
	End
	
	Method New( x:T,y:T,z:T )
		Self.x=x;Self.y=y;Self.z=z
	End
	
	Method New( v:Vec2<T>,z:T )
		Self.x=v.x;Self.y=v.y;Self.z=z
	End
	
	Property X:T()
		Return x
	Setter( x:T )
		Self.x=x
	End
	
	Property Y:T()
		Return y
	Setter( y:T )
		Self.y=y
	End
	
	Property Z:T()
		Return z
	Setter( z:T )
		Self.z=z
	End
	
	Operator-:Vec3()
		Return New Vec3( -x,-y,-z )
	End
	
	Operator*:Vec3( v:Vec3 )
		Return New Vec3( x*v.x,y*v.y,z*v.z )
	End
	
	Operator/:Vec3( v:Vec3 )
		Return New Vec3( x/v.x,y/v.y,z/v.z )
	End
	
	Operator+:Vec3( v:Vec3 )
		Return New Vec3( x+v.x,y+v.y,z+v.z )
	End
	
	Operator-:Vec3( v:Vec3 )
		Return New Vec3( x-v.x,y-v.y,z-v.z )
	End
	
	Operator*:Vec3( s:Double )
		Return New Vec3( x*s,y*s,z*s )
	End
	
	Operator/:Vec3( s:Double )
		Return New Vec3( x/s,y/s,z/s )
	End
	
	Operator+:Vec3( s:T )
		Return New Vec3( x+s,y+s,z+s )
	End
	
	Operator-:Vec3( s:T )
		Return New Vec3( x-s,y-s,z-s )
	End
	
	Property Length:Double()
		Return Sqrt( x*x+y*y+z*z )
	End

	Method Dot:Double( v:Vec3 )
		Return x*v.x+y*v.y+z*v.z
	End
	
	Method Normalize:Vec3()
		Return Self/Length
	End
	
	Method Blend:Vec3( v:Vec3,alpha:Double )
		Return New Vec3( (v.x-x)*alpha+x,(v.y-y)*alpha+y,(v.z-z)*alpha+z )
	End
	
	Method ToString:String()
		Return "Vec3("+x+","+y+","+z+")"
	End

End
