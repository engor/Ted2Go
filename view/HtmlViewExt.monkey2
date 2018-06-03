
Namespace ted2go


Class HtmlViewExt Extends HtmlView

	Field Navigated:Void( url:String )
	
	Method New()
		
		Super.New()
		
		_navOps.OnNavigate += Lambda( nav:Nav )
			
			Go( nav.url )
			Navigated( nav.url )
			
			nav.state+=1
			If nav.state=1 Return 'navigated first time, so it's new page, don't touch the scroll
			
			Scroll=nav.scroll
			
			'wait a bit for layout
			If _timer Then _timer.Cancel()
			_timer=New Timer(20, Lambda()
				Scroll=nav.scroll
				_timer.Cancel()
				_timer=Null
			End)
			
		End
	End
	
	Method Navigate( url:String )
		
		StoreScroll()
		
		Local nav:=New Nav
		nav.url=url
		_navOps.Navigate( nav )
		
	End
	
	Method Back()
		
		StoreScroll()
		_navOps.TryBack()
	End

	Method Forward()
		
		StoreScroll()
		_navOps.TryForward()
	End
	
	Method ClearHistory()
		
		_navOps.Clear()
	End
	
	
	Private
	
	Field _navOps:=New NavOps<Nav>
	Field _timer:Timer
	
	Method StoreScroll()
		
		If Not _navOps.Empty Return
		
		Local nav:=_navOps.Current
		If nav Then nav.scroll=Scroll
	End
	
	Class Nav ' make 'class' to use as ref in method
	
		Field url:String
		Field scroll:Vec2i
		Field state:=0 'nav counts
		
		Operator =:Bool(value:Nav)
			Return url=value.url
		End
	End
	
End
