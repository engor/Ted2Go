
#include "process.h"

#ifndef EMSCRIPTEN

#include <thread>
#include <atomic>
#include <mutex>
#include <condition_variable>

#include <SDL.h>

bbInt g_mojox_AppInstance_AddAsyncCallback(bbFunction<void()> l_func);

struct semaphore{

	int count=0;
	std::mutex mutex;
	std::condition_variable cond_var;
	
	void wait(){
		std::unique_lock<std::mutex> lock( mutex );
		while( !count ) cond_var.wait( lock );
		--count;
	}
	
	void signal(){
		std::unique_lock<std::mutex> lock( mutex );
		++count;
		cond_var.notify_one();
	}
};

#if _WIN32

#include <windows.h>
#include <tlhelp32.h>

#else

#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/wait.h>
#include <signal.h>

#endif

namespace{

	const int INVOKE=0x40000000;
	const int REMOVE=0x80000000;

	void postEvent( int code ){
		SDL_UserEvent event;
		event.type=SDL_USEREVENT;
		event.code=code;
		event.data1=0;
		event.data2=0;
		if( SDL_PeepEvents( (SDL_Event*)&event,1,SDL_ADDEVENT,SDL_FIRSTEVENT,SDL_LASTEVENT )!=1 ){
			printf(" SDL_PeepEvents error!\n" );fflush( stdout );
		}
	}
	
#if _WIN32

	void terminateChildren( DWORD procid,HANDLE snapshot,int exitCode ){
	
		PROCESSENTRY32 procinfo;
			
		procinfo.dwSize=sizeof( procinfo );
		
		int gotinfo=Process32First( snapshot,&procinfo );
			
		while( gotinfo ){
		
			if( procinfo.th32ParentProcessID==procid ){
			
//				printf("process=%i parent=%i module=%x path=%s\n",procinfo.th32ProcessID,procinfo.th32ParentProcessID,procinfo.th32ModuleID,procinfo.szExeFile);

				terminateChildren( procinfo.th32ProcessID,snapshot,exitCode );
				 
				HANDLE child=OpenProcess( PROCESS_ALL_ACCESS,0,procinfo.th32ProcessID );
				
				if( child ){
					int res=TerminateProcess( child,exitCode );
					CloseHandle( child );
				}
			}
			
			gotinfo=Process32Next( snapshot,&procinfo );
		}	
	}
	
	int TerminateProcessGroup( HANDLE prochandle,int exitCode ){

		HANDLE snapshot;
		
		int procid=GetProcessId( prochandle );
		
		snapshot=CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS,0 );
		
		if( snapshot!=INVALID_HANDLE_VALUE ){
		
			terminateChildren( GetProcessId( prochandle ),snapshot,exitCode );

			CloseHandle( snapshot );
		}
			
		int res=TerminateProcess( prochandle,exitCode );
		return res;
	}
	
#endif	

#ifndef _WIN32

	char **makeargv( const char *cmd ){
	    int n,c;
	    char *p;
	    static char *args,**argv;
	
	    if( args ) free( args );
	    if( argv ) free( argv );
	    args=(char*)malloc( strlen(cmd)+1 );
	    strcpy( args,cmd );
	
	    n=0;
	    p=args;
	    while( (c=*p++) ){
	        if( c==' ' ){
	            continue;
	        }else if( c=='\"' ){
	            while( *p && *p!='\"' ) ++p;
	        }else{
	            while( *p && *p!=' ' ) ++p;
	        }
	        if( *p ) ++p;
	        ++n;
	    }
	    argv=(char**)malloc( (n+1)*sizeof(char*) );
	    n=0;
	    p=args;
	    while( (c=*p++) ){
	        if( c==' ' ){
	            continue;
	        }else if( c=='\"' ){
	            argv[n]=p;
	            while( *p && *p!='\"' ) ++p;
	        }else{
	            argv[n]=p-1;
	            while( *p && *p!=' ' ) ++p;
	        }
	        if( *p ) *p++=0;
	        ++n;
	    }
	    argv[n]=0;
	    return argv;
	}
	
