
#ifndef BB_STD_SOCKET_H
#define BB_STD_SOCKET_H

#include <bbmonkey.h>

namespace bbSocket{

	int connect( bbString hostname,bbString service );

	int listen( bbString service,int queue );
	
	int accept( int socket );
	
	void close( int socket );
	
	int send( int socket,void *data,int size );
	
	int recv( int socket,void *data,int size );

	void setopt( int socket,bbString name,int value );
	
	int getopt( int socket,bbString name );
}

#endif
