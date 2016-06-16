
Namespace std.graphics

#rem monkeydoc The Color type provides support for manipulating red, green blue, alpha colors.
#end
Struct Color
	
	#rem monkeydoc Transparent black.
	#end
	Const None:=New Color( 0,0,0,0 )
	
	#rem monkeydoc Red.
	#end
	Const Red:=New Color( 1,0,0 )
	
	#rem monkeydoc Green.
	#end
	Const Green:=New Color( 0,1,0 )
	
	#rem monkeydoc Blue.
	#end
	Const Blue:=New Color( 0,0,1 )
	
	#rem monkeydoc Yellow.
	#end
	Const Yellow:=New Color( 1,1,0 )
	
	#rem monkeydoc Magenta.
	#end
	Const Magenta:=New Color( 1,0,1 )
	
	#rem monkeydoc Cyan.
	#end
	Const Cyan:=New Color( 0,1,1 )

	#rem monkeydoc Black.
	#end
	Const Black:=New Color( 0,0,0 )

	#rem monkeydoc White.
	#end
	Const White:=New Color( 1,1,1 )

	#rem monkeydoc Grey.
	#end
	Const Grey:=New Color( .5,.5,.5 )

	#rem monkeydoc Light Grey.
	#end
	Const LightGrey:=New Color( .75,.75,.75 )

	#rem monkeydoc Dark Grey.
	#end
	Const DarkGrey:=New Color( .25,.25,.25 )
	
	#rem monkeydoc Red component of color.
	#end
	Field r:Float

	#rem monkeydoc Green component of color.
	#end
	Field g:Float
	#rem monkeydoc Blue component of color.
	#end
	Field b:Float
	
	#rem monkeydoc Alpha component of color.
	#end
	Field a:Float
	
	#rem monkeydoc Creates a new color.
	#end
	Method New( a:Float=1 )
		Self.a=a
	End
	
	Method New( i:Float,a:Float=1 )
		Self.r=i
		Self.g=i
		Self.b=i
		Self.a=1
	End
	
	Method New( r:Float,g:Float,b:Float,a:Float=1 )
		Self.r=r
		Self.g=g
		Self.b=b
		Self.a=a
	End
	
	#rem monkeydoc The Red color component.
	#end
	Property R:Float()
		Return r
	Setter( r:Float )
		Self.r=r
	End
	
	#rem monkeydoc The green color component.
	#end
	Property G:Float()
		Return g
	Setter( g:Float )
		Self.g=g
	End
	
	#rem monkeydoc The blue color component.
	#end
	Property B:Float()
		Return b
	Setter( b:Float )
		Self.b=b
	End
	
	#rem monkeydoc The alpha color component.
	#end
	Property A:Float()
		Return a
	Setter( a:Float )
		Self.a=a
	End
	
	#rem monkeydoc Multiplies the color by another color or value and returns the result.
	#end
	Operator*:Color( color:Color )
		Return New Color( r*color.r,g*color.g,b*color.b,a*color.a )
	End

	Operator*:Color( scale:Float )
		Return New Color( r*scale,g*scale,b*scale,a*scale )
	End
	
	#rem monkeydoc Divides the color by another color or value and returns the result.
	#end
	Operator/:Color( color:Color )
		Return New Color( r/color.r,g/color.g,b/color.b,a/color.a )
	End

	Operator/:Color( scale:Float )
		Return New Color( r/scale,g/scale,b/scale,a/scale )
	End

	#rem monkeydoc Adds another color or value to the color and returns the result.
	#end
	Operator+:Color( color:Color )
		Return New Color( r+color.r,g+color.g,b+color.b,a+color.a )
	End

	Operator+:Color( offset:Float )
		Return New Color( r+offset,g+offset,b+offset,a+offset )
	End

	#rem monkeydoc Subtracts another color or value from the color and returns the result.
	#end
	Operator-:Color( color:Color )
		Return New Color( r-color.r,g-color.g,b-color.b,a-color.a )
	End

	Operator-:Color( offset:Float )
		Return New Color( r-offset,g-offset,b-offset,a-offset )
	End

	#rem monkeydoc Blends the color with another color and returns the result.
	#end	
	Method Blend:Color( color:Color,delta:Float )
		Local idelta:=1-delta
		Return New Color( r*idelta+color.r*delta,g*idelta+color.g*delta,b*idelta+color.b*delta,a*idelta+color.a*delta )
	End

	#rem monkeydoc Converts the color to 32 bit ARGB format.
	#end	
	Method ToARGB:UInt()
		Return UInt(a*255) Shl 24 | UInt(r*255) Shl 16 | UInt(g*255) Shl 8 | UInt(b*255)
	End
	
	#rem monkeydoc Creates a color from hue, saturation and value.
	#end
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
	
	#rem monkeydoc Creates a color from a 32 bit ARGB color.
	#end
	Function FromARGB:Color( argb:UInt )
		Local a:=(argb Shr 24 & $ff)/255.0
		Local r:=(argb Shr 16 & $ff)/255.0
		Local g:=(argb Shr 8 & $ff)/255.0
		Local b:=(argb & $ff)/255.0
		Return New Color( r,g,b,a )
	End
	
End
