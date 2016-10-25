
Namespace std.socket

Class SocketStream Extends std.stream.Stream

	#rem monkeydoc Creates a new socketsteam from an existing socket.

	Note: Closing the stream will also close the socket.
	
	#end	
	Method New( socket:Socket )
	
		_socket=socket
	End
	
	#rem monkeydoc The underlying socket.
	#end
	Property Socket:Socket()
	
		Return _socket
	End

	#rem monkeydoc True if socket has been closed.
	#end
	Property Eof:Bool() Override

		Return _socket.Closed
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
	
		Local sent:=0
		
		While count>0
		
			Local n:=_socket.Send( buf,count )
			If n<0 Exit
			
			buf=Cast<Byte Ptr>( buf )+n
			count-=n
			sent+=n

		Wend
		
		Return sent
	End

	Private
	
	Field _socket:Socket

End
