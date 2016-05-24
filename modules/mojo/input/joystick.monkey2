
Namespace mojo.input

#rem monkeydoc

| JoystickHat value	| 
|:------------------|
| Centered
| Up
| Right
| Down
| Left
| RightUp
| RightDown
| LeftUp
| LeftDown

#end
Enum JoystickHat	'SDL values...
	Centered=0
	Up=1
	Right=2
	Down=4
	Left=8
	RightUp=Right|Up
	RightDown=Right|Down
	LeftUp=Left|Up
	LeftDown=Left|Down
End

Class JoystickDevice Extends InputDevice

	Property Name:String()
		Return _name
	End
	
	Property GUID:String()
		Return _guid
	End

	Property NumAxes:Int()
		Return _numAxes
	End
	
	Property NumBalls:Int()
		Return _numBalls
	End
	
	Property NumButtons:Int()
		Return _numButtons
	End
	
	Property NumHats:Int()
		Return _numHats
	End
	
	Method GetAxis:Float( axis:Int )
		Return (Float(SDL_JoystickGetAxis( _joystick,axis ))+32768)/32767.5-1
	End
	
	Method GetBall:Vec2i( ball:Int )
		Local x:Int,y:Int
		SDL_JoystickGetBall( _joystick,ball,Varptr x,Varptr y )
		Return New Vec2i( x,y )
	End

	Method GetHat:JoystickHat( hat:Int )
		Return Cast<JoystickHat>( SDL_JoystickGetHat( _joystick,hat ) )
	End

	Method ButtonDown:Bool( button:Int )
		Return SDL_JoystickGetButton( _joystick,button )
	End
	
	Method ButtonHit:Bool( button:Int )
		If ButtonDown( button )
			If _hits[button] Return False
			_hits[button]=True
			Return True
		Endif
		_hits[button]=False
		Return False
	End
	
	Function NumJoysticks:Int()
		Return Min( SDL_NumJoysticks(),8 )
	End

	#rem  monkeydoc @hidden
	#end	
	Function UpdateJoysticks()
		SDL_JoystickUpdate()
	End
	
	Function Open:JoystickDevice( index:Int )
		Assert( index>=0 And index<8 )
		Local joystick:=_joysticks[index]
		If Not joystick
			Local sdlJoystick:=SDL_JoystickOpen( index )
			If Not sdlJoystick Return Null
			joystick=New JoystickDevice( sdlJoystick )
			_joysticks[index]=joystick
		Endif
		Return joystick
	End
	
	Private
	
	Global _joysticks:=New JoystickDevice[8]
	
	Field _joystick:SDL_Joystick Ptr
	Field _name:String
	Field _guid:String
	Field _numAxes:Int
	Field _numBalls:Int
	Field _numButtons:Int
	Field _numHats:Int
	Field _hits:=New Bool[32]
	
	Method New( joystick:SDL_Joystick Ptr )
		_joystick=joystick
		_name=String.FromCString( SDL_JoystickName( _joystick ) )
		_numAxes=SDL_JoystickNumAxes( _joystick )
		_numBalls=SDL_JoystickNumBalls( _joystick )
		_numButtons=SDL_JoystickNumButtons( _joystick )
		_numHats=SDL_JoystickNumHats( _joystick )
		
		Local buf:=New Byte[64]
		Local guid:=SDL_JoystickGetGUID( _joystick )
		SDL_JoystickGetGUIDString( guid,Cast<libc.char_t Ptr>( buf.Data ),buf.Length )
		buf[buf.Length-1]=0
		_guid=String.FromCString( buf.Data )
	End

End
