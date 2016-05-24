
Namespace mojo.input

Global Keyboard:=New KeyboardDevice

Class KeyboardDevice Extends InputDevice

	#rem monkeydoc @hidden
	#end
	Method Reset()
		Init()
		For Local i:=0 Until _numKeys
			_keyHit[i]=True
		Next
	End
	
	Method KeyDown:Bool( key:Key )
		Init()
		Return _keyMatrix[key]
	End
	
	Method KeyHit:Int( key:Key )
		Init()
		If _keyMatrix[key]
			If _keyHit[key] Return False
			_keyHit[key]=True
			Return True
		Endif
		_keyHit[key]=False
		Return False
	End
	
	#rem monkeydoc @hidden
	#end
	Method KeyName:String( key:Key )
		Local ikey:=Int( key )
	
		If ikey>=Int( Key.A ) And ikey<=Int( Key.Z ) Return String.FromChar( ikey-Int( Key.A )+65 )
	
		If ikey>=Int( Key.F1 ) And ikey<=Int( Key.F12 ) Return "F"+( ikey-Int( Key.F1 )+1 )
		
		Return "?"
	End
	
	'Method GetButton:Bool( index:Int ) Override
	'	Return KeyDown( Cast<Key>( index ) )
	'End
	
	Private
	
	Field _init:Bool
	Field _numKeys:Int
	Field _keyMatrix:UByte Ptr
	Field _keyHit:Bool[]
	
	Method New()
	End
	
	Method Init()
		If _init Return
		_keyMatrix=SDL_GetKeyboardState( Varptr _numKeys )
		_keyHit=New Bool[_numKeys]
		_init=True
	End

End
