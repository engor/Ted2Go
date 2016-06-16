
Namespace std.geom

#rem monkeydoc @hidden
#end
Alias Mat3f:Mat3<Float>

#rem monkeydoc @hidden
#end
Struct Mat3<T>

	Field i:Vec3<T>
	Field j:Vec3<T>
	Field k:Vec3<T>
	
	Method New()
		i.x=1;j.y=1;k.z=1
	End
	
	Method New( i:Vec3<T>,j:Vec3<T>,k:Vec3<T> )
		Self.i=i;Self.j=j;Self.k=k
	End
	
	Method New( ix:T,iy:T,iz:T,jx:T,jy:T,jz:T,kx:T,ky:T,kz:T )
		Self.i.x=ix;Self.i.y=iy;Self.i.z=iz
		Self.j.x=jx;Self.j.y=jy;Self.j.z=jz
		Self.k.x=jx;Self.k.y=jy;Self.k.z=kz
	End

End
