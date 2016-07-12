
Namespace std.audio

Enum AudioFormat
	Mono8=1
	Mono16=2
	Stereo8=3
	Stereo16=4
End

Function BytesPerSample:Int( format:AudioFormat )
	Select format
	Case AudioFormat.Mono8 Return 1
	Case AudioFormat.Mono16 Return 2
	Case AudioFormat.Stereo8 Return 2
	Case AudioFormat.Stereo16 Return 4
	End
	Return 0
End

