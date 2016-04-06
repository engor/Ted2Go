
Namespace std.geom

Alias Vec2f:Vec2<Float>

Struct Vec2<T>

	Field x:T
	Field y:T
	
	Method New()
	End
	
'	Method New( v:Vec2 )
'		x=v.x;y=v.y
'	End
	
	Method New( x:T,y:T )
		Self.x=x
		Self.y=y
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
	
	Operator-:Vec2()
		Return New Vec2( -x,-y )
	End
	
	Operator*:Vec2( v:Vec2 )
		Return New Vec2( x*v.x,y*v.y )
	End
	
	Operator/:Vec2( v:Vec2 )
		Return New Vec2( x/v.x,y/v.y )
	End
	
	Operator+:Vec2( v:Vec2 )
		Return New Vec2( x+v.x,y+v.y )
	End
	
	Operator-:Vec2( v:Vec2 )
		Return New Vec2( x-v.x,y-v.y )
	End
	
	Operator*:Vec2( s:Double )
		Return New Vec2( x*s,y*s )
	End
	
	Operator/:Vec2( s:Double )
		Return New Vec2( x/s,y/s )
	End
	
	Operator+:Vec2( s:T )
		Return New Vec2( x+s,y+s )
	End
	
	Operator-:Vec2( s:T )
		Return New Vec2( x-s,y-s )
	End

	Property Length:Double()
		Return Sqrt( x*x+y*y )
	End
	
	Method Dot:Double( v:Vec2 )
		Return x*v.x+y*v.y
	End
	
	Method Normalize:Vec2()
		Return Self/Length
	End
	
	Method Blend:Vec2( v:Vec2,alpha:Double )
		Return New Vec2( (v.x-x)*alpha+x,(v.y-y)*alpha+y )
	End
	
	Method ToString:String()
		Return "Vec2("+x+","+y+")"
	End

End
