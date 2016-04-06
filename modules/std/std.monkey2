
Namespace std

#Import "<libc.monkey2>"

#Import "collections/container.monkey2"
#Import "collections/stack.monkey2"
#Import "collections/list.monkey2"
#Import "collections/map.monkey2"

#Import "memory/byteorder.monkey2"
#Import "memory/databuffer.monkey2"

#Import "stream/stream.monkey2"
#Import "stream/filestream.monkey2"
#Import "stream/datastream.monkey2"
#Import "stream/zipstream.monkey2"

#Import "geom/vec2.monkey2"
#Import "geom/vec3.monkey2"
#Import "geom/vec4.monkey2"
#Import "geom/mat3.monkey2"
#Import "geom/mat4.monkey2"
#Import "geom/affinemat3.monkey2"
'#Import "geom/affinemat4.monkey2"
#Import "geom/rect.monkey2"

#Import "graphics/pixelformat.monkey2"
#Import "graphics/pixmap.monkey2"
#Import "graphics/pixmaploader.monkey2"
#Import "graphics/color.monkey2"

#Import "misc/random.monkey2"
#Import "misc/chartype.monkey2"
#Import "misc/filesystem.monkey2"
#Import "misc/stringio.monkey2"
#Import "misc/json.monkey2"
#Import "misc/markdown.monkey2"
#Import "misc/time.monkey2"

'#Import "_dev/fiber.monkey2"
'#Import "_dev/generator.monkey2"

Private

Function Main()

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
