
Namespace std.audio

Function LoadAudioData_OGG:AudioData( path:String )

	Local buf:=std.memory.DataBuffer.Load( path )
	If Not buf Return Null
	
	Local channels:Int
	Local hertz:Int
	Local samples:Short Ptr
	
	Local length:=stb.vorbis.stb_vorbis_decode_memory( buf.Data,buf.Length,Varptr channels,Varptr hertz,Varptr samples )
	
	If length=-1 Return Null
	
	Local format:AudioFormat
	Select channels
	Case 1 
		format=AudioFormat.Mono16
	Case 2 
		format=AudioFormat.Mono16
	Default
		libc.free( samples )
		Return Null
	End
	
	Local data:=New AudioData( length,format,hertz,samples )
	
	data.OnDiscarded+=Lambda()
		libc.free( samples )
	End
	
	Return data

End



