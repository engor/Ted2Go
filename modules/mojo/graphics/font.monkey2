
Namespace mojo.graphics

#rem monkeydoc The Glyph struct.

Glyph are used to store the individual character data for fonts.

#end
Struct Glyph

	Field rect:Recti
	Field offset:Vec2f
	Field advance:Float

	#rem monkeydoc Creates a new glyph.
	#end
	Method New( rect:Recti,offset:Vec2f,advance:Float )
		Self.rect=rect
		Self.offset=offset
		Self.advance=advance
	End

End

#rem monkeydoc The Font class.

Mojo fonts use an image atlas system for storing font data.

The glyph struct is used to store the location, size and advance for individual characters within a font.
All character image data for a font must A font must occupy a single image, 

#end
Class Font

	#rem monkeydoc Creates a new font.

	@param image The image atlas.

	@param height The height of the font in pixels.

	@param firstChar The first character contained in the font.

	@param glyphs An array of glyph structs describing the characters in the font.

	#end
	Method New( image:Image,height:Float,firstChar:Int,glyphs:Glyph[] )
		_image=image
		_height=height
		_firstChar=firstChar
		_glyphs=glyphs
	End
	
	#rem monkeydoc The font image atlas.
	#end
	Property Image:Image()
	
		Return _image
	End
	
	#rem monkeydoc The font height in pixels.
	#end
	Property Height:Float()
	
		Return _height
	End
	
	#rem monkeydoc The first character contained in the font.
	#end
	Property FirstChar:Int()
	
		Return _firstChar
	End
	
	#rem monkeydoc The number of characters in the font.
	#end
	Property NumChars:Int()
	
		Return _glyphs.Length
	End
	
	#rem monkeydoc @hidden
	#end
	Property Glyphs:Glyph[]()
	
		Return _glyphs
	End
	
	#rem monkeydoc Gets a glyph from the font.
	#end
	Method GetGlyph:Glyph( char:Int )
		If char>=_firstChar And char<_firstChar+_glyphs.Length Return _glyphs[ char-_firstChar ]
		Return _glyphs[0]
	End
	
	#rem monkedoc Measures the width of some text when rendered by the font.
	#end
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
	#rem monkeydoc Loads a font from a ttf file.
	#end
	Function Load:Font( path:String,height:Float,textureFlags:TextureFlags=Null,shader:Shader=Null )
	
		If Not shader shader=Shader.GetShader( "font" )
		
		Local font:=fontloader.LoadFont( path,height,textureFlags,shader )
		
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

