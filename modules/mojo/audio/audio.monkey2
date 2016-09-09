
#rem monkeydoc

Highly experimental audio module!

#end
Namespace mojo.audio

Private

Function ALFormat:ALenum( format:AudioFormat )
	Local alFormat:ALenum
	Select format
	Case AudioFormat.Mono8
		alFormat=AL_FORMAT_MONO8
	Case AudioFormat.Mono16
		alFormat=AL_FORMAT_MONO16
	Case AudioFormat.Stereo8
		alFormat=AL_FORMAT_STEREO8
	Case AudioFormat.Stereo16
		alFormat=AL_FORMAT_STEREO16
	End
	Return alFormat
End

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
	
		Local error:=""

		_alcDevice=alcOpenDevice( Null )
		If _alcDevice
			_alcContext=alcCreateContext( _alcDevice,Null )
			If _alcContext
				If alcMakeContextCurrent( _alcContext )
					Return
				Else
					error="Failed to make OpenAL current"
				Endif
			Else
				error="Failed to create OpenAL context"
			Endif
		Else
			error="Failed to create OpenAL device"
		Endif

	End
	
	Private
	
	Field _alcDevice:ALCdevice Ptr
	Field _alcContext:ALCcontext Ptr
	Field _error:String
	
End

#rem monkeydoc The Sound class.
#end
Class Sound

	#rem monkeydoc Creates a new sound.
	#end
	Method New( data:AudioData )
		alGenBuffers( 1,Varptr _alBuffer )
		alBufferData( _alBuffer,ALFormat( data.Format ),data.Data,data.Size,data.Hertz )
	End
	
	#rem monkeydoc Discards a sound.
	#end
	Method Discard()
		If Not _alBuffer Return
		alDeleteBuffers( 1,Varptr _alBuffer )
		_alBuffer=0
	End
	
	#rem monkeydoc Plays a sound through a temporary channel.
	
	The returned channel will be automatically discarded when it finishes playing or is stopped with [[Channel.Stop]].
	
	#end
	Method Play:Channel( loop:Bool=False )
	
		Local channel:=New Channel( ChannelFlags.AutoDiscard )
		
		channel.Play( Self,loop )
		
		Return channel
	End
	
	#rem monkeydoc Loads a sound.
	#end
	Function Load:Sound( path:String )
	
		Local data:=AudioData.Load( path )
		If Not data Return Null
		
		Local sound:=New Sound( data )

		data.Discard()
		Return sound
	End
	
	Private
	
	Field _alBuffer:ALuint

End

#rem monkeydoc ChannelFlags enum.

| Flag			| Description
|:--------------|:-----------
| `AutoDiscard`	| Channel will be automatically discarded when it finishes playing, or when it is stopped using [[Channel.Stop]].

#end
Enum ChannelFlags
	AutoDiscard=1
End

