
Namespace ted2go


Class Utils
	
	Function ArrayContains<T>:Bool(arr:T[], value:T)
		If arr = Null Then Return False
		For Local v := Eachin arr
			If v = value Then Return True
		Next
		Return False
	End

	Function ValueAt<T>:T(list:List<T>, index:Int)
		Local k := 0
		For Local i := Eachin list
			If k = index Return i
			k += 1
		End
		Return Null
	End
	
	Function RepeatInvoke<T>(func:T(), count:Int)
		For Local k := 0 Until count
			func()
		Next
	End
	
	Private
	
	Method New()
	End
	
End
