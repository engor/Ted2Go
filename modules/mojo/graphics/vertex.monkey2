
Namespace mojo.graphics

#rem monkeydoc @hidden
#end	
Struct Vertex2f

	Field x:Float,y:Float	'mx2_Vertex
	Field s0:Float,t0:Float	'mx2_TexCoord0
	Field ix:Float,iy:Float	'mx2_Tangent
	Field color:UInt		'mx2_Color
	
	Method New()
	End
	
	Method New( position:Vec2f,texCoord0:Vec2f=New Vec2f,tangent:Vec2f=New Vec2f,colorARGB:UInt=$ffffffff )
		Position=position
		TexCoord0=texCoord0
		Tangent=tangent
		ColorARGB=colorARGB
	End
	
	Method New( x:Float,y:Float,s0:Float=0,t0:Float=0,ix:Float=0,iy:Float=0,colorARGB:UInt=$ffffffff )
		Self.x=x;Self.y=y
		Self.s0=s0;Self.t0=t0
		Self.ix=ix;Self.iy=iy
		Self.color=colorARGB
	End
	
	Property Position:Vec2f()
		Return New Vec2f( x,y )
	Setter( position:Vec2f )
		x=position.x
		y=position.y
	End
	
	Property TexCoord0:Vec2f()
		Return New Vec2f( s0,t0 )
	Setter( texCoord0:Vec2f )
		s0=texCoord0.x
		t0=texCoord0.y
	End
	
	Property Tangent:Vec2f()
		Return New Vec2f( ix,iy )
	Setter( tangent:Vec2f )
		ix=tangent.x
		iy=tangent.y
	End
	
	Property ColorARGB:UInt()
		Return color
	Setter( colorARGB:UInt )
		color=colorARGB
	End
	
End
