
Namespace std.graphics

Alias Vec2i:Vec2<Int>
Alias Vec2f:Vec2<Float>

Alias Vec3i:Vec3<Int>
Alias Vec3f:Vec3<Float>

Alias Vec4i:Vec4<Int>
Alias Vec4f:Vec4<Float>

Alias Mat4f:Mat4<Float>

Alias Recti:Rect<Int>
Alias Rectf:Rect<Float>

#rem monkeydoc @hidden
#end
Struct Vec2<T>

	Field x:T
	Field y:T
	
	Method New()
	End
	
	Method New( x:T,y:T )
		Self.x=x;Self.y=y
	End
	
	'TODO: Generic ctors
	'Method New<T2>( v:Vec2<T2> )
	'	Self.x=v.x;Self.y=v.y
	'End
	
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
	
	Property Length:T()
		Return Sqrt( x*x+y*y )
	End
	
	Operator-:Vec2()
		Return New Vec2( -x,-y )
	End
	
	Operator*=( v:Vec2 )
		x*=v.x;y*=v.y
	End

	Operator/=( v:Vec2 )
		x/=v.x;y/=v.y
	End

	Operator+=( v:Vec2 )
		x+=v.x;y+=v.y
	End

	Operator-=( v:Vec2 )
		x-=v.x;y-=v.y
	End
	
	Operator*=( t:T )
		x*=t;y*=t
	End
	
	Operator/=( t:T )
		x/=t;y/=t
	End
	
	Operator+=( t:T )
		x+=t;y+=t
	End
	
	Operator-=( t:T )
		x-=t;y-=t
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
	
	Operator*:Vec2( t:T )
		Return New Vec2( x*t,y*t )
	End
	
	Operator/:Vec2( t:T )
		Return New Vec2( x/t,y/t )
	End
	
	Operator+:Vec2( t:T )
		Return New Vec2( x+t,y+t )
	End
	
	Operator-:Vec2( t:T )
		Return New Vec2( x-t,y-t )
	End
	
	Operator<=>:Int( v:Vec2 )
		If x<v.x Return -1
		If x>v.x Return 1
		If y<v.y Return -1
		If y>v.y Return 1
		Return 0
	End
	
	Method Dot:T( v:Vec2 )
		Return x*v.x+y*v.y
	End
	
	Method Normalize:Vec2()
		Return Self/Length
	End
	
	Method Blend:Vec2( v:Vec2,alpha:Float )
		Return New Vec2( (v.x-x)*alpha+x,(v.y-y)*alpha+y )
	End
	
	Method ToVec2<T2>:Vec2<T2>()
		Return New Vec2<T2>( x,y )
	End
	
	Method ToString:String()
		Return "Vec2("+x+","+y+")"
	End

End

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
	
	'TODO: Generic ctors
	'Method New<T2>( v:Vec3<T2> )
	'	Self.x=v.x;Self.y=v.y;Self.z=v.z
	'End
	
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
	
	Property Length:T()
		Return Sqrt( x*x+y*y+z*z )
	End	
	
	Operator-:Vec3()
		Return New Vec3( -x,-y,-z )
	End
	
	Operator*=( v:Vec3 )
		x*=v.x;y*=v.y;z*=v.z
	End

	Operator/=( v:Vec3 )
		x/=v.x;y/=v.y;z/=v.z
	End

	Operator+=( v:Vec3 )
		x+=v.x;y+=v.y;z+=v.z
	End

	Operator-=( v:Vec3 )
		x-=v.x;y-=v.y;z-=v.z
	End
	
	Operator*=( t:T )
		x*=t;y*=t;z*=t
	End
	
	Operator/=( t:T )
		x/=t;y/=t;z/=t
	End
	
	Operator+=( t:T )
		x+=t;y+=t;z+=t
	End
	
	Operator-=( t:T )
		x-=t;y-=t;z-=t
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
	
	Operator*:Vec3( t:T )
		Return New Vec3( x*t,y*t,z*t )
	End
	
	Operator/:Vec3( t:T )
		Return New Vec3( x/t,y/t,z/t )
	End
	
	Operator+:Vec3( t:T )
		Return New Vec3( x+t,y+t,z+t )
	End
	
	Operator-:Vec3( t:T )
		Return New Vec3( x-t,y-t,z-t )
	End
	
	Operator<=>:Int( v:Vec3 )
		If x<v.x Return -1
		If x>v.x Return 1
		If y<v.y Return -1
		If y>v.y Return 1
		If z<v.z Return -1
		If z>v.z Return 1
		Return 0
	End
	
	Method Dot:T( v:Vec3 )
		Return x*v.x + y*v.y + z*v.z
	End
	
	Method Normalize:Vec3()
		Return Self/Length
	End
	
	Method ToString:String()
		Return "Vec3("+x+","+y+","+z+")"
	End
	
