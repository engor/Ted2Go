
Namespace ted2go


Class DialogExt Extends Dialog
	
	Property IsOpened:Bool()
		Return _opened
	End
	
	Method Show()
		If _opened Return
		_opened = True
		Open()
	End
	
	Method Hide()
		If Not _opened Return
		_opened = False
		Close()
	End
	
	Private
	
	Field _opened:Bool
	
End
