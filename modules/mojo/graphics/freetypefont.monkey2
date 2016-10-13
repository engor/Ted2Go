
Namespace mojo.graphics

#Import "<freetype>"

Private

Using freetype

Global FreeType:FT_Library

Function FontError()
	RuntimeError( "Font error" )
End

Public

#rem monkeydoc @hidden
#end
Class FreeTypeFont Extends Font

	Function Load:FreeTypeFont( path:String,fheight:Float,shader:Shader )
	
		Local ext:=ExtractExt( path )
		If Not ext
			Local font:=Load( path+".otf",fheight,shader )
			If Not font font=Load( path+".ttf",fheight,shader )
			If Not font font=Load( path+".fon",fheight,shader )
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
		
		Local font:=New FreeTypeFont( data,face,fheight,shader )
		
		Return font
	End
	
	Protected
	
	Method OnDiscard() Override
	
		FT_Done_Face( _face )
	
		_data.Discard()
		
		Super.OnDiscard()
	End
	
	Method OnLoadGlyphPage( page:Int,gpage:GlyphPage ) Override
	
		Const MaxTexWidth:=1024
	
		Local firstChar:=page * 256
		Local numChars:=256
	
		Local slot:=_face->glyph
		
		'Measure atlas first
		'
		'Would really rather not render glyphs here, but can't see how...
		'
		Local tx:=0,ty:=0,texw:=0,texh:=0,maxh:=0
		
		For Local i:=-1 Until numChars
		
			If i<0
				If FT_Load_Char( _face,0,FT_LOAD_RENDER|FT_LOAD_FORCE_AUTOHINT ) FontError()
			Else
				If Not FT_Get_Char_Index( _face,firstChar+i ) Or FT_Load_Char( _face,firstChar+i,FT_LOAD_RENDER|FT_LOAD_FORCE_AUTOHINT ) Continue
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
		
		Local pixmap:=New Pixmap( texw,texh,PixelFormat.A8 )
		pixmap.Clear( Color.None )
	
		Local glyphs:=New Glyph[numChars],nullGlyph:Glyph
		
		tx=0;ty=0;maxh=0
		
		For Local i:=-1 Until numChars
		
			If i<0
				If FT_Load_Char( _face,0,FT_LOAD_RENDER|FT_LOAD_FORCE_AUTOHINT ) FontError()
			Else
				If Not FT_Get_Char_Index( _face,firstChar+i ) Or FT_Load_Char( _face,firstChar+i,FT_LOAD_RENDER|FT_LOAD_FORCE_AUTOHINT ) 
					glyphs[i]=nullGlyph
					Continue
				Endif
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
			
			tmp.Discard()
			
			Local glyph:=New Glyph( New Recti( tx,ty,tx+gw,ty+gh ),New Vec2f( slot->bitmap_left,_ascent-slot->bitmap_top ),slot->advance.x Shr 6 )
	
			If i>=0 glyphs[i]=glyph Else nullGlyph=glyph
	
			maxh=Max( maxh,gh+1 )
			tx+=gw+1
		Next
		
		gpage.image=New Image( pixmap,Null,_shader )
		gpage.glyphs=glyphs
		
		pixmap.Discard()
		
'		Print "Loading glyph page "+page+", image size="+gpage.image.Rect.Size
	End

	Private
	
	Field _data:DataBuffer
	Field _face:FT_Face
	Field _shader:Shader
	Field _height:Int
	Field _ascent:Int
	
	Method New( data:DataBuffer,face:FT_Face,fheight:Float,shader:Shader )
		_data=data
		_face=face
		_shader=shader

		Local size_req:FT_Size_RequestRec
		
		size_req.type=FT_SIZE_REQUEST_TYPE_REAL_DIM
		size_req.width=0
		size_req.height=fheight * 64
		size_req.horiResolution=0
		size_req.vertResolution=0
		
		If FT_Request_Size( face,Varptr size_req ) FontError()
		
		_height=(face->size->metrics.height+32) Shr 6
		_ascent=(face->size->metrics.ascender+32) Shr 6

		Local gindex:FT_UInt,nchars:=0
		Local charcode:=FT_Get_First_Char( face,Varptr gindex )
		
		Local pages:=New GlyphPage[256]
		
		Local maxpage:=0
		
		While gindex
		
			Local page:Int=charcode Shr 8
			
			If page>=0 And page<pages.Length
			
				maxpage=Max( maxpage,page )

				If Not pages[page] pages[page]=New GlyphPage
				
			Endif
			
			charcode=FT_Get_Next_Char( face,charcode,Varptr gindex )

		Wend
		
		InitFont( _height,pages.Slice( 0,maxpage+1 ) )
	End
	
End
