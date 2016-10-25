
#include "socket.h"

#include "../../async/native/async.h"
#include "../../fiber/native/fiber.h"

#if _WIN32

#include <Ws2tcpip.h>

typedef int socklen_t;

#else

#include <netdb.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>

#define closesocket close
#define ioctlsocket ioctl

#endif

namespace bbSocket{

	struct Future : public bbAsync::Event{
		
		int fiber;
		int result=-1;
				
		Future():fiber( bbFiber::getCurrentFiber() ){}
				
		void dispatch(){
				
			bbFiber::resumeFiber( fiber );
		}
		
		void set( int result ){
		
			this->result=result;
			
			post();
		}
		
		int get(){
		
			bbFiber::suspendCurrentFiber();
			
			return result;
		}
	};
	
	int err(){
#if _WIN32	
		return WSAGetLastError();
#else
		return errno;
#endif
	}
		
	void init(){
		static bool done;
		if( done ) return;
		done=true;
#if _WIN32	
		WSADATA wsa;
		WSAStartup( MAKEWORD(2,2),&wsa );
#endif
	}

	void dontBlock( int sock ){
		//make non-blocking
		u_long cmd=1;
		ioctlsocket( sock,FIONBIO,&cmd );
	}
   
	bool wouldBlock(){
#if _WIN32
		return WSAGetLastError()==WSAEWOULDBLOCK;
#else
		return errno==EAGAIN || errno==EWOULDBLOCK;
#endif
	}
	
	int _connect( const char *hostname,const char *service,int type ){
	
		init();
	
		addrinfo hints;
		memset( &hints,0,sizeof( hints ) );

		hints.ai_family=AF_UNSPEC;
		hints.ai_socktype=(type==1) ? SOCK_DGRAM : SOCK_STREAM;

		addrinfo *res=0;
		if( getaddrinfo( hostname,service,&hints,&res ) ) return -1;
		
		addrinfo *pres=res;
		
		int sock=-1;
		
		while( res ){
			
			sock=socket( res->ai_family,res->ai_socktype,res->ai_protocol );

			if( sock>=0 ){
			
				if( !connect( sock,res->ai_addr,res->ai_addrlen ) ) break;
				
				::closesocket( sock );
				sock=-1;
			}

			res=res->ai_next;
		}
		
		freeaddrinfo( pres );
		
		if( sock<0 ){
			 printf( "socket_connect error! err=%i\n",err() );
			 return -1;
		}
		
		return sock;
	}
	
	int _bind( const char *service,int type ){
	
		init();
	
		addrinfo hints;
		memset( &hints,0,sizeof( hints ) );
		
		hints.ai_family=AF_UNSPEC;
		hints.ai_socktype=(type==1) ? SOCK_DGRAM : SOCK_STREAM;
		hints.ai_flags=AI_PASSIVE;
		
		addrinfo *res=0;
		if( getaddrinfo( 0,service,&hints,&res ) ) return -1;
		
		addrinfo *pres=res;
		
		int sock=-1;
		
		while( res ){
		
			sock=socket( res->ai_family,res->ai_socktype,res->ai_protocol );
			
			if( sock>=0 ){
			
				if( !::bind( sock,res->ai_addr,res->ai_addrlen ) ) break;
				
				::closesocket( sock );
				sock=-1;
			}
			
			res=res->ai_next;
		}
		
		freeaddrinfo( pres );
		
		if( sock<0 ){
			 printf( "socket_bind error! err=%i\n",err() );
			 return -1;
		}
		
// So server ports can be quickly reused...
//
#if __APPLE__ || __linux
		int flag=1;
		setsockopt( sock,SOL_SOCKET,SO_REUSEADDR,&flag,sizeof(flag) );
#endif
		return sock;
	}
	
