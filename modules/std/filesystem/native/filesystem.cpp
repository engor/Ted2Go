
#include "filesystem.h"

#if _WIN32

#include <windows.h>
	
#elif __APPLE__

#include <mach-o/dyld.h>
#include <sys/syslimits.h>

#include <limits.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <copyfile.h>
	
#elif __linux

#include <limits.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
	
#else

#include <limits.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#endif

namespace bbFileSystem{

	bbString _appDir;
	bbString _appPath;
	bbArray<bbString> *_appArgs;
	
	struct GCRoot : public bbGCRoot{
		void gcMark(){
			bbGCMark( _appArgs );
		}
	};

	GCRoot root;

	void init(){
	
		static bool done;
		if( done ) return;
		done=true;
		
		_appArgs=bbArray<bbString>::create( bb_argc );
		
		for( int i=0;i<bb_argc;++i ) _appArgs->at(i)=bbString( bb_argv[i] );
		
		#if _WIN32
	
			WCHAR buf[MAX_PATH];
			GetModuleFileNameW( GetModuleHandleW(0),buf,MAX_PATH );
			buf[MAX_PATH-1]=0;
	
			for( WCHAR *p=buf;*p;++p ) if( *p=='\\' ) *p='/';
	
			_appPath=bbString( buf );
		
		#elif __APPLE__
	
			char buf[PATH_MAX];
			uint32_t size=sizeof( buf );
			_NSGetExecutablePath( buf,&size );
			buf[PATH_MAX-1]=0;
			
			_appPath=bbString( buf );
		
		#elif __linux
	
			pid_t pid=getpid();
			char lnk[PATH_MAX];
			char buf[PATH_MAX];
	
			sprintf( lnk,"/proc/%i/exe",pid );
			int i=readlink( lnk,buf,PATH_MAX )
			;
			if( i>0 && i<PATH_MAX ){
				buf[i]=0;
				_appPath=bbString( buf );
			}
			
		#else
	
			_appPath="/";
	
		#endif

		int e=_appPath.findLast( "/" );
		
		if( e!=-1 ){
			_appDir=_appPath.slice( 0,e+1 );
		}else{
			_appDir=_appPath;
		}
	}

	bbString appDir(){
		init();
		return _appDir;
	}
	
	bbString appPath(){
		init();
		return _appPath;
	}
	
	bbArray<bbString> *appArgs(){
		init();
		return _appArgs;
	}
	
	bbBool copyFile( bbString srcPath,bbString dstPath ){
	
#if _WIN32

		return CopyFileA( bbTString( srcPath ),bbTString( dstPath ),FALSE );
		
#elif __APPLE__

		int ret=copyfile( bbTString( srcPath ),bbTString( dstPath ),0,COPYFILE_ALL );
		
		if( ret>=0 ) return true;
		
//		printf( "copyfile failed, ret=%i\n",ret );
//		printf( "src=%s\n",srcPath.c_str() );
//		printf( "dst=%s\n",dstPath.c_str() );

		return false;
	
#else
		//TODO: use sendfile() here?
		//
		int err=-1;
		if( FILE *srcp=fopen( bbTString( srcPath ),"rb" ) ){
			err=-2;
			if( FILE *dstp=fopen( bbTString( dstPath ),"wb" ) ){
				err=0;
				char buf[1024];
				while( int n=fread( buf,1,1024,srcp ) ){
					if( fwrite( buf,1,n,dstp )!=n ){
						err=-3;
						break;
					}
				}
				fclose( dstp );
			}else{
//				printf( "FOPEN 'wb' for CopyFile(%s,%s) failed\n",C_STR(srcpath),C_STR(dstpath) );
				fflush( stdout );
			}
			fclose( srcp );
		}else{
//			printf( "FOPEN 'rb' for CopyFile(%s,%s) failed\n",C_STR(srcpath),C_STR(dstpath) );
			fflush( stdout );
		}
		return err==0;
#endif
	}
	
}
