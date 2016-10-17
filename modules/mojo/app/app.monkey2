
#Import "native/app.cpp"
#Import "native/app.h"

Namespace mojo.app

Extern Private

Function AppInit()="bbApp::init"

Public

'#Import "assets/Roboto-Regular.ttf@/mojo"
'#Import "assets/RobotoMono-Regular.ttf@/mojo"

#rem monkeydoc The global AppInstance instance.
#end
Global App:AppInstance

#rem monkeydoc @hidden
#end
Struct DisplayMode
	Field width:Int
	Field height:Int
	Field hertz:Int
End

#rem monkeydoc The AppInstance class.

The AppInstance class is mainly reponsible for running the app 'event loop', but also provides several utility functions for managing the application.

A global instance of the AppInstance class is stored in the [[App]] global variable, so you can use any member of the AppInstance simply by prefixing it with 'App.', eg: App.MilliSecs

#end
Class AppInstance
	
	#rem monkeydoc Invoked when the app becomes idle.
	#end
	Field Idle:Void()
	
	#rem monkeydoc Invoked when app is activated.
	#end
	Field Activated:Void()
	
	#rem monkeydoc Invoked when app is deactivated.
	#end
	Field Deactivated:Void()
	
	#rem monkeydoc @hidden
	#end
	Field ThemeChanged:Void()
	
	#rem monkeydoc Invoked when a file is dropped on an app window.
	#end
	Field FileDropped:Void( path:String )
	
	#rem monkeydoc Key event filter.
	
	To prevent the event from being sent to a view, a filter can eat the event using [[Event.Eat]].
	
	Filter functions should check if the event has already been 'eaten' by checking the event's [[Event.Eaten]] property before processing the event.
	
	#end
	Field KeyEventFilter:Void( event:KeyEvent )

	#rem monkeydoc MouseEvent filter.
	
	To prevent the event from being sent to a view, a filter can eat the event using [[Event.Eat]].

	Filter functions should check if the event has already been 'eaten' by checking the event's [[Event.Eaten]] property before processing the event.
	
	#end	
	Field MouseEventFilter:Void( event:MouseEvent )

	#rem monkeydoc Create a new app instance.
	#end
	Method New( config:StringMap<String> =Null )
	
		App=Self
		
		If Not config config=New StringMap<String>
	
		_config=config

		SDL_Init( SDL_INIT_VIDEO|SDL_INIT_JOYSTICK )

		'possible fix for linux crashing at exit (can't reproduce myself).
		'		
		libc.atexit( SDL_Quit )
		
		AppInit()
		
		Keyboard.Init()
		
		Mouse.Init()
		
		Audio.Init()
		
		SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER,1 )
		
#If __TARGET__="windows" Or __TARGET__="macos" Or __TARGET__="emscripten"

		_captureMouse=True
#Endif

#if __MOBILE_TARGET__

		_touchMouse=True

    	SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK,SDL_GL_CONTEXT_PROFILE_ES )
		SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION,2 )
		
#Else If __TARGET__="emscripten"

		
#Else If __TARGET__="raspbian"


#Else If __DESKTOP_TARGET__

#if __TARGET__="windows"

		Local gl_major:=Int( GetConfig( "GL_context_major_version",-1 ) )
		Local gl_minor:=Int( GetConfig( "GL_context_major_version",-1 ) )
		
		Local gl_profile:Int

		Select GetConfig( "GL_context_profile","es" )
		Case "core"
			gl_profile=SDL_GL_CONTEXT_PROFILE_CORE
		Case "compatibility"
			gl_profile=SDL_GL_CONTEXT_PROFILE_COMPATIBILITY
		Default
			gl_profile=SDL_GL_CONTEXT_PROFILE_ES
			If gl_major=-1 gl_major=2
			If gl_minor=-1 gl_minor=0
		End
		
		SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK,gl_profile )
		
		If gl_major<>-1 SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION,gl_major )
		If gl_minor<>-1 SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION,gl_minor )

