
Namespace std.socket

#If __TARGET__="windows"
#Import "<libWs2_32.a>"
#Endif

#Import "native/socket.cpp"
#Import "native/socket.h"

Extern

#rem monkeydoc @hidden
#end
Function socket_connect:Int( hostname:String,service:String,type:Int )="bbSocket::connect"

#rem monkeydoc @hidden
#end
Function socket_bind:Int( service:String )="bbSocket::bind"

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
Function socket_sendto:Int( socket:Int,data:Void Ptr,size:Int,addr:Void ptr,addrlen:Int )="bbSocket::sendto"

#rem monkeydoc @hidden
#end
Function socket_recvfrom:Int( socket:Int,data:Void Ptr,size:Int,addr:Void ptr,addrlen:Int Ptr )="bbSocket::recvfrom"

#rem monkeydoc @hidden
#end
Function socket_setopt( socket:Int,opt:String,value:Int )="bbSocket::setopt"

#rem monkeydoc @hidden
#end
Function socket_getopt:Int( socket:Int,opt:String )="bbSocket::getopt"

#rem monkeydoc @hidden
#end
Function socket_cansend:Int( socket:Int )="bbSocket::cansend"

#rem monkeydoc @hidden
#end
Function socket_canrecv:Int( socket:Int )="bbSocket::canrecv"

#rem monkeydoc @hidden
#end
Function socket_getsockaddr:Int( socket:Int,addr:Void Ptr,addrlen:Int Ptr )="bbSocket::getsockaddr"

#rem monkeydoc @hidden
#end
Function socket_getpeeraddr:Int( socket:Int,addr:Void Ptr,addrlen:Int Ptr )="bbSocket::getpeeraddr"

#rem monkeydoc @hidden
#end
Function socket_sockaddrname:Int( addr:Void Ptr,addrlen:Int,host:libc.char_t Ptr,service:libc.char_t Ptr )="bbSocket::sockaddrname"

Public

Enum SocketType

	Stream=0
	Datagram=1

End

Class SocketAddress

	Property Host:String()
		Validate()
		Return _host
	End
	
	Property Service:String()
		Validate()
		Return _service
	End
	
	Method To:String()
		Return Host+":"+Service
	End
	
	Private
	
	Field _addr:=New Byte[128]
	Field _addrlen:Int=0

	Field _dirty:Bool=False	
	Field _host:String=""
	Field _service:String=""
	
	Method Validate()
		If Not _dirty Return
		
		Local host:=New libc.char_t[1024]
		Local service:=New libc.char_t[80]
		
		If socket_sockaddrname( _addr.Data,_addrlen,host.Data,service.Data )>=0
			_host=String.FromCString( host.Data )
			_service=String.FromCString( service.Data )
		Else
			_host=""
			_service=""
		Endif
		
		_dirty=False
	End

	Property Addr:Void Ptr()
		Return _addr.Data
	End
	
	Property Addrlen:Int()
		Return _addrlen
	End
	
	Method Update( addrlen:Int )
		_addrlen=addrlen
		If _addrlen
			_dirty=True
			Return
		Endif
		_host=""
		_service=""
		_dirty=False
	End
	
End

Class Socket

	#rem Not on Windows...
	
	#rem monkeydoc The number of bytes that be sent to the socket without it blocking.
	#end
	Property CanSend:Int()
		If _socket=-1 Return 0
		
		Return socket_cansend( _socket )
	End
	#end
	
	#rem  monkeydoc True if socket has been closed
	#end
	Property Closed:Bool()
		Return _socket=-1
	End
	
	#rem monkeydoc The number of bytes that can be received from the socket without blocking.
	#end
	Property CanReceive:Int()
		If _socket=-1 Return 0
		
		Return socket_canrecv( _socket )
	End
	
	#rem monkeydoc The address of the socket.
	#end
	Property Address:SocketAddress()
		If _socket=-1 Return Null
	
		If Not _addr
			Local addrlen:Int=128
			_addr=New SocketAddress
			Local n:=socket_getsockaddr( _socket,_addr.Addr,Varptr addrlen )
			_addr.Update( n>=0 ? addrlen Else 0 )
		Endif
		
		Return _addr
	End
	
	#rem monkeydoc The address of the socket peer.
	#end
	Property PeerAddress:SocketAddress()
		If _socket=-1 Return Null

		If Not _peer
			Local addrlen:Int=128
			_peer=New SocketAddress
			Local n:=socket_getpeeraddr( _socket,_peer.Addr,Varptr addrlen )
			_peer.Update( n>=0 ? addrlen Else 0 )
		Endif
		
		Return _peer
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
		_addr=Null
		_peer=null
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
	
	Method SendTo:Int( data:Void Ptr,size:Int,address:SocketAddress )
		If _socket=-1 Return 0
		
		DebugAssert( address.Addrlen,"SocketAddress is invalid" )
		
		Return socket_sendto( _socket,data,size,address.Addr,address.Addrlen )
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
	
	Method ReceiveFrom:Int( data:Void Ptr,size:Int,address:SocketAddress )
		If _socket=-1 Return 0
		
		Local addrlen:Int=128
		
		Local n:=socket_recvfrom( _socket,data,size,address.Addr,Varptr addrlen  )
		
		address.Update( n>=0 ? addrlen Else 0 )
		
		Return n
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
	Function Connect:Socket( hostname:String,service:String,type:SocketType=SocketType.Stream )

		Local socket:=socket_connect( hostname,service,type )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End

	#rem monkeydoc Creates a server socket.
	
	Returns a new server socket listening at `service` if successful.
	
	Returns a closed socket upon failure.

	@return A new socket.
	
	#end
	Function Bind:Socket( service:String )
	
		Local socket:=socket_bind( service )
		If socket=-1 Return Null
		
		Return New Socket( socket )
	End

	#rem monkeydoc Creates a server socket and listens on it.
	
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
	Field _addr:SocketAddress
	Field _peer:SocketAddress
	
	Method New( socket:Int )

		_socket=socket
	End

End
