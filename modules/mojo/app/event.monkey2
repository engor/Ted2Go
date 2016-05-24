
Namespace mojo.app

#rem monkeydoc Event types.

| EventType			| Description
|:------------------|:-----------
| KeyDown			| Key down event.
| KeyUp				| Key up event.
| KeyChar			| Key char event.
| MouseDown			| Mouse button down event.
| MouseUp			| Mouse button up event.
| MouseMove			| Mouse movement event.
| MouseWheel		| Mouse wheel event.
| MouseEnter		| Mouse enter event.
| MouseLeave		| Mouse leave event.
| WindowClose		| Window close clicked event.
| WindowMoved		| Window moved event.
| WindowResized		| Window resized event.
| WindowGainedFocus	| Window gained input focus.
| WindowLostFocus	| Window lost input focus.

#end
Enum EventType

	KeyDown,
	KeyUp,
	KeyChar,
	
	MouseDown,
	MouseUp,
	MouseMove,
	MouseWheel,
	MouseEnter,
	MouseLeave,

	WindowClose,
	WindowMoved,
	WindowResized,
	WindowGainedFocus,
	WindowLostFocus,
	
	Eaten=$80000000
End

#rem monkeydoc Event class
#end
Class Event Abstract

	#rem monkedoc The event type.
	#end
	Property Type:EventType()
		Return _type
	End
	
	#rem monkeydoc The event view.
	#end
	Property View:View()
		Return _view
	End
	
	#rem monkeydoc True if event has been eaten.
	
	#end
	Property Eaten:Bool()
		Return (_type & EventType.Eaten)<>Null
	End
	
	#rem monkeydoc Eats the event.
	#end
	Method Eat()
		_type|=EventType.Eaten
	End
	
	Protected
	
	#rem monkeydoc @hidden
	#end
	Field _type:EventType

	#rem monkeydoc @hidden
	#end
	Field _view:View
	
	#rem monkeydoc @hidden
	#end
	Method New( type:EventType,view:View )
		_type=type
		_view=view
	End
End

#rem monkeydoc The KeyEvent class
#end
Class KeyEvent Extends Event

	#rem monkeydoc @hidden
	#end
	Method New( type:EventType,view:View,key:Key,scanCode:ScanCode,modifiers:Modifier,text:String )
		Super.New( type,view )
		_key=key
		_scanCode=ScanCode
		_modifiers=modifiers
		_text=text
	End
	
	#rem monkeydoc The key involved in the event.
	#end
	Property Key:Key()
		Return _key
	End
	
	#rem monkeydoc The keyboard scan code of the key.
	#end
	Property ScanCode:ScanCode()
		Return _scanCode
	End
	
	#rem monkeydoc The modifiers at the time of the event.
	#end
	Property Modifiers:Modifier()
		Return _modifiers
	End
	
	#rem monkeydoc The text for [[EventType.KeyChar]] events.
	#end
	Property Text:String()
		Return _text
	End
	
	Private
	
	Field _key:Key
	Field _scanCode:ScanCode
	Field _modifiers:Modifier
	Field _text:String
	
End

#rem monkeydoc The MouseEvent class.
#end
Class MouseEvent Extends Event

	#rem monkeydoc @hidden
	#end
	Method New( type:EventType,view:View,location:Vec2i,button:MouseButton,wheel:Vec2i,modifiers:Modifier )
		Super.New( type,view )
		_location=location
		_button=button
		_wheel=wheel
		_modifiers=modifiers
	End
	
	#rem monkeydoc Mouse location.
	#end
	Property Location:Vec2i()
		Return _location
	End
	
	#rem monkeydoc Mouse button.
	#end
	Property Button:MouseButton()
		Return _button
	End

	#rem monkeydoc Mouse wheel deltas.
	#end	
	Property Wheel:Vec2i()
		Return _wheel
	End
	
	#rem monkeydoc Event modifiers.
	#end
	Property Modifiers:Modifier()
		Return _modifiers
	End
	
	Private
	
	Field _location:Vec2i
	Field _button:MouseButton
	Field _wheel:Vec2i
	Field _modifiers:Modifier
	
End

#rem monkeydoc The WindowEvent class.
#end
Class WindowEvent Extends Event

	#rem monkeydoc @hidden
	#end
	Method New( type:EventType,window:Window )
		Super.New( type,window )
		_window=window
	End

	#rem monkeydoc The window the event was sent to.
	#end
	Property Window:Window()
		Return _window
	End
	
	Private
	
	Field _window:Window
	
End
