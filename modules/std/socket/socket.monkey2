
Namespace std.socket

#If __TARGET__="windows"
#Import "<libWs2_32.a>"
#Endif

#Import "native/socket.cpp"
#Import "native/socket.h"

Extern

#rem monkeydoc @hidden
#end
Function socket_connect:Int( hostname:String,service:String )="bbSocket::connect"

#rem monkeydoc @hidden
#end
Function socket_listen:Int( service:String,queue:Int=128 )="bbSocket::listen"

#rem monkeydoc @hidden
#end
Function socket_accept:Int( socket:Int )="bbSocket::accept"

#rem monkeydoc @hidden
#end
Function socket_close( socket:Int )="bbSocket::close"

#rem monkeydoc @hidden
#end
Function socket_send:Int( socket:Int,data:Void Ptr,size:Int )="bbSocket::send"

#rem monkeydoc @hidden
#end
Function socket_recv:Int( socket:Int,data:Void Ptr,size:Int )="bbSocket::recv"

#rem monkeydoc @hidden
#end
Function socket_setopt( socket:Int,opt:String,value:Int )="bbSocket::setopt"

#rem monkeydoc @hidden
#end
Function socket_getopt:Int( socket:Int,opt:String )="bbSocket::getopt"

Public

Class Socket Extends std.stream.Stream

	#rem monkeydoc True if socket has been closed.
	#end
	Property Eof:Bool() Override

		Return _socket<0
	End

	#rem monkeydoc Always 0.
	#end
	Property Position:Int() Override
	
		Return 0
	End

	#rem monkeydoc Always -1.
	#end
	Property Length:Int() Override
	
		Return -1
	End

	#rem monkeydoc Closes the socket.
	#end
	Method Close:Void() Override
		If _socket<0 Return
	
		socket_close( _socket )
		_socket=0
	End

	#rem monkeydoc No operation.
	#end
	Method Seek( position:Int ) Override
	End

	#rem monkeydoc Reads data from the socket.
	
	Reads at most `count` bytes from the socket.
	
	Returns 0 if the socket has been closed by the peer.
	
	Can return less than `count`, in which case you may have to read again if you know there's more data coming.
	
	@param buf The memory buffer to read data into.
	
	@param count The number of bytes to read from the socket.
	
	@return The number of bytes actually read.

	#end
	Method Read:Int( buf:Void Ptr,count:Int ) Override
		If _socket<0 Return 0
	
		Return socket_recv( _socket,buf,count )
	End
	
	#rem monkeydoc Writes data to the socket.
	
	Writes `count` bytes to the socket.
	
	Returns the number of bytes actually written.
	
	Can return less than `count` if the socket has been closed by the peer or if an error occured.
	
	@param buf The memory buffer to read data from.
	
	@param count The number of bytes to write to the socket.
	
	@return The number of bytes actually written.

	#end
	Method Write:Int( buf:Void Ptr,count:Int ) Override
		If _socket<0 Return 0
	
		Return socket_send( _socket,buf,count )
	End

	#rem monkeydoc Sets a socket option.
	
	Currently, only "TCP_NODELAY" is supported, which should be 1 to enable, 0 to disable.
	
	#end	
	Method SetOption( name:String,value:Int )
		If _socket<0 Return
	
		socket_setopt( _socket,name,value )
	End
	
	#rem monkeydoc Gets a socket option.
	
	Currently, only "TCP_NODELAY" is supported.
	
	#end	
	Method GetOption:Int( name:String )
		If _socket<0 Return -1
	
		Return socket_getopt( _socket,name )
	End

	#rem monkeydoc Connects to a host/service.
	
	Returns a new socket if successful, else null.
	
	`service` can be an integer port number.
	
	@param hostname The name of the host to connect to.
	
	@param service The service or port to connect to.
	
	#end	
	Function Connect:Socket( hostname:String,service:String )
	
		Local socket:=socket_connect( hostname,service )
		If socket<0 Return Null
		
		Return New Socket( socket )
	End
	
	Private
	
	Field _socket:Int 
	
	Method New( socket:Int )
		_socket=socket
	End

End

Class SocketServer

	#rem monkeydoc Closes the server.
	#end
	Method Close()
		If _socket<0 Return
	
		socket_close( _socket )
	End

	#rem monkeydoc Accepts a new connection.
	
	Waits until a new incoming connection is available.
	
	@return A new connection, or null if there is a network error.
	
	#end
	Method Accept:Socket()
		If _socket<0 Return Null
	
		Local socket:=socket_accept( _socket )	
		If socket<0 Return Null
		
		Return New Socket( socket )
	End

	#rem monkeydoc Creates a server and starts listening.
	
	Returns a new server if successful, else null.
	
	`service` can be an integer port number.
	
	@param service The service or port to listen on.
	
	@param queue The number of incoming connections that can be queued.
	
	#end
	Function Listen:SocketServer( service:String,queue:Int=128 )
	
		Local socket:=socket_listen( service,queue )
		If socket<0 Return Null
		
		Return New SocketServer( socket )
	End
	
	Private
	
	Field _socket:Int
	
	Method New( socket:Int )
		_socket=socket
	End

End
