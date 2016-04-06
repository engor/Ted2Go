
Namespace std.geom

Alias Mat4f:Mat4<Float>

Struct Mat4<T>

	Field i:Vec4<T>
	Field j:Vec4<T>
	Field k:Vec4<T>
	Field t:Vec4<T>
	
	Method New()
		i.x=1;j.y=1;k.z=1;t.w=1
	End
	
	Method New( i:T,j:T,k:T,t:T )
		Self.i.x=i;Self.j.y=j;Self.k.z=k;Self.t.w=t
	End
	
	Method New( i:Vec4<T>,j:Vec4<T>,k:Vec4<T>,t:Vec4<T> )
		Self.i=i;Self.j=j;Self.k=k;Self.t=t
	End
	
End
