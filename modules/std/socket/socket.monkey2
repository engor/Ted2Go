
Namespace std.socket

#If __TARGET__="windows"
#Import "<libWs2_32.a>"
#Endif

#Import "native/socket.cpp"
#Import "native/socket.h"

Extern

'Note: should probably just make this an extern bbSocket struct, ala bbProcess.

#rem monkeydoc @hidden
#end
Function socket_connect:Int( hostname:String,service:String )="bbSocket::connect"

#rem monkeydoc @hidden
#end
Function socket_listen:Int( service:String,queue:Int )="bbSocket::listen"

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

Struct Socket

	#rem monkeydoc True if socket is currently open.
	#end
	Property IsOpen:Bool()
	
		Return _socket<>-1
	End

	#rem monkeydoc Accepts a new incoming connection on a listening socket.
	
	Returns null if there was an error, otherwise blocks until an incoming connection has been made.
	
	@return new incomnig connection or null if there was an error.
	
	#end
	Method Accept:Socket()
		If _socket=-1 Return Null
	
		Local socket:=socket_accept( _socket )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End

	#rem monkeydoc Closes a socket.
	
	Once closed, a socket should not be used anymore.
	
	#end	
	Method Close()
		If _socket=-1 Return

		socket_close( _socket )
		_socket=-1
	End
	
	#rem monkeydoc Sends data on a connected socket.

	Writes `size` bytes to the socket.
	
	Returns the number of bytes actually written.
	
	Can return less than `sizet` if the socket has been closed by the peer or if an error occured.
	
	@param buf The memory buffer to write data from.
	
	@param size The number of bytes to write to the socket.
	
	@return The number of bytes actually written.
	
	#end
	Method Send:Int( data:Void Ptr,size:Int )
		If _socket=-1 Return 0
		
		Return socket_send( _socket,data,size )
	End
	
	#rem monkeydoc Receives data on a connected socket.
	
	Reads at most `size` bytes from the socket.
	
	Returns 0 if the socket has been closed by the peer.
	
	Can return less than `size`, in which case you may have to read again if you know there's more data coming.
	
	@param buf The memory buffer to read data into.
	
	@param size The number of bytes to read from the socket.
	
	@return The number of bytes actually read.
	
	#end
	Method Receive:Int( data:Void Ptr,size:Int )
		If _socket=-1 Return 0
	
		Return socket_recv( _socket,data,size )
	End
	
	#rem monkeydoc Sets a socket option.

	Currently, only "TCP_NODELAY" is supported, which should be 1 to enable, 0 to disable.
	
	#end
	Method SetOption( opt:String,value:Int )
		If _socket=-1 Return
	
		socket_setopt( _socket,opt,value )
	End
	
	#rem monkeydoc Gets a socket option.
	#end
	Method GetOption:Int( opt:String )
		If _socket=-1 Return -1
	
		Return socket_getopt( _socket,opt )
	End

	#rem monkeydoc Creates a connected socket.
	
	Attempts to connect to the host at `hostname` and service at `service` and returns a new connected socket if successful.
	
	Returns a closed socket upon failue.
	
	@return A new socket.
	
	#end	
	Function Connect:Socket( hostname:String,service:String )

		Local socket:=socket_connect( hostname,service )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End

	#rem monkeydoc Creates a server socket.
	
	Returns a new server socket listening at `service` if successful.
	
	Returns a closed socket upon failure.

	@return A new socket.
	
	#end
	Function Listen:Socket( service:String,queue:Int=128 )
	
		Local socket:=socket_listen( service,queue )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End
	
	Private
	
	Field _socket:Int=-1
	
	Method New( socket:Int )

		_socket=socket
	End

End