#endif

}

struct bbProcess::Rep{

	std::atomic_int refs;
	
	semaphore stdoutSema;
	char stdoutBuf[4096];
	char *stdoutGet;
	int stdoutAvail=0;
	bool terminated=false;
	int exit;

#if _WIN32

	HANDLE proc;
	HANDLE in;
	HANDLE out;
	HANDLE err;
	
	Rep( HANDLE proc,HANDLE in,HANDLE out,HANDLE err ):proc( proc ),in( in ),out( out ),err( err ),exit( -1 ),refs( 1 ){
	}
	
	void close(){
		CloseHandle( in );
		CloseHandle( out );
		CloseHandle( err );
	}

#else

	int proc;
	int in;
	int out;
	int err;

	Rep( int proc,int in,int out,int err ):proc( proc ),in( in ),out( out ),err( err ),exit( -1 ),refs( 1 ){
	}
	
	void close(){
		::close( in );
		::close( out );
		::close( err );
	}

#endif
	
	void retain(){
		++refs;
	}
	
	void release(){
		if( --refs ) return;
		
		close();
		
		delete this;
	}
};

bbProcess::bbProcess():_rep( nullptr ){
}

bbProcess::~bbProcess(){

	if( _rep ) _rep->release();
}

bbBool bbProcess::start( bbString cmd ){

	if( _rep ) return false;
	
#if _WIN32

	HANDLE in[2],out[2],err[2];
	SECURITY_ATTRIBUTES sa={sizeof(sa),0,1};
	CreatePipe( &in[0],&in[1],&sa,0 );
	CreatePipe( &out[0],&out[1],&sa,0 );
	CreatePipe( &err[0],&err[1],&sa,0 );

	STARTUPINFOA si={sizeof(si)};
	si.dwFlags=STARTF_USESTDHANDLES|STARTF_USESHOWWINDOW;
	si.hStdInput=in[0];
	si.hStdOutput=out[1];
	si.hStdError=err[1];
	si.wShowWindow=SW_HIDE;

	PROCESS_INFORMATION pi={0};
    
	DWORD flags=CREATE_NEW_PROCESS_GROUP;
    
	int res=CreateProcessA( 0,(LPSTR)cmd.c_str(),0,0,TRUE,flags,0,0,&si,&pi );

	CloseHandle( in[0] );
	CloseHandle( out[1] );
	CloseHandle( err[1] );

	if( !res ){
		CloseHandle( in[1] );
		CloseHandle( out[0] );
		CloseHandle( err[0] );
		return false;
	}

	CloseHandle( pi.hThread );
	
	Rep *rep=new Rep( pi.hProcess,in[1],out[0],err[0] );
    
#else
  
	int in[2],out[2],err[2];

	pipe( in );
	pipe( out );
	pipe( err );

	char **argv=makeargv( bbCString( cmd ) );
	
	bool failed=false;

	int proc=vfork();

	if( !proc ){

#if __linux
		setsid();
#else
		setpgid(0,0);
#endif

		dup2( in[0],0 );
		dup2( out[1],1 );
		dup2( err[1],2 );

		execvp( argv[0],argv );
		
		failed=true;

		_exit( 127 );
	}
	
	if( failed ) proc=-1;

	close( in[0] );
	close( out[1] );
	close( err[1] );

	if( proc==-1 ){
		close( in[1] );
		close( out[0] );
		close( err[0] );
		return false;
	}
  
	Rep *rep=new Rep( proc,in[1],out[0],err[0] );
	
#endif

	//Create finished thread    
    rep->retain();

    int callback=g_mojox_AppInstance_AddAsyncCallback( finished );
    
    std::thread( [=](){
    
		#if _WIN32
		
	    	WaitForSingleObject( rep->proc,INFINITE );
	    	
	    	GetExitCodeProcess( rep->proc,(DWORD*)&rep->exit );
	    		
	    	CloseHandle( rep->proc );
	    	
		#else
		
			int status;
			waitpid( rep->proc,&status,0 );
			
			if( WIFEXITED( status ) ){
				rep->exit=WEXITSTATUS( status );
			}else{
				rep->exit=-1;
			}
			
		#endif
    		
	    	postEvent( callback|INVOKE|REMOVE );
    		
    		rep->release();

	} ).detach();
	
	
	//Create stdoutReady thread
	rep->retain();
	
	int callback2=g_mojox_AppInstance_AddAsyncCallback( stdoutReady );
	
	std::thread( [=](){
	
		for(;;){
		
#if _WIN32		
			DWORD n=0;
			if( !ReadFile( rep->out,rep->stdoutBuf,4096,&n,0 ) ) break;
			if( n<=0 ) break;
#else
			int n=read( rep->out,rep->stdoutBuf,4096 );
			if( n<=0 ) break;
#endif
			rep->stdoutGet=rep->stdoutBuf;
			
			rep->stdoutAvail=n;
			
			postEvent( callback2|INVOKE );
			
			rep->stdoutSema.wait();
			
			if( rep->stdoutAvail ) break;
		}
		
		rep->stdoutAvail=0;
		
		postEvent( callback2|INVOKE|REMOVE );
		
		rep->release();

	} ).detach();
	
	_rep=rep;
    
    return true;
}

