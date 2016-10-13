
Namespace mojo.graphics

Using std.resource

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

Class GlyphPage

	Field image:Image
	Field glyphs:Glyph[]

End

Class Font Extends Resource

	#rem monkeydoc The font height in pixels.
	#end
	Property Height:Float()
	
		Return _height
	End
	
	#rem monkeydoc Measures the width of some text when rendered by the font.
	#end
	Method TextWidth:Float( text:String )
		Local w:=0.0
		For Local char:=Eachin text
			w+=GetGlyph( char ).advance
		Next
		Return w
	End

	#rem monkeydoc @hidden
	
	Gets the glyph page for a given char.
	
	Returns null if char does not have a glyph.
	
	#end	
	Method GetGlyphPage:GlyphPage( char:Int )
		Local page:=char Shr 8
		If page<0 Or page>=_pages.Length Return Null
		
		Local gpage:=_pages[page]
		If Not gpage Return Null
		
		If Not gpage.image LoadGlyphPage( page )
				
		Local index:=char & 255
		If index>=gpage.glyphs.Length Return Null
		
		Return gpage
	End
	
	#rem monkeydoc @hidden
	
	Gets the glyph for a given char.

	#end
	Method GetGlyph:Glyph( char:Int )
		Local page:=char Shr 8
		If page<0 Or page>=_pages.Length Return _nullGlyph

		Local gpage:=_pages[page]
		If Not gpage Return _nullGlyph

		If Not gpage.image LoadGlyphPage( page )
				
		Local index:=char & 255
		If index>=gpage.glyphs.Length Return _nullGlyph
		
		Return gpage.glyphs[index]
	End
	
	#rem monkeydoc Loads a font from a file.
	#end
	Function Load:Font( path:String,height:Float,shader:Shader=Null )
	
		If Not shader shader=Shader.GetShader( "font" )
		
		Local font:=FreeTypeFont.Load( path,height,shader )
		If Not font And Not ExtractRootDir( path ) font=FreeTypeFont.Load( "font::"+path,height,shader )
		
		Return font
	End
	
	Protected
	
	Method OnLoadGlyphPage( page:Int,gpage:GlyphPage ) Abstract
	
	Method InitFont( height:Float,pages:GlyphPage[] )
	
		_height=height
		_pages=pages
		
		LoadGlyphPage( 0 )
		
		_nullGlyph=GetGlyph( 0 )
	End
	
	Method OnDiscard() Override
	
		For Local page:=Eachin _pages
			If page And page.image page.image.Discard()
		Next
		
		_pages=Null
		
	End
	
	Private
	
	Field _height:Float

	Field _pages:GlyphPage[]
	
	Field _nullGlyph:Glyph
	
	Method LoadGlyphPage( page:Int )
	
		Local gpage:=_pages[page]
		
		If Not gpage.image OnLoadGlyphPage( page,gpage )
	End

End

Class ResourceManager Extension

	Method OpenFont:Font( path:String,height:Float,shader:Shader=Null )
	
		Local slug:="Font:name="+StripDir( StripExt( path ) )+"&height="+height+"&shader="+(shader ? shader.Name Else "")
		
		Local font:=Cast<Font>( OpenResource( slug ) )
		If font Return font
		
		font=Font.Load( path,height )
		
		AddResource( slug,font )
		Return font
	End

End

