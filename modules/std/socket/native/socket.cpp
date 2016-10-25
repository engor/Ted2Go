
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

		addrinfo *pres=0;
		if( getaddrinfo( hostname,service,&hints,&pres ) ) return -1;
		
		int sock=-1;
		
		for( addrinfo *res=pres;res;res=res->ai_next ){
		
			sock=socket( res->ai_family,res->ai_socktype,res->ai_protocol );

			if( sock==-1 ) continue;
			
			if( !connect( sock,res->ai_addr,res->ai_addrlen ) ) break;
				
			::closesocket( sock );
			sock=-1;
		}
		
		freeaddrinfo( pres );
		
		return sock;
	}
	
	int _bind( const char *hostname,const char *service,int type ){
	
		init();
		
		addrinfo hints;
		memset( &hints,0,sizeof( hints ) );
		
		hints.ai_family=AF_UNSPEC;
		hints.ai_socktype=(type==1) ? SOCK_DGRAM : SOCK_STREAM;
		hints.ai_flags=AI_PASSIVE;
		
		addrinfo *pres=0;
		if( getaddrinfo( hostname,service,&hints,&pres ) ) return -1;
		
		int sock=-1;
		
		for( addrinfo *res=pres;res;res=res->ai_next ){
		
			sock=socket( res->ai_family,res->ai_socktype,res->ai_protocol );

			if( sock==-1 ) continue;

			if( !::bind( sock,res->ai_addr,res->ai_addrlen ) ) break;
				
			::closesocket( sock );
			sock=-1;
		}
		
		freeaddrinfo( pres );

		return sock;
	}
	
	int _listen( const char *hostname,const char *service,int queue,int type ){

		int sock=_bind( hostname,service,type );
			
		if( sock!=-1 ) ::listen( sock,queue );
		
		return sock;
	}
	
	int connect( const char *hostname,const char *service,int type ){

		int sock=-1;
		
		if( bbFiber::getCurrentFiber() ){

			Future future;
			
			std::thread thread( [=,&future](){

				future.set( _connect( hostname,service,type ) );
	
			} );
			
			sock=future.get();
			
			thread.join();

		}else{
		
			sock=_connect( hostname,service,type );
		}
		
		return sock;
	}
	
	int bind( const char *hostname,const char *service ){
	
		int sock=-1;
		
		if( bbFiber::getCurrentFiber() ){

			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( _bind( hostname,service,1 ) );
	
			} );
			
			sock=future.get();

			thread.join();
			
		}else{
		
			sock=_bind( hostname,service,1 );
		}
		
		return sock;
	}
	
	int listen( const char *hostname,const char *service,int queue ){
	
		int sock=-1;
		
		if( bbFiber::getCurrentFiber() ){

			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( _listen( hostname,service,queue,0 ) );
	
			} );
			
			sock=future.get();
			
			thread.join();
			
		}else{
		
			sock=_listen( hostname,service,queue,0 );
		}
		
		return sock;
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
		if( ioctlsocket( socket,FIONREAD,&count )==-1 ) count=0;
#else
		int count=0;
		if( ioctl( socket,FIONREAD,&count )==-1 ) count=0;
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
			
		if( n==-1 ){
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
			
		if( n==-1 ){
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
		
		if( n==-1 ){
			printf( "socket_recv error! err=%i, msg=%s, socket=%i, data=%p, size=%i\n",err(),strerror( err() ),socket,data,size );fflush( stdout );
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
		
		if( n==-1 ){
			printf( "socket_recvfrom error! err=%i, socket=%i, data=%p, size=%i\n",err(),socket,data,size );fflush( stdout );
		}
		
		return n;
	}
	
	void setopt( int socket,bbString name,int value ){
	
		const char *ip=(const char*)&value;
		int sz=sizeof( value );
		
		if( name=="TCP_NODELAY" ){
			setsockopt( socket,IPPROTO_TCP,TCP_NODELAY,ip,sz );
		}else if( name="SO_REUSEADDR" ){
			setsockopt( socket,SOL_SOCKET,SO_REUSEADDR,ip,sz );
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
		}else if( name="SO_REUSEADDR" ){
			getsockopt( socket,SOL_SOCKET,SO_REUSEADDR,ip,(socklen_t*)&sz );
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
	
		return getnameinfo( (const sockaddr*)addr,addrlen,host,1023,service,79,0 );
	}
	
}