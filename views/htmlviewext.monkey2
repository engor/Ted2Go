
Namespace ted2go


Class HtmlViewExt Extends HtmlView

	Field Navigated:Void( url:String )
	
	Method Navigate( url:String )
		
		Go( url )
		_url=url
		
		' remove all forwarded
		While _index<_count-1
			_history.Pop()
			_count-=1
		Wend
		
		' the same current url
		If _count > 0 And _history[_count-1]=url Return
		
		_history.Push( url )
		_index+=1
		_count+=1
		
		Navigated( url )
	End
	
	Method Back()
		
		_index-=1
		If _index<0
			_index=0
			Return
		Endif
		Local url:=_history.Get( _index )
		Go( url )
		_url=url
		Navigated( url )
	End

	Method Forward()
		
		_index+=1
		If _index>=_count
			_index=_count-1
			Return
		Endif
		Local url:=_history.Get( _index )
		Go( url )
		_url=url
		Navigated( url )
	End
	
	Method ClearHistory()
		_history.Clear()
		_index=-1
		_count=0
	End
	
	Property Url:String()
		Return _url
	End

	Private
	
	Field _index:=-1, _count:Int
	Field _url:String
	Field _history:=New Stack<String>
	
End
