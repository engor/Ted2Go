
Namespace mojo.input

#rem monkeydoc Key codes.

By default, key codes refer to 'virtual' keys. For example, `KEY_W` refers to the key with 'W' printed on it. However, this key may be not
be in the same physical location on all users' keyboards, due to OS language and keyboard settings.

To deal with this, mojo also provides support for 'raw' keys. A raw key code is simply a virtual key code 'or'ed with the special key code
`Key.Raw`.

A raw key represents the physical location of a key on US keyboards. For example, `Key.Q|Key.Raw` indicates the key at the top left of the
'qwerty' (or 'azerty' etc) keys regardless of the current OS settings.

| Key
|:---
| A
| B
| C
| D
| E
| F
| G
| H
| I
| J 
| K
| L
| M
| N
| O
| P
| Q
| R
| S
| T
| U
| V
| W
| X
| Y
| Z
| Key0
| Key1
| Key2
| Key3
| Key4
| Key5
| Key6
| Key7
| Key8
| Key9
| Enter
| Escape
| Backspace
| Tab
| Space
| Minus
| Equals
| LeftBracket
| RightBracket
| Backslash
| Semicolon
| Apostrophe
| Grave
| Comma
| Period
| Slash
| CapsLock
| F1
| F2
| F3
| F4
| F5
| F6
| F7
| F8
| F9
| F10
| F11
| F12
| PrintScreem
| ScrollLock
| Pause
| Insert
| Home
| PageUp
| KeyDelete
| KeyEnd
| PageDown
| Right
| Left
| Down
| Up
| LeftControl
| LeftShift
| LeftAlt
| LeftGui
| RightControl
| RightShift
| RightAlt
| RightGui

#end

Enum Key

	None=0

	Backspace=8,Tab
	Enter=13
	Escape=27
	Space=32
	Comma=44,Minus,Period,Slash
	Key0=48,Key1,Key2,Key3,Key4,Key5,Key6,Key7,Key8,Key9
	Semicolon=59,
	LeftBracket=91,Backslash,RightBracket
	Backquote=96
	A=97,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
	KeyDelete=127
	
	CapsLock=185,F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12
	PrintScreen,ScrollLock,Pause,Insert,Home,PageUp,nop,KeyEnd,PageDown
	Right,Left,Down,Up
	KeypadNumLock,KeypadDivide,KeypadMultiply,KeypadMinus,KeypadPlus,KeypadEnter
	Keypad1,Keypad2,Keypad3,Keypad4,Keypad5,Keypad6,Keypad7,Keypad8,Keypad9,Keypad0
	KeypadPeriod
	
	LeftControl=185+167,LeftShift,LeftAlt,LeftGui,RightControl,RightShift,RightAlt,RightGui
	
	Raw=$10000
	
End

#rem gone?
Enum ScanCode

	None=0
	A=4,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z
	Key1=30,Key2,Key3,Key4,Key5,Key6,Key7,Key8,Key9,Key0
	Enter=40,Escape,Backspace,Tab,Space
	Minus=45,Equals,LeftBracket,RightBracket,Blackslash
	Semicolon=51,Apostrophe,Grave,Comma,Period,Slash
	CapsLock=57
	F1=58,F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12
	PrintScreen=70,ScrollLock,Pause,Insert
	Home=74,PageUp,KeyDelete,KeyEnd,PageDown,Right,Left,Down,Up
	LeftControl=224,LeftShift,LeftAlt,LeftGui
	RightControl=228,RightShift,RightAlt,RightGui
	
End
#end

#rem monkeydoc Modifier masks.

| Modifier 		| Description 
|:--------------|:-----------
| LeftShift		| Left shift key.
| RightShift	| Right shift key.
| LeftControl	| Left control key.
| RightControl	| Right control key.
| LeftAlt		| Left alt key.
| RightAlt		| Right alt key.
| LeftGui		| Left gui key.
| RightGui		| Right gui key.
| NumLock		| Num lock key.
| CapsLock		| Caps lock key.
| Shift			| LeftShit | RightShift mask.
| Control		| LeftControl | RightControl mask.
| Alt			| LeftAlt | RightAlt mask.
| Gui			| LeftGui | RightGui mask.

#end
Enum Modifier

	None=			$0000
	LeftShift=		$0001
	RightShift=		$0002
	LeftControl=	$0040
	RightControl=	$0080
	LeftAlt=		$0100
	RightAlt=		$0200
	LeftGui=		$0400
	RightGui=		$0800
	NumLock=		$1000
	CapsLock=		$2000
	
	Shift=			LeftShift|RightShift
	Control=		LeftControl|RightControl
	Alt=			LeftAlt|RightAlt
	Gui=			LeftGui|RightGui
End
