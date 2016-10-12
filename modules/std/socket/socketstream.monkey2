
Namespace std.socket

Class SocketStream Extends std.stream.Stream

	#rem monkeydoc The underlying socket.
	#end
	Property Socket:Socket()
	
		Return _socket
	End

	#rem monkeydoc True if socket has been closed.
	#end
	Property Eof:Bool() Override

		Return Not _socket.IsOpen
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
	Method OnClose() Override

		_socket.Close()
	End

	#rem monkeydoc No operation.
	#end
	Method Seek( position:Int ) Override
	End

	#rem monkeydoc Reads data from the socket stream.
	
	Reads at most `count` bytes from the socket.
	
	Returns 0 if the socket has been closed by the peer.
	
	Can return less than `count`, in which case you may have to read again if you know there's more data coming.
	
	@param buf The memory buffer to read data into.
	
	@param count The number of bytes to read from the socket stream.
	
	@return The number of bytes actually read.

	#end
	Method Read:Int( buf:Void Ptr,count:Int ) Override
	
		Return _socket.Receive( buf,count )
	End
	
	#rem monkeydoc Writes data to the socket stream.
	
	Writes `count` bytes to the socket.
	
	Returns the number of bytes actually written.
	
	Can return less than `count` if the socket has been closed by the peer or if an error occured.
	
	@param buf The memory buffer to write data from.
	
	@param count The number of bytes to write to the socket stream.
	
	@return The number of bytes actually written.

	#end
	Method Write:Int( buf:Void Ptr,count:Int ) Override
	
		Return _socket.Send( buf,count )
	End

	#rem monkeydoc Connects to a host/service.
	
	Returns a new socket stream if successful, else null.
	
	`service` can be an integer port number.
	
	@param hostname The name of the host to connect to.
	
	@param service The service or port to connect to.
	
	#end	
	Function Connect:SocketStream( hostname:String,service:String )
	
		Local socket:=std.socket.Socket.Connect( hostname,service )
		If Not socket.IsOpen Return Null
		
		Return New SocketStream( socket )
	End
	
	Private
	
	Field _socket:Socket
	
	Method New( socket:Socket )
	
		_socket=socket
	End

End

Class SocketServer

	#rem monkeydoc The underlying socket.
	#end
	Property Socket:Socket()
	
		Return _socket
	End

	#rem monkeydoc Closes the server.
	#end
	Method Close()
	
		_socket.Close()
	End

	#rem monkeydoc Accepts a new connection.
	
	Waits until a new incoming connection is available.
	
	@return A new connection, or null if there is a network error.
	
	#end
	Method Accept:SocketStream()
	
		Local socket:=_socket.Accept()
		If Not socket.IsOpen Return Null
		
		Return New SocketStream( socket )
	End

	#rem monkeydoc Creates a server and starts listening.
	
	Returns a new server if successful, else null.
	
	`service` can be an integer port number.
	
	@param service The service or port to listen on.
	
	@param queue The number of incoming connections that can be queued.
	
	#end
	Function Listen:SocketServer( service:String,queue:Int=128 )
	
		Local socket:=std.socket.Socket.Listen( service,queue )
		If Not socket.IsOpen Return Null
		
		Return New SocketServer( socket )
	End
	
	Private
	
	Field _socket:Socket
	
	Method New( socket:Socket )

		_socket=socket
	End

End
