
Namespace mojo.graphics

#rem monkeydoc The Glyph struct.
#end
Struct Glyph

	Field rect:Recti
	Field offset:Vec2f
	Field advance:Float
	
	Method New( rect:Recti,offset:Vec2f,advance:Float )
		Self.rect=rect
		Self.offset=offset
		Self.advance=advance
	End

End

#rem monkeydoc The Font class.
#end
Class Font

	Method New( image:Image,height:Float,firstChar:Int,glyphs:Glyph[] )
		_image=image
		_height=height
		_firstChar=firstChar
		_glyphs=glyphs
	End
	
	Property Image:Image()
	
		Return _image
	End
	
	Property Height:Float()
	
		Return _height
	End
	
	Property FirstChar:Int()
	
		Return _firstChar
	End
	
	Property NumChars:Int()
	
		Return _glyphs.Length
	End
	
	#rem monkeydoc @hidden
	#end
	Property Glyphs:Glyph[]()
	
		Return _glyphs
	End
	
	Method GetGlyph:Glyph( char:Int )
		If char>=_firstChar And char<_firstChar+_glyphs.Length Return _glyphs[ char-_firstChar ]
		Return _glyphs[0]
	End
	
	Method TextWidth:Float( text:String )
		Local w:=0.0
		For Local char:=Eachin text
			w+=GetGlyph( char ).advance
		Next
		Return w
	End
	
	#rem monkeydoc @hidden
	#end
	Function Open:Font( path:String,height:Float )
	
		Local tag:=RealPath( path )+":"+height
		
		Local font:=_openFonts[tag]
		If Not font
			font=Load( path,height )
			_openFonts[tag]=font
		Endif
		
		Return font
	End

	'Make this ALWAYS work!	
	Function Load:Font( path:String,height:Float )
	
		Local font:=fontloader.LoadFont( path,height )
		
		Return font
	End

	Private
	
	Private
	
	Field _image:Image
	Field _height:Float
	Field _firstChar:Int
	Field _glyphs:Glyph[]
	
	Global _openFonts:=New StringMap<Font>

End

