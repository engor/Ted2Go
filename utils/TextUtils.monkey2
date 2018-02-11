
Namespace ted2go


Class TextUtils Final
	
	Function GetSpacesForTabEquivalent:String()
	
		If Prefs.EditorTabSize<>_storedTabSize
			_storedTabSize=Prefs.EditorTabSize
			_spacesForTab=" ".Dup( _storedTabSize )
		Endif
	
		Return _spacesForTab
	End
	
	Private
	
	Global _storedTabSize:=0,_spacesForTab:String
	
	Method New()
	End
	
End


Struct Chars
	
	Const SINGLE_QUOTE:="'"[0] '39
	Const DOUBLE_QUOTE:="~q"[0] '34
	Const COMMA:=","[0] '44
	Const SEMICOLON:=";"[0]
	Const DOT:="."[0] '46
	Const EQUALS:="="[0] '61
	Const LESS_BRACKET:="<"[0] '60
	Const MORE_BRACKET:=">"[0] '62
	Const OPENED_SQUARE_BRACKET:="["[0] '91
	Const CLOSED_SQUARE_BRACKET:="]"[0] '93
	Const OPENED_ROUND_BRACKET:="("[0] '40
	Const CLOSED_ROUND_BRACKET:=")"[0] '41
	Const DIGIT_0:="0"[0] '48
	Const DIGIT_9:="9"[0] '57
	Const AT:="@"[0] '64
	Const GRID:="#"[0] '35
	Const TAB:="~t"[0] '9
	Const SPACE:=" "[0] '32
	Const NEW_LINE:="~n"[0] '10
	
End