#Endif

		SDL_GL_SetAttribute( SDL_GL_SHARE_WITH_CURRENT_CONTEXT,1 )
		
		SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE,Int( GetConfig( "GL_depth_buffer_enabled",0 ) ) )
		SDL_GL_SetAttribute( SDL_GL_STENCIL_SIZE,Int( GetConfig( "GL_stencil_buffer_enabled",0 ) ) )
		
		'create dummy window/context
		Local _sdlWindow:=SDL_CreateWindow( "<dummy>",0,0,0,0,SDL_WINDOW_HIDDEN|SDL_WINDOW_OPENGL )
		Assert( _sdlWindow,"FATAL ERROR: SDL_CreateWindow failed" )

		Local _sdlGLContext:=SDL_GL_CreateContext( _sdlWindow )
		Assert( _sdlGLContext,"FATAL ERROR: SDL_GL_CreateContext failed" )
		
		SDL_GL_MakeCurrent( _sdlWindow,_sdlGLContext )

#Endif
		_defaultFont=_res.OpenFont( "DejaVuSans",16 )
		
		_theme=New Theme
		
		Local themePath:=GetConfig( "initialTheme","default" )
		
		Local themeScale:=Float( GetConfig( "initialThemeScale",1 ) )
		
		_theme.Load( themePath,New Vec2f( themeScale ) )
		
		_theme.ThemeChanged+=Lambda()

			ThemeChanged()
			
			RequestRender()
			
			UpdateWindows()
		End
	End
	
	#rem monkeydoc Fallback font.
	#end
	Property DefaultFont:Font()
	
		Return _defaultFont
	End
	
	#rem monkeydoc The current theme.
	#end
	Property Theme:Theme()
	
		Return _theme
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
		
		Local str:=String.FromCString( p )

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
	
		If Not _active Return Null
	
		If IsActive( _keyView ) Return _keyView
		
		If _modalView Return _modalView
		
		Return _activeWindow
		
	Setter( keyView:View )
	
		_keyView=keyView
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
	
	#rem monkeydoc True if app is active.
	
	An app is active if any of its windows has system input focus.
	
	#end
	Property Active:Bool()
	
		Return _active
	End

	#rem monkeydoc The currently active window.
	
	The active window is the window that has system input focus.
	
	#end
	Property ActiveWindow:Window()
	
		If Not _activeWindow
			Local windows:=Window.VisibleWindows()
			If windows _activeWindow=windows[0]
		Endif
	
		Return _activeWindow
	End
	
	#rem monkeydoc Mouse location relative to the active window.
	
	@see [[ActiveWindow]], [[MouseX]], [[MouseY]]
	
	#end	
	Property MouseLocation:Vec2i()

		Return _mouseLocation
	End
	
	Property ModalView:View()
	
		Return _modalView
	End
	
	#rem monkeydoc Approximate frames per second rendering rate.
	#end
	Property FPS:Float()

		Return _fps
	End
	
	#rem monkeydoc Number of milliseconds app has been running.
	
	Deprecated! Just use std.time.Millisecs()
	
	#end
	Property Millisecs:Int()
	
		Return std.time.Millisecs()
	End
	
#If __TARGET__<>"emscripten"

	Method Sleep( seconds:Double )
	
		Local timeout:=Now()+seconds
		
		Repeat
			Local sleep:=timeout-Now()
			If sleep>10
				time.Sleep( sleep )
				UpdateWindows()
			Else If sleep>0
				time.Sleep( sleep )
			Else
				Return
			Endif
		Forever
	
	End

#endif
	
#If __DESKTOP_TARGET__
	
	#rem monkeydoc @hidden
	#end
	Method WaitIdle()
		Local future:=New Future<Bool>
		
		Idle+=Lambda()
			future.Set( True )
		End
		
		future.Get()
	End
	
