
Namespace test

#Import "<libc.monkey2>"
#Import "<sdl2.monkey2>"
#Import "<gles20.monkey2>"

Using sdl2
Using gles20

Function Main()

	'Initialize SDL
	'
	SDL_Init( SDL_INIT_EVERYTHING )

	'Create SDL window
	'
	Local window:=SDL_CreateWindow( "GLES20 Window",SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,640,480,SDL_WINDOW_OPENGL )

	'Create an OpenGL context	 and make it current
	'
	Local glContext:=SDL_GL_CreateContext( window )
	SDL_GL_MakeCurrent( window,glContext )
	
	Repeat
	
		Local event:SDL_Event
	
		'Flush event queue
		'	
		While SDL_PollEvent( Varptr event )
		
			'Handle event
			'
			Select event.type
			Case SDL_WINDOWEVENT
			
				Local wevent:=Cast<SDL_WindowEvent Ptr>( Varptr event )
			
				Select wevent[0].event
				Case SDL_WINDOWEVENT_CLOSE
				
					'Just exit on wndow close
					'
					libc.exit_( 0 )
				End
			End
		
		Wend

		'Render something
		'		
		glClearColor( 1,1,0,1 )
		glClear( GL_COLOR_BUFFER_BIT )
		
		'Swap buffers
		'
		SDL_GL_SwapWindow( window )

	Forever

End
