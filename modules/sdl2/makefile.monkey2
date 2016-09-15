
Namespace sdl2

#If __TARGET__="windows"

	#Import "makefile_windows.monkey2"
		
#Else If __TARGET__="macos"
	
	#Import "makefile_macos.monkey2"
		
#Else If __TARGET__="linux"
	
	#Import "makefile_linux.monkey2"
	
#Else If __TARGET__="raspbian"

	#Import "makefile_raspbian.monkey2"

#Else If __TARGET__="emscripten"

	#Import "makefile_emscripten.monkey2"
	
#Else If __TARGET__="android"

	#Import "makefile_android.monkey2"
	
#Else If __TARGET__="ios"

	#Import "makefile_ios.monkey2"

#Endif
