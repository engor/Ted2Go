
Namespace mojo.app

#Import "assets/Roboto-Regular.ttf@/mojo"
#Import "assets/RobotoMono-Regular.ttf@/mojo"

Global App:AppInstance

Class AppInstance
	
	#rem monkeydoc Idle signal.
	
	Invoked when the app becomes idle.
	
	This is reset to null after being invoked.

	#end
	Field Idle:Void()
	
	#rem monkeydoc @hidden
	#end
	Field NextIdle:Void()	
	
	#rem monkeydoc Key event filter.
	
	Functions should check if the event has already been 'eaten' by checking the event's [[Event.Eaten]] property before processing the event.
	
	#end
	Field KeyEventFilter:Void( event:KeyEvent )

	#rem monkeydoc MouseEvent filter.

	Functions should check if the event has already been 'eaten' by checking the event's [[Event.Eaten]] property before processing the event.
	
	#end	
	Field MouseEventFilter:Void( event:MouseEvent )

	#rem monkeydoc Create a new app instance.
	#end
	Method New()
	
		App=Self
	
		SDL_Init( SDL_INIT_EVERYTHING )
		
		_sdlThread=SDL_ThreadID()
		
		Keyboard.Init()
		
		Mouse.Init()
		
		Audio.Init()

#If __TARGET__<>"emscripten"

		_glWindow=SDL_CreateWindow( "",0,0,0,0,SDL_WINDOW_HIDDEN|SDL_WINDOW_OPENGL )

		_glContext=SDL_GL_CreateContext( _glWindow )

		SDL_GL_MakeCurrent( _glWindow,_glContext )
		
		SDL_GL_SetAttribute( SDL_GL_SHARE_WITH_CURRENT_CONTEXT,1 )
		
#Endif
		_defaultFont=Font.Open( DefaultFontName,16 )
		
		_defaultMonoFont=Font.Open( DefaultMonoFontName,16 )

		Local style:=Style.GetStyle( "" )
		style.DefaultFont=_defaultFont
		style.DefaultColor=Color.White
	End

	#rem monkeydoc @hidden
	#end
	Property DefaultFontName:String()
		Return "asset::mojo/Roboto-Regular.ttf"
	End
	
	#rem monkeydoc @hidden
	#end
	Property DefaultMonoFontName:String()
		Return "asset::mojo/RobotoMono-Regular.ttf"
	End
	
	#rem monkeydoc @hidden
	#end
	Property DefaultFont:Font()
		Return _defaultFont
	End
	
	#rem monkeydoc @hidden
	#end
	Property DefaultMonoFont:Font()
		Return _defaultMonoFont
	End
	
	#rem monkeydoc True if clipboard text is empty.
	
	This is faster than checking whether [[ClipboardText]] returns an empty string.
	
	#end
	Property ClipboardTextEmpty:Bool()
	
		Return SDL_HasClipboardText()=SDL_FALSE
	End
	
	#rem monkeydoc Clipboard text.
	#end
	Property ClipboardText:String()
	
		If SDL_HasClipboardText()=SDL_FALSE Return ""
	
		Local p:=SDL_GetClipboardText()
		
		Local str:=String.FromUtf8String( p )

		'fix windows eols		
		str=str.Replace( "~r~n","~n" )
		str=str.Replace( "~r","~n" )		
		
		SDL_free( p )
		
		Return str
		
	Setter( text:String )
	
		SDL_SetClipboardText( text )
	End
	
	#rem monkeydoc The current key view.
	
	The key view is the view key events are sent to.

	#end
	Property KeyView:View()
	
		Local window:=ActiveWindow
		If window Return window.KeyView
		
		Return Null
		
	Setter( keyView:View )

		Local window:=ActiveWindow
		If window window.KeyView=keyView

	End
	
	#rem monkeydoc The current mouse view.
	
	The mouse view is the view that the mouse is currently 'dragging'.
	
	#end
	Property MouseView:View()
	
		Return _mouseView
	End
	
	#rem monkeydoc The current hover view.
	
	The hover view is the view that the mouse is currently 'hovering' over.
	
	#end
	Property HoverView:View()
	
		Return _hoverView
	End

	#rem monkeydoc The desktop size
	#end	
	Property DesktopSize:Vec2i()
	
