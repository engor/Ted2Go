
Namespace mojo.input

#rem monkeydoc @hidden
#end
Enum GameControllerButton	'uses SDL values
	A=0
	B=1
	X=2
	Y=3
	Back=4
	Guide=5
	Start=6
	LeftStick=7
	RightStick=8
	LeftShoulder=9
	RightShoulder=10
	DpadUp=11
	DpadDown=12
	DpadLeft=13
	DpadRight=14
End

#rem monkeydoc @hidden
#end
Enum GameControllerAxis		'uses SDL values
	LeftX=0
	LeftY=1
	RightX=2
	RightY=3
	LeftTrigger=4
	RightTrigger=5
End

#rem monkeydoc @hidden
#end
Class GameController Extends InputDevice

	Method New( axisDevice:InputDevice,buttonDevice:InputDevice,_pointerDevice:InputDevice )
		_axisDevice=axisDevice
		_buttonDevice=buttonDevice
		_pointerDevice=pointerDevice
		For Local i:=0 Until _axisMap.Length
			_axisMap[i]=i
		Next
		For Local i:=0 Until _buttonMap.Length
			_buttonMap[i]=i
		Next
		For Local i:=0 Until _pointerMap.Length
			_pointerMap[i]=i
		Next
	End
	
	Method GetAxis:Float( axis:GameControllerAxis ) Override
		If _axisDevice Return _axisDevice.GetAxis( _axisMap[axis] )
		Return 0
	End
	
	Method GetButton:Bool( button:GameControllerButton ) Override
		If _buttonDevice Return _buttonDevice.GetButton( _buttonMap[button] )
		Return False
	End
	
	Method GetPointer:Vec2i( pointer:Int ) Override
		If _pointerDevice Return _pointerDevice.GetPointer( _pointerMap[pointer] )
	End
	
	Method MapAxis( axis:GameControllerAxis,deviceAxis:Int )
		_axisMap[axis]=deviceAxis
	End
	
	Method MapButton( button:GameControllerButton,deviceButton:Int )
		_buttonMap[button]=deviceButton
	End
	
	Method MapPointer( pointer:Int,devicePointer:Int )
		_pointerMap[pointer]=devicePointer
	End
	
	Function WASD:GameController()
		If Not _wasd
			_wasd=New GameController( Null,Keyboard )
			_wasd.MapButton( GameControllerButton.DpadLeft,Key.A )
			_wasd.MapButton( GameControllerButton.DpadRight,Key.D )
			_wasd.MapButton( GameControllerButton.DpadUp,Key.W )
			_wasd.MapButton( GameControllerButton.DpadDown,Key.S )
		Endif
		Return _wasd
	End
	
	Private
	
	Global _wasd:GameController
	
	Field _axisDevice:InputDevice
	Field _buttonDevice:InputDevice
	Field _pointerDevice:InputDevice
	Field _axisMap:=New Int[6]
	Field _buttonMap:=New Int[16]
	Field _pointerMap:=New Int[10]
	
End
