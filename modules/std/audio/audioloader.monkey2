
#include "<libc>"

Namespace std.audio.wavloader

Private

Using std.stream

Struct WAV_Header
	'
	Field RIFF:Int
	Field len:Int
	Field WAVE:Int
	Field fmt:Int
	Field headerLen:Int
	'
	Field formatTag:Short
	Field numChannels:Short
	Field samplesPerSec:Int
	Field avgBytesPerSec:Int
	Field blockalignment:Short
	Field bitsPerSample:Short
	'
End

Function ReadWAV:AudioData( stream:Stream )

	Local header:=New WAV_Header
	Local header_sz:=libc.sizeof( header )
	
	If stream.Read( Varptr header,header_sz )<>header_sz Return null

	If header.RIFF<>$46464952 Return Null

	Local format:AudioFormat
	
	If header.numChannels=1 And header.bitsPerSample=8
		format=AudioFormat.Mono8
	Else If header.numChannels=1 And header.bitsPerSample=16
		format=AudioFormat.Mono16
	Else If header.numChannels=2 And header.bitsPerSample=8
		format=AudioFormat.Stereo8
	Else If header.numChannels=2 And header.bitsPerSample=16
		format=AudioFormat.Stereo16
	Else
		Return Null
	Endif
	
	Local skip:=header.headerLen-16
	If skip>0 stream.Skip( skip )
	
	While Not stream.Eof
	
		Local tag:=stream.ReadInt()
		Local size:=stream.ReadInt()
		
		If tag<>$61746164	'"DATA"
			stream.Skip( size )
			Continue
		Endif
		
		Local data:=New AudioData( size/BytesPerSample( format ),format,header.samplesPerSec )
		
		stream.Read( data.Data,size )
		
		Return data

	Wend
	
	Return Null

End

Public

Function LoadAudioData:AudioData( path:String )

	Local stream:=Stream.Open( path,"r" )
	If Not stream Return Null
	
	Local data:=ReadWAV( stream )
	
	stream.Close()
	Return data

End
