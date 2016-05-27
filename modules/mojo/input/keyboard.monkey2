
Namespace mojo.input

Global Keyboard:=New KeyboardDevice

Class KeyboardDevice Extends InputDevice

	#rem monkeydoc @hidden
	#end
	Method Reset()
		For Local i:=0 Until _numKeys
			_pressed[i]=True
			_released[i]=True
		Next
	End
	
	Method KeyDown:Bool( key:Key )
		DebugAssert( key>=0 And key<_numKeys,"Key code out of range" )
		Return _matrix[key]
	End
	
	Method KeyPressed:Bool( key:Key )
		DebugAssert( key>=0 And key<_numKeys,"Key code out of range" )
		If _matrix[key]
			If _pressed[key] Return False
			_pressed[key]=True
			Return True
		Endif
		_pressed[key]=False
		Return False
	End
	
	Method KeyReleased:Bool( key:Key )
		DebugAssert( key>=0 And key<_numKeys,"Key code out of range" )
		If Not _matrix[key]
			If _released[key] Return False
			_released[key]=True
			Return True
		Endif
		_released[key]=False
		Return False
	End
	
	Method KeyHit:Bool( key:Key )
		Return KeyPressed( key )
	End
	
	#rem monkeydoc @hidden
	#end
	Method KeyName:String( key:Key )
		DebugAssert( key>0 And key<_numKeys,"Key code out of range" )
		Local ikey:=Int( key )
	
		If ikey>=Int( Key.A ) And ikey<=Int( Key.Z ) Return String.FromChar( ikey-Int( Key.A )+65 )

		If ikey>=Int( Key.F1 ) And ikey<=Int( Key.F12 ) Return "F"+( ikey-Int( Key.F1 )+1 )
		
		Return "?"
	End
	
	'***** Internal *****
	
	Method Init()
		If _init Return
		_matrix=SDL_GetKeyboardState( Varptr _numKeys )
		_pressed=New Bool[_numKeys]
		_released=New Bool[_numKeys]
		_init=True
		Reset()
	End

	Private
	
	Field _init:Bool
	Field _numKeys:Int
	Field _matrix:UByte Ptr
	Field _pressed:Bool[]
	Field _released:Bool[]
	
	Method New()
	End
	
End
