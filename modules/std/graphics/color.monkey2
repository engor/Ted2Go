
Namespace std.graphics

Struct Color
	
	Const None:=New Color( 0,0,0,0 )
	Const Red:=New Color( 1,0,0 )
	Const Green:=New Color( 0,1,0 )
	Const Blue:=New Color( 0,0,1 )
	Const Yellow:=New Color( 1,1,0 )
	Const Magenta:=New Color( 1,0,1 )
	Const Cyan:=New Color( 0,1,1 )
	Const Black:=New Color( 0,0,0 )
	Const White:=New Color( 1,1,1 )
	Const Grey:=New Color( .5,.5,.5 )
	Const LightGrey:=New Color( .75,.75,.75 )
	Const DarkGrey:=New Color( .25,.25,.25 )

	Field r:Float
	Field g:Float
	Field b:Float
	Field a:Float
	
	Method New()
	End
	
	Method New( argb:UInt )
		a=(argb Shr 24 & $ff)/255.0
		r=(argb Shr 16 & $ff)/255.0
		g=(argb Shr 8 & $ff)/255.0
		b=(argb & $ff)/255.0
	End
	
	Method New( r:Float,g:Float,b:Float,a:Float=1 )
		Self.r=r
		Self.g=g
		Self.b=b
		Self.a=a
	End
	
	Property R:Float()
		Return r
	Setter( r:Float )
		Self.r=r
	End
	
	Property G:Float()
		Return g
	Setter( g:Float )
		Self.g=g
	End
	
	Property B:Float()
		Return b
	Setter( b:Float )
		Self.b=b
	End
	
	Property A:Float()
		Return a
	Setter( a:Float )
		Self.a=a
	End
	
	Method ToARGB:UInt()
		Return UInt(a*255) Shl 24 | UInt(r*255) Shl 16 | UInt(g*255) Shl 8 | UInt(b*255)
	End
	
	Function FromHSV:Color( h:Float,s:Float,v:Float,a:Float=1 )

		h*=6
		
		Local f:=h-Floor( h )
		
		Local p:=v * ( 1 - s )
		Local q:=v * ( 1 - ( s * f ) )
		Local t:=v * ( 1 - ( s * ( 1-f ) ) )
		
		Local r:Float,g:Float,b:Float
		
		Select Int( h ) Mod 6
		Case 0 r=v ; g=t ; b=p
		Case 1 r=q ; g=v ; b=p
		Case 2 r=p ; g=v ; b=t
		Case 3 r=p ; g=q ; b=v
		Case 4 r=t ; g=p ; b=v
		Case 5 r=v ; g=p ; b=q
		End
		
		Return New Color( r,g,b,a )
	End
	
	Function FromARGB:Color( argb:UInt )
		Local a:=(argb Shr 24 & $ff)/255.0
		Local r:=(argb Shr 16 & $ff)/255.0
		Local g:=(argb Shr 8 & $ff)/255.0
		Local b:=(argb & $ff)/255.0
		Return New Color( r,g,b,a )
	End
	
End
