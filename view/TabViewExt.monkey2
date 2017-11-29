
Namespace ted2go


Class ScrollViewTabs Extends ScrollView

	Method New( contentView:View )
		Super.New( contentView )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		' catch horizontal scrolling
		Select event.Type
		Case EventType.MouseWheel
		
			Local scroll:=Scroll
		
			Local delta:=New Vec2i( 4*ContentView.RenderStyle.Font.Height*event.Wheel.Y,0 )
		
			Scroll-=delta
		
			'If scroll<>Scroll event.Eat()
			event.Eat()
			Return
		End
		
		Super.OnMouseEvent( event )
		
	End
	
End


' full copy of mojox.TabView
' can't extend it, all I need is private there
'
Class TabViewExt Extends DockingView Implements IDraggableHolder

	#rem monkeydoc Invoked when the current tab changes.
	#end
	Field CurrentChanged:Void()
	
	#rem monkeydoc @hidden
	#end
	Field Clicked:Void()
	
	#rem monkeydoc Invoked when a tab is right clicked.
	#end
	Field RightClicked:Void()
	
	#rem monkeydoc Invoked when a tab is double clicked.
	#end
	Field DoubleClicked:Void()
	
	#rem monkeydoc Invoked when a tab is double clicked.
	#end
	Field CloseClicked:Void( index:Int )

	#rem monkeydoc Invoked when a tab is dragged.
	#end	
	Field Dragged:Void()

	#rem monkeydoc Creates a new tab view.
	#end
	Method New( flags:TabViewFlags=TabViewFlags.DraggableTabs )
	
		_flags=flags
		
		Style=GetStyle( "TabView" )
		Layout="fill"
		_tabBar=New TabBar
		
		' add scrollbar here
		Local headerDock:=New DockingView
		
		_prevNextDock=New DockingView
		_prevNextDock.Visible=False
		Local nxt:=New PushButton( ">" )
		nxt.Style=App.Theme.GetStyle( "TabViewArrowNext" )
		_prevNextDock.AddView( nxt,"right" )
		
		Local prev:=New PushButton( "<" )
		prev.Style=App.Theme.GetStyle( "TabViewArrowPrev" )
		_prevNextDock.AddView( prev,"right" )
		
		headerDock.AddView( _prevNextDock,"right" )
		
		_scrollView=New ScrollViewTabs( _tabBar )
		_scrollView.ScrollBarsVisible=False
		headerDock.ContentView=_scrollView
		AddView( headerDock,"top" )
		
		nxt.Clicked+=Lambda()
			Local s:=_scrollView.Scroll
			_scrollView.Scroll=s+New Vec2i( 150,0 )
		End
		prev.Clicked+=Lambda()
			Local s:=_scrollView.Scroll
			_scrollView.Scroll=s-New Vec2i( 150,0 )
		End
		
		MinSize=New Vec2i( 50,50 )
		
		If Not _listener Then _listener=New DraggableTabsListener
	End
	
	Function CreateDraggableTab:TabButtonExt( text:String,view:View,possibleParents:TabViewExt[],icon:Image=Null,closable:Bool=False )
		
		Local tab:=New TabButtonExt( text,icon,view,closable,Null )
		tab.PossibleHolders=possibleParents
		Return tab
	End
	
	Method Attach( item:Object,eventLocation:Vec2i )
		
		Local tab:=Cast<TabButtonExt>( item )
		AddTab( tab )
		MakeCurrent( tab,True )
		
		_vis=True
		_curIndex=CurrentIndex-1 '-1 for [+] tab
	End
	
	Method Detach:View( item:Object )
		
		Local tab:=Cast<TabButtonExt>( item )
		RemoveTab( tab )
		tab.Selected=True
		Return tab
	End
	
	Method OnDragStarted()
		
		_dragDropMode=True
		_curIndex=CurrentIndex
		_vis=Visible
		Visible=True
		If Not _placeHolderTab
			Local v:=New Label ("[Drop tab here]")
			v.Style=GetStyle( "TabsDropArea","Label" )
			v.Layout="fill"
			v.Gravity=New Vec2f( .5,.5 )
			_placeHolderTab=AddTab( "[+]",v,True )
			_placeHolderContent=v
		Else
			AddTab( _placeHolderTab,True )
		Endif
	End
	
	Method OnDragEnded()
		
		If Not _dragDropMode Return
		
		_dragDropMode=False
		
		RemoveTab( _placeHolderTab )
		_placeHolderTab=Null