int bbProcess::exitCode(){

	if( !_rep ) return -1;

	return _rep->exit;
}

bbInt bbProcess::stdoutAvail(){

	if( !_rep ) return 0;

	return _rep->stdoutAvail;
}

bbString bbProcess::readStdout(){

	if( !_rep || !_rep->stdoutAvail ) return "";

	bbString str=bbString::fromCString( _rep->stdoutGet,_rep->stdoutAvail );
	
	_rep->stdoutAvail=0;
	
	_rep->stdoutSema.signal();
	
	return str;
}

bbInt bbProcess::readStdout( void *buf,int count ){

	if( !_rep || count<=0 || !_rep->stdoutAvail ) return 0;

	if( count>_rep->stdoutAvail ) count=_rep->stdoutAvail;
	
	memcpy( buf,_rep->stdoutGet,count );
	
	_rep->stdoutGet+=count;

	_rep->stdoutAvail-=count;
	
	if( !_rep->stdoutAvail ) _rep->stdoutSema.signal();
	
	return count;
}

void bbProcess::writeStdin( bbString str ){

	if( !_rep ) return;

#if _WIN32	
	WriteFile( _rep->in,str.c_str(),str.length(),0,0 );
#else
	write( _rep->in,str.c_str(),str.length() );
#endif
}

void bbProcess::sendBreak(){

	if( !_rep ) return;
	
#if _WIN32
	GenerateConsoleCtrlEvent( CTRL_BREAK_EVENT,GetProcessId( _rep->proc ) );
#else
	killpg( _rep->proc,SIGTSTP );
#endif
}

void bbProcess::terminate(){

	if( !_rep ) return;

#if _WIN32
	TerminateProcessGroup( _rep->proc,-1 );
#else
	killpg( _rep->proc,SIGTERM );
#endif
}

#else

//***** Dummy emscripten version *****

struct bbProcess::Rep{
};

void bbProcess::discard(){
}

bbBool bbProcess::start( bbString cmd ){
	return false;
}
	
bbInt bbProcess::exitCode(){
	return -1;
}
	
bbInt bbProcess::stdoutAvail(){
	return 0;
}
	
bbString bbProcess::readStdout(){
	return "";
}

bbInt bbProcess::readStdout( void *buf,bbInt count ){
	return 0;
}

void bbProcess::writeStdin( bbString str ){
}

void bbProcess::sendBreak(){
}

void bbProcess::terminate(){
}

#endif
