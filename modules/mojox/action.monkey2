
Namespace mojox

#rem monkeydoc The Action class.
#end
Class Action

	#rem monkeydoc Invoked when the action is triggered.
	#end
	Field Triggered:Void()
	
	#rem monkeydoc Invoked when the [[Text]], [[Icon]] or [[Enabled]] property is changed.
	#end
	Field Modified:Void()

	#rem monkeydoc Creates a new action.
	#end
	Method New( text:String,icon:Image=Null )
	
		_text=text
		_icon=icon
	End

	#rem monkeydoc Text representintg the action.

	This is used for button or menu text.

	#end
	Property Text:String()
	
		Return _text
	
	Setter( text:String )
		If text=_text Return
	
		_text=text
		
		Modified()
	End
	
	#rem monkeydoc Icon representing the action.
	
	This is used for button or menu icon.
	
	#end
	Property Icon:Image()
	
		Return _icon
	
	Setter( icon:Image )
		If icon=_icon Return
		
		_icon=icon
		
		Modified()
	End
	
	#rem monkeydoc Action enabled state.
	#end
	Property Enabled:Bool()
	
		Return _enabled
	
	Setter( enabled:Bool )
		If enabled=_enabled Return
		
		_enabled=enabled
		
		If _enabled EnableHotKey() Else DisableHotKey()
		
		Modified()
	End
	
	#rem monkeydoc Action async flag.
	
	If true (the default), then when the action is triggered the [[Triggered]] signal is run on a new fiber.
	
	Note: Fiber are not supported in emscripten, so this property has no effect.
	
	#end
	Property Async:Bool()
	
		Return _async
	
	Setter( async:Bool )

		_async=async
	End
	
	#rem monkeydoc Hotkey for the action.
	#end
	Property HotKey:Key()
	
		Return _hotKey
	
	Setter( hotKey:Key )
		If hotKey=_hotKey Return
	
		If _enabled DisableHotKey()
	
		_hotKey=hotKey
		
		If _enabled EnableHotKey()
	End
	
	#rem monkeydoc Hotkey modifiers for the action.
	#end
	Property HotKeyModifiers:Modifier()
	
		Return _hotKeyMods
	
	Setter( hotKeyModifiers:Modifier )
	
		_hotKeyMods=hotKeyModifiers
	End
	
	#rem monkeydoc Text representation of the action hotkey.
	#end
	Property HotKeyText:String()

		If Not _hotKey Return ""
		
		Local text:=""
		If _hotKeyMods & Modifier.Shift text+="Shift"
		If _hotKeyMods & Modifier.Control text+="+Ctrl"
		If _hotKeyMods & Modifier.Alt text+="+Alt"
		If _hotKeyMods & Modifier.Gui text+="+Cmd"
		text+="+"+Keyboard.KeyName( _hotKey )
		If text.StartsWith( "+" ) text=text.Slice( 1 )
		Return text
	End

	#rem monkeydoc Triggers the action.
	#end	
	Method Trigger()
	
#if __TARGET__<>"emscripten"
	
		If _async
			New Fiber( Triggered )
		Else
			Triggered()
		Endif

#else

		Triggered()
#endif
		
	End
	
	Private
	
	Field _enabled:Bool=True
	Field _text:String
	Field _icon:Image
	Field _hotKey:Key
	Field _hotKeyMods:Modifier
	Field _async:Bool=True
	
	Global _hotKeys:Map<Key,Stack<Action>>
	
	Method DisableHotKey()
	
		If Not _hotKey Return
		
		_hotKeys[_hotKey].Remove( Self )
	End
	
	Method EnableHotKey()
	
		If Not _hotKey Return
		
		If Not _hotKeys
			
			_hotKeys=New Map<Key,Stack<Action>>
			
			App.KeyEventFilter+=Lambda( event:KeyEvent )
			
				If event.Eaten Return
				
				If App.ModalView Return
			
				If event.Type<>EventType.KeyDown Return

				Local actions:=_hotKeys[event.Key]
				If Not actions Return

				Local mods:=event.Modifiers
				mods|=Cast<Modifier>( (Int(mods) & $541) Shl 1 | (Int(mods) & $a82) Shr 1 )

				For Local action:=Eachin actions
					If event.Key<>action._hotKey Continue
					If mods<>action._hotKeyMods Continue
					action.Trigger()
					event.Eat()
					Return
				Next
				
			End
			
		Endif
		
		Local actions:=_hotKeys[_hotKey]
		If Not actions
			actions=New Stack<Action>
			_hotKeys[_hotKey]=actions
		Endif
		
		actions.Add( Self )
	End

End
