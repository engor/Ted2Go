
Namespace mojo.audio

Private

Global _alloced:Int[]

Public

#rem monkeydoc Global instance of the AudioDevice class.
#end
Const Audio:=New AudioDevice

#rem monkeydoc The AudioDevice class.
#end
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

#rem monkeydoc The Sound class.
#end
Class Sound

	#rem monkeydoc Plays a sound.
	#end
	Method Play:Channel( loops:Int=0 )

		Local channel:=New Channel
		If Not channel.Play( Self,loops ) Return Null
		
		Return channel
	End

	#rem monkeydoc Loads a sound.
	#end
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

#rem monkeydoc The Channel class.
#end
Class Channel

	#rem monkeydoc Creates a new channel.
	#end
	Method New()
	End

	#rem monkeydoc True if this channel is playing audio.
	
	If the channel is playing audio but is in the paused state, this property will still return true.

	#end
	Property Playing:Bool()
		If Invalid Return False
		Return Mix_Playing( _id & 31 )
	End
	
	#rem monkeydoc Channel volume in the range 0 to 1.
	#end
	Property Volume:Float()
		If Invalid Return 0
		Return _volume
	Setter( volume:Float )
		If Invalid Return
		_volume=Clamp( volume,0.0,1.0 )
		Mix_Volume( _id & 31,_volume*128 )
	End

	#rem monkeydoc Channel playback rate.
	#end	
	Property Rate:Float()
		Return 1
	Setter( rate:Float )
	End
	
	#rem monkeydoc Channel pan in the range -1 to 1.
	#end
	Property Pan:Float()
		Return 0
	Setter( pan:Float )
	End
	
	#rem monkeydoc Channel paused state.
	#end
	Property Paused:Bool()
		If Invalid Return False
		Return Mix_Paused( _id & 31 )
	Setter( paused:Bool )
		If Invalid Return
		Mix_Pause( _id & 31 )
	End
	
	#rem monkeydoc Plays a sound through the channel.
	#end
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
	
	#rem monkeydoc Stops the channel.
	#end
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
