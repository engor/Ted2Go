
Namespace mojo.graphics.fontloader

#Import "<freetype>"

Private

Using freetype

Global FreeType:FT_Library

Public

#rem monkeydoc @hidden
#end
Function LoadFont:Font( path:String,fheight:Float )

	If Not FreeType And FT_Init_FreeType( Varptr FreeType ) Return Null
	
	Local data:=DataBuffer.Load( path )
	If Not data Return Null
	
	Local face:FT_Face
	
	If FT_New_Memory_Face( FreeType,data.Data,data.Length,0,Varptr face ) 
		data.Discard()
		Return Null
	Endif
	
	Local size_req:FT_Size_RequestRec
	
	size_req.type=FT_SIZE_REQUEST_TYPE_REAL_DIM
	size_req.width=0
	size_req.height=fheight * 64
	size_req.horiResolution=0
	size_req.vertResolution=0
	
	If FT_Request_Size( face,Varptr size_req )
		data.Discard()
		Return Null
	Endif
	
	Local height:=(face->size->metrics.height+32) Shr 6
	Local ascent:=(face->size->metrics.ascender+32) Shr 6

'	Print face->size->metrics.height/64.0
'	Print face->size->metrics.ascender/64.0
'	Print face->size->metrics.descender/64.0

	Local firstChar:=32,numChars:=96

	Local glyphs:=New Glyph[numChars]
	Local pixmap:=New Pixmap( 512,512,PixelFormat.A8 )
	pixmap.Clear( Color.None )
	
	Local slot:=face->glyph
	
	Local x:=0,y:=0,h:=0
	
	For Local i:=0 Until numChars
	
		If FT_Load_Char( face,firstChar+i,FT_LOAD_RENDER )
'		If FT_Load_Char( face,firstChar+i,FT_LOAD_RENDER|FT_LOAD_NO_HINTING )
'		If FT_Load_Char( face,firstChar+i,FT_LOAD_RENDER|FT_LOAD_FORCE_AUTOHINT )
			Continue
		Endif
		
		#rem
		If FT_Render_Glyph( slot,FT_RENDER_MODE_NORMAL )
			Continue
		Endif
		#end
		
		Local gw:=slot->bitmap.width
		Local gh:=slot->bitmap.rows
		
		If x+gw+1>pixmap.Width
			y+=h
			h=0
			x=0
		Endif
		
		Local tmp:=New Pixmap( gw,gh,PixelFormat.A8,slot->bitmap.buffer,slot->bitmap.pitch,Null )
		
		pixmap.Paste( tmp,x,y )
		
		glyphs[i]=New Glyph( New Recti( x,y,x+gw,y+gh ),New Vec2f( slot->bitmap_left,ascent-slot->bitmap_top ),slot->advance.x Shr 6 )

		h=Max( Int(h),Int(gh)+1 )
		x+=gw+1
	Next
	
	FT_Done_Face( face )
	
	data.Discard()
	
	Local image:=New Image( pixmap,Shader.GetShader( "font" ) )
	
	Local font:=New Font( image,height,firstChar,glyphs )
	
	Return font

End
