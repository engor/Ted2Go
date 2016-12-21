
Namespace ted2go


Class DialogExt Extends Dialog
	
	Field OnShow:Void()
	Field OnHide:Void()
	
	Property IsOpened:Bool()
		Return _opened
	End
	
	Method Show()
		If _opened Return
		_opened = True
		Open()
		OnShow()
	End
	
	Method Hide()
		If Not _opened Return
		_opened = False
		Close()
		OnHide()
	End
	
	Private
	
	Field _opened:Bool
	
End
