
Namespace std

#Import "<stb-image.monkey2>"

Using libc
Using stb.image

#rem monkeydoc Pixmap class.

A pixmap contains a block of memory used to store a rectangular array of pixels.

#end
Class Pixmap

	#rem monkeydoc Creates a new pixmap.

	@param width The width of the pixmap in pixels.
	
	@param height The height of the pixmap in pixels.
	
	@param format The pixmap format.
	
	#end
	Method New( width:Int,height:Int,format:PixelFormat=PixelFormat.Any )
		Self.New( width,height,format,Null,0,Null )
	End

	#rem monkeydoc Releases the memory used by a pixmap.
	
	Memory is only released if the pixmap was created using New, Copy, Convert or Load.
	
	If the pixmap represents a 'window' into another pixmap (ie: it was created using Window) then memory is not released.
	
	Discarding a pixmap also sets its width, height, pitch and depth to 0.
	
	#end
	Method Discard()
		If Not _data Return
		If Not _owner libc.free( _data )
		_width=0
		_height=0
		_pitch=0
		_depth=0
		_format=PixelFormat.None
		_data=Null
		_owner=Null
	End
	
	#rem monkeydoc The pixmap width.
	
	#end
	Property Width:Int()
		Return _width
	End
	
	#rem monkeydoc The pixmap height.
	
	#end
	Property Height:Int()
		Return _height
	End
	
	#rem monkeydoc The pixmap format.
	
	#end
	Property Format:PixelFormat()
		Return _format
	End
	
	#rem monkeydoc The pixmap depth. 
	
	The number of bytes per pixel.
	
	#end
	Property Depth:Int()
		Return _depth
	End
	
	#rem monkeydoc The raw pixmap data.
	
	#end
	Property Data:UByte Ptr()
		Return _data
	End
	
	#rem monkeydoc The pixmap pitch.
	
	This is the number of bytes between one row of pixels in the pixmap and the next.
	
	#end
	Property Pitch:Int()
		Return _pitch
	End
	
	#rem monkeydoc Gets a pointer to a pixel in the pixmap.
	
	@param x the x coordinate of the pixel.
	
	@param y the y coordinate of the pixel.
	
	@return the address of the pixel at `x`, `y`.
	
	#end
	Method PixelPtr:UByte Ptr( x:Int,y:Int )
		Return _data + y*_pitch + x*_depth
	End
	
	#rem monkeydoc Sets a pixel to a color.
	
	Sets the pixel at `x`, `y` to `pixel`.
	
	In debug builds, a runtime error will occur if the pixel coordinates lie outside of the pixmap area.
	
	@param x The x coordinate of the pixel.
	
	@param y The y coordinate of the pixel.
	
	@param color The color to set the pixel to.
	
	#end
	Method SetPixel( x:Int,y:Int,color:Color )
		DebugAssert( x>=0 And y>=0 And x<_width And y<_height )
		
		Local p:=PixelPtr( x,y )
		Select _format
		Case Format.A8
			p[0]=color.a * 255
		Case Format.I8
			p[0]=color.r * 255
		Case Format.IA16
			p[0]=color.r * 255
			p[1]=color.a * 255
		Case Format.RGB24
			p[0]=color.r * 255
			p[1]=color.g * 255
			p[2]=color.b * 255
		Case Format.RGBA32
			p[0]=color.r * 255
			p[1]=color.g * 255
			p[2]=color.b * 255
			p[3]=color.a * 255
		End
	End

	#rem monkeydoc Gets the color of a pixel.
	
	Gets the pixel at `x`, `y` and returns it in ARGB format.
	
	In debug builds, a runtime error will occur if the pixel coordinates lie outside of the pixmap area.

	@param x The x coordinate of the pixel.
	
	@param y The y coordinate of the pixel.
	
	@return The color of the pixel at `x`, `y`.
	
	#end
	Method GetPixel:Color( x:Int,y:Int )
		DebugAssert( x>=0 And y>=0 And x<_width And y<_height )
	
		Local p:=PixelPtr( x,y )
		Select _format
		Case Format.A8 
			Return New Color( 0,0,0,p[0]/255.0 )
		Case Format.I8
			Local i:=p[0]/255.0
			Return New Color( i,i,i,1 )
		Case Format.IA16
			Local i:=p[0]/255.0
			Return New Color( i,i,i,p[1]/255.0 )
		Case Format.RGB24
			Return New Color( p[0]/255.0,p[1]/255.0,p[2]/255.0,1 )
		Case Format.RGBA32
			Return New Color( p[0]/255.0,p[1]/255.0,p[2]/255.0,p[3]/255.0 )
		Default
			Assert( False )
		End
		Return Color.None
	End
	
	#rem monkeydoc Sets a pixel to an ARGB color.
	
	Sets the pixel at `x`, `y` to `pixel`.
	
	In debug builds, a runtime error will occur if the pixel coordinates lie outside of the pixmap area.
	
	@param x The x coordinate of the pixel.
	
	@param y The y coordinate of the pixel.
	
	@param pixel The pixel to set in ARGB format.
	
	#end
	Method SetPixelARGB( x:Int,y:Int,color:UInt )
		DebugAssert( x>=0 And y>=0 And x<_width And y<_height )
	
		Local p:=PixelPtr( x,y )
		Select _format
		Case Format.A8
			p[0]=color Shr 24
		Case Format.I8
			p[0]=color Shr 16
		Case Format.IA16
			p[0]=color Shr 24
			p[1]=color Shr 16
		Case Format.RGB24
			p[0]=color Shr 16
			p[1]=color Shr 8
			p[2]=color
		Case Format.RGBA32
			p[0]=color Shr 16
			p[1]=color Shr 8
			p[2]=color
			p[3]=color Shr 24
		Default
			Assert( False )
		End
	End

	#rem monkeydoc Gets the ARGB color of a pixel.
	
	Get the pixel at `x`, `y` and returns it in ARGB format.

	@param x the x coordinate of the pixel.
	
	@param y the y coordinate of the pixel.
	
	@return the pixel at `x`, `y` in ARGB format.
	
	#end
	Method GetPixelARGB:UInt( x:Int,y:Int )
		DebugAssert( x>=0 And y>=0 And x<_width And y<_height )
	
		Local p:=PixelPtr( x,y )
		Select _format
		Case Format.A8 
			Return p[0] Shl 24
		Case Format.I8 
			Local i:=p[0]
			Return UByte($ff) Shl 24 | i Shl 16 | i Shl 8 | i
		Case Format.IA16
			Local i:=p[1]
			Return p[0] Shl 24 | i Shl 16 | i Shl 8 | i
		Case Format.RGB24
			Return UByte($ff) Shl 24 | p[0] Shl 16 | p[1] Shl 8 | p[2]
		Case Format.RGBA32
			Return p[3] Shl 24 | p[0] Shl 16 | p[1] Shl 8 | p[2]
		Default
			Assert( False )
		End

		Return 0
	End
	
	'Optimize!
	'
	#rem monkeydoc Clears the pixmap to a given color.
	
	@param color The color to clear the pixmap to.
	
	#end
	Method Clear( color:Color )
		For Local y:=0 Until _height
			For Local x:=0 Until _width
				SetPixel( x,y,color )
			Next
		Next
	End
	
	'Optimize!
	'
	#rem monkeydoc Pastes the pixmap to another pixmap.
	
	In debug builds, a runtime error will occur if the operation would write to pixels outside of the target pixmap.

	@param pixmap The pixmap to paste to.
	
	@param x The x coordinate to paste to.
	
	@param y The y coordinate to paste to.
	
	#end
	Method PasteTo( pixmap:Pixmap,x:Int,y:Int )
		DebugAssert( x>=0 And x+_width<=pixmap._width And y>=0 And y+_height=pixmap._height )
		
		'TODO: Check for overlapping rects in same pixmap!
		'
		For Local ty:=0 Until _height
			For Local tx:=0 Until pixmap._width
				pixmap.SetPixel( tx,ty,GetPixel( tx,ty ) )
			Next
		Next
	End

	'Optimize!
	'
	#rem monkeydoc Creates a copy of the pixmap.
	
	@return A new pixmap.
	
	#end
	Method Copy:Pixmap()
		Return Convert( _format )
	End

	'Optimize!
	'
	#rem monkeydoc Converts the pixmap to a different format.
	
	@param format The pixel format to convert the pixmap to.
	
	@return A new pixmap.
	
	#end
	Method Convert:Pixmap( format:PixelFormat )
		Local t:=New Pixmap( _width,_height,format )
		For Local y:=0 Until _height
			For Local x:=0 Until _width
				t.SetPixel( x,y,GetPixel( x,y ) )
			Next
		Next
		Return t
	End
	
	'Optimize!
	'
	#rem monkeydoc Premultiply pixmap r,g,b components by alpha.
	#end
	Method PremultiplyAlpha()
		Select _format
		Case PixelFormat.IA16,PixelFormat.RGBA32
			For Local y:=0 Until _height
				For Local x:=0 Until _width
					Local color:=GetPixel( x,y )
					color.r*=color.a
					color.g*=color.a
					color.b*=color.a
					SetPixel( x,y,color )
				Next
			Next
		End
	End
	
	#rem monkeydoc Returns a rectangular window into the pixmap.
	
	In debug builds, a runtime error will occur if the rectangle lies outside of the pixmap area.
