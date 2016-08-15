
#import "<libc>"
#import "<sdl2>"
#import "<gles20>"

Namespace sdl2test

Using libc..
Using sdl2..
Using gles20..

Class SdlWindow

	Field sdlWindow:SDL_Window Ptr
	Field sdlGLContext:SDL_GLContext
	
	Method New()
	
		SDL_Init( SDL_INIT_EVERYTHING )
		
		sdlWindow=SDL_CreateWindow( "SDL2 OpenGL Window",SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,640,480,SDL_WINDOW_OPENGL )
		
		sdlGLContext=SDL_GL_CreateContext( sdlWindow )
		
		SDL_GL_MakeCurrent( sdlWindow,sdlGLContext )
	End
	
	Method Run()
	
		Repeat
		
			Local event:SDL_Event
			
			While( SDL_PollEvent( Varptr event ) )
		
				Select event.type
					
				Case SDL_WINDOWEVENT
		
					Local wevent:=Cast<SDL_WindowEvent Ptr>( Varptr event )
			
					Select wevent->event
					
					Case SDL_WINDOWEVENT_CLOSE
					
						exit_( 0 )
					
					End
					
				End

			Wend
			
			OnRender()
			
			SDL_GL_SwapWindow( sdlWindow )
		Forever
		
	End
	
	Method OnRender()
	
		glClearColor( 1,1,0,1 )
		
		glClear( GL_COLOR_BUFFER_BIT )
	End
	
End


Function Main()

	Local window:=New SdlWindow
	
	window.Run()

End
