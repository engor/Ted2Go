
Namespace std.geom

#rem monkeydoc Convenience type alias for Vec2\<Int\>.
#end
Alias Vec2i:Vec2<Int>

#rem monkeydoc Convenience type alias for Vec2\<Float\>.
#end
Alias Vec2f:Vec2<Float>

#rem monkeydoc The Vec2 type provides support for 2 component vectors.
#end
Struct Vec2<T>

	#rem monkeydoc Vector x coordinate.
	#end
	Field x:T
	
	#rem monkeydoc Vector y coodinate.
	#end
	Field y:T
	
	#rem monkeydoc Creates a new vector.
	#end
	Method New()
	End
	
	Method New( t:T )
		x=t;y=t
	End
		
	Method New( x:T,y:T )
		Self.x=x;Self.y=y
	End
	
	#rem monkeydoc Converts the vector to a vector of a different type.
	#end
	Operator To<C>:Vec2<C>()
		Return New Vec2<C>( x,y )
	End

	#rem monkeydoc Converts the vector to a printable string.
	#end
	Operator To:String()
		Return "Vec2("+x+","+y+")"
	End

	#rem monkeydoc The X coordinate of the vector.
	#end
	Property X:T()
		Return x
	Setter( x:T )
		Self.x=x
	End
	
	#rem monkeydoc The Y coordinate of the vector.
	#end
	Property Y:T()
		Return y
	Setter( y:T )
		Self.y=y
	End
	
	#rem monkeydoc Negates the vector components and returns the result.
	#end
	Operator-:Vec2()
		Return New Vec2( -x,-y )
	End
	
	#rem monkeydoc Multiplies the vector by another vector and returns the result.
	#end
	Operator*:Vec2( v:Vec2 )
		Return New Vec2( x*v.x,y*v.y )
	End

	#rem monkeydoc Divides the vector by another vector and returns the result.
	#end	
	Operator/:Vec2( v:Vec2 )
		Return New Vec2( x/v.x,y/v.y )
	End

	#rem monkeydoc Adds another vector to the vector and returns the result.
	#end	
	Operator+:Vec2( v:Vec2 )
		Return New Vec2( x+v.x,y+v.y )
	End
	
	#rem monkeydoc Subtracts another vector from the vector and returns the result.
	#end
	Operator-:Vec2( v:Vec2 )
		Return New Vec2( x-v.x,y-v.y )
	End
	
	#rem monkeydoc Scales the vector by a value and returns the result.
	#end
	Operator*:Vec2( s:Double )
		Return New Vec2( x*s,y*s )
	End
	
	#rem monkeydoc Inverse scales the vector by a value and returns the result.
	#end
	Operator/:Vec2( s:Double )
		Return New Vec2( x/s,y/s )
	End
	
	#rem monkeydoc Adds a value to the vector components and returns the result.
	#end
	Operator+:Vec2( s:T )
		Return New Vec2( x+s,y+s )
	End
	
	#rem monkeydoc Subtracts a value from the vector components and returns the result.
	#end
	Operator-:Vec2( s:T )
		Return New Vec2( x-s,y-s )
	End
	
	#rem monkeydoc The length of the vector.
	#end
	Property Length:Double()
		Return Sqrt( x*x+y*y )
	End

	#rem monkeydoc The normal to the vector.
	#end	
	Property Normal:Vec2()
		Return New Vec2( -y,x )
	End

	#rem monkeydoc Computes the dot product of the vector with another vector.
	#end
	Method Dot:Double( v:Vec2 )
		Return x*v.x+y*v.y
	End
	
	#rem monkeydoc Normalizes the vector and returns the result.
	#end
	Method Normalize:Vec2()
		Return Self/Length
	End
	
	#rem monkeydoc Blends the vector with another vector and returns the result.
	#end
	Method Blend:Vec2( v:Vec2,alpha:Double )
		Return New Vec2( (v.x-x)*alpha+x,(v.y-y)*alpha+y )
	End
	
	#rem monkeydoc Gets a string representation for the vector.
	#end
	Method ToString:String()
		Return Self
	End

End

#rem monkeydoc Transforms a Vec2\<Int\> by an AffineMat3.
#end
Function TransformVec2i<T>:Vec2i( vec:Vec2i,matrix:AffineMat3<T> )
	
	Local tmp:=matrix * New Vec2<T>( rect.min.x,rect.min.y )
	
	Return New Vec2i( Round( tmp.x ),Round( tmp.y ) )
End

