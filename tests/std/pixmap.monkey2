
#Import "<std.monkey2>"

Using std
Using std.graphics
Using std.stringio
Using std.chartype
Using std.filesystem

Function Main()

	Local pixmap:=New Pixmap( 2,2 )
	
	Print pixmap.Width						'2
	Print pixmap.Height						'2
	Print Int( pixmap.Format )				'5
	Print pixmap.Pitch						'8
	Print ""
	
	pixmap.Clear( New Color( .25,.5,.75,.5 ) )
	pixmap.SetPixel( 0,0,New Color( 1,0,0,.5 ) )
	pixmap.SetPixel( 1,0,New Color( 0,1,0,.25 ) )
	pixmap.SetPixel( 0,1,New Color( 0,0,1,.75 ) )
'	pixmap.SetPixel( 1,1,New Color( .25,.5,.75,.5 ) )
	
	Print Hex( pixmap.GetPixelARGB( 0,0 ) )	'7FFF0000
	Print Hex( pixmap.GetPixelARGB( 1,0 ) )	'3F00FF00
	Print Hex( pixmap.GetPixelARGB( 0,1 ) )	'BF0000FF
	Print Hex( pixmap.GetPixelARGB( 1,1 ) )	'7F3F7FBF
	
	pixmap.PremultiplyAlpha()
	
	Print Hex( pixmap.GetPixelARGB( 0,0 ) )	'7F7F0000
	Print Hex( pixmap.GetPixelARGB( 1,0 ) )	'3F003F00
	Print Hex( pixmap.GetPixelARGB( 0,1 ) )	'BF0000BF
	Print Hex( pixmap.GetPixelARGB( 1,1 ) )	'7F1F3F5F
	
End