#If __TARGET__="emscripten"

		Return New Vec2i( 1280,960 )

#Else
		Local dm:SDL_DisplayMode
		
		If SDL_GetDesktopDisplayMode( 0,Varptr dm ) Return New Vec2i
		
		Return New Vec2i( dm.w,dm.h )
#Endif

	End

	#rem monkeydoc The current active window.
	
	The active window is the window that has input focus.
	
	#end
	Property ActiveWindow:Window()
	
		Return Window.VisibleWindows()[0]
	End
	
	#rem monkeydoc Approximate frames per second rendering rate.
	#end
	Property FPS:Float()

		Return _fps
	End
	
	#rem monkeydoc Number of milliseconds app has been running.
	
	This property uses the high precision system timer if possible.
	
	#end
	Property Millisecs:Int()
	
		Return SDL_GetTicks()
	End
	
	#rem monkeydoc Mouse location relative to the active window.
	
	@see [[ActiveWindow]], [[MouseX]], [[MouseY]]
	
	#end	
	Property MouseLocation:Vec2i()

		Return _mouseLocation
	End
	
	#rem monkeydoc Terminate the app.
	#end
	Method Terminate()

		libc.exit_( 0 )
	End
	
	#rem monkeydoc Request that the app render itself.
	#end
	Method RequestRender()

		_requestRender=True
	End

	#rem @hidden
	#end
	Method MainLoop()
	
		If Not _requestRender 

			SDL_WaitEvent( Null )
			
		Endif
	
		UpdateEvents()
		
		If Not _requestRender Return
		
		_requestRender=False
		
		UpdateFPS()
			
		For Local window:=Eachin Window.VisibleWindows()
			window.Render()
		Next
			
	End
	
	Function EmscriptenMainLoop()

		App._requestRender=True
		
		App.MainLoop()
	End
	
	#rem monkeydoc Run the app.
	#end
	Method Run()
	
		SDL_AddEventWatch( _EventFilter,Null )
'		SDL_SetEventFilter( _EventFilter,Null )
		
		RequestRender()
		
#If __TARGET__="emscripten"

		emscripten_set_main_loop( EmscriptenMainLoop,0,1 )
		
#Else
		Repeat
		
			MainLoop()
			
		Forever
#Endif
	
	End

	Private
	
	Field _sdlThread:SDL_threadID
	Field _glWindow:SDL_Window Ptr
	Field _glContext:SDL_GLContext

	Field _defaultFont:Font
	Field _defaultMonoFont:Font
		
	Field _requestRender:Bool
	
	Field _hoverView:View
	Field _mouseView:View
	
	Field _fps:Float
	Field _fpsFrames:Int
	Field _fpsMillis:Int
	
	Field _window:Window
	Field _key:Key
	Field _rawKey:Key
	Field _keyChar:String
	Field _modifiers:Modifier
	Field _mouseButton:MouseButton
	Field _mouseLocation:Vec2i
	Field _mouseWheel:Vec2i
	
	Field _polling:Bool
	
	Global _nextCallbackId:Int
	Global _asyncCallbacks:=New IntMap<Void()>
	Global _disabledCallbacks:=New IntMap<Bool>
	
	Method UpdateFPS()
	
		_fpsFrames+=1
			
		Local elapsed:=App.Millisecs-_fpsMillis
		
		If elapsed>=250
			_fps=Round( _fpsFrames/(elapsed/1000.0) )
			_fpsMillis+=elapsed
			_fpsFrames=0
		Endif

	End
	
	Method UpdateEvents()
	
		Local event:SDL_Event

		_polling=True
		
		While SDL_PollEvent( Varptr event )
		
			DispatchEvent( Varptr event )
			
		Wend
		
		_polling=False
		
		Local idle:=Idle
		Idle=NextIdle
		NextIdle=Null
		idle()
		
		For Local window:=Eachin Window.VisibleWindows()
			window.Update()
		Next

	End
	
	Method SendKeyEvent( type:EventType )
	
		Local view:=KeyView
		If view And Not view.ReallyEnabled view=Null
		
		Local event:=New KeyEvent( type,view,_key,_rawKey,_modifiers,_keyChar )
		
		KeyEventFilter( event )
		
		If event.Eaten Return
		
		If view 
			view.SendKeyEvent( event )
		Else If ActiveWindow
			ActiveWindow.SendKeyEvent( event )
		Endif
	End
	
	Method SendMouseEvent( type:EventType,view:View )
	
		Local location:=view.TransformWindowPointToView( _mouseLocation )
		
		Local event:=New MouseEvent( type,view,location,_mouseButton,_mouseWheel,_modifiers )
		
		MouseEventFilter( event )
		
		If event.Eaten Return
		
		view.SendMouseEvent( event )
	End
	
	Method SendWindowEvent( type:EventType )
	
		Local event:=New WindowEvent( type,_window )
		
		_window.SendWindowEvent( event )
	End
	
	Method DispatchEvent( event:SDL_Event Ptr )

		Select event->type
		
		Case SDL_KEYDOWN
		
			Local kevent:=Cast<SDL_KeyboardEvent Ptr>( event )
			
			_window=Window.WindowForID( kevent->windowID )
			If Not _window Return
			
			_key=Keyboard.KeyCodeToKey( Int( kevent->keysym.sym ) )
			_rawKey=Keyboard.ScanCodeToRawKey( Int( kevent->keysym.scancode ) )
