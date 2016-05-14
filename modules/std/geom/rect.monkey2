
Namespace std.geom

Alias Recti:Rect<Int>
Alias Rectf:Rect<Float>

Struct Rect<T>

	Field min:Vec2<T>
	Field max:Vec2<T>
	
	Method New()
	End
	
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
	
	Method Centered:Rect( r:Rect )
		Local x:=(r.Width-Width)/2+min.x
		Local y:=(r.Height-Height)/2+min.y
		Return New Rect( x,y,x+Width,y+Height )
	End
	
	Method Contains:Bool( v:Vec2<T> )
		Return v.x>=min.x And v.x<max.x And v.y>=min.y And v.y<max.y
	End
	
	Method Contains:Bool( r:Rect )
		Return min.x<=r.min.x And max.x>=r.max.x And min.y<=r.min.y And max.y>=r.max.y
	End
	
	Method Intersects:Bool( r:Rect )
		Return r.max.x>min.x And r.min.x<max.x And r.max.y>min.y And r.min.y<max.y
	End
	
	Method ToString:String()
		Return "Rect("+min.ToString()+","+max.ToString()+")"
	End
	
End

Function TransformRecti<T>:Recti( rect:Recti,matrix:AffineMat3<T> )
	
	Local min:=matrix * New Vec2f( rect.min.x,rect.min.y )
	Local max:=matrix * New Vec2f( rect.max.x,rect.max.y )
		
	Return New Recti( Round( min.x ),Round( min.y ),Round( max.x ),Round( max.y ) )
End