	int _listen( const char *service,int queue,int type ){
	
		init();
	
		addrinfo hints;
		memset( &hints,0,sizeof( hints ) );
		
		hints.ai_family=AF_UNSPEC;
		hints.ai_socktype=(type==1) ? SOCK_DGRAM : SOCK_STREAM;
		hints.ai_flags=AI_PASSIVE;
		
		addrinfo *res=0;
		if( getaddrinfo( 0,service,&hints,&res ) ) return -1;
		
		addrinfo *pres=res;
		
		int sock=-1;
		
		while( res ){
		
			sock=socket( res->ai_family,res->ai_socktype,res->ai_protocol );
			
			if( sock>=0 ){
			
				if( !::bind( sock,res->ai_addr,res->ai_addrlen ) ) break;
				
				::closesocket( sock );
				sock=-1;
			}
			
			res=res->ai_next;
		}
		
		freeaddrinfo( pres );
		
		if( sock<0 ){
			 printf( "socket_listen error! err=%i\n",err() );
			 return -1;
		}
		
// So server ports can be quickly reused...
//
#if __APPLE__ || __linux
		int flag=1;
		setsockopt( sock,SOL_SOCKET,SO_REUSEADDR,&flag,sizeof(flag) );
#endif
		::listen( sock,queue );
		
		return sock;
	}
	
	int connect( bbString hostname,bbString service,int type ){
	
		if( hostname.length()>1023 || service.length()>79 ) return -1;

		char _hostname[1024];
		char _service[80];
		
		strcpy( _hostname,hostname.c_str() );
		strcpy( _service,service.c_str() );
		
		int result=-1;
		
		if( bbFiber::getCurrentFiber() ){

			Future future;
			
			std::thread thread( [=,&future](){

				future.set( _connect( _hostname,_service,type ) );
	
			} );
			
			result=future.get();
			
			thread.join();

		}else{
		
			result=_connect( _hostname,_service,type );
		}
		
		return result;
	}
	
	int bind( bbString service ){
	
		if( service.length()>79 ) return -1;
	
		char _service[80];
		strcpy( _service,service.c_str() );
		
		int result=-1;
		
		if( bbFiber::getCurrentFiber() ){

			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( _bind( _service,1 ) );
	
			} );
			
			result=future.get();
			
