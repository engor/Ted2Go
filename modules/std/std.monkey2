
Namespace std

#Import "<libc.monkey2>"
#Import "<stb-image>"
#Import "<stb-image-write>"

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
#import "audio/audioloader"

#Import "misc/random"
#Import "misc/chartype"
#Import "misc/filesystem"
#Import "misc/stringio"
#Import "misc/json"
#Import "misc/time"

#Import "fiber/fiber"
#Import "fiber/future"
'#Import "_dev/fiber"
'#Import "_dev/generator"

Private

Function Main()

	'capture app start time
	std.time.Microsecs()

	Stream.OpenFuncs["file"]=Lambda:Stream( proto:String,path:String,mode:String )

		Return FileStream.Open( path,mode )
	End
	
	Stream.OpenFuncs["asset"]=Lambda:Stream( proto:String,path:String,mode:String )
	
		Return FileStream.Open( filesystem.AssetsDir()+path,mode )
	End
	
	Stream.OpenFuncs["zip"]=Lambda:Stream( proto:String,path:String,mode:String )

		Return ZipStream.Open( path,mode )
	End

End
