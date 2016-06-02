	
Namespace mojo.app

#rem monkeydoc Window creation flags.

| WindowFlags	| Description
|:--------------|:-----------
| CenterX		| Center window horizontally.
| CenterY		| Center window vertically.
| Center		| Center window.
| Hidden		| Window is initally hidden.
| Resizable		| Window is resizable.
| Fullscreen	| Window is a fullscreen window.

#end
Enum WindowFlags
	CenterX=1
	CenterY=2
	Hidden=4
	Resizable=8
	Borderless=16
	Fullscreen=32
	Center=CenterX|CenterY
End

Class Window Extends View

	Method New()
		Init( "Window",New Recti( 0,0,640,480 ),WindowFlags.Center )
	End
	
	Method New( title:String="Window",width:Int=640,height:Int=480,flags:WindowFlags=Null )
		Init( title,New Recti( 0,0,width,height ),flags|WindowFlags.Center )
	End

	Method New( title:String,rect:Recti,flags:WindowFlags=Null )
		Init( title,rect,flags )
	End
	
	#rem monkeydoc Window title.
	#end
	Property Title:String()
	
		Return String.FromUtf8String( SDL_GetWindowTitle( _sdlWindow ) )
	
	Setter( title:String )
	
		SDL_SetWindowTitle( _sdlWindow,title )
	End
	
	#rem monkeydoc Window clear color.
	#end
	Property ClearColor:Color()

		Return _clearColor

	Setter( clearColor:Color )

		_clearColor=clearColor
	End
	
	#rem monkeydoc Window swap interval
	#end
	Property SwapInterval:Int()
	
		Return _swapInterval
	
	Setter( swapInterval:Int )
	
		_swapInterval=swapInterval
	End
	
	#rem monkeydoc @hidden
	#end
	Method Update()

#If __TARGET__="emscripten"

		'ugly...fixme.
		Local w:Int,h:Int,fs:Int
		emscripten_get_canvas_size( Varptr w,Varptr h,Varptr fs )
		If w<>Frame.Width Or h<>Frame.Height
			Frame=New Recti( 0,0,w,h )
		Endif
	
#Else
		'ugly...fixme.
		If MinSize<>_minSize
			SDL_SetWindowMinimumSize( _sdlWindow,MinSize.x,MinSize.y )
			_minSize=GetMinSize()
			MinSize=_minSize
		Endif
		
		If MaxSize<>_maxSize 
			SDL_SetWindowMaximumSize( _sdlWindow,MaxSize.x,MaxSize.y )
			_maxSize=GetMaxSize()
			MaxSize=_maxSize
		Endif
		
		If Frame<>_frame
			SDL_SetWindowPosition( _sdlWindow,Frame.X,Frame.Y )
			SDL_SetWindowSize( _sdlWindow,Frame.Width,Frame.Height )
			_frame=GetFrame()
			Frame=_frame
		Endif
		
#Endif

		Measure()
		
		UpdateLayout()
	End
	
	#rem monkeydoc @hidden
	#end
	Method Render()
	
		SDL_GL_MakeCurrent( _sdlWindow,_sdlGLContext )

		SDL_GL_SetSwapInterval( _swapInterval )
		
		Local bounds:=New Recti( 0,0,Frame.Size )
		
		_canvas.Resize( bounds.Size )
		
		_canvas.BeginRender( bounds,New AffineMat3f )
		
		_canvas.Clear( _clearColor )
		
		Render( _canvas )
		
		_canvas.EndRender()
		
		SDL_GL_SwapWindow( _sdlWindow )
	End
	
	#rem monkeydoc @hidden
	#end
	Method FindWindow:Window() Override
	
		Return Self
	End
	
	#rem monkeydoc @hidden
	#end
	Property NativeWindow:SDL_Window Ptr()
	
		Return _sdlWindow
	End
	
	#rem monkeydoc @hidden
	#end
	Function AllWindows:Window[]()
	
		Return _allWindows.ToArray()
	End

	#rem monkeydoc @hidden
	#end
	Function VisibleWindows:Window[]()
	
		Return _visibleWindows.ToArray()
	End
	
	#rem monkeydoc @hidden
	#end
	Function WindowForID:Window( id:UInt )
	
		Return _windowsByID[id]
	End

	'***** INTERNAL *****
	
	#rem monkeydoc @hidden
	#end
	Method SendWindowEvent( event:WindowEvent )
	
		Select event.Type
		Case EventType.WindowMoved,EventType.WindowResized
			_frame=GetFrame()
			Frame=_frame
		End
		
		OnWindowEvent( event )
	End
	
	#rem monkeydoc @hidden
	#end
	Property KeyView:View()
	
		Return _keyView
		
	Setter( keyView:View )
	
		_keyView=keyView
	End
	
	Protected
	
	#rem monkeydoc Window event handler.
	
	Called when the window is sent a window event.
	
	#end
	Method OnWindowEvent( event:WindowEvent ) Virtual
	
		Select event.Type
		Case EventType.WindowClose
		
			App.Terminate()
			
		Case EventType.WindowMoved
		
		Case EventType.WindowResized
		
			App.RequestRender()
			
		Case EventType.WindowGainedFocus
		
		Case EventType.WindowLostFocus
		
		End
		
	End
	
	Private
	
	Field _sdlWindow:SDL_Window Ptr
	Field _sdlGLContext:SDL_GLContext
	Field _swapInterval:Int=1
	
	Field _canvas:Canvas

	Field _clearColor:=Color.Grey
	Field _keyView:View
	
	Field _minSize:Vec2i
	Field _maxSize:Vec2i
	Field _frame:Recti
	
	Global _allWindows:=New Stack<Window>
	Global _visibleWindows:=New Stack<Window>
	Global _windowsByID:=New Map<UInt,Window>
	
	Method GetMinSize:Vec2i()
		Local w:Int,h:Int
		SDL_GetWindowMinimumSize( _sdlWindow,Varptr w,Varptr h )
		Return New Vec2i( w,h )
	End
	
	Method GetMaxSize:Vec2i()
		Local w:Int,h:Int
		SDL_GetWindowMaximumSize( _sdlWindow,Varptr w,Varptr h )
		Return New Vec2i( w,h )
	End
	
	Method GetFrame:Recti()
		Local x:Int,y:Int,w:Int,h:Int
		SDL_GetWindowPosition( _sdlWindow,Varptr x,Varptr y )
		SDL_GetWindowSize( _sdlWindow,Varptr w,Varptr h )
		Return New Recti( x,y,x+w,y+h )
	End
	
	Method Init( title:String,rect:Recti,flags:WindowFlags )
	
		Layout="fill"
	
		Local x:=(flags & WindowFlags.CenterX) ? SDL_WINDOWPOS_CENTERED Else rect.X
		Local y:=(flags & WindowFlags.CenterY) ? SDL_WINDOWPOS_CENTERED Else rect.Y
		
		Local sdlFlags:SDL_WindowFlags=SDL_WINDOW_OPENGL
		
		If flags & WindowFlags.Hidden sdlFlags|=SDL_WINDOW_HIDDEN
		If flags & WindowFlags.Resizable sdlFlags|=SDL_WINDOW_RESIZABLE
		If flags & WindowFlags.Borderless sdlFlags|=SDL_WINDOW_BORDERLESS
		If flags & WindowFlags.Fullscreen sdlFlags|=SDL_WINDOW_FULLSCREEN
	
		_sdlWindow=SDL_CreateWindow( title,x,y,rect.Width,rect.Height,sdlFlags )
		Assert( _sdlWindow,"Failed to create SDL_Window" )

		_allWindows.Push( Self )
		_windowsByID[SDL_GetWindowID( _sdlWindow )]=Self
		If Not (flags & WindowFlags.Hidden) _visibleWindows.Push( Self )
		
		_minSize=GetMinSize()
		MinSize=_minSize
		
		_maxSize=GetMaxSize()
		MaxSize=_maxSize
		
		_frame=GetFrame()
		Frame=_frame
		
		'Create GLContext and canvas
		
		_sdlGLContext=SDL_GL_CreateContext( _sdlWindow )
		SDL_GL_MakeCurrent( _sdlWindow,_sdlGLContext )
		
		_canvas=New Canvas( _frame.Width,_frame.Height )
		
		Update()
	End
End
