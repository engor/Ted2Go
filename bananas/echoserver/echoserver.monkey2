
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
		
'		New Timer( 60,App.RequestRender )
	End
	
	Method Server()
	
		Local server:=SocketServer.Listen( 12345 )
		If Not server print "Server:Failed to create server" ; Return
		
		Print "Server:Listening"
		
		Repeat
		
			Local socket:=server.Accept()
			If Not socket Exit
			
			Print "Server:Accepted"
			
			New Fiber( Lambda()
			
				Repeat
				
					Local line:=socket.ReadCString()
					If Not line Exit
					
					socket.WriteCString( line )
				Forever
				
				socket.Close()
				
			End )
		
		Forever
		
		'Never gets here!
		'
		Print "Server:Bye"
		
		server.Close()
	
	End
	
	Method Client()
	
		Fiber.Sleep( .5 )	'wait a bit for server to start
		
		Local socket:=SocketStream.Connect( "localhost",12345 )
		If Not socket Print "Client:Couldn't connect to server" ; Return
		
		Print "Client:Connected"

		For Local i:=0 Until 100
		
			socket.WriteCString( "This is a number:"+i )
			
			Print "Reply:"+socket.ReadCString()
		Next
		
		Print "Client:Bye"
		
		socket.Close()
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
