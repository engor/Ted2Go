
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
	
	Function GetIndent:Int(line:String)
		Local len := line.Length, n := 0
		While n < len And line[n] <= 32
			n += 1
		Wend
		Return n
	End
		
	Function GetIndentStr:String(line:String)
		Local n := GetIndent(line)
		Return  (n > 0) ? line.Slice(0,n) Else ""
	End
	
	Function DrawRect( canvas:Canvas,rect:Rectf,fill:Bool )
		If fill
			canvas.DrawRect( rect )
		Else
			canvas.DrawLine( rect.Left,rect.Top,rect.Right,rect.Top )
			canvas.DrawLine( rect.Right,rect.Top,rect.Right,rect.Bottom )
			canvas.DrawLine( rect.Left,rect.Bottom,rect.Right,rect.Bottom )
			canvas.DrawLine( rect.Left,rect.Top,rect.Left,rect.Bottom )
		End
	End
	
	Private
	
	Method New()
	End
	
End
