
#Import "<mojox>"
#Import "<mojo>"
#Import "<std>"

Using mojox..
Using mojo..
Using std..

Class MyWindow Extends Window

	Method New()
	
		New Fiber( Server )
		
		New Fiber( Client )
	End
	
	Method Server()
	
		Local server:=Socket.Listen( 12345 )
		If Not server print "Server: Failed to create server" ; Return
		
		Print "Server @"+server.Address+" listening"
		
		Repeat
		
			Local socket:=server.Accept()
			If Not socket Exit
			
			Print "Server accepted client @"+socket.PeerAddress
			
			Local stream:=New SocketStream( socket )
			
			New Fiber( Lambda()
			
				Repeat
				
					Local line:=stream.ReadSizedString()
					If Not line Exit
					
					stream.WriteSizedString( line )
					
				Forever
				
				stream.Close()
				
			End )
		
		Forever
		
		Print "Server:Bye"
		
		server.Close()
	End
	
	Method Client()
	
		Fiber.Sleep( .5 )
	
		Local socket:=Socket.Connect( "localhost",12345 )
		If Not socket Print "Client: Couldn't connect to server" ; Return
		
		Print "Client @"+socket.Address+" connected to server @"+socket.PeerAddress
		
		Local stream:=New SocketStream( socket )

		For Local i:=0 Until 100
		
			stream.WriteSizedString( "This is a number:"+i )
			
			Print "Reply:"+stream.ReadSizedString()
		Next
		
		Print "Client:Bye"
		
		stream.Close()
	End
	
	Method OnRender( canvas:Canvas ) Override
	
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