'			_modifiers=Keyboard.Modifiers
			_keyChar=Keyboard.KeyName( _key )
			
			If kevent->repeat_
				SendKeyEvent( EventType.KeyRepeat )
			Else
				SendKeyEvent( EventType.KeyDown )
			Endif

			_modifiers=Keyboard.Modifiers
			
		Case SDL_KEYUP

			Local kevent:=Cast<SDL_KeyboardEvent Ptr>( event )
			
			_window=Window.WindowForID( kevent->windowID )
			If Not _window Return
			
			_key=Keyboard.KeyCodeToKey( Int( kevent->keysym.sym ) )
			_rawKey=Keyboard.ScanCodeToRawKey( Int( kevent->keysym.scancode ) )
'			_modifiers=Keyboard.Modifiers
			_keyChar=Keyboard.KeyName( _key )
			
			SendKeyEvent( EventType.KeyUp )

			_modifiers=Keyboard.Modifiers

		Case SDL_TEXTINPUT
		
			Local tevent:=Cast<SDL_TextInputEvent Ptr>( event )

			_window=Window.WindowForID( tevent->windowID )
			If Not _window Return
			
			_keyChar=String.FromChar( tevent->text[0] )
			
			SendKeyEvent( EventType.KeyChar )
		
		Case SDL_MOUSEBUTTONDOWN
		
			Local mevent:=Cast<SDL_MouseButtonEvent Ptr>( event )
			
			_window=Window.WindowForID( mevent->windowID )
			If Not _window Return
			
			_mouseLocation=New Vec2i( mevent->x,mevent->y )
			_mouseButton=Cast<MouseButton>( mevent->button )
			
			If Not _mouseView
			
				Local view:=_window.FindViewAtWindowPoint( _mouseLocation )
				If view
'#If __HOSTOS__<>"linux"
					SDL_CaptureMouse( SDL_TRUE )
'#Endif
					_mouseView=view
				Endif
			Endif
				
			If _mouseView SendMouseEvent( EventType.MouseDown,_mouseView )
		
		Case SDL_MOUSEBUTTONUP
		
			Local mevent:=Cast<SDL_MouseButtonEvent Ptr>( event )
			
			_window=Window.WindowForID( mevent->windowID )
			If Not _window Return
			
			_mouseLocation=New Vec2i( mevent->x,mevent->y )
			_mouseButton=Cast<MouseButton>( mevent->button )
			
			If _mouseView

				SendMouseEvent( EventType.MouseUp,_mouseView )
'#If __HOSTOS__<>"linux"				
				SDL_CaptureMouse( SDL_FALSE )
