
Namespace mojo.input

#Import "native/keyinfo.h"
#Import "native/keyinfo.cpp"

Extern Private

Struct bbKeyInfo
	Field name:Void Ptr
	Field scanCode:Int
	Field keyCode:Int
End

Global bbKeyInfos:bbKeyInfo Ptr

Public

#rem monkeydoc Global instance of the KeyboardDevice class.

#end
Const Keyboard:=New KeyboardDevice

#rem monkeydoc The KeyboardDevice class.

All method that take a `key` parameter can also be used with 'raw' keys.

A raw key represents the physical location of a key on US keyboards. For example, `Key.Q|Key.Raw` indicates the key at the top left of the
'qwerty' keys regardless of the current keyboard layout.

Please see the [[Key]] enum for more information on raw keys.

To access the keyboard device, use the global [[Keyboard]] constant.

The keyboard device should only used after a new [[app.AppInstance]] is created.

#end
Class KeyboardDevice Extends InputDevice

	#rem monkeydoc The current state of the modifier keys.
	#end
	Property Modifiers:Modifier()
		Return _modifiers
	End

	#rem monkeydoc Gets the name of a key.
	
	If `key` is a raw key, returns the name 'printed' on that key.
	
	if `key` is a virtual key
	
	#end	
	Method KeyName:String( key:Key )
		If key & key.Raw key=TranslateKey( key )
		Return _names[key]
	End
	
	#rem monkeydoc Translates a key to/from a raw key.
	
	If `key` is a raw key, returns the corresponding virual key.
	
	If `key` is a virtual key, returns the corresponding raw key.
	
	#end
	Method TranslateKey:Key( key:Key )
		If key & Key.Raw
#If __TARGET__="emscripten"
			Return key & ~Key.Raw
#Else
			Local keyCode:=SDL_GetKeyFromScancode( Cast<SDL_Scancode>( _raw2scan[ key & ~Key.Raw ] ) )
			Return KeyCodeToKey( keyCode )
#Endif
		Else
			Local scanCode:=_key2scan[key]
			Return _scan2raw[scanCode]
		Endif
		Return Key.None
	End
	
	#rem monkeydoc Checks the current up/down state of a key.
	
	Returns true if `key` is currently held down.
	
	If `key` is a raw key, the state of the key as it is physically positioned on US keyboards is returned.
	
	@param key Key to check.
	
	#end
	Method KeyDown:Bool( key:Key )

		Local scode:=ScanCode( key )

		Return _matrix[scode]
	End
	
	#rem monkeydoc Checks if a key was pressed.
	
	Returns true if `key` was pressed since the last call to KeyPressed with the same key.

	If `key` is a raw key, the state of the key as it is physically positioned on US keyboards is returned.
	
	@param key Key to check.
	
	#end
	Method KeyPressed:Bool( key:Key )
	
		Local scode:=ScanCode( key )
		
		If _matrix[scode]
			If _pressed[scode] Return False
			_pressed[scode]=True
			Return True
		Endif

		_pressed[scode]=False
		Return False
	End

	#rem monkeydoc Checks if a key was released.
	
	Returns true if `key` was released since the last call to KeyReleased with the same key.
	
	If `key` is a raw key, the state of the key as it is physically positioned on US keyboards is returned.
	
	@param key Key to check.
	
	#end
	Method KeyReleased:Bool( key:Key )
	
		Local scode:=ScanCode( key )

		If Not _matrix[scode]
			If _released[scode] Return False
			_released[scode]=True
			Return True
		Endif
	
		_released[scode]=False
		Return False
	End
	
	#rem monkeydoc @hidden
	#end
	Method KeyHit:Bool( key:Key )

		Return KeyPressed( key )
	End
	
	'***** Internal *****
	
	#rem  monkeydoc @hidden
	#end
	Method Reset()
		For Local i:=0 Until 512
			_matrix[i]=False
			_pressed[i]=True
			_released[i]=True
		Next
		_modifiers=Null
	End

	#rem monkeydoc @hidden
	#end
	Method ScanCode:Int( key:Key )
		If key & Key.Raw Return _raw2scan[ key & ~Key.Raw ]
		Return _key2scan[ key ]
	End
	
	#rem monkeydoc @hidden
	#end
	Method KeyCodeToKey:Key( keyCode:Int )
		If (keyCode & $40000000) keyCode=(keyCode & ~$40000000)+$80
		Return Cast<Key>( keyCode )
	End
	
	#rem monkeydoc @hidden
	#end
	Method ScanCodeToRawKey:Key( scanCode:Int )
		Return _scan2raw[ scanCode ]
	End
	
	#rem monkeydoc @hidden
	#end
	Method Init()
		If _init Return
		_init=True
		
		Local p:=bbKeyInfos
		
		While p->name
		
			Local name:=String.FromCString( p->name )
			Local scanCode:=p->scanCode
			Local keyCode:=p->keyCode
			
			Local key:=KeyCodeToKey( keyCode )
			
			_names[key]=name
			_raw2scan[key]=scanCode
			_scan2raw[scanCode]=key | Key.Raw