#Endif
	
	#rem monkeydoc @hidden
	#end
	Method GetConfig:String( name:String,defValue:String )
		If _config.Contains( name ) Return _config[name]
		Return defValue
	End

	#rem monkeydoc @hidden
	#end
	Method GetDisplayModes:DisplayMode[]()
	
		Local n:=SDL_GetNumDisplayModes( 0 )
		Local modes:=New DisplayMode[n]
		For Local i:=0 Until n
			Local mode:SDL_DisplayMode
			SDL_GetDisplayMode( 0,i,Varptr mode )
			modes[i].width=mode.w
			modes[i].height=mode.h
			modes[i].hertz=mode.refresh_rate
		Next

		Return modes
	End
	
	#rem monkeydoc @hidden
	#end
	Method BeginModal( view:View )
	
		_modalStack.Push( _modalView )
		
		_modalView=view
		
		RequestRender()
	End
	
	#rem monkeydoc @hidden
	#end
	Method EndModal()
	
		_modalView=_modalStack.Pop()
		
		RequestRender()
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
		
		UpdateWindows()
	End
	
	#rem @hiddden
	#end
	Method IsActive:Bool( view:View )
	
		Return view And view.Active And (Not _modalView Or view.IsChildOf( _modalView ))
	End
	
	#rem @hiddden
	#end
	Method ActiveViewAtMouseLocation:View()
	
		If Not _window Return Null
		
		Local view:=_window.FindViewAtWindowPoint( _mouseLocation )
		If IsActive( view ) Return view
		
		Return Null
	End

	#rem @hidden
	#end	
	Method UpdateWindows()
	
		Local render:=_requestRender
		_requestRender=False
		
		If render UpdateFPS()
		
		For Local window:=Eachin Window.VisibleWindows()
			window.UpdateWindow( render )
		End

		If _mouseView And Not IsActive( _mouseView )
			SendMouseEvent( EventType.MouseUp,_mouseView )
			_mouseView=Null
		Endif
		
		If _hoverView And Not IsActive( _hoverView )
			SendMouseEvent( EventType.MouseLeave,_hoverView )
			_hoverView=Null
		Endif
		
		If Not _hoverView And Not _touchMouse
			_hoverView=ActiveViewAtMouseLocation()
			If _mouseView And _hoverView<>_mouseView _hoverView=Null
			If _hoverView SendMouseEvent( EventType.MouseEnter,_hoverView )
		Endif
		
	End
	
	#rem monkeydoc @hidden
	#end
	Function EmscriptenMainLoop()

		App._requestRender=True
		
		App.MainLoop()
	End
	
	#rem monkeydoc Run the app.
	#end
	Method Run()
	
#if __DESKTOP_TARGET__ 
	
		SDL_AddEventWatch( _EventFilter,Null )