'		
		Visible=(_vis And NumTabs>0)
		
		If _curIndex>=0 Then CurrentIndex=_curIndex
	End
	
	#rem monkeydoc Tab view flags.
	#end
	Property Flags:TabViewFlags()
	
		Return _flags
	End
	
	#rem monkeydoc Number of tabs
	#end
	Property NumTabs:Int()
	
		Return _tabs.Length
	End
	
	#rem monkeydoc The current index.
	#end
	Property CurrentIndex:Int()

		If _current Return TabIndex( _current.View )

		Return -1
		
	Setter( currentIndex:Int )
		
		MakeCurrent( _tabs[currentIndex],False )
	End
	
	#rem monkeydoc The current view.
	#end
	Property CurrentView:View()
	
		If _current Return _current.View

		Return Null
	
	Setter( currentView:View )
	
		MakeCurrent( _tabs[ TabIndex( currentView ) ],False )
	End

	#rem monkeydoc Gets a tab's view.
	#end
	Method TabView:View( index:Int )
		Assert( index>=0 And index<_tabs.Length,"Tab index out of range" )
	
		Return _tabs[index].View
	End

	#rem monkeydoc Gets a tab's index.
	#end
	Method TabIndex:Int( view:View )
	
		For Local i:=0 Until _tabs.Length
			If _tabs[i].View=view Return i
		Next

		Return -1
	End
	
	Property Tabs:TabButtonExt[]()
		Return _tabs.ToArray()
	End
	
	Property TabsNames:String[]()
		
		Local arr:=New String[NumTabs]
		For Local i:=0 Until _tabs.Length
			arr[i]=_tabs[i].Text
		Next
		Return arr
	End
	
	Property ActiveName:String()
		Return _current ? _current.Text Else ""
	End
	
	#rem monkeydoc Adds a tab.
	#end	
	Method AddTab:TabButtonExt( text:String,view:View,makeCurrent:Bool=False,addAtBegin:Bool=False )
	
		Return AddTab( text,Null,view,makeCurrent,addAtBegin )
	End

	Method AddTab:TabButtonExt( text:String,icon:Image,view:View,makeCurrent:Bool=False,addAtBegin:Bool=False )
		
		Local tab:=New TabButtonExt( text,icon,view,_flags & TabViewFlags.ClosableTabs,Self )
		
		AddTab( tab,makeCurrent,addAtBegin )
		
		Return tab
	End
	
	Method AddTab( tab:TabButtonExt,makeCurrent:Bool=False,addAtBegin:Bool=False )
	
		Assert( TabIndex( tab.View )=-1,"View has already been added to TabView" )
		
		TabButtonExt_Bridge.SetTabParent( tab,Self )
	
		tab.Clicked=Lambda()
		
			MakeCurrent( tab,True )

			Clicked()
		End
		
		tab.RightClicked=Lambda()
		
			MakeCurrent( tab,True )
			
			RightClicked()
		End
		
		tab.DoubleClicked=Lambda()
		
			MakeCurrent( tab,True )
			
			DoubleClicked()
		End
		
		tab.Dragged=Lambda( v:Vec2i )
		
			If Not (_flags & TabViewFlags.DraggableTabs) Return

			Local mx:=_tabBar.MouseLocation.x
			If mx<0 Return
			
			Local w:=tab.Bounds.Width

			Local x:=0,i:=_tabs.Length
			For Local j:=0 Until i

				If mx<x+w
					i=j
					Exit
				Endif
				
				If tab=_tabs[j] Continue
				
				x+=_tabs[j].Bounds.Width
				If mx<x Return
			Next
			
			Local i2:=_tabs.FindIndex( tab )
			If i=i2 Return

			If i>i2 i-=1
			
			_tabs.Erase( i2 )
			_tabs.Insert( i,tab )
			
			_tabBar.RemoveAllViews()
			For Local view:=Eachin _tabs
				_tabBar.AddView( view )
			Next

			RequestRender()
			
			Dragged()
		End
		
		tab.CloseClicked=Lambda()
		
			CloseClicked( TabIndex( tab.View ) )
		End
		
		Local index:=_tabs.Length
		
		If addAtBegin
			_tabBar.RemoveAllViews()
			_tabs.Insert( 0,tab )
			For Local view:=Eachin _tabs
				_tabBar.AddView( view )
			Next
		Else
			_tabBar.AddView( tab )
			_tabs.Add( tab )
		Endif
		
		If makeCurrent MakeCurrent( tab,True ) 'CurrentIndex=index
		
	End
	
	#rem monkeydoc Removes a tab.
	#end
	Method RemoveTab( index:Int )
		
		Local tab:=_tabs[index]
		If _current=tab
			_current.Selected=False
			_current=Null
			ContentView=Null
		Endif
		
		_tabBar.RemoveView( tab )
		_tabs.Erase( index )
		
		tab.Clicked=Null
		tab.RightClicked=Null
		tab.DoubleClicked=Null
		tab.Dragged=Null
		tab.CloseClicked=Null
		
		If index>=NumTabs Then index-=1
		If index>=0 Then CurrentIndex=index
	End
	
	Method RemoveTab( view:View )
	
		RemoveTab( TabIndex( view ) )
	End
	
	Method RemoveTab( tab:TabButton )
	
		RemoveTab( TabIndex( tab.View ) )
	End
	
	Method SetTabView( index:Int,view:View )
	
		_tabs[index].View=view
		
		If _tabs[index]=_current ContentView=view
	End
	
	Method SetTabView( view:View,newView:View )

		SetTabView( TabIndex( view ),newView )
	End
	
	#rem monkeydoc Sets a tab's text.
	#end
	Method SetTabText( index:Int,text:String )
	
		_tabs[index].Text=text
	End
	
	Method SetTabText( view:View,text:String )
		
		Local index:=TabIndex( view )
		If index>=0 Then SetTabText( index,text )
	End
	
	#rem monkeydoc Sets a tab's icon.
	#end
	Method SetTabIcon( index:Int,icon:Image )
	
		_tabs[index].Icon=icon
	End
	
	Method SetTabIcon( view:View,icon:Image )
	
		SetTabIcon( TabIndex( view ),icon )
	End
	
	Method EnsureVisibleCurrentTab()
	
		EnsureVisibleTab( _current )
	End
	
	Method MakeCurrent( tabCaption:String )
		
		For Local t:=Eachin _tabs
			If t.Text=tabCaption
				MakeCurrent( t,True )
				Return
			Endif
		Next
	End
	
	
	Protected
	
	Method OnMeasure:Vec2i() Override
		
		Local size:=Super.OnMeasure()
		' show / hide navigation buttons
		Local ww:=GetTabsWidth()
		Local vis:=(ww>Frame.Width)
		_prevNextDock.Visible=vis
		
		Return size
	End
	
	Method OnThemeChanged() Override
		
		If _placeHolderContent Then _placeHolderContent.Style=GetStyle( "TabsDropArea","Label" )
	End
	
	
	Private
	
	Field _flags:TabViewFlags
	Field _tabBar:TabBar
	Field _tabs:=New Stack<TabButtonExt>
	Field _current:TabButtonExt
	Field _scrollView:ScrollView
	'Field _nxt:PushButton,_prev:PushButton
	Field _placeHolderTab:TabButtonExt
	Field _placeHolderContent:View
	Field _prevNextDock:DockingView
	Field _curIndex:Int
	Field _dragDropMode:Bool
	Field _vis:Bool
	Global _listener:DraggableTabsListener
	
	Method MakeCurrent( tab:TabButtonExt,notify:Bool )
	
		If tab=_current Return
		
		Local prev:=_current
		
		ContentView=tab.View
		
		_current=tab
		
		If prev
			prev.Selected=False
			prev.ActiveChanged()
		Endif
		If _current
			_current.Selected=True
			_current.ActiveChanged()
		Endif
		
		If notify CurrentChanged()
		
		EnsureVisibleTab( tab )
		
	End
	
	Method EnsureVisibleTab( tab:TabButton )
	
		If Not tab Return
		
		MainWindow.UpdateWindow( False )
		
		Local scroll:=_scrollView.Scroll
		Local xx:=GetTabPosX( tab )
		Local L:=xx-scroll.x
		Local R:=L+tab.Frame.Width
	
		If L < 0
			scroll.x+=L-8
			_scrollView.Scroll=scroll
		Else
			Local d:=R-_scrollView.Frame.Width
			If d > 0
				scroll.x+=d+8
				_scrollView.Scroll=scroll
			Endif
		Endif
	End
	
	Method GetTabPosX:Int( tab:TabButton )
		
		Local xx:=0
		For Local view:=Eachin _tabs
			If view=tab Exit
			xx+=view.Frame.Width
		Next
		Return xx
	End
	
	Method GetTabsWidth:Int()
	
		Local xx:=0
		For Local view:=Eachin _tabs
			xx+=view.Frame.Width
		Next
		Return xx
	End
	
