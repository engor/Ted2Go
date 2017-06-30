
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
	
	Method ShowModal:Bool()
		
		If _opened Return False
		
		_opened = True
		Open()
		OnShow()
		
		App.BeginModal( Self )
		_wait=New Future<Bool>
		Local ok:=_wait.Get()
		App.EndModal()
		
		Return ok
	End
	
	Method Hide()
	
		HideWithResult( True )
	End
	
	Method HideWithResult( ok:Bool )
		
		If Not _opened Return
		
		_opened = False
		Close()
		OnHide()
		
		If _wait
			_wait.Set( ok )
			_wait=Null
		Endif
	End
	
	
	Private
	
	Field _opened:Bool
	Field _wait:Future<Bool>
	
End