#If __TARGET__="emscripten"
			_key2scan[key]=scanCode
#Else
			_key2scan[key]=SDL_GetScancodeFromKey( Cast<SDL_Keycode>( keyCode ) )
#Endif
			_scan2key[_key2scan[key]]=scanCode
			
			p=p+1
		Wend
		
		SDL_AddEventWatch( _EventFilter,Null )
		
		Reset()
	End

	Private
	
	Field _init:Bool
	Field _modifiers:Modifier
	Field _matrix:=New Bool[512]
	Field _pressed:=New Bool[512]
	Field _released:=New Bool[512]
	Field _names:=New String[512]
	Field _raw2scan:=New Int[512]	'no translate
	Field _scan2raw:=New Key[512]	'no translate
	Field _key2scan:=New Int[512]	'translate
	Field _scan2key:=New Int[512]	'translate
	
	Method New()
	End
	
	Function _EventFilter:Int( userData:Void Ptr,event:SDL_Event Ptr )
	
		Return Keyboard.EventFilter( userData,event )
	End
	
	Method EventFilter:Int( userData:Void Ptr,event:SDL_Event Ptr )

		Select event->type
			
		Case SDL_KEYDOWN
		
			Local kevent:=Cast<SDL_KeyboardEvent Ptr>( event )
			
			_matrix[kevent->keysym.scancode]=True
			
			Select kevent->keysym.sym
			Case $400000e0 _modifiers|=Modifier.LeftControl
			Case $400000e1 _modifiers|=Modifier.LeftShift
			Case $400000e2 _modifiers|=Modifier.LeftAlt
			Case $400000e3 _modifiers|=Modifier.LeftGui
			Case $400000e4 _modifiers|=Modifier.RightControl
			Case $400000e5 _modifiers|=Modifier.RightShift
			Case $400000e6 _modifiers|=Modifier.RightAlt
			Case $400000e7 _modifiers|=Modifier.RightGui
			End

		Case SDL_KEYUP
		
			Local kevent:=Cast<SDL_KeyboardEvent Ptr>( event )
		
			_matrix[kevent->keysym.scancode]=False

			Select kevent->keysym.sym
			Case $400000e0 _modifiers&=~Modifier.LeftControl
			Case $400000e1 _modifiers&=~Modifier.LeftShift
			Case $400000e2 _modifiers&=~Modifier.LeftAlt
			Case $400000e3 _modifiers&=~Modifier.LeftGui
			Case $400000e4 _modifiers&=~Modifier.RightControl
			Case $400000e5 _modifiers&=~Modifier.RightShift
			Case $400000e6 _modifiers&=~Modifier.RightAlt
			Case $400000e7 _modifiers&=~Modifier.RightGui
			End

		End
		
		Return 1
	End

End