End

#rem monkeydoc @hidden
#end
Struct Vec4<T>

	Field x:T
	Field y:T
	Field z:T
	Field w:T
	
	Method New()
	End
	
	Method New( t:T )
		x=t;y=t;z=t;w=t
	End
	
	Method New( x:T,y:T,z:T,w:T )
		Self.x=x;Self.y=y;Self.z=z;Self.w=w
	End
	
	'TODO: Generic ctors
	'Method New<T2>( v:Vec4<T2> )
	'	Self.x=v.x;Self.y=v.y;Self.z=v.z;Self.w=v.w
	'End
	
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
	
	Property W:T()
		Return w
	Setter( w:T )
		Self.w=w
	End
		
	Operator-:Vec4()
		Return New Vec4( -x,-y,-z,-w )
	End
	
	Operator*=( v:Vec4 )
		x*=v.x;y*=v.y;z*=v.z;w*=v.w
	End

	Operator/=( v:Vec4 )
		x/=v.x;y/=v.y;z/=v.z;w/=v.w
	End

	Operator+=( v:Vec4 )
		x+=v.x;y+=v.y;z+=v.z;w+=v.w
	End

	Operator-=( v:Vec4 )
		x-=v.x;y-=v.y;z-=v.z;w-=v.w
	End
	
	Operator*=( t:T )
		x*=t;y*=t;z*=t;w*=t
	End
	
	Operator/=( t:T )
		x/=t;y/=t;z/=t;w/=t
	End
	
	Operator+=( t:T )
		x+=t;y+=t;z+=t;w+=t
	End
	
	Operator-=( t:T )
		x-=t;y-=t;z-=t;w-=t
	End
	
	Operator*:Vec4( v:Vec4 )
		Return New Vec4( x*v.x,y*v.y,z*v.z,w*v.w )
	End
	
	Operator/:Vec4( v:Vec4 )
		Return New Vec4( x/v.x,y/v.y,z/v.z,w/v.w )
	End
	
	Operator+:Vec4( v:Vec4 )
		Return New Vec4( x+v.x,y+v.y,z+v.z,w+v.w )
	End
	
	Operator-:Vec4( v:Vec4 )
		Return New Vec4( x-v.x,y-v.y,z-v.z,w-v.w )
	End
	
	Operator*:Vec4( t:T )
		Return New Vec4( x*t,y*t,z*t,w*t )
	End
	
	Operator/:Vec4( t:T )
		Return New Vec4( x/t,y/t,z/t,w/t )
	End
	
	Operator+:Vec4( t:T )
		Return New Vec4( x+t,y+t,z+t,w+t )
	End
	
	Operator-:Vec4( t:T )
		Return New Vec4( x-t,y-t,z-t,w-t )
	End
	
	Operator<=>:Int( v:Vec4 )
		If x<v.x Return -1
		If x>v.x Return 1
		If y<v.y Return -1
		If y>v.y Return 1
		If z<v.z Return -1
		If z>v.z Return 1
		If w<v.w Return -1
		If w>v.w Return 1
		Return 0
	End
	
	Method Dot:T( v:Vec4 )
		Return x*v.x + y*v.y + z*v.z + w*v.w
	End
	
	Method ToString:String()
		Return "Vec4("+x+","+y+","+z+","+w+")"
	End
	
