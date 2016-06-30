
Namespace mojox

Class TabButton Extends Button

	Method New( text:String,view:View )
		Super.New( text )
		Style=Style.GetStyle( "mojo.TabButton" )
		TextGravity=New Vec2f( 0,.5 )
		_view=view
	End
	
	Property View:View()
	
		Return _view
	End
	
	Private
	
	Field _view:View

End

Class TabView Extends View

	Field CurrentChanged:Void()

	Method New()
		Style=Style.GetStyle( "mojo.TabView" )
		Layout="fill"
	End
	
	Property Count:Int()
	
		Return _tabs.Length
	End
	
	Property CurrentIndex:Int()

		If _current Return IndexOfView( _current.View )
		Return -1
		
	Setter( currentIndex:Int )
	
		MakeCurrent( _tabs[currentIndex] )
	End
	
	Property CurrentView:View()
	
		If _current Return _current.View
		Return Null
	
	Setter( currentView:View )
	
		For Local tab:=Eachin _tabs
			If tab.View<>currentView Continue
			MakeCurrent( tab )
			Return
		Next
	End
	
	Method ViewAtIndex:View( index:Int )
		Return _tabs[index].View
	End

	Method IndexOfView:Int( view:View )
		For Local i:=0 Until _tabs.Length
			If _tabs[i].View=view Return i
		Next
		Return -1
	End

	Method AddTab:Int( text:String,view:View,makeCurrent:Bool=False )

		Local index:=_tabs.Length

		Local tab:=New TabButton( text,view )
		tab.Clicked=Lambda()
			MakeCurrent( tab )
		End
		_tabs.Add( tab )

		AddChild( tab )

		If makeCurrent MakeCurrent( tab )

		Return index
	End
	
	Method RemoveTab( view:View )
	
		RemoveTab( IndexOfView( view ) )
	End
	
	Method RemoveTab( index:Int )
	
		If _current=_tabs[index]
			_current.Selected=False
			RemoveChild( _current.View.Container )
			_current=Null
		Endif
		
		RemoveChild( _tabs[index] )
		
		_tabs.Erase( index )
	End
	
	Method SetTabLabel( view:View,label:String )
	
		SetTabLabel( IndexOfView( view ),label )
	
	End
	
	Method SetTabLabel( index:Int,label:String )
	
		_tabs[index].Text=label
	End
	
	Private
	
	Field _tabs:=New Stack<TabButton>
	
	Field _current:TabButton
	
	Field _buttonsSize:Vec2i
	
	Method MakeCurrent( tab:TabButton )
	
		If tab=_current Return
		
		If _current 
			_current.Selected=False
			RemoveChild( _current.View.Container )
		Endif

		_current=tab

		If _current
			_current.Selected=True
			AddChild( _current.View.Container )
		Endif
		
		CurrentChanged()
			
	End
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=New Vec2i
		
		For Local tab:=Eachin _tabs
			size.x+=tab.LayoutSize.x
			size.y=Max( size.y,tab.LayoutSize.y )
		Next
		
		_buttonsSize=size
		
		If _current
			size.x=Max( size.x,_current.View.LayoutSize.x )
			size.y+=_current.View.LayoutSize.y
		Endif
		
		Return size
	
	End
	
	Method OnLayout() Override
	
		Local x:=0
		
		For Local tab:=Eachin _tabs
			tab.Frame=New Recti( x,0,x+tab.LayoutSize.x,_buttonsSize.y )
			x+=tab.LayoutSize.x
		Next
		
		If _current _current.View.Container.Frame=New Recti( 0,_buttonsSize.y,Width,Height )
	End
	
End

