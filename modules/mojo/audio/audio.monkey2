
Namespace mojo.audio

Private

Global _alloced:Int[]

Public

Global Audio:=New AudioDevice

Class AudioDevice

	'***** Internal *****
	
	#rem monkeydoc @hidden
	#end
	Method Init()
	
		Mix_Init( 0 )
		
		Mix_OpenAudio( 44100,MIX_DEFAULT_FORMAT,2,1024 )
		
		Mix_AllocateChannels( 32 )
		
		_alloced=New Int[32]
		For Local i:=0 Until 32
			_alloced[i]=i+32
		Next
	End
	
End

Class Sound

	Method Play:Channel( loops:Int=0 )

		Local channel:=New Channel
		If Not channel.Play( Self,loops ) Return Null
		
		Return channel
	End

	Function Load:Sound( path:String )
	
		Local data:=DataBuffer.Load( path )
		If Not data Return Null
		
		Local rwops:=SDL_RWFromMem( data.Data,data.Length )
		Local chunk:=Mix_LoadWAV_RW( rwops,1 )
		If Not chunk Return Null
		
		Return New Sound( chunk )
	End
	
	Private
	
	Field _chunk:Mix_Chunk Ptr
	
	Method New( chunk:Mix_Chunk Ptr )
		_chunk=chunk
	End
	
End

Class Channel

	Method New()
	End

	Property Playing:Bool()
		If Invalid Return False
		Return Mix_Playing( _id & 31 )
	End
	
	Property Volume:Float()
		If Invalid Return 0
		Return _volume
	Setter( volume:Float )
		If Invalid Return
		_volume=Clamp( volume,0.0,1.0 )
		Mix_Volume( _id & 31,_volume*128 )
	End
	
	Property Rate:Float()
		Return 1
	Setter( rate:Float )
	End
	
	Property Pan:Float()
		Return 0
	Setter( pan:Float )
	End
	
	Property Paused:Bool()
		If Invalid Return False
		Return Mix_Paused( _id & 31 )
	Setter( paused:Bool )
		If Invalid Return
		Mix_Pause( _id & 31 )
	End
	
	Method Play:Bool( sound:Sound,loops:Int=0 )
	
		Local id:=_id & 31
		If _alloced[id]<>_id id=-1

		id=Mix_PlayChannel( id,sound._chunk,loops )
		If id<0 Return False
		
		_alloced[id]+=32
		_id=_alloced[id]
		
		_volume=1
		
		Return True
	End
	
	Method Stop()
		If Invalid Return
		Mix_HaltChannel( _id )
	End
	
	Private
	
	Field _id:Int=0
	Field _volume:Float=1
	
	Property Invalid:Bool()
		Return _alloced[_id&31]<>_id
	End

End
