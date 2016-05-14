
Namespace mojo.app

'These are actually SDL 'scan codes', ie: what's written on US keyboard keys...
'
#rem monkeydoc Key codes.

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

#rem monkeydoc @hidden
#end
Enum ScanCode
End

#rem monkeydoc Modifiers.

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

#rem monkeydoc Mouse buttons.

| MouseButton	| Description
|:--------------|------------
| Left			| Left mouse button.
| Middle		| Middle mouse button.
| Right			| Right mouse button.

#end
Enum MouseButton
	None=0
	Left=1
	Middle=2
	Right=3
	X1=4
	X2=5
End

#rem monkeydoc Gets the name of a key.
#end
Function KeyName:String( key:Key )
	Local ikey:=Int( key )

	If ikey>=Int( Key.A ) And ikey<=Int( Key.Z ) Return String.FromChar( ikey-Int( Key.A )+65 )

	If ikey>=Int( Key.F1 ) And ikey<=Int( Key.F12 ) Return "F"+( ikey-Int( Key.F1 )+1 )
	
	Return "?"
End
