
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
		
			If scroll<>Scroll event.Eat()
			Return
		End
		
		Super.OnMouseEvent( event )
		
	End
	
End


' full copy of mojox.TabView
' can't extend it, all I need is private there
'
Class TabViewExt Extends DockingView

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
		_nxt=New PushButton( ">" )
		_nxt.Style=App.Theme.GetStyle( "TabViewArrowNext" )
		headerDock.AddView( _nxt,"right" )
		_nxt.Visible=False
		
		_prev=New PushButton( "<" )
		_prev.Style=App.Theme.GetStyle( "TabViewArrowPrev" )
		headerDock.AddView( _prev,"right" )
		_prev.Visible=False
		
		_scrollView=New ScrollViewTabs( _tabBar )
		_scrollView.ScrollBarsVisible=False
		headerDock.ContentView=_scrollView
		AddView( headerDock,"top" )
		
		_nxt.Clicked+=Lambda()
			Local s:=_scrollView.Scroll
			_scrollView.Scroll=s+New Vec2i( 200,0 )
		End
		_prev.Clicked+=Lambda()
			Local s:=_scrollView.Scroll
			_scrollView.Scroll=s-New Vec2i( 200,0 )
		End
		
		MinSize=New Vec2i( 50,50 )
		
		If Not _listener Then _listener=New DraggableTabsListener
	End
	
	Function CreateDraggableTab:TabButtonExt( text:String,view:View,possibleParents:TabViewExt[],icon:Image=Null,closable:Bool=False )
		
		Local tab:=New TabButtonExt( text,icon,view,closable,Null )
		tab.PossibleParentDocks=possibleParents
		Return tab
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
	Method AddTab:TabButtonExt( text:String,view:View,makeCurrent:Bool=False )
	
		Return AddTab( text,Null,view,makeCurrent )
	End

	Method AddTab:TabButtonExt( text:String,icon:Image,view:View,makeCurrent:Bool=False )
		
		Local tab:=New TabButtonExt( text,icon,view,_flags & TabViewFlags.ClosableTabs,Self )
		
		AddTab( tab,makeCurrent )
		
		Return tab
	End
	
	Method AddTab( tab:TabButtonExt,makeCurrent:Bool=False )
	
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

		_tabBar.AddView( tab )
		_tabs.Push( tab )
		
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
	
		SetTabText( TabIndex( view ),text )
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
	
	Method ShowDragPlaceHolder()
		
		_dragDropMode=True
		_curIndex=CurrentIndex
		Visible=True
		If Not _placeHolderTab
			Local v:=New Label '("[Drop tab here]")
			v.Style=GetStyle( "TabsDropArea","Label" )
			v.Layout="fill"
			v.Gravity=New Vec2f( .5,.5 )
			_placeHolderTab=AddTab( "[+]",v,True )
		Else
			AddTab( _placeHolderTab,True )
		Endif
	End
	
	Method HideDragPlaceHolder()
		
		If Not _dragDropMode Return
		
		_dragDropMode=False
		
		RemoveTab( _placeHolderTab )
		_placeHolderTab=Null
'		
		Visible=NumTabs>0
		
		If _curIndex>=0 Then CurrentIndex=_curIndex
	End
	
	
	Protected
	
	Method OnMeasure:Vec2i() Override
		
		Local size:=Super.OnMeasure()
		' show / hide navigation buttons
		Local ww:=GetTabsWidth()
		Local vis:=(ww>_scrollView.Frame.Width)
		_nxt.Visible=vis
		_prev.Visible=vis
		
		Return size
	End
	
	
	Private
	
	Field _flags:TabViewFlags
	Field _tabBar:TabBar
	Field _tabs:=New Stack<TabButtonExt>
	Field _current:TabButton
	Field _scrollView:ScrollView
	Field _nxt:PushButton,_prev:PushButton
	Field _placeHolderTab:TabButtonExt
	Field _curIndex:Int
	Field _dragDropMode:Bool
	Global _listener:DraggableTabsListener
	
	Method MakeCurrent( tab:TabButton,notify:Bool )
	
		If tab=_current Return
		
		If _current _current.Selected=False
		
		ContentView=tab.View
		
		_current=tab
		
		If _current _current.Selected=True
		
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


