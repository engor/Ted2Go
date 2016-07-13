
Namespace std.audio

Class AudioData

	Field OnDiscarded:Void()

	Method New( length:Int,format:AudioFormat,hertz:Int )
	
		Local data:=libc.malloc( BytesPerSample( format )*length )
		
		_length=length
		_format=format
		_hertz=hertz
		_data=Cast<UByte Ptr>( data )
		
		OnDiscarded=Lambda()
			libc.free( data )
		End
	End

	Method New( length:Int,format:AudioFormat,hertz:Int,data:Void Ptr )
		_length=length
		_format=format
		_hertz=hertz
		_data=Cast<UByte Ptr>( data )
	End
	
	Property Length:Int()
	
		Return _length
	End
	
	Property Format:AudioFormat()
		
		Return _format
	End
	
	Property Hertz:Int()
	
		Return _hertz
	End
	
	Property Data:UByte Ptr()
	
		Return _data
	End
	
	Property Size:Int()
	
		Return BytesPerSample( _format ) * _length
	End
	
	Method Discard()
		If _discarded Return
		_discarded=True
		OnDiscarded()
		_length=0
		_format=Null
		_data=Null
	End
	
	Function Load:AudioData( path:String )
	
		Select ExtractExt( path ).ToLower()
		Case ".wav" Return LoadAudioData_WAV( path )
		Case ".ogg" Return LoadAudioData_OGG( path )
		End
		
		Return Null
	End
	
	Private
	
	Field _length:Int
	Field _format:AudioFormat
	Field _hertz:Int
	Field _data:UByte Ptr
	Field _discarded:Bool
	
End
