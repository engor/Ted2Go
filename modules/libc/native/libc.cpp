
#include "libc.h"

#if _WIN32
#include <windows.h>
#include <bbstring.h>
#endif

void setenv_( const char *name,const char *value,int overwrite ){

#if _WIN32

	if( !overwrite && getenv( name ) ) return;

	bbString tmp=bbString( name )+BB_T( "=" )+bbString( value );
	putenv( tmp.c_str() );

#else
	setenv( name,value,overwrite );
#endif
}

int system_( const char *cmd ){

#if _WIN32

	bool inherit=false;
	DWORD flags=CREATE_NO_WINDOW;
	STARTUPINFOA si={sizeof(si)};
	PROCESS_INFORMATION pi={0};
	
	bbString tmp=BB_T( "cmd /S /C\"" )+BB_T( cmd )+BB_T( "\"" );
	
	if( GetStdHandle( STD_OUTPUT_HANDLE ) ){
	
		inherit=true;
		si.dwFlags=STARTF_USESTDHANDLES;
		si.hStdInput=GetStdHandle( STD_INPUT_HANDLE );
		si.hStdOutput=GetStdHandle( STD_OUTPUT_HANDLE );
		si.hStdError=GetStdHandle( STD_ERROR_HANDLE );
	}
	
	if( !CreateProcessA( 0,(LPSTR)tmp.c_str(),0,0,inherit,flags,0,0,&si,&pi ) ) return -1;

	WaitForSingleObject( pi.hProcess,INFINITE );
	
	int res=GetExitCodeProcess( pi.hProcess,(DWORD*)&res ) ? res : -1;
	
	CloseHandle( pi.hProcess );
	CloseHandle( pi.hThread );

	return res;

#else

	return system( cmd );

#endif

}

int mkdir_( const char *path,int mode ){
#if _WIN32
	return mkdir( path );
#else
	return mkdir( path,0777 );
#endif
}

int gettimeofday_( timeval *tv ){
	return gettimeofday( tv,0 );
}
