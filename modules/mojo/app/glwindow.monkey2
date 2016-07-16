
Namespace mojo.app

Class GLWindow Extends Window

	Method New()
		Init()
	End
	
	Method New( title:String="Window",width:Int=640,height:Int=480,flags:WindowFlags=Null )
		Super.New( title,width,height,flags )
		Init()
	End

	Method New( title:String,rect:Recti,flags:WindowFlags=Null )
		Super.New( title,rect,flags )
		Init()
	End
	
	Method BeginGL()
	
#If __HOSTOS__="macos"
		glFlush()
#Endif		

		SDL_GL_MakeCurrent( SDLWindow,_sdlGLContext )
	End
	
	Method EndGL()

#If __HOSTOS__="macos"
		glFlush()
#Endif		

		SDL_GL_MakeCurrent( Super.SDLWindow,Super.SDLGLContext )
	End
	
	Protected
	
	Method OnRender( canvas:Canvas ) Override
	
		BeginGL()
		
		OnRenderGL()
		
		EndGL()
	End
	
	Method OnRenderGL() Virtual
	
	End
	
	Private
	
	Field _sdlGLContext:SDL_GLContext
	
	Method Init()
		_sdlGLContext=SDL_GL_CreateContext( SDLWindow )
		Assert( _sdlGLContext,"FATAL ERROR: SDL_GL_CreateContext failed" )
	End

End