'#Endif
				_mouseView=Null

				_mouseButton=Null
			Endif
			
		Case SDL_MOUSEMOTION
		
			Local mevent:=Cast<SDL_MouseMotionEvent Ptr>( event )
			
			_window=Window.WindowForID( mevent->windowID )
			If Not _window Return
			
			_mouseLocation=New Vec2i( mevent->x,mevent->y )
			
			Local view:=_window.FindViewAtWindowPoint( _mouseLocation )

			If _mouseView And view<>_mouseView view=Null
			
			If view<>_hoverView
			
				If _hoverView SendMouseEvent( EventType.MouseLeave,_hoverView )
				
				_hoverView=view
				
				If _hoverView SendMouseEvent( EventType.MouseEnter,_hoverView )
			Endif
			
			If _mouseView

				SendMouseEvent( EventType.MouseMove,_mouseView )
				
			Else If _hoverView

				SendMouseEvent( EventType.MouseMove,_hoverView )
			
			Endif

		Case SDL_MOUSEWHEEL
		
			Local mevent:=Cast<SDL_MouseWheelEvent Ptr>( event )
			
			_window=Window.WindowForID( mevent->windowID )
			If Not _window Return
			
			_mouseWheel=New Vec2i( mevent->x,mevent->y )
			
			If _mouseView
			
				SendMouseEvent( EventType.MouseWheel,_mouseView )
				
			Else If _hoverView

				SendMouseEvent( EventType.MouseWheel,_hoverView )
			
			Endif
			
		Case SDL_WINDOWEVENT
		
			Local wevent:=Cast<SDL_WindowEvent Ptr>( event )
			
			_window=Window.WindowForID( wevent->windowID )
			If Not _window Return
			
			Select wevent->event
					
			Case SDL_WINDOWEVENT_CLOSE
			
				SendWindowEvent( EventType.WindowClose )
			
			Case SDL_WINDOWEVENT_MOVED
			
			Case SDL_WINDOWEVENT_RESIZED
			
			Case SDL_WINDOWEVENT_FOCUS_GAINED
			
				SendWindowEvent( EventType.WindowGainedFocus )
			
			Case SDL_WINDOWEVENT_FOCUS_LOST
			
				SendWindowEvent( EventType.WindowLostFocus )
				
			Case SDL_WINDOWEVENT_LEAVE
			
				If _hoverView
					SendMouseEvent( EventType.MouseLeave,_hoverView )
					_hoverView=Null
				Endif
				
			End
			
		Case SDL_USEREVENT
		
			Local t:=Cast<SDL_UserEvent Ptr>( event )
			
			Local code:=t[0].code
			Local id:=code & $3fffffff
			
			If code & $40000000
				Local func:=_asyncCallbacks[ id ]				'null if removed
				If code & $80000000 RemoveAsyncCallback( id )
				If Not _disabledCallbacks[id] func()
			Else If code & $80000000
				RemoveAsyncCallback( id )
			Endif

		End
			
	End
	
	Function _EventFilter:Int( userData:Void Ptr,event:SDL_Event Ptr )
	
		Return App.EventFilter( userData,event )
	End
	
	Method EventFilter:Int( userData:Void Ptr,event:SDL_Event Ptr )
	
		#rem
		If SDL_ThreadID()<>_sdlThread 
			Print "Yikes! EventFilter running in non-main thread..."
			Return 1
		Endif
		#end
			
		Select event[0].type
		Case SDL_WINDOWEVENT

			Local wevent:=Cast<SDL_WindowEvent Ptr>( event )
			
			_window=Window.WindowForID( wevent->windowID )
			If Not _window Return 1
			
			Select wevent->event
			
			Case SDL_WINDOWEVENT_MOVED
			
				SendWindowEvent( EventType.WindowMoved )
			
				Return 0
					
			Case SDL_WINDOWEVENT_RESIZED',SDL_WINDOWEVENT_SIZE_CHANGED

				SendWindowEvent( EventType.WindowResized )
			
				If _requestRender
				
					_requestRender=False
					
					For Local window:=Eachin Window.VisibleWindows()
						window.Update()
						window.Render()
					Next
					
				Endif

				Return 0

			End
		End
		
		Return 1
	End
	
	Function AddAsyncCallback:Int( func:Void() )
		_nextCallbackId+=1
		Local id:=_nextCallbackId
		_asyncCallbacks[id]=func
		Return id
	End
	
	Function RemoveAsyncCallback( id:Int )
		_disabledCallbacks.Remove( id )
		_asyncCallbacks.Remove( id )
	End
	
	Function EnableAsyncCallback( id:Int )
		_disabledCallbacks.Remove( id )
	End
	
	Function DisableAsyncCallback( id:Int )
		If _asyncCallbacks.Contains( id ) _disabledCallbacks[id]=True
	End
	
End
