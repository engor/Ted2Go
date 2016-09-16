
Namespace std

#Import "<libc.monkey2>"
#Import "<stb-image>"
#Import "<stb-image-write>"
#import "<stb-vorbis>"

#Import "collections/container"
#Import "collections/stack"
#Import "collections/list"
#Import "collections/map"
#Import "collections/deque"

#Import "memory/byteorder"
#Import "memory/databuffer"

#Import "stream/stream"
#Import "stream/filestream"
#Import "stream/datastream"
#Import "stream/zipstream"

#Import "geom/vec2"
#Import "geom/vec3"
#Import "geom/vec4"
#Import "geom/mat3"
#Import "geom/mat4"
#Import "geom/affinemat3"
'#Import "geom/affinemat4"
#Import "geom/rect"
#Import "geom/axis"

#Import "graphics/pixelformat"
#Import "graphics/pixmap"
#Import "graphics/pixmaploader"
#Import "graphics/pixmapsaver"
#Import "graphics/color"

#import "audio/audioformat"
#import "audio/audiodata"
#import "audio/load_wav"
#import "audio/load_vorbis"

#Import "async/async"
#Import "time/time"
#Import "time/timer"
#Import "fiber/fiber"
#Import "fiber/future"
#Import "process/process"
#Import "filesystem/filesystem"

#Import "misc/random"
#Import "misc/chartype"
#Import "misc/stringio"
#Import "misc/json"
#Import "misc/jsonify"
#Import "misc/zipfile"

#Import "socket/socket"

Private

Function Main()

	'Capture app start time
	'
	std.time.Microsecs()

	Stream.OpenFuncs["zip"]=Lambda:Stream( proto:String,path:String,mode:String )

		Return ZipStream.Open( path,mode )
	End

	Stream.OpenFuncs["file"]=Lambda:Stream( proto:String,path:String,mode:String )

		Return FileStream.Open( path,mode )
	End
	
	'Note: "asset::" support for android/ios is in mojo, as it uses SDL_RWop and we don't want to std to be dependant on SDL2...
	'	
#If Not __MOBILE_TARGET__
	
	Stream.OpenFuncs["asset"]=Lambda:Stream( proto:String,path:String,mode:String )

		Return FileStream.Open( filesystem.AssetsDir()+path,mode )

	End
	
#endif
	
End
