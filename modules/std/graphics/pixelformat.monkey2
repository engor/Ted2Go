
Namespace std.graphics

#rem monkeydoc Pixel formats supported by pixmaps.

| PixelFormat	| Description
|:--------------|:-----------
| `Unknown`		| Unknown pixel format.
| `I8`			| 8 bit intensity.
| `A8`			| 8 bit alpha.
| `IA16`		| 8 bit intensity, alpha.
| `RGB24`		| 8 bit red, green, blue.
| `RGBA32`		| 8 bit red, green, blue, alpha.

#end
Enum PixelFormat

	Unknown,I8,A8,IA16,RGB24,RGBA32

End

#rem monkeydoc Gets the number of bytes per pixel for a particular pixel format.
#end
Function PixelFormatDepth:Int( format:PixelFormat )

	Select format
	Case PixelFormat.I8 Return 1
	Case PixelFormat.A8 Return 1
	Case PixelFormat.IA16 Return 2
	Case PixelFormat.RGB24 Return 3
	Case PixelFormat.RGBA32 Return 4
	End
	
	Return 0
End
