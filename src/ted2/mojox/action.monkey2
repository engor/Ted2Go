
Namespace mojox

Class Action

	Field Triggered:Void()
	
	Field Modified:Void()

	Method New( label:String,icon:Image=Null )
	
		_label=label
		_icon=icon
	End
	
	Property Label:String()
	
		Return _label
	
	Setter( label:String )
		If label=_label Return
	
		_label=label
		
		Modified()
	End
	
	Property Icon:Image()
	
		Return _icon
	
	Setter( icon:Image )
		If icon=_icon Return
		
		_icon=icon
		
		Modified()
	End
	
	Property Enabled:Bool()
	
		Return _enabled
	
	Setter( enabled:Bool )
		If enabled=_enabled Return
		
		_enabled=enabled
		
		If _enabled EnableHotKey() Else DisableHotKey()
		
		Modified()
	End
	
	Property Async:Bool()
	
		Return _async
	
	Setter( async:Bool )
	
		_async=async
	End
	
	Property HotKey:Key()
	
		Return _hotKey
	
	Setter( hotKey:Key )
		If hotKey=_hotKey Return
	
		If _enabled DisableHotKey()
	
		_hotKey=hotKey
		
		If _enabled EnableHotKey()
	End
	
	Property HotKeyModifiers:Modifier()
	
		Return _hotKeyMods
	
	Setter( hotKeyModifiers:Modifier )
	
		_hotKeyMods=hotKeyModifiers
	End
	
	Property HotKeyLabel:String()

		If Not _hotKey Return ""
		
		Local label:=""
		If _hotKeyMods & Modifier.Shift label+="Shift"
		If _hotKeyMods & Modifier.Control label+="+Ctrl"
		If _hotKeyMods & Modifier.Alt label+="+Alt"
		label+="+"+Keyboard.KeyName( _hotKey )
		If label.StartsWith( "+" ) label=label.Slice( 1 )
		Return label
	End
	
	Method Trigger()
	
		If _async
			New Fiber( Triggered )
		Else
			Triggered()
		Endif
		
	End
	
	Private
	
	Field _enabled:Bool=True
	Field _label:String
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