			thread.join();
			
		}else{
		
			result=_bind( _service,1 );
		}
		
		return result;
	}
	
	int listen( bbString service,int queue ){
	
		if( service.length()>79 ) return -1;
	
		char _service[80];
		strcpy( _service,service.c_str() );
		
		int result=-1;
		
		if( bbFiber::getCurrentFiber() ){

			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( _listen( _service,queue,0 ) );
	
			} );
			
			result=future.get();
			
			thread.join();
			
		}else{
		
			result=_listen( _service,queue,0 );
		}
		
		return result;
	}
	
	int accept( int socket ){
	
		sockaddr_storage clientaddr;
		socklen_t addrlen=sizeof( clientaddr );
		
		int newsock=-1;
		
		if( bbFiber::getCurrentFiber() ){
		
			Future future;
			
			std::thread thread( [&,socket](){
			
				future.set( ::accept( socket,(sockaddr*)&clientaddr,&addrlen ) );
			} );
			
			newsock=future.get();
			
			thread.join();
		
		}else{
			
			newsock=::accept( socket,(struct sockaddr*)&clientaddr,&addrlen );
		}
		
		return newsock;
	}
	
	void close( int socket ){
	
		if( bbFiber::getCurrentFiber() ){
		
			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( ::closesocket( socket ) );
				
			} );
			
			future.get();
			
			thread.join();
			
		}else{

			::closesocket( socket );
		}
	}
	
	int cansend( int socket ){
		return 0;
	}
	
	int canrecv( int socket ){
#if _WIN32
		u_long count=0;
		if( ioctlsocket( socket,FIONREAD,&count )==SOCKET_ERROR ){
			puts( "ERROR!" );
			count=0;
		}
#else
		int count=0;
		if( ioctl( socket,FIONREAD,&count )<0 ) count=0;
#endif
		return count;
	}
	
	int send( int socket,void *data,int size ){
	
		int n=-1;
		
		if( bbFiber::getCurrentFiber() && cansend( socket )<size ){
			
			Future future;
				
			std::thread thread( [=,&future](){
				
				future.set( ::send( socket,(const char*)data,size,0 ) );
					
			} );
				
			n=future.get();
				
			thread.join();
				
		}else{
	
			n=::send( socket,(const char*)data,size,0 );
		}
			
		if( n<0 ){
			printf( "socket_send error! err=%i, socket=%i, data=%p, size=%i\n",err(),socket,data,size );fflush( stdout );
		}
		
		return n;
	}
	
	int sendto( int socket,void *data,int size,const void *addr,int addrlen ){
	
		int n=-1;
		
		if( bbFiber::getCurrentFiber() && cansend( socket )<size  ){
			
			Future future;
				
			std::thread thread( [=,&future](){
				
				future.set( ::sendto( socket,(const char*)data,size,0,(const sockaddr*)addr,addrlen ) );
					
			} );
				
			n=future.get();
				
			thread.join();
				
		}else{
	
			n=::sendto( socket,(const char*)data,size,0,(const sockaddr*)addr,addrlen );
		}
			
		if( n<0 ){
			printf( "socket_sendto error! err=%i, socket=%i, data=%p, size=%i\n",err(),socket,data,size );fflush( stdout );
		}
		
		return n;
	}
	
	int recv( int socket,void *data,int size ){
	
		int n=-1;
	
		if( bbFiber::getCurrentFiber() && canrecv( socket )<size ){
		
			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( ::recv( socket,(char*)data,size,0 ) );
				
			} );
			
			n=future.get();
			
			thread.join();
			
		}else{

			n=::recv( socket,(char*)data,size,0 );
		}
		
		if( n<0 ){
			printf( "socket_recv error! err=%i, socket=%i, data=%p, size=%i\n",err(),socket,data,size );fflush( stdout );
		}
		
		return n;
	}
	
	int recvfrom( int socket,void *data,int size,void *addr,int *addrlen ){
	
		int n=-1;

		if( bbFiber::getCurrentFiber() && canrecv( socket )<size ){
		
			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( recvfrom( socket,(char*)data,size,0,(sockaddr*)addr,(socklen_t*)addrlen ) );
				
			} );
			
			n=future.get();
			
			thread.join();
			
		}else{

			n=::recvfrom( socket,(char*)data,size,0,(sockaddr*)addr,(socklen_t*)addrlen );
		}
		
		if( n<0 ){
			printf( "socket_recvfrom error! err=%i, socket=%i, data=%p, size=%i\n",err(),socket,data,size );fflush( stdout );
		}

		
		return n;
	}
	
	void setopt( int socket,bbString name,int value ){
	
		const char *ip=(const char*)&value;
		int sz=sizeof( value );
		
		if( name=="TCP_NODELAY" ){
			setsockopt( socket,IPPROTO_TCP,TCP_NODELAY,ip,sz );
		}else if( name=="SO_SNDTIMEO" ){
			setsockopt( socket,SOL_SOCKET,SO_SNDTIMEO,ip,sz );
		}else if( name=="SO_RCVTIMEO" ){
			setsockopt( socket,SOL_SOCKET,SO_RCVTIMEO,ip,sz );
		}
	}
	
	int getopt( int socket,bbString name ){

		int value=-1;
		
		char *ip=(char*)&value;
		int sz=sizeof( value );
		
		if( name=="TCP_NODELAY" ){
			getsockopt( socket,IPPROTO_TCP,TCP_NODELAY,ip,(socklen_t*)&sz );
		}else if( name=="SO_SNDTIMEO" ){
			getsockopt( socket,SOL_SOCKET,SO_SNDTIMEO,ip,(socklen_t*)&sz );
		}else if( name=="SO_RCVTIMEO" ){
			getsockopt( socket,SOL_SOCKET,SO_RCVTIMEO,ip,(socklen_t*)&sz );
		}
		
		return value;
	}
	
	int getsockaddr( int socket,void *addr,int *addrlen ){
	
		return getsockname( socket,(sockaddr*)addr,(socklen_t*)addrlen );
	}
	
	int getpeeraddr( int socket,void *addr,int *addrlen ){
	
		return getpeername( socket,(sockaddr*)addr,(socklen_t*)addrlen );
	}
	
	int sockaddrname( const void *addr,int addrlen,char *host,char *service ){
	
		getnameinfo( (const sockaddr*)addr,addrlen,host,1023,service,79,0 );
	}
	
}