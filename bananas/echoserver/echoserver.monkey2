
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
				
					Local line:=ReadLine( socket )
					If Not line Exit
					
					WriteLine( socket,line )
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
	
		Fiber.Sleep( .1 )	'wait a bit for server to start!
		
		Local socket:=Socket.Connect( "localhost",12345 )
		If Not socket Print "Client:Couldn't connect to server" ; Return
		
		Print "Client:Connected"

		For Local i:=0 Until 100
		
			WriteLine( socket,"This is a number:"+i )
			
			Print "Reply:"+ReadLine( socket )
		Next
		
		Print "Client:Bye"
		
		socket.Close()
	End
	
	'Returns empty line at EOF.
	'
	Method ReadLine:String( socket:Socket )
	
		Local buf:=New DataBuffer( 1024 )
		
		Local pos:=0
		Repeat
			Assert( pos<1024 )
			Local n:=socket.Read( buf,pos,1024-pos )
			If Not n Exit
			pos+=n
			If buf.PeekByte( pos-1 )=10 Exit
		Forever
		
		Return String.FromCString( buf.Data,pos )
	End
	
	Method WriteLine( socket:Socket,line:String )
	
		Assert( line.Length<1024 )
	
		Local buf:=New DataBuffer( 1024 )
		
		Local pos:=0
		For pos=0 Until line.Length
			If line[pos]=10 Exit
			buf.PokeByte( pos,line[pos] )
		Next
		
		buf.PokeByte( pos,10 )
		socket.Write( buf,0,pos+1 )
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