End


Class TabButtonExt Extends TabButton Implements IDraggableItem<TabViewExt>
	
	Field ActiveChanged:Void()
	
	Method New( text:String,icon:Image,view:View,closable:Bool,parentDock:TabViewExt )
		
		Super.New( text,icon,view,closable )
		_parentDock=parentDock
		_closable=closable
	End
	
	Property Detachable:Bool()
		Return PossibleHolders<>Null
	End
	
	Property CurrentHolder:TabViewExt()
		Return _parentDock
	End
	
	Property PossibleHolders:TabViewExt[]()
		Return _possibleParentDocks
	Setter( value:TabViewExt[] )
		_possibleParentDocks=value
	End
	
	Method Activate()
		
		CurrentHolder?.MakeCurrent( Text )
	End
	
	Property IsActive:Bool()
		Return _parentDock.ActiveName=Text
	End
	
	Method SetLockedState( locked:Bool )
		
		_locked=locked
		OnThemeChanged()
	End
	
	
	Protected
	
	Field _parentDock:TabViewExt
	
	Method OnThemeChanged() Override
		
		Super.OnThemeChanged()
		Style=GetStyle( _locked ? "TabButtonLocked" Else "TabButton" )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
		
		If _closable And 
			event.Type=EventType.MouseUp And 
			event.Button=MouseButton.Middle
			
			CloseClicked()
			event.Eat()
			Return
		Endif
		
		Super.OnMouseEvent( event )
	End
	
	
	Private
	
	Field _possibleParentDocks:TabViewExt[]
	Field _locked:Bool
	Field _closable:Bool
End


Private 

Class TabButtonExt_Bridge Extends TabButtonExt Abstract

	Function SetTabParent( tab:TabButtonExt,parent:TabViewExt )
		
		tab._parentDock=parent
	End
	
	Private
	
	Method New( text:String,icon:Image,view:View,closable:Bool,parentDock:TabViewExt )
		
		Super.New( text,icon,view,closable,parentDock )
	End
	
	
End


Class DraggableTabsListener Extends DraggableViewListener<TabButtonExt,TabViewExt>
	
	Method GetItem:TabButtonExt( eventView:View,eventLocation:Vec2i ) Override
		
		Return Cast<TabButtonExt>( eventView )
	End
	
	Method GetHolder:TabViewExt( view:View ) Override
		
		Return FindViewInHierarchy<TabViewExt>( view )
	End
	
End
