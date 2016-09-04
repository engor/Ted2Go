
Namespace std.geom

#rem monkeydoc Convenience type alias for AffineMat3\<Float\>
#end
Alias AffineMat3f:AffineMat3<Float>

#rem monkeydoc Affine 3x3 matrix class.

An affine 3x3 matrix is a 3x3 matrix whose right hand column is always 0,0,1.

Affine 3x3 matrices are often used for 2d transformations such as scaling, rotation and translation.

#end
Struct AffineMat3<T>

	#rem monkeydoc The first row of the matrix.
	#end
	Field i:Vec2<T>
	
	#rem monkeydoc The second row of the matrix.
	#end
	Field j:Vec2<T>
	
	#rem monkeydoc The third row of the matrix.
	#end
	Field t:Vec2<T>

	#rem monkeydoc Creates a new matrix.
	#end
	Method New()
		i.x=1;j.y=1
	End
	
	Method New( i:Vec2<T>,j:Vec2<T>,t:Vec2<T> )
		Self.i=i;Self.j=j;Self.t=t
	End
	
	Method New( ix:T,iy:T,jx:T,jy:T,tx:T,ty:T )
		Self.i.x=ix;Self.i.y=iy;Self.j.x=jx;Self.j.y=jy;Self.t.x=tx;Self.t.y=ty
	End
	
	#rem monkeydoc Converts the matrix to a matrix of a different type.
	#end
	Operator To<C>:AffineMat3<C>()
		Return New AffineMat3<C>( i.x,i.y,j.x,j.y,t.x,t.y )
	End 
	
	#rem monkeydoc Converts the matrix to a printable string.
	#end
	Operator To:String()
		Return "AffineMat3("+i.x+","+i.y+","+j.x+","+j.y+","+t.x+","+t.y+")"
	End
	
	#rem monkeydoc Returns the inverse of the matrix.
	#end
	Operator-:AffineMat3()
		Local idet:=1.0/(i.x*j.y-i.y*j.x)
		Return New AffineMat3(
			j.y*idet , -i.y*idet,
			-j.x*idet , i.x*idet,
			(j.x*t.y-j.y*t.x)*idet , (i.y*t.x-i.x*t.y)*idet )
	End
	
	#rem monkeydoc Multiplies a vector by the matrix and returns the result.
	#end
	Operator*:Vec2<T>( v:Vec2<T> )
		Return New Vec2<T>( i.x*v.x + j.x*v.y + t.x , i.y*v.x + j.y*v.y + t.y )
	End
	
	#rem monkeydoc Multiplies the matrix by another matrix and returns the result.
	#end
	Operator*:AffineMat3( m:AffineMat3 )
		Return New AffineMat3(
			i.x*m.i.x + j.x*m.i.y       , i.y*m.i.x + j.y*m.i.y ,
			i.x*m.j.x + j.x*m.j.y       , i.y*m.j.x + j.y*m.j.y ,
			i.x*m.t.x + j.x*m.t.y + t.x , i.y*m.t.x + j.y*m.t.y + t.y )
	End
	
	#rem monkeydoc Multiplies a vector by the matrix and returns the result.
	#end
	Method Transform:Vec2<T>( v:Vec2<T> )
		Return New Vec2<T>( i.x*v.x + j.x*v.y + t.x , i.y*v.x + j.y*v.y + t.y )
	End
			
	#rem monkeydoc Multiplies a vector by the matrix and returns the result.
	#end
	Method Transform:Vec2<T>( x:T,y:T )
		Return New Vec2<T>( i.x*x + j.x*y + t.x , i.y*x + j.y*y + t.y )
	End
	
	#rem monkeydoc Multiplies the matrix by another matrix and returns the result.
	#end
	Method Transform:AffineMat3( ix:Float,iy:Float,jx:Float,jy:Float,tx:Float,ty:Float )
		Return New AffineMat3(
			i.x*ix + j.x*iy       , i.y*ix + j.y*iy ,
			i.x*jx + j.x*jy       , i.y*jx + j.y*jy ,
			i.x*tx + j.x*ty + t.x , i.y*tx + j.y*ty + t.y )
	End
	
	#rem monkeydoc Applies a translation transformation to the matrix and returns the result.
	#end
	Method Translate:AffineMat3( v:Vec2<T> )
		Return Transform( 1,0,0,1,v.x,v.y )
	End
	
	Method Translate:AffineMat3( tx:T,ty:T )
		Return Transform( 1,0,0,1,tx,ty )
	End
	
	#rem monkeydoc Applies a rotation transformation to the matrix and returns the result.
	#end
	Method Rotate:AffineMat3( rz:Double )
		Return Transform( Cos( rz ),-Sin( rz ),Sin( rz ),Cos( rz ),0,0 )
	End
	
	#rem monkeydoc Applies a scale transformation to the matrix and returns the result.
	#end
	Method Scale:AffineMat3( v:Vec2<T> )
		Return Transform( v.x,0,0,v.y,0,0 )
	End
	
	Method Scale:AffineMat3( sx:T,sy:T )
		Return Transform( sx,0,0,sy,0,0 )
	End

	#rem monkeydoc @hidden
	#end
	Function Ortho:AffineMat3( left:T,right:T,bottom:T,top:T )

		Local w:=right-left,h:=top-bottom

		Local r:AffineMat3
		r.i.x=2/w
		r.j.y=2/h
		r.t.x=-(right+left)/w
		r.t.y=-(top+bottom)/h
		Return r
	End
	
End
