
#Import "<mojox>"
#Import "<mojo>"
#Import "<std>"

Using mojox..
Using mojo..
Using std..

Class MyWindow Extends Window

	Method New()
	
		New Fiber( Server )
		
		For Local i:=0 Until 5
			New Fiber( Client )
		Next
	End
	
	Method Server()
	
		Local socket:=Socket.Bind( 12345 )
		If Not socket print "Server: Failed to create server" ; Return
		
		Print "Server @"+socket.Address+" ready"
		
		Local addr:=New SocketAddress
				
		Repeat
		
			Local data:Int
			
			If socket.ReceiveFrom( Varptr data,4,addr )<>4 Exit
			
			Print "Server received msg:"+data+" from client @"+addr
			
			data=-data
				
			socket.SendTo( Varptr data,4,addr )
				
		Forever
		
		socket.Close()
		
	End
	
	Method Client()
	
		Global _id:Int
		
		_id+=1
		
		Local id:=_id
	
		Fiber.Sleep( .5 )	'wait a bit for server to start
		
		Local socket:=Socket.Connect( "localhost",12345,SocketType.Datagram )
		If Not socket Print "Client("+id+"): Couldn't connect to server" ; Return
		
		Print "Client("+id+") @"+socket.Address+" connected to @"+socket.PeerAddress
		
		For Local i:=0 Until 10
		
			Fiber.Sleep( Rnd( .1,.2 ) )
		
			Local data:Int=i*10
			
			socket.Send( Varptr data,4 )
			
			If socket.Receive( Varptr data,4 )<>4 Exit
			
			Print "Client("+id+") received reply:"+data+" from server"
			
		Next
		
		Print "Client("+id+") finished!"
		
	End
	
	Method OnRender( canvas:Canvas ) Override
	
'		App.RequestRender()
		
		Global ticks:=0
		ticks+=1
		
		canvas.DrawText( ticks,0,0 )
	End
	
End

Function Main()

	New AppInstance
	New MyWindow
	App.Run()

End
