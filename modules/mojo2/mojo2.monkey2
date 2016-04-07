
Namespace mojo2

#Import "<libc>"
#Import "<gles20>"
#Import "<std>"
#Import "<stb-truetype>"

#Import "math3d.monkey2"
#Import "glutil.monkey2"
#Import "graphics.monkey2"
#Import "glslparser.monkey2"
#Import "renderer.monkey2"

Using libc
Using gles20

Using std.memory
Using std.graphics
Using std.collections

Using stb.truetype

Global DeviceWidth:=640
Global DeviceHeight:=480

Function Mojo2Error( msg:String )
	Print( "Mojo2 error:"+msg )
	exit_( -1 )
End