End

#rem monkeydoc @hidden
#end
Struct Mat4<T>

	Field i:Vec4<T>
	Field j:Vec4<T>
	Field k:Vec4<T>
	Field t:Vec4<T>
	
	Method New()
		i.x=1
		j.y=1
		k.z=1
		t.w=1
	End
	
	Method New( i:Vec4<T>,j:Vec4<T>,k:Vec4<T>,t:Vec4<T> )
		Self.i=i
		Self.j=j
		Self.k=k
		Self.t=t
	End
	
	Operator*:Vec4<T>( v:Vec4<T> )
		Return New Vec4<T>
	End
	
	Operator*:Mat4( m:Mat4 )
		Return New Mat4
	End
	
	Operator<=>:Int( m:Mat4 )
		If i<m.i Return -1
		If i>m.i Return 1
		If j<m.j Return -1
		If j>m.j Return 1
		If k<m.k Return -1
		If k>m.k Return 1
		If t<m.t Return -1
		If t>m.t Return 1
		Return 0
	End
	
End

#rem monkeydoc @hidden
#end
Struct Rect<T>

	Field min:Vec2<T>
	Field max:Vec2<T>
	
	Method New( min:Vec2<T>,max:Vec2<T> )
		Self.min=min
		Self.max=max
	End
	
	Method New( x0:T,y0:T,x1:T,y1:T )
		min=New Vec2<T>( x0,y0 )
		max=New Vec2<T>( x1,y1 )
	End
	
	Method New( x0:T,y0:T,max:Vec2<T> )
		Self.min=New Vec2<T>( x0,y0 )
		Self.max=max
	End
	
	Method New( min:Vec2<T>,x1:T,y1:T )
		Self.min=min
		Self.max=New Vec2<T>( x1,y1 )
	End
	
	'TODO: Generic ctors
	'Method New<T2>( r:Rect<T2> )
	'	Self.min=New Vec2<T>( r.min )
	'	Self.max=New Vec2<T>( r.max )
	'End
	
	Property X:T()
		Return min.x
	Setter( x:T )
		min.x=x
	End
	
	Property Y:T()
		Return min.y
	Setter( y:T )
		min.y=y
	End
	
	Property Width:T()
		Return max.x-min.x
	Setter( width:T )
		max.x=min.x+width
	End
	
	Property Height:T()
		Return max.y-min.y
	Setter( height:T )
		max.y=min.y+height
	End
	
	Property Left:T()
		Return min.x
	Setter( left:T )
		min.x=left
	End
	
	Property Top:T()
		Return min.y
	Setter( top:T )
		min.y=top
	End
	
	Property Right:T()
		Return max.x
	Setter( right:T )
		max.x=right
	End
	
	Property Bottom:T()
		Return max.y
	Setter( bottom:T )
		max.y=bottom
	End
	
	Property Origin:Vec2<T>()
		Return min
	Setter( origin:Vec2<T> )
		min=origin
	End
	
	Property Size:Vec2<T>()
		Return max-min
	Setter( size:Vec2<T> )
		max=min+size
	End
	
	Property Center:Vec2<T>()
		Return (min+max)/2
	End
	
	Property TopLeft:Vec2<T>()
		Return min
	Setter( v:Vec2<T> )
		min=v
	End
	
	Property TopRight:Vec2<T>()
		Return New Vec2<T>( max.x,min.y )
	Setter( v:Vec2<T> )
		max.x=v.x
		min.y=v.y
	End
	
	Property BottomRight:Vec2<T>()
		Return max
	Setter( v:Vec2<T> )
		max=v
	End
	
	Property BottomLeft:Vec2<T>()
		Return New Vec2<T>( min.x,max.y )
	Setter( v:Vec2<T> )
		min.x=v.x
		max.y=v.y
	End
	
	Property Empty:Bool()
		Return max.x<=min.x Or max.y<=min.y
	End

	Operator+:Rect( r:Rect )
		Return New Rect( min+r.min,max+r.max )
	End
	
	Operator-:Rect( r:Rect )
		Return New Rect( min-r.min,max-r.max )
	End
	
	Operator*:Rect( v:Vec2<T> )
		Return New Rect( min.x*v.x,min.y*v.y,max.x*v.x,max.y*v.y )
	End
	
	Operator/:Rect( v:Vec2<T> )
		Return New Rect( min.x/v.x,min.y/v.y,max.x/v.x,max.y/v.y )
	End
	
	Operator+:Rect( v:Vec2<T> )
		Return New Rect( min+v,max+v )
	End
	
	Operator-:Rect( v:Vec2<T> )
		Return New Rect( min-v,max-v )
	End
	
	Operator+=( r:Rect )
		min+=r.min
		max+=r.max
	End
	
	Operator-=( r:Rect )
		min-=r.min
		max-=r.max
	End

	Operator*=( v:Vec2<T> )
		min*=v
		max*=v
	End
	
	Operator/=( v:Vec2<T> )
		min/=v
		max/=v
	End
	
	Operator+=( v:Vec2<T> )
		min+=v
		max+=v
	End
	
	Operator-=( v:Vec2<T> )
		min-=v
		max-=v
	End
	
	Operator&:Rect( r:Rect )
		Local x0:=Max( min.x,r.min.x )
		Local y0:=Max( min.y,r.min.y )
		Local x1:=Min( max.x,r.max.x )
		Local y1:=Min( max.y,r.max.y )
		Return New Rect( x0,y0,x1,y1 )
	End
	
	Operator&=( r:Rect )
		min.x=Max( min.x,r.min.x )
		min.y=Max( min.y,r.min.y )
		max.x=Min( max.x,r.max.x )
		max.y=Min( max.y,r.max.y )
	End
	
	Operator|:Rect( r:Rect )
		Local x0:=Min( min.x,r.min.x )
		Local y0:=Min( min.y,r.min.y )
		Local x1:=Max( max.x,r.max.x )
		Local y1:=Max( max.y,r.max.y )
		Return New Rect( x0,y0,x1,y1 )
	End
	
	Operator|=( r:Rect )
		min.x=Min( min.x,r.min.x )
		min.y=Min( min.y,r.min.y )
		max.x=Max( max.x,r.max.x )
		max.y=Max( max.y,r.max.y )
	End
	
	Operator<=>:Int( r:Rect )
		If min.x<r.min.x Return -1
		If min.x>r.min.x Return 1
		If min.y<r.min.y Return -1
		If min.y>r.min.y Return 1
		If max.x<r.max.x Return -1
		If max.x>r.max.x Return 1
		If max.y<r.max.y Return -1
		If max.y>r.max.y Return 1
		Return 0
	End
	
	Method Centered:Rect( r:Rect )
		Local x:=(r.Width-Width)/2+min.x
		Local y:=(r.Height-Height)/2+min.y
		Return New Rect( x,y,x+Width,y+Height )
	End
	
	Method Contains:Bool( v:Vec2<T> )
		Return v.x>=min.x And v.x<max.x And v.y>=min.y And v.y<max.y
	End
	
	Method Intersects:Bool( r:Rect<T> )
		Return r.max.x>min.x And r.min.x<max.x And r.max.y>min.y And r.min.y<max.y
	End
	
	Method ToString:String()
		Return "Rect("+min.ToString()+","+max.ToString()+")"
	End
	
End
