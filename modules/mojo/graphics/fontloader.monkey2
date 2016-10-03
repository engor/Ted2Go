
Namespace mojo.graphics.fontloader

#Import "<freetype>"

Private

Using freetype

Global FreeType:FT_Library

Public

#rem monkeydoc @hidden
#end
Function LoadFont:Font( path:String,fheight:Float,shader:Shader )

	Local ext:=ExtractExt( path )
	If Not ext
		Local font:=LoadFont( path+".otf",fheight,shader )
		If Not font font=LoadFont( path+".ttf",fheight,shader )
		Return font
	Endif

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

	Local slot:=face->glyph
	
	'Measure atlas first
	'
	'Would really rather not render glyphs here, but can't see how...
	'
	Local tx:=0,ty:=0,texw:=0,texh:=0,maxh:=0
	
	Const MaxTexWidth:=64'1024

	For Local i:=0 Until numChars

		If FT_Load_Char( face,firstChar+i,FT_LOAD_RENDER|FT_LOAD_FORCE_AUTOHINT )
			Continue
		Endif

		Local gw:=Int( slot->bitmap.width )
		Local gh:=Int( slot->bitmap.rows )
		
		If tx+gw+1>MaxTexWidth
			texw=Max( texw,tx )
			texh+=maxh
			maxh=0
			tx=0
		Endif
		
		maxh=Max( maxh,gh+1 )
		tx+=gw+1
		
	Next
	
	texw=Max( texw,tx )
	If tx texh+=maxh
	
	'round up texw, texh to ^2 in case we're mipmapping on mobile/webgl.
	texw=1 Shl Int( Ceil( Log2( texw ) ) )
	texh=1 Shl Int( Ceil( Log2( texh ) ) )
	
	Print "path="+path+", height="+fheight+", texw="+texw+", texh="+texh
	
	Local pixmap:=New Pixmap( texw,texh,PixelFormat.A8 )
	pixmap.Clear( Color.None )
	
	tx=0;ty=0;maxh=0
	
	For Local i:=0 Until numChars

		If FT_Load_Char( face,firstChar+i,FT_LOAD_RENDER|FT_LOAD_FORCE_AUTOHINT )
			Continue
		Endif
		
		Local gw:=Int( slot->bitmap.width )
		Local gh:=Int( slot->bitmap.rows )

		Local tmp:=New Pixmap( gw,gh,PixelFormat.A8,slot->bitmap.buffer,slot->bitmap.pitch )
		
		If tx+gw+1>pixmap.Width
			ty+=maxh
			maxh=0
			tx=0
		Endif
		
		pixmap.Paste( tmp,tx,ty )
		
		glyphs[i]=New Glyph( New Recti( tx,ty,tx+gw,ty+gh ),New Vec2f( slot->bitmap_left,ascent-slot->bitmap_top ),slot->advance.x Shr 6 )

		maxh=Max( maxh,gh+1 )
		tx+=gw+1
		
	Next
	
	FT_Done_Face( face )
	
	data.Discard()
	
	Local image:=New Image( pixmap,Null,shader )
	
	Local font:=New Font( image,height,firstChar,glyphs )
	
	font.OnDiscarded+=Lambda()
		image.Discard()
		pixmap.Discard()
	End
	
	Return font
End
