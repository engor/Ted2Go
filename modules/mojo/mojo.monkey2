
Namespace mojo

#Import "assets/"

#Import "<emscripten>"
#Import "<std>"
#Import "<sdl2>"
#Import "<gles20>"
#Import "<openal>"

#Import "app/app"
#Import "app/event"
#Import "app/skin"
#Import "app/style"
#Import "app/theme"

#Import "app/view"
#Import "app/window"
#Import "app/glwindow"

#Import "app/sdl_rwstream.monkey2"

#Import "graphics/canvas"
#Import "graphics/font"
#Import "graphics/fontloader"
#Import "graphics/glutil"
#Import "graphics/graphicsdevice"
#Import "graphics/image"
#Import "graphics/indexbuffer"
#Import "graphics/shader"
#Import "graphics/shadowcaster"
#Import "graphics/texture"
#Import "graphics/uniformblock"
#Import "graphics/vertex"
#Import "graphics/vertexbuffer"

#Import "input/device"
#Import "input/keyboard"
#Import "input/mouse"
#Import "input/joystick"
#Import "input/keycodes"

#Import "requesters/requesters"
#Import "audio/audio"

Using emscripten..
Using std..
Using sdl2..
Using gles20..
Using openal..
Using mojo..

Private

Function Main()

	Stream.OpenFuncs["font"]=Lambda:Stream( proto:String,path:String,mode:String )
	
		Return Stream.Open( "asset::fonts/"+path,mode )
	End
		
	Stream.OpenFuncs["image"]=Lambda:Stream( proto:String,path:String,mode:String )
	
		Return Stream.Open( "asset::images/"+path,mode )
	End

	Stream.OpenFuncs["theme"]=Lambda:Stream( proto:String,path:String,mode:String )
	
		If Not App Or Not App.Theme Or Not App.Theme.Path Return Null

		Return Stream.Open( ExtractDir( App.Theme.Path )+path,mode )
	End
	
#if __TARGET__="android"

	Stream.OpenFuncs["asset"]=Lambda:Stream( proto:String,path:String,mode:String )
	
		Return SDL_RWStream.Open( path,mode )

	End

#else if __TARGET__="ios"

	Stream.OpenFuncs["asset"]=Lambda:Stream( proto:String,path:String,mode:String )
	
		Return SDL_RWStream.Open( "assets/"+path,mode )

	End
	
#endif
	
End
