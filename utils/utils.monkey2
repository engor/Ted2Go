
Namespace ted2go


Class Utils
	
	Function ArrayContains<T>:Bool(arr:T[], value:T)
		If arr = Null Then Return False
		For Local v := Eachin arr
			If v = value Then Return True
		Next
		Return False
	End

	Private
	
	Method New()
	End
	
End