#endif
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
	
	Field _config:StringMap<String>

	Field _touchMouse:Bool=False		'Whether mouse is really touch
	Field _captureMouse:Bool=False		'Whether to use SDL_CaptureMouse
	
	Field _res:=New ResourceManager
	Field _defaultFont:Font
	Field _theme:Theme

	Field _active:Bool
	Field _activeWindow:Window
	
	Field _keyView:View
	Field _hoverView:View
	Field _mouseView:View
	
	Field _requestRender:Bool
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
	Field _mouseClicks:Int=0
	
	Field _modalView:View
	Field _modalStack:=New Stack<View>
	
	Field _polling:Bool
	
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
		
		Mouse.Update()
		
		Keyboard.Update()
		
		While SDL_PollEvent( Varptr event )
		
			Keyboard.SendEvent( Varptr event )
			
			DispatchEvent( Varptr event )
			
		Wend
		
		_polling=False
		
		Local idle:=Idle
		Idle=Null
		idle()
		
	End
	
	Method SendKeyEvent( type:EventType )
	
		Local view:=KeyView
		
		Local event:=New KeyEvent( type,view,_key,_rawKey,_modifiers,_keyChar )
		
		KeyEventFilter( event )
		
		If event.Eaten Return
		
		If view view.SendKeyEvent( event )
	End
	
	Method SendMouseEvent( type:EventType,view:View )
	
		Local location:=view.TransformWindowPointToView( _mouseLocation )
		
		Local event:=New MouseEvent( type,view,location,_mouseButton,_mouseWheel,_modifiers,_mouseClicks )
		
		MouseEventFilter( event )
		
		If event.Eaten Return
		
		view.SendMouseEvent( event )
		
		If event.Eaten Return
		
		Select type
		Case EventType.MouseDown
		
			Select _mouseButton
			Case MouseButton.Left
			
				SendMouseEvent( EventType.MouseClick,view )
				
				If _mouseClicks And Not (_mouseClicks & 1)
				
					SendMouseEvent( EventType.MouseDoubleClick,view )
					
				End
			
			Case MouseButton.Right

				SendMouseEvent( EventType.MouseRightClick,view )
			End
		End
		
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
			
			_keyChar=String.FromCString( tevent->text )
			
			SendKeyEvent( EventType.KeyChar )
			
		Case SDL_MOUSEBUTTONDOWN
		
			Local mevent:=Cast<SDL_MouseButtonEvent Ptr>( event )
			
			_window=Window.WindowForID( mevent->windowID )
			If Not _window Return
			
			_mouseLocation=_window.MouseScale * New Vec2i( mevent->x,mevent->y )
			_mouseButton=Cast<MouseButton>( mevent->button )
			
			If Not _mouseView
			
				Local mouseView:=ActiveViewAtMouseLocation()
				
				If mouseView

					If _touchMouse
					
						_hoverView=mouseView
						
						SendMouseEvent( EventType.MouseEnter,_hoverView )
					
					Endif
				
					If _captureMouse SDL_CaptureMouse( SDL_TRUE )
					
					_mouseView=mouseView
					
					_mouseClicks=mevent->clicks
					
					SendMouseEvent( EventType.MouseDown,_mouseView )
					
					_mouseClicks=0

				Endif
				
			Endif
		
		Case SDL_MOUSEBUTTONUP
		
			Local mevent:=Cast<SDL_MouseButtonEvent Ptr>( event )
			
			_window=Window.WindowForID( mevent->windowID )
			If Not _window Return
			
			_mouseLocation=_window.MouseScale * New Vec2i( mevent->x,mevent->y )
			_mouseButton=Cast<MouseButton>( mevent->button )
			
			If _mouseView

				If _captureMouse SDL_CaptureMouse( SDL_FALSE )

				SendMouseEvent( EventType.MouseUp,_mouseView )

				_mouseButton=Null
				
				_mouseView=Null
				
				If _touchMouse
					
					SendMouseEvent( EventType.MouseLeave,_hoverView )
				
					_hoverView=Null

				Endif

			Endif
			
		Case SDL_MOUSEMOTION
		
			Local mevent:=Cast<SDL_MouseMotionEvent Ptr>( event )
				
			_window=Window.WindowForID( mevent->windowID )
			If Not _window Return
				
			_mouseLocation=_window.MouseScale * New Vec2i( mevent->x,mevent->y )
			
			If Not _touchMouse
			
				Local hoverView:=ActiveViewAtMouseLocation()
				If _mouseView And hoverView<>_mouseView hoverView=Null
	
				If hoverView<>_hoverView
	
					If _hoverView SendMouseEvent( EventType.MouseLeave,_hoverView )
						
					_hoverView=hoverView
						
					If _hoverView SendMouseEvent( EventType.MouseEnter,_hoverView )
				
				Endif
				
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
			
			Case SDL_WINDOWEVENT_SIZE_CHANGED
			
			Case SDL_WINDOWEVENT_FOCUS_GAINED
			
				Print "SDL_WINDOWEVENT_FOCUS_GAINED"
			
				Local active:=_active
				_activeWindow=_window
				_active=True
				
				SendWindowEvent( EventType.WindowGainedFocus )
				
				If active<>_active Activated()
				
			Case SDL_WINDOWEVENT_FOCUS_LOST
			
				Print "SDL_WINDOWEVENT_FOCUS_LOST"
			
				Local active:=_active
