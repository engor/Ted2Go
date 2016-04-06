
Namespace std.geom

Alias AffineMat3f:AffineMat3<Float>

Struct AffineMat3<T>

	Field i:Vec2<T>
	Field j:Vec2<T>
	Field t:Vec2<T>
	
	Method New()
		i.x=1;j.y=1
	End
	
'	Method New( m:AffineMat3 )
'		i=m.i;j=m.j;t=m.t
'	End
	
	Method New( i:Vec2<T>,j:Vec2<T>,t:Vec2<T> )
		Self.i=i;Self.j=j;Self.t=t
	End
	
	Method New( ix:T,iy:T,jx:T,jy:T,tx:T,ty:T )
		Self.i.x=ix;Self.i.y=iy;Self.j.x=jx;Self.j.y=jy;Self.t.x=tx;Self.t.y=ty
	End
	
	Operator-:AffineMat3()
		Local idet:=1.0/(i.x*j.y-i.y*j.x)
		Return New AffineMat3(
			j.y*idet , -i.y*idet,
			-j.x*idet , i.x*idet,
			(j.x*t.y-j.y*t.x)*idet , (i.y*t.x-i.x*t.y)*idet )
	End
	
	Operator*:Vec2<T>( v:Vec2<T> )
		Return New Vec2<T>( i.x*v.x + j.x*v.y + t.x , i.y*v.x + j.y*v.y + t.y )
	End
	
	Operator*:AffineMat3( m:AffineMat3 )
		Return New AffineMat3(
			i.x*m.i.x + j.x*m.i.y       , i.y*m.i.x + j.y*m.i.y ,
			i.x*m.j.x + j.x*m.j.y       , i.y*m.j.x + j.y*m.j.y ,
			i.x*m.t.x + j.x*m.t.y + t.x , i.y*m.t.x + j.y*m.t.y + t.y )
	End
			
	Method Transform:Vec2<T>( x:T,y:T )
		Return New Vec2<T>( i.x*x + j.x*y + t.x , i.y*x + j.y*y + t.y )
	End
	
	Method Transform:AffineMat3( ix:Float,iy:Float,jx:Float,jy:Float,tx:Float,ty:Float )
		Return New AffineMat3(
			i.x*ix + j.x*iy       , i.y*ix + j.y*iy ,
			i.x*jx + j.x*jy       , i.y*jx + j.y*jy ,
			i.x*tx + j.x*ty + t.x , i.y*tx + j.y*ty + t.y )
	End
	
	Method Translate:AffineMat3( v:Vec2<T> )
		Return Transform( 1,0,0,1,v.x,v.y )
	End
	
	Method Translate:AffineMat3( tx:T,ty:T )
		Return Transform( 1,0,0,1,tx,ty )
	End
	
	Method Rotate:AffineMat3( rz:Double )
		Return Transform( Cos( rz ),-Sin( rz ),Sin( rz ),Cos( rz ),0,0 )
	End
	
	Method Scale:AffineMat3( v:Vec2<T> )
		Return Transform( v.x,0,0,v.y,0,0 )
	End
	
	Method Scale:AffineMat3( sx:T,sy:T )
		Return Transform( sx,0,0,sy,0,0 )
	End
	
End