Class Channel

	#rem monkeydoc Creates a new audio channel.
	
	If `flags` is ChannelFlags.AutoDiscard, then the channel will be automatically discarded when it finishes playing, or when it is
	stopped using [[Stop]].
	
	#end
	Method New( flags:ChannelFlags=Null )
	
		_flags=flags
	
		FlushTmpChannels()
		
		alGenSources( 1,Varptr _alSource )
		
		If _flags & ChannelFlags.AutoDiscard _tmpChannels.Push( Self )
		
		_active+=1
		Print "Active channels="+_active
	End
	
	Property Flags:ChannelFlags()
	
		Return _flags
	End
	
	#rem monkeydoc True if channel is playing audio.
	
	If the channel is playing audio but is in the paused state, this property will still return true.

	#end
	Property Playing:Bool()
		If Not _alSource Return False
		
		Local state:=ALState()
		Return state=AL_PLAYING Or state=AL_PAUSED
	End
	
	#rem monkeydoc True if channel is paused.
	#end
	Property Paused:Bool()
		If Not _alSource Return False
		
		Return ALState()=AL_PAUSED
		
	Setter( paused:Bool )
		If Not Playing Return
		
		If paused
			alSourcePause( _alSource )
		Else
			alSourcePlay( _alSource )
		Endif
	End
	
	#rem monkeydoc Channel volume in the range 0 to 1.
	#end
	Property Volume:Float()
		If Not _alSource Return 0
	
		Return _volume
		
	Setter( volume:Float )
		If Not _alSource Return
		
		_volume=Clamp( volume,0.0,1.0 )
		alSourcef( _alSource,AL_GAIN,_volume )
	End
	
	#rem monkeydoc Channel playback rate.
	#end	
	Property Rate:Float()
		If Not _alSource Return 0

		Return _rate
		
	Setter( rate:Float )
		If Not _alSource Return
		
		_rate=rate
		alSourcef( _alSource,AL_PITCH,_rate )
	End
	
	#rem monkeydoc Channel pan in the range -1 (left) to 1 (right).
	#end	
	Property Pan:Float()
		If Not _alSource Return 0
	
		Return _pan
		
	Setter( pan:Float)
		If Not _alSource Return
		
		_pan=Clamp( pan,-1.0,1.0 )
		Local x:=Sin( _pan ),z:=-Cos( _pan )
		alSource3f( _alSource,AL_POSITION,x,0,z )
	End
	
	#rem monkeydoc Discard channel resources.
	#end
	Method Discard()
		If Not _alSource Return
		
		alDeleteSources( 1,Varptr _alSource )
		_alSource=0
		
		_active-=1
		Print "Active channels="+_active
	End

	#rem monkeydoc Play a sound through the channel.
	#end
	Method Play( sound:Sound,loop:Bool=False )
		If Not _alSource Or Not sound Or Not sound._alBuffer Return
		
		alSourcei( _alSource,AL_LOOPING,loop ? AL_TRUE Else AL_FALSE )
		
		alSourcei( _alSource,AL_BUFFER,sound._alBuffer )
		
		alSourcePlay( _alSource )
	End

	#if __TARGET__<>"emscripten"

	#rem monkeydoc @hidden - Highly experimental!!!!!
	#end
	Method WaitQueued( queued:Int )
	
		While _queued>queued
		
			FlushProcessed()
			
			If _queued<=queued Return
		
			_waiting=True
			
			_future.Get()
		
		Wend

	End
	
	#rem monkeydoc @hidden - Highly experimental!!!!!
	#end
	Method Queue( data:AudioData )
	
		Local buf:ALuint
		
		If Not _tmpBuffers
		
			_tmpBuffers=New Stack<ALuint>
			_freeBuffers=New Stack<ALuint>
			_future=New Future<Int>
			_waiting=False
			_queued=0
			
			_timer=New Timer( 60,Lambda()
				FlushProcessed()
			End )

		Endif		
		
		If _freeBuffers.Empty
			
			alGenBuffers( 1,Varptr buf )
			_tmpBuffers.Push( buf )
		
		Else
			buf=_freeBuffers.Pop()
		Endif
		
		alBufferData( buf,ALFormat( data.Format ),data.Data,data.Size,data.Hertz )
		
		alSourceQueueBuffers( _alSource,1,Varptr buf )
		_queued+=1
		
		Local state:=ALState()
		If state=AL_INITIAL Or state=AL_STOPPED alSourcePlay( _alSource )
	
	End
	
	#endif
	
	#rem monkeydoc Stops channel.
	#end
	Method Stop()
		If Not _alSource Return

		alSourceStop( _alSource )
		
		If _flags & ChannelFlags.AutoDiscard Discard()
	End

	Private
	
	Field _flags:ChannelFlags
	Field _alSource:ALuint
	Field _volume:Float=1
	Field _rate:Float=1
	Field _pan:Float=0
	
	Global _active:=0
	
	Global _tmpChannels:=New Stack<Channel>
	
	Method ALState:ALenum()
		Local state:ALenum
		alGetSourcei( _alSource,AL_SOURCE_STATE,Varptr state )
		Return state
	End
	
	Function FlushTmpChannels()
	
		Local put:=0
		For Local chan:=Eachin _tmpChannels
			If Not chan._alSource Continue
		
			If chan.ALState()<>AL_STOPPED
				_tmpChannels[put]=chan;put+=1
				Continue
			Endif
			
			chan.Discard()
		Next

		_tmpChannels.Resize( put )
	End
	
	#if __TARGET__<>"emscripten"
	
	Field _tmpBuffers:Stack<ALuint>
	Field _freeBuffers:Stack<ALuint>
	Field _future:Future<Int>
	Field _waiting:Bool
	Field _queued:Int
	Field _timer:Timer
	
	Method FlushProcessed:Int()
	
		Local proc:ALint
		alGetSourcei( _alSource,AL_BUFFERS_PROCESSED,Varptr proc )
		
'		Print "processed: "+proc

		If Not proc Return 0
		
		For Local i:=0 Until proc
		
			Local buf:ALuint
			
			alSourceUnqueueBuffers( _alSource,1,Varptr buf )
			_queued-=1
			
			If _tmpBuffers.Contains( buf ) _freeBuffers.Push( buf )
		Next

		If _waiting 
			_waiting=False
			_future.Set( proc )
		Endif
		
		Return proc

	End
	
	#endif
	
End
