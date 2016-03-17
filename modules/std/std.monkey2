
Namespace std

#Import "<libc.monkey2>"

#Import "container.monkey2"
#Import "stack.monkey2"
#Import "list.monkey2"
#Import "map.monkey2"
#Import "random.monkey2"
#Import "chartype.monkey2"

#Import "filesystem.monkey2"
#Import "filesystemex.monkey2"

#Import "byteorder.monkey2"

#Import "stream.monkey2"
#Import "filestream.monkey2"
#Import "databuffer.monkey2"

#Import "stringio.monkey2"
#Import "datastream.monkey2"
#Import "zipstream.monkey2"
#Import "fiber.monkey2"

#Import "pixelformat.monkey2"
#Import "color.monkey2"
#Import "pixmap.monkey2"

#Import "generator.monkey2"

#Import "geom.monkey2"
'#Import "json.monkey2"

#Import "time.monkey2"

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