s	
	@param x The x coordinate of the top left of the rectangle.

	@param y The y coordinate of the top left of the rectangle.
	
	@param width The width of the rectangle.

	@param height The height of the rectangle.
	
	#end
	Method Window:Pixmap( x:Int,y:Int,width:Int,height:Int )
		DebugAssert( x>=0 And y>=0 And width>=0 And height>=0 And x+width<=_width And y+height<=_height )
		
		Return New Pixmap( width,height,_format,PixelPtr( x,y ),_pitch,Self )
	End
	
	#rem monkeydoc Loads a pixmap from a file.
	
	@param path The file path.
	
	@param format The format to load the pixmap in.
	
	@return Null if the file could not be opened, or contained invalid image data.
	
	#end
	Function Load:Pixmap( path:String,format:PixelFormat=PixelFormat.Any )
	
		Local x:Int,y:Int,comp:Int,req_comp:Int
		
		Select format
		Case PixelFormat.Any
			req_comp=0
		Case PixelFormat.A8,PixelFormat.I8
			req_comp=1
		Case PixelFormat.IA16
			req_comp=2
		Case PixelFormat.RGB24
			req_comp=3
		Case PixelFormat.RGBA32
			req_comp=4
		Default
			'THROW
		End
		
		Local stream:=Stream.Open( path,"r" )
		If Not stream Return Null
		
		Local user:stbi_user
		user.stream=stream
		
		Local clbks:stbi_io_callbacks
		clbks.read=stbi_read
		clbks.skip=stbi_skip
		clbks.eof=stbi_eof
		
		Local data:=stbi_load_from_callbacks( Varptr clbks,Varptr user,Varptr x,Varptr y,Varptr comp,req_comp )
		
		stream.Close()
		
		If Not data Return Null
		
		If format=PixelFormat.Any
			Select comp
			Case 1 
				format=PixelFormat.I8
			Case 2
				format=PixelFormat.IA16
			Case 3
				format=PixelFormat.RGB24
			Case 4
				format=PixelFormat.RGBA32
			Default
				Assert( False )
			End
		End
		
		Return New Pixmap( x,y,format,data,0,null )
	End
	
	Private
	
	Field _width:Int
	Field _height:Int
	Field _format:PixelFormat
	Field _depth:Int
	Field _data:UByte Ptr
	Field _pitch:Int
	Field _owner:Pixmap
	
	Struct stbi_user
		Field stream:Stream
	End
	
	Function stbi_read:Int( user:Void Ptr,data:stbi_char Ptr,count:Int )
		Local stream:=Cast<stbi_user Ptr>( user )[0].stream
		Return stream.Read( data,count )
	End
	
	Function stbi_skip:Void( user:Void Ptr,count:Int )
		Local stream:=Cast<stbi_user Ptr>( user )[0].stream
		stream.Seek( stream.Position+count )
	End
	
	Function stbi_eof:Int( user:Void Ptr )
		Local stream:=Cast<stbi_user Ptr>( user )[0].stream
		Return stream.Eof
	End
	
	Method New( width:Int,height:Int,format:PixelFormat,data:UByte Ptr,pitch:Int,owner:Pixmap )
	
		If format=PixelFormat.Any format=PixelFormat.RGBA32
	
		Local depth:=0
		Select format
		Case PixelFormat.A8
			depth=1
		Case PixelFormat.I8
			depth=1
		Case PixelFormat.IA16
			depth=2
		Case PixelFormat.RGB24
			depth=3
		Case PixelFormat.RGBA32
			depth=4
		Default
			'THROW
		End
		
		_width=width
		_height=height
		_format=format
		_depth=depth
		
		_data=data
		_pitch=pitch
		_owner=owner
		
		If Not _pitch _pitch=_width*_depth
		
		If Not _data _data=Cast<UByte Ptr>( libc.malloc( _pitch*_height ) )
	End

End
