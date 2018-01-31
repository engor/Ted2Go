Namespace ted2go

Class UndockWindow Extends Window
		
		Field _storeView:View
		Field _storeTabbutton:TabButtonExt
		Field _storeIndex:Int
		Field _visible:Int
		
		Global _undockWindows:=New Stack<UndockWindow>
		
		Method New()
		
			Super.New( "Undock Window", MainWindow.Width/2, MainWindow.Height/2, WindowFlags.Resizable | WindowFlags.HighDPI | WindowFlags.Center )
			Self.UpdateWindow( True )
			_undockWindows.Push( Self )
		End
		
		Function NewUndock:UndockWindow( _tabbutton:TabButtonExt )
			
			Local _window:UndockWindow
		
			For Local dw:=Eachin _undockWindows
				If(dw.Title=_tabbutton.Text)_window=dw;Exit
			Next
				
			If Not (_window) _window=New UndockWindow
			
			_tabbutton.CurrentHolder.MakeCurrent( _tabbutton.Text )
			_window.Title=_tabbutton.Text
			_tabbutton.Visible=False
		
			_window._storeTabbutton=_tabbutton
			_window._storeView=_tabbutton.CurrentHolder.CurrentView
			_window._storeIndex=_tabbutton.CurrentHolder.CurrentIndex
		
			_tabbutton.CurrentHolder.SetTabView( _window._storeIndex, Null )
			If Not _tabbutton.CurrentHolder.VisibleTabs _tabbutton.CurrentHolder.Visible=False
		
			For Local mk:=Eachin _tabbutton.CurrentHolder.Tabs
				If mk.Visible _tabbutton.CurrentHolder.MakeCurrent( mk.Text )
			Next
		
			_window.ContentView=_window._storeView
			_window._visible=True
			_window.Activated()
			Return _window
		End
			
		Method SetUndockFrame( _frame:Recti )
			
			SDL_SetWindowPosition( Self.Window.SDLWindow, _frame.X, _frame.Y )
			SDL_SetWindowSize( Self.Window.SDLWindow, _frame.Width, _frame.Height )
			Self.Restore()
		End
		
		Method OnWindowEvent( event:WindowEvent ) Override
		
			Select event.Type
				Case EventType.WindowClose
					CloseWindow()
				Default
					Super.OnWindowEvent( event )
			End
		End
		
		Method CloseWindow()
			
			Local view:=ContentView
			ContentView=Null
			_storeTabbutton.CurrentHolder.SetTabView( _storeIndex, view )
			_storeTabbutton.Visible=True
			If Not _storeTabbutton.CurrentHolder.Visible _storeTabbutton.CurrentHolder.Visible=True
			SDL_HideWindow( Self.Window.SDLWindow )
			Self._visible=False
		End
		
		Function RestoreUndock()

			For Local i:=Eachin _undockWindows
				i.CloseWindow()
				_undockWindows.RemoveEach( i )
			Next
			If _undockWindows.Length RestoreUndock()		
		End	
End