
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

	#rem monkeydoc @hidden
	#end
	Field WindowClose:Void()
	
	#rem monkeydoc @hidden
	#end
	Field WindowMoved:Void()
	
	#rem monkeydoc @hidden
	#end
	Field WindowResized:Void()
	
	Method New()
		Init( "Window",New Recti( 0,0,640,480 ),WindowFlags.Center )
	End
	
	Method New( title:String="Window",width:Int=640,height:Int=480,flags:WindowFlags=Null )
		Init( title,New Recti( 0,0,width,height ),flags|WindowFlags.Center )
	End

	Method New( title:String,rect:Recti,flags:WindowFlags=Null )
		Init( title,rect,flags )
	End
	
	#rem monkeydoc Window clear color
	
	#end
	Property ClearColor:Color()

		Return _clearColor

	Setter( clearColor:Color )

		_clearColor=clearColor
	End
	
	#rem monkeydoc @hidden
	#end
	Property SwapInterval:Int()
	
		Return _swapInterval
	
	Setter( swapInterval:Int )
	
		_swapInterval=swapInterval
	End
	
	#rem monkeydoc @hidden
	#end
	Method Update()
	
		'ugly...fixme.
#If __TARGET__="emscripten"
		Local w:Int,h:Int,fs:Int
		emscripten_get_canvas_size( Varptr w,Varptr h,Varptr fs )
		If w<>Frame.Width Or h<>Frame.Height Frame=New Recti( 0,0,w,h )
#Endif

		'ugly...fixme.
		If MinSize<>_minSize Or MaxSize<>_maxSize Or Frame<>_frame
			_minSize=MinSize
			_maxSize=MaxSize
			_frame=Frame
			SDL_SetWindowMinimumSize( _sdlWindow,_minSize.x,_minSize.y )
			SDL_SetWindowMinimumSize( _sdlWindow,_maxSize.x,_maxSize.y )
			SDL_SetWindowPosition( _sdlWindow,_frame.X,_frame.Y )
			SDL_SetWindowSize( _sdlWindow,_frame.Width,_frame.Height )
		Endif
		
		Measure()
		
		UpdateLayout()
	End
	
	#rem monkeydoc @hidden
	#end
	Method Render()
	
		SDL_GL_MakeCurrent( _sdlWindow,_sdlGLContext )

'		Causes a warning in SDL2 on windows...
'		
		SDL_GL_SetSwapInterval( _swapInterval )
		
		Local viewport:=New Recti( 0,0,Frame.Size )
		
		_canvas.Resize( viewport.Size )
		
'		_canvas.BeginRender()
		
		_canvas.RenderColor=Color.White
		_canvas.RenderMatrix=New AffineMat3f
		_canvas.RenderBounds=viewport
		
		_canvas.Viewport=viewport
		_canvas.Scissor=New Recti( 0,0,16384,16384 )
		_canvas.ViewMatrix=New Mat4f
		_canvas.ModelMatrix=New Mat4f

		_canvas.BlendMode=BlendMode.Alpha
		_canvas.Color=Color.White
		_canvas.Font=Null
		_canvas.Matrix=New AffineMat3f
		
		_canvas.Clear( _clearColor )
		
		Render( _canvas )

		_canvas.Flush()
		
'		_canvas.EndRender()
		
		SDL_GL_SwapWindow( _sdlWindow )
	End
	
	#rem monkeydoc @hidden
	#end
	Method SendWindowEvent( event:WindowEvent )
	
		OnWindowEvent( event )
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
	Property KeyView:View()
	
		Return _keyView
		
	Setter( keyView:View )
	
		_keyView=keyView
	End
	
	Protected
	
	Method OnValidateStyle() Override
	
		SDL_SetWindowMinimumSize( _sdlWindow,MinSize.x,MinSize.y )
		SDL_SetWindowMaximumSize( _sdlWindow,MaxSize.x,MaxSize.y )
	
	End
	
	#rem monkeydoc Window event handler.
	
	Called when the window is sent a window event.
	
	#end
	Method OnWindowEvent( event:WindowEvent ) Virtual
	
		Select event.Type
		Case EventType.WindowClose
			WindowClose()
		Case EventType.WindowMoved
			Frame=event.Rect
			WindowMoved()
		Case EventType.WindowResized
			Frame=event.Rect
'			Frame=New Recti( 0,0,event.Rect.Size )
			App.RequestRender()
			WindowResized()
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
		If Not (flags & WindowFlags.Hidden) _visibleWindows.Push( Self )
		_windowsByID[SDL_GetWindowID( _sdlWindow )]=Self
		
		Local tx:Int,ty:Int,tw:Int,th:Int
		SDL_GetWindowMinimumSize( _sdlWindow,Varptr tw,Varptr th )
		_minSize=New Vec2i( tw,th )

		SDL_GetWindowMaximumSize( _sdlWindow,Varptr tw,Varptr th )
		_maxSize=New Vec2i( tw,th )
		
		SDL_GetWindowPosition( _sdlWindow,Varptr tx,Varptr ty )
		SDL_GetWindowSize( _sdlWindow,Varptr tw,Varptr th )
		_frame=New Recti( tx,ty,tx+tw,ty+th )
		
		MinSize=_minSize
		MaxSize=_maxSize
		Frame=_frame
		
		WindowClose=App.Terminate
		
		'Create GLContext and canvas
		
		_sdlGLContext=SDL_GL_CreateContext( _sdlWindow )
		
		SDL_GL_MakeCurrent( _sdlWindow,_sdlGLContext )
		
		_canvas=New Canvas( rect.Width,rect.Height )
	End
End