Class TabButtonExt Extends TabButton
	
	Method New( text:String,icon:Image,view:View,closable:Bool,parentDock:TabViewExt )
		
		Super.New( text,icon,view,closable )
		_parentDock=parentDock
	End
	
	Property Detachable:Bool()
		Return PossibleParentDocks<>Null
	End
	
	Property ParentDock:TabViewExt()
		Return _parentDock
	End
	
	Property PossibleParentDocks:TabViewExt[]()
		Return _possibleParentDocks
	Setter( value:TabViewExt[] )
		_possibleParentDocks=value
	End
	
	Method Activate()
		
		Local dock:=ParentDock
		If dock Then dock.MakeCurrent( Text )
	End
	
	Method TryDropTo( tabDock:TabViewExt )
		
		If Not CanDropTo( tabDock )
			tabDock=_parentDock
		Endif
		
		_parentDock.Visible=(_parentDock.NumTabs>0)
		_parentDock=tabDock
		tabDock.AddTab( Self )
		tabDock.Visible=True
		
		Activate()
	End
	
	Property IsActive:Bool()
		Return _parentDock.ActiveName=Text
	End
	
	Protected
	
	Field _parentDock:TabViewExt
	
	
	Private
	
	Field _possibleParentDocks:TabViewExt[]
	
	Method CanDropTo:Bool( tabDock:TabViewExt,skipSelfParent:Bool=True )
	
		If Not tabDock Return False
		If Not _possibleParentDocks Return False
	
		For Local d:=Eachin _possibleParentDocks
	
			If skipSelfParent And d=_parentDock Continue
			If d=tabDock Return True
		Next
		Return False
	End
	
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


Class DraggableTabsListener
	
	Method New()
		
		App.MouseEventFilter+=OnMouseEvent
	End
	
	Private
	
	Global _label:Label
	Global _tab:TabButtonExt
	Global _pressedPos:Vec2i
	Global _detached:Bool
	
	Function OnMouseEvent( event:MouseEvent )
	
		Select event.Type
			
			Case EventType.MouseDown
				
				_tab=Cast<TabButtonExt>( event.View )
				If Not _tab Return
				
				If Not _tab.Detachable
					_tab=Null
					Return
				Endif
				
				_pressedPos=Mouse.Location
				
			
			Case EventType.MouseMove
			
				If Not _tab Return
				
				If _detached
					Local r:=_tab.Frame
					Local sz:=r.Size
					r.TopLeft=Mouse.Location+New Vec2i( 0,-10 )
					r.BottomRight=r.TopLeft+sz
					_tab.Frame=r
					App.RequestRender()
					Return
				Endif
				
				Local dy:Float=Abs(Mouse.Y-_pressedPos.y)
				If dy>10.0*App.Theme.Scale.y
					Detach()
				Endif
				
				
			Case EventType.MouseUp
				
				If Not _detached 
					_tab=Null
					Return
				Endif
				
				Local dock:TabViewExt=Null
				Local v:=App.ActiveViewAtMouseLocation()
				While v
					Local d:=Cast<TabViewExt>( v )
					If d
						dock=d
						Exit
					Endif
					v=v.Parent
				Wend
				
				If _tab.PossibleParentDocks
					For Local d:=Eachin _tab.PossibleParentDocks
						d.HideDragPlaceHolder()
					Next
				Endif
				
				MainWindow.RemoveChildView( _tab )
				
				_tab.TryDropTo( dock )
				
				_tab=Null
				_detached=False
			
		End
	
	End
	
	Function Detach()
		
		_detached=True
		
'		If Not _label
'			_label=New Label
'			_label.Layout="float"
'			_label.MaxSize=New Vec2i( 40,100 )
'			MainWindow.AddChildView( _label )
'		Endif
'		_label.Text=_tab.Text
'		_label.Visible=True
		'Local size:=_label.MeasureLayoutSize()
		'_label.Frame=New Recti( Mouse.Location,Mouse.Location+size)
		
		_tab.ParentDock.RemoveTab( _tab )
		MainWindow.AddChildView( _tab )
		_tab.Selected=True
		
		If Not _tab.PossibleParentDocks Return
		
		For Local d:=Eachin _tab.PossibleParentDocks
			d.ShowDragPlaceHolder()
		Next
		
	End
	
	
End
	