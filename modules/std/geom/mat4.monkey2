
Namespace std.geom

#rem monkeydoc @hidden
#end
Alias Mat4f:Mat4<Float>

#rem monkeydoc @hidden
#end
Struct Mat4<T>

	Field i:Vec4<T>
	Field j:Vec4<T>
	Field k:Vec4<T>
	Field t:Vec4<T>
	
	Method New()
		i.x=1;j.y=1;k.z=1;t.w=1
	End
	
	Method New( ix:T,jy:T,kz:T,tw:T )
		i.x=ix;j.y=jy;k.z=kz;t.w=tw
	End
	
	Method New( i:Vec4<T>,j:Vec4<T>,k:Vec4<T>,t:Vec4<T> )
		Self.i=i;Self.j=j;Self.k=k;Self.t=t
	End
	
	Method New( m:AffineMat3<T> )
		i.x=m.i.x;i.y=m.i.y
		j.x=m.j.x;j.y=m.j.y
		k.z=1
		t.x=m.t.x;t.y=m.t.y;t.w=1
	End
	
	Operator*:Mat4( m:Mat4 )
		Local r:Mat4
		
		r.i.x=i.x*m.i.x + j.x*m.i.y + k.x*m.i.z + t.x*m.i.w 
		r.i.y=i.y*m.i.x + j.y*m.i.y + k.y*m.i.z + t.y*m.i.w
		r.i.z=i.z*m.i.x + j.z*m.i.y + k.z*m.i.z + t.z*m.i.w
		r.i.w=i.w*m.i.x + j.w*m.i.y + k.w*m.i.z + t.w*m.i.w
		
		r.j.x=i.x*m.j.x + j.x*m.j.y + k.x*m.j.z + t.x*m.j.w 
		r.j.y=i.y*m.j.x + j.y*m.j.y + k.y*m.j.z + t.y*m.j.w
		r.j.z=i.z*m.j.x + j.z*m.j.y + k.z*m.j.z + t.z*m.j.w
		r.j.w=i.w*m.j.x + j.w*m.j.y + k.w*m.j.z + t.w*m.j.w
		
		r.k.x=i.x*m.k.x + j.x*m.k.y + k.x*m.k.z + t.x*m.k.w 
		r.k.y=i.y*m.k.x + j.y*m.k.y + k.y*m.k.z + t.y*m.k.w
		r.k.z=i.z*m.k.x + j.z*m.k.y + k.z*m.k.z + t.z*m.k.w
		r.k.w=i.w*m.k.x + j.w*m.k.y + k.w*m.k.z + t.w*m.k.w
		
		r.t.x=i.x*m.t.x + j.x*m.t.y + k.x*m.t.z + t.x*m.t.w 
		r.t.y=i.y*m.t.x + j.y*m.t.y + k.y*m.t.z + t.y*m.t.w
		r.t.z=i.z*m.t.x + j.z*m.t.y + k.z*m.t.z + t.z*m.t.w
		r.t.w=i.w*m.t.x + j.w*m.t.y + k.w*m.t.z + t.w*m.t.w
		
		Return r
	End
	
	Function Ortho:Mat4( left:Float,right:Float,bottom:Float,top:Float,near:Float,far:Float )

		Local w:=right-left,h:=top-bottom,d:=far-near

		Local r:Mat4
		r.i.x=2/w ; r.j.y=2/h ; r.k.z=2/d
		r.t=New Vec4<T>( -(right+left)/w,-(top+bottom)/h,-(far+near)/d,1 )
		Return r
	End
	
End