'				_activeWindow=Null		'Not a great idea!
				_active=False
			
				If _mouseView And Not _captureMouse	'should probably do this anyway?
					SendMouseEvent( EventType.MouseUp,_mouseView )
					_mouseView=Null
				Endif

				If _hoverView
					SendMouseEvent( EventType.MouseLeave,_hoverView )
					_hoverView=Null
				Endif
			
				SendWindowEvent( EventType.WindowLostFocus )
				
				If active<>_active Deactivated()
				
			Case SDL_WINDOWEVENT_LEAVE
			
				If _mouseView And Not _captureMouse
					SendMouseEvent( EventType.MouseUp,_mouseView )
					_mouseView=Null
				Endif
			
				If _hoverView
					SendMouseEvent( EventType.MouseLeave,_hoverView )
					_hoverView=Null
				Endif
				
			End
			
		Case SDL_USEREVENT
		
			Local uevent:=Cast<SDL_UserEvent Ptr>( event )
			
			Local event:=Cast<AsyncEvent Ptr>( uevent->data1 )
			
			event->Dispatch()

		Case SDL_RENDER_TARGETS_RESET
		
			Print "SDL_RENDER_TARGETS_RESET"
		
			RequestRender()
			
		Case SDL_RENDER_DEVICE_RESET
		
			Print "SDL_RENDER_DEVICE_RESET"
		
			mojo.graphics.glutil.glGraphicsSeq+=1

		Case SDL_WINDOWEVENT_MOVED
			
			SendWindowEvent( EventType.WindowMoved )
					
		Case SDL_WINDOWEVENT_RESIZED
		
			SendWindowEvent( EventType.WindowResized )
				
			UpdateWindows()
			
		Case SDL_WINDOWEVENT_EXPOSED
		
			RequestRender()

		Case SDL_DROPFILE
		
			Local devent:=Cast<SDL_DropEvent Ptr>( event )
			
			Local path:=String.FromCString( devent->file ).Replace( "\","/" )
			
			SDL_free( devent->file )
			
			FileDropped( path )

		End
			
	End
	
	Function _EventFilter:Int( userData:Void Ptr,event:SDL_Event Ptr )
	
		Return App.EventFilter( userData,event )
	End
	
	Method EventFilter:Int( userData:Void Ptr,event:SDL_Event Ptr )
	
		Select event[0].type
		Case SDL_WINDOWEVENT

			Local wevent:=Cast<SDL_WindowEvent Ptr>( event )
			
			_window=Window.WindowForID( wevent->windowID )
			If Not _window Return 1
			
			Select wevent->event
			
			Case SDL_WINDOWEVENT_MOVED
			
				SendWindowEvent( EventType.WindowMoved )
			
				Return 0
					
			Case SDL_WINDOWEVENT_RESIZED
			
				SendWindowEvent( EventType.WindowResized )
				
				UpdateWindows()
			
				Return 0
				
			End

#if __TARGET__="ios"

		Case SDL_APP_TERMINATING
			'Terminate the app.
			'Shut everything down before returning from this function.		
			return 0
		Case SDL_APP_LOWMEMORY
			'You will get this when your app is paused and iOS wants more memory.
			'Release as much memory as possible.		
	        return 0
		Case SDL_APP_WILLENTERBACKGROUND
			'Prepare your app to go into the background. Stop loops, etc.
			'This gets called when the user hits the home button, or gets a call.
	        return 0
		Case SDL_APP_DIDENTERBACKGROUND
			'This will get called if the user accepted whatever sent your app to the background.
			'If the user got a phone call and canceled it, you'll instead get an SDL_APP_DIDENTERFOREGROUND event and restart your loops.
			'When you get this, you have 5 seconds to save all your state or the app will be terminated.
			'Your app is NOT active at this point.
	        return 0
		Case SDL_APP_WILLENTERFOREGROUND
			'This call happens when your app is coming back to the foreground.
			'Restore all your state here.
	        return 0
		Case SDL_APP_DIDENTERFOREGROUND
			'Restart your loops here.
			'Your app is interactive and getting CPU again.
	        return 0

#Endif
	        
		End
		
		Return 1
	End
	
End
