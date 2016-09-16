
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
	
	int _connect( const char *hostname,const char *service ){
	
		init();
	
		addrinfo hints;
		memset( &hints,0,sizeof( hints ) );

		hints.ai_family=AF_UNSPEC;
		hints.ai_socktype=SOCK_STREAM;

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
		
		if( sock<0 ) return -1;
		
		return sock;
	}
	
	int _listen( const char *service,int queue ){
	
		init();
	
		addrinfo hints;
		memset( &hints,0,sizeof( hints ) );
		
		hints.ai_family=AF_UNSPEC;
		hints.ai_socktype=SOCK_STREAM;
		hints.ai_flags=AI_PASSIVE;
		
		addrinfo *res=0;
		if( getaddrinfo( 0,service,&hints,&res ) ) return -1;
		
		addrinfo *pres=res;
		
		int sock=-1;
		
		while( res ){
		
			sock=socket( res->ai_family,res->ai_socktype,res->ai_protocol );
			
			if( sock>=0 ){
			
				if( !bind( sock,res->ai_addr,res->ai_addrlen ) ) break;
				
				::closesocket( sock );
				sock=-1;
			}
			
			res=res->ai_next;
		}
		
		freeaddrinfo( pres );
		
		if( sock<0 ) return -1;
		
// So server ports can be quickly reused...
//
#if __APPLE__ || __linux
		int flag=1;
		setsockopt( sock,SOL_SOCKET,SO_REUSEADDR,&flag,sizeof(flag) );
#endif
		::listen( sock,queue );
		
		return sock;
	}
	
	int connect( bbString hostname,bbString service ){
	
		if( hostname.length()>1023 || service.length()>79 ) return -1;

		char _hostname[1024];
		char _service[80];
		
		strcpy( _hostname,hostname.c_str() );
		strcpy( _service,service.c_str() );
		
		int result=-1;
		
		if( bbFiber::getCurrentFiber() ){

			Future future;
			
			std::thread thread( [=,&future](){

				future.set( _connect( _hostname,_service ) );
	
			} );
			
			result=future.get();
			
			thread.join();

		}else{
		
			result=_connect( _hostname,_service );
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
			
				future.set( _listen( _service,queue ) );
	
			} );
			
			result=future.get();
			
			thread.join();
			
		}else{
		
			result=_listen( _service,queue);
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
	
	int send( int socket,void *data,int size ){
	
		int sent=0;
		
		while( size>0 ){
	
			int n=-1;
		
			if( bbFiber::getCurrentFiber() ){
			
				Future future;
				
				std::thread thread( [=,&future](){
				
					future.set( ::send( socket,(const char*)data,size,0 ) );
					
				} );
				
				n=future.get();
				
				thread.join();
				
			}else{
	
				n=::send( socket,(const char*)data,size,0 );
			}
			
			if( !n ) return sent;
			
			if( n<0 ){
				printf( "socket_send error!\n" );fflush( stdout );
				return sent;
			}
			
			data=(char*)data+n;
			size-=n;
			sent+=n;
		}
		
		return sent;
	}
	
	int recv( int socket,void *data,int size ){
	
		int n=-1;
	
		if( bbFiber::getCurrentFiber() ){
		
			Future future;
			
			std::thread thread( [=,&future](){
			
				future.set( ::recv( socket,(char*)data,size,0 ) );
				
			} );
			
			n=future.get();
			
			thread.join();
			
		}else{

			n=::recv( socket,(char*)data,size,0 );
		}
		
		if( !n ) return 0;
		
		if( n<0 ){
			printf( "socket_recv error!\n" );fflush( stdout );
			return 0;
		}
		
		return n;
	}
	
	void setopt( int socket,bbString name,int value ){
	
		if( name=="TCP_NODELAY" ){
			setsockopt( socket,IPPROTO_TCP,TCP_NODELAY,(const char*)&value,sizeof(value) );
		}
	}
	
	int getopt( int socket,bbString name ){

		int value=-1;
		socklen_t optlen=sizeof(value);
		
		if( name=="TCP_NODELAY" ){
			getsockopt( socket,IPPROTO_TCP,TCP_NODELAY,(char*)&value,&optlen );
		}
		
		return value;
	}
	

	/*	***** EXPERIMENTAL *****
	
	int send( int socket,void *data,int size ){
	
		if( !size ) return 0;
	
		int sent=0;
		
		while( size ){
		
			int n=::send( socket,(const char*)data,size,0 );
			
			if( !n ) return sent;
			
			if( n<0 ){

				if( !wouldBlock() ){
					printf( "socket_send error!\n",fflush( stdout ) );
					return sent;
				}
				
				Future future;
	
				std::thread thread( [=,&future](){
					
					fd_set writeset;
						
					FD_ZERO( &writeset );
					FD_SET( socket,&writeset );
					
					if( ::select( socket+1,0,&writeset,0,0 )==1 ){
						
						future.set( ::send( socket,(const char*)data,size,0 ) );
						
					}else{
					
						future.set( -1 );
					}
					
				} );
					
				n=future.get();
				
				thread.join();
				
				if( n<0 ){
					printf( "socket_send error!\n",fflush( stdout ) );
					return sent;
				}
			}

			data=(char*)data+n;
			size-=n;
			sent+=n;
		}
		
		return sent;
	}
	*/

	/*	***** EXPERIMENTAL *****
	
	int recv( int socket,void *data,int size ){
		
		if( !size ) return 0;
		
		for( ;; ){
	
			int n=::recv( socket,(char*)data,size,0 );
				
			if( !n ) return 0;
				
			if( n<0 ){
				
				if( !wouldBlock() ){
					printf( "socket_recv error!\n" );fflush( stdout );
					return 0;
				}
				
				Future future;
						
				std::thread thread( [=,&future](){
						
					fd_set readset;
							
					FD_ZERO( &readset );
					FD_SET( socket,&readset );
							
					if( ::select( socket+1,&readset,0,0,0 )==1 ){
						future.set( ::recv( socket,(char*)data,size,0 ) );
					}else{
						future.set( -1 );
					}
				} );
						
				n=future.get();
					
				thread.join();
					
				if( n<0 ){
					printf( "socket_recv error!\n" );fflush( stdout );
					return 0;
				}
			}
				
			return n;
		}
	}
	*/
	
}