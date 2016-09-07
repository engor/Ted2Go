
#ifndef BB_PLATFORM_H
#define BB_PLATFORM_H

#ifdef _WIN32

	#define BB_WINDOWS 1

   #ifdef _WIN64
   
   #endif
   
#elif __APPLE__

    #include "TargetConditionals.h"
    
    #if TARGET_IPHONE_SIMULATOR
    
    #elif TARGET_OS_IPHONE
    
    	#define BB_IOS 1
    	
    #elif TARGET_OS_MAC
    
        #define BB_MACOS 1
        
    #else
    
    	#error "Unknown Apple platform"
    
    #endif
    
#elif __EMSCRIPTEN__

	#define BB_EMSCRIPTEN 1
	    
#elif __ANDROID__

	#define BB_ANDROID 1
	
#elif __linux__

	#define BB_LINUX 1

/*	
#elif __unix__ // all unices not caught above

    // Unix
    
#elif defined(_POSIX_VERSION)

    // POSIX
*/
    
#else

	#error "Unknown compiler"

#endif

#endif
