
Namespace mojo.graphics.fontloader

#Import "<stb-truetype>"

Using stb.truetype

#rem monkeydoc @hidden
#end
Function LoadFont:Font( path:String,height:Float )

	Local firstChar:=32
	Local numChars:=96

	Local data:=DataBuffer.Load( path )
	If Not data Return Null
	
	'Get font info
	Local f:stbtt_fontinfo,fp:=Varptr f
	If Not stbtt_InitFont( fp,data.Data,0 ) Return Null

	Local ascenti:Int,descenti:Int,linegapi:Int
	stbtt_GetFontVMetrics( fp,Varptr ascenti,Varptr descenti,Varptr linegapi )
	
	Local scale:=stbtt_ScaleForPixelHeight( fp,height )

	Local ascent:=ascenti*scale,descent:=descenti*scale,linegap:=linegapi*scale
	
	Local fheight:=(ascenti-descenti+linegapi)*scale
	
	'Bake the chars		
	Local bakedChars:=New stbtt_bakedchar[numChars]
	Local pixmap:=New Pixmap( 512,512,PixelFormat.A8 )
	stbtt_BakeFontBitmap( data.Data,0,height,pixmap.Data,512,512,firstChar,numChars,bakedChars.Data )

	Local image:=New Image( pixmap,Shader.GetShader( "font" ) )
	
	Local glyphs:=New Glyph[numChars]
	
	For Local i:=0 Until numChars
	
		Local x:=bakedChars[i].x0
		Local y:=bakedChars[i].y0
		Local w:=bakedChars[i].x1-x
		Local h:=bakedChars[i].y1-y
		Local xoffset:=bakedChars[i].xoff
		Local yoffset:=bakedChars[i].yoff+ascent
		Local advance:=bakedChars[i].xadvance
		
		glyphs[i]=New Glyph( New Recti( x,y,x+w,y+h ),New Vec2f( xoffset,yoffset ),advance )
		
	Next
	
	Local font:=New Font( image,fheight,firstChar,glyphs )
	
	Return font
End
