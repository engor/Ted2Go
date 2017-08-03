'IRC module for Monkey 2 by @Hezkore
'https://github.com/Hezkore/IRC-Monkey2

Namespace ted2go

'=MODULE=

'This class is the main class
'It may contain multiple server connections at once
Class IRC
	Field servers:=New List<IRCServer>
	
	'When a new message is received
	Field OnMessage:Void(message:IRCMessage,container:IRCMessageContainer,server:IRCServer)
	
	'When the userlist's been updated
	Field OnUserUpdate:Void(container:IRCMessageContainer,server:IRCServer)
	
	'When a new message container is created
	Field OnNewContainer:Void(container:IRCMessageContainer,server:IRCServer)
	
	'When a message container is removed
	Field OnRemoveContainer:Void(container:IRCMessageContainer,server:IRCServer)
	
	'Add and connect to a new IRC server
	'Nickname is your user name to connect with
	'Name/Description of server, can by anything you want
	'Server is IP/address
	'Port is server... port...
	Method AddServer:IRCServer(nickname:String,name:String,server:String,port:Int)
		Local nS:=New IRCServer(nickname,name,server,port)
		nS.parent=Self
		nS.type=ContainerType.Server
		servers.AddLast(nS)
		OnNewContainer(nS,nS)
		Return nS
	End
End

'Message container types
Enum ContainerType 
	None=0
	Server=1	'Is the server message container
	Room=2		'Is a room message container
	User=3		'Is a private chat between two users
End

'This class acts as a single IRC server connection
'It contains "message containers", such as rooms and private messages from users
'The server itself is also a message container
Class IRCServer Extends IRCMessageContainer
	Field parent:IRC
	Field serverAddress:String
	Field serverPort:Int
	Field sendBuffer:DataBuffer
	Field receiveBuffer:DataBuffer=New DataBuffer(512)
	Field fiberSleep:Float=0.35 'Lower value gets internet messages faster but uses more CPU
	Field updateFiber:Fiber 'Fiber for updating internet mesages
	Field socket:Socket
	Field stream:SocketStream
	Field nickname:String
	Field realname:String="KoreIRC 1.0"
	Field messageContainers:=New List<IRCMessageContainer>
	Field skipContainers:=New String[]("chanserv","nickserv","services","*") 'Make sure these are lower case!
	
	Field autoJoinRooms:String
	Field hasAutoJoinedRooms:Bool
	
	Field accepted:Bool
	
	Property AutoJoinRooms:String()
		Return autoJoinRooms
	Setter(str:String)
		autoJoinRooms=str
	End
	
	Property Connected:Bool()
		If stream And socket And Not socket.Closed Return True
		Return False
	End
	
	'Is this a container we should skip?
	Method SkipContainer:Bool(compare:String,alsoSkip:String="")
		compare=compare.ToLower()
		
		'Skip containers for the server host name (user server name instead)
		If compare=socket.PeerAddress.Host.ToLower() Return True
		
		'Skip one extra thing, like own username
		If compare=alsoSkip.ToLower() Return True
		
		'Skip the defined skip containers
		For Local s:=Eachin skipContainers
			If s=compare Then Return True
		Next
		
		'Skip nothing!
		Return False
	End
	
	Method Disconnect()
		If socket Then socket.Close()
		If stream Then stream.Close()
		
		For Local mC:=Eachin Self.messageContainers
			Self.RemoveMessageContainer(mC)
		Next
	End
	
	Method Remove() Override
		parent.servers.Remove(Self)
	End
	
	'Connect using existing nickname, server address and port
	Method Connect()
		If Connected Then Return
		
		TriggerOnMessage("Connecting to server "+Self.serverAddress+":"+Self.serverPort,Self.name,Self.name,null,Self)
		
		socket=Socket.Connect(Self.serverAddress,Self.serverPort)
		If Not socket
			TriggerOnMessage("Couldn't connect to server",Self.name,Self.name,null,Self)
			Return
		Endif
		
		'No delay pretty please
		socket.SetOption("TCP_NODELAY",True)
		
		'Prepare stream
		stream=New SocketStream(socket)
		If Not stream
			TriggerOnMessage("Couldn't create socket stream",Self.name,Self.name,null,Self)
			Return
		Endif
		
		'Start our update loop in the background
		UpdateLoop()
	End
	
	'New IRC server
	Method New(nickname:String,name:String,server:String,port:Int,autoConnect:Bool=True)
		Self.nickname=nickname
		Self.name=name
		Self.serverAddress=server
		Self.serverPort=port
		
		If autoConnect Then Self.Connect()
	End
	
	'Background update loop for internet messages
	Method UpdateLoop()
		updateFiber=New Fiber(Lambda()
			
			'Send register stuff at start
			'PASSWORD HERE
			SendString("USER"+" "+nickname+" "+socket.Address+" "+socket.PeerAddress+" :"+realname)
			SendString("NICK"+" "+nickname)
			
			'Stuff we'll use later
			Local lineSplit:String[]
			Local recLine:String
			Local recLength:Int
			Local linePos:Int
			Local line:String
			Local data:String
			Local msg:String
			Local param:String[]
			
			'Never ending loop of internet data
			While Not stream.Eof And Self.Connected
				
				'Try to auto join channels
				If Not hasAutoJoinedRooms And accepted Then
					hasAutoJoinedRooms=True
					Local rooms:=autoJoinRooms.Split("#")
					
					For Local s:String=Eachin rooms
						If s.Length>0 Then
							SendString("JOIN #"+s)
							Fiber.Sleep(fiberSleep)
						Endif
					Next
					
				Endif
				
				'Do we have anything to receive?
				While socket.CanReceive
					'How much should we receive, no more than our buffer length
					recLength=Min(socket.CanReceive,receiveBuffer.Length)
					socket.Receive(receiveBuffer.Data,recLength)
					
					'Add to our receive string until we've got a line ready
					recLine+=receiveBuffer.PeekString(0,recLength).Replace("~r","")
					While recLine.Contains("~n") 'We got a line!
						'Remove processed line from receive string
						linePos=recLine.Find("~n")
						line=recLine.Left(linePos)
						recLine=recLine.Slice(linePos+1)
						
						'Process our newly received line
						
						'Remove start : if it exists
						If line.StartsWith(":") Then line=line.Slice(1)
						
						'Return any PING message instantly
						If line.ToLower().StartsWith("ping ") Then
							SendString("PONG "+line.Split(" ")[1])
							Continue 'We're done with the ping message now
						Endif
						
						'If we've got a : somewhere, it's probably a message
						If line.Contains(":") Then
							data=line.Split(":")[0]
							msg=line.Split(data)[1]
							If msg.StartsWith(":") Then msg=msg.Slice(1)
						Else
							data=line
							msg=Null
						Endif
						
						'Debug print message
						'Print "MSG: "+data+">"+msg
						
						'Process the message we got
						If data.Contains(" ") Then
							param=data.Split(" ")
							OnMessage(msg,param)
						Endif
						
					Wend
				Wend
				
				'Sleep if there's nothing more to receive
				Fiber.Sleep(fiberSleep)
			Wend
			
			TriggerOnMessage("Disconnected",Self.name,Self.name,null,Self)
			If stream Then stream.Close()
		End)
	End
	
	Private
		'A safe way to read from an array
		Method GetParam:String(index:Int,param:String[])
			If param.Length>index Then Return param[index]
			Return Null
		End
		
		'Internal message processing
		Method OnMessage(msg:String,param:String[])
			Local triggerOnMessage:Bool=False
			Local container:IRCMessageContainer
			Local fromUser:String
			Local type:String
			Local toUser:String
			
			fromUser=GetParam(0,param)
			type=GetParam(1,param)
			toUser=GetParam(2,param)
			container=Self
			
			While msg.StartsWith(" ")
				msg=msg.Slice(1)
			Wend
			
			'For message information, visit: https://tools.ietf.org/html/rfc2812
			
			'Process message type
			Select type.ToUpper()
				Case "001" 'Welcome message
					'Check if our nickname was accepted or not
					If Self.nickname<>GetParam(2,param) Then
						Self.nickname=GetParam(2,param)
						parent.OnUserUpdate(container,Self)
					Endif
					
				Case "376" 'End of MOTD
					accepted=True
					TriggerOnMessage(msg,fromUser,toUser,type,container)
					
				Case "353" 'Username list
					Local nameSplit:String[]
					If msg.Contains(" ") Then 
						nameSplit=msg.Split(" ")
					Else
						nameSplit=New String[1]
						nameSplit[0]=msg
					Endif
					
					container=GetMessageContainer(GetParam(4,param))
					
					'Is this the first time we're getting users?
					If container then
						If container.gotUsers Then
							TriggerOnMessage(msg,fromUser,toUser,type,Self)
						Else
							container.gotUsers=True
						Endif
						
						container.users.Clear()
						
						For Local i:Int=0 Until nameSplit.Length
							Local nU:=New IRCUser
							nU.parent=container
							nU.name=nameSplit[i]
							container.users.AddLast(nU)
						Next
						
						container.SortUsers()
					Else
						TriggerOnMessage(msg,fromUser,toUser,type,Self)
					Endif
					
				Case "366" 'End of username list
					container=GetMessageContainer(GetParam(3,param))
					parent.OnUserUpdate(container,Self)
					
				Case "331" 'Channel topic empty
					container=GetMessageContainer(GetParam(3,param))
					container.topic=""
					
					TriggerOnMessage(msg,fromUser,toUser,type,container)
					
				Case "332" 'Channel topic
					container=GetMessageContainer(GetParam(3,param))
					container.topic=msg
					'container.AddMessage("Topic for "+container.name+" is: "+msg,container.name,container.name,type,GetHostname(toUser))
					
					'parent.OnMessage(container.messages.Last,container,Self)
					TriggerOnMessage(msg,fromUser,toUser,type,container)
					
				Case "JOIN" 'Joining a new channel
					Local chan:String=toUser
					If Not chan Then chan=msg
					container=GetMessageContainer(chan,ContainerType.Room)
					
					'Update message containers to contain new user
					Local nU:=New IRCUser
					nU.parent=container
					nU.name=GetNickname(fromUser)
					container.users.AddLast(nU)
					parent.OnUserUpdate(container,Self)
					
					TriggerOnMessage(msg,fromUser,toUser,type,container)
					
				Case "NOTICE"
					'Notices are sent to all containers!
					TriggerOnMessage(msg,fromUser,toUser,type,container)
					For container=Eachin Self.messageContainers
						'If container.type=ContainerType.User Then Continue
						TriggerOnMessage(msg,fromUser,toUser,type,container)
					Next
					
				Case "PRIVMSG"
					'Check if private messager from user or room
					If toUser.StartsWith("#") Then
						'Room
						container=GetMessageContainer(toUser,ContainerType.Room)
					Else
						'Possibly from user!
						If Not SkipContainer(GetNickname(fromUser)) Then 'skip some users
							container=GetMessageContainer(GetNickname(fromUser),ContainerType.User)
							If container.topic<>fromUser Then container.topic=fromUser
						Endif
					Endif
					
					TriggerOnMessage(msg,fromUser,toUser,type,container)
					
				Case "PART","QUIT" 'Leaving a channel
					container=GetMessageContainer(toUser,ContainerType.Room)
					
					If GetNickname(fromUser)=nickname Then
						RemoveMessageContainer(container)
						container=Self
					Else
						For Local u:=Eachin container.users
							If u.name=GetNickname(fromUser) Then
								container.users.Remove(u)
								TriggerOnMessage(msg,fromUser,toUser,type,container)
								parent.OnUserUpdate(container,Self)
								Exit
							Endif
						Next
					Endif
					
				Case "NICK" 'Changing names
					'Was local name?
					Local wasSelf:Bool
					If GetNickname(fromUser)=nickname Then
						wasSelf=True
						nickname=msg
					Endif
					
					'Update message containers to new name
					For container=Eachin Self.messageContainers
						For Local u:=Eachin container.users
							If u.name=GetNickname(fromUser) Then
								u.name=msg
								container.SortUsers()
								
								If Not wasSelf Then 
									TriggerOnMessage(msg,fromUser,msg,type,container)
									parent.OnUserUpdate(container,Self)
								Endif
								
								Exit
							Endif
						Next
					Next
					
					'Update server (No one in server but you!)
					If wasSelf Then
						container=Self
						TriggerOnMessage(msg,fromUser,msg,type,container)
						parent.OnUserUpdate(container,Self)
					Endif
					
				Default
					TriggerOnMessage(msg,fromUser,toUser,type,container)
			End
			
		End
		
		'Internal message triggering method (sends to end user)
		Method TriggerOnMessage(msg:String,fromUser:String,toUser:String,type:String,container:IRCMessageContainer)
			If Not container Then container=Self
			Local m:=New IRCMessage
			m.text=msg
			m.fromUser=GetNickname(fromUser)
			m.toUser=toUser
			m.type=type
			m.hostname=fromUser
			If parent Then parent.OnMessage(m,container,Self)
		End
	Public
	
	'Send string to server
	Method SendString(str:String)
		If Not str.EndsWith("~n") Then str+="~n"
		Local sendBuffer:DataBuffer=New DataBuffer(str.Length)
		sendBuffer.PokeString(0,str)
		socket.Send(sendBuffer.Data,sendBuffer.Length)
	End
	
	'Return a message container
	'Option to create it if it doesn't exist
	Method GetMessageContainer:IRCMessageContainer(name:String,addType:ContainerType=ContainerType.None)
		If name="*" Or name=Self.name Or name.Length<=0 Then Return Self
		
		'First we look for existing containers
		For Local c:=Eachin messageContainers
			If c.name.ToLower()=name.ToLower() Then Return c
		Next
		
		'Create a new container
		If addType<>ContainerType.None Then Return AddMessageContainer(name,addType)
		
		Return Self
	End
	
	'Add a new message container
	Method AddMessageContainer:IRCMessageContainer(name:String,type:ContainerType)
		Local nC:=New IRCMessageContainer
		nC.parent=Self
		nC.name=name
		nC.type=type
		messageContainers.AddLast(nC)
		parent.OnNewContainer(nC,Self)
		
		'Load history for chat rooms
		If nC.name.StartsWith("#") Then nC.LoadHistory()
		
		Return nC
	End
	
	'Remove a specific message container
	Method RemoveMessageContainer(container:IRCMessageContainer)
		
		'Save history for chat rooms
		If container.name.StartsWith("#") Then container.SaveHistory()
		
		messageContainers.Remove(container)
		If parent Then parent.OnRemoveContainer(container,Self)
	End
	
	'Remove message container by name
	Method RemoveMessageContainer(name:String)
		For Local c:=Eachin messageContainers
			If c.name.ToLower()=name.ToLower() Then
					RemoveMessageContainer(c)
				Return
			Endif
		Next
	End
	
	'Strips hostname and returns nickname
	Method GetNickname:String(str:String)
		If str.Contains("!") Then Return str.Split("!")[0]
		Return str
	End
	
	'Strips nickname and return hostname
	Method GetHostname:String(str:String)
		If str.Contains("!") Then Return str.Split("!")[1]
		Return str
	End
End

'This class is used by servers to contain messages in rooms and private chats
'It can also contain users and a topic which is mostly used for rooms
Class IRCMessageContainer
	Field parent:IRCServer
	Field name:String
	Field topic:String
	Field type:ContainerType
	Field users:=New List<IRCUser>
	Field gotUsers:Bool 'Have we gotten users before?
	Field messages:=New List<IRCMessage>
	
	Method LogPath:String()
		
		Return AppDir() + "/logs/" + parent.serverAddress + "/" + name + ".txt"
		
	End
	
	Method LoadHistory()
		Local file:String=LoadString( Self.LogPath() )
		If Not file Then Return
		
		Local lines:=file.Split( "~n" )
		Local type:String
		Local time:String
		Local user:String
		Local message:String
		
		For Local s:=Eachin lines
			If Not s.Contains( ">" ) Or Not s.Contains( " " ) Or Not s.Contains( ":" ) Then Continue
			
			type=s.Split( ">" )[0]
			time=s.Split( ">" )[1].Split( " " )[0]
			user=s.Split( ">" )[1].Split( " " )[1].Split( ":" )[0]
			message=s.Split( type + ">" + time + " " + user + ":" )[1]
			
			Self.AddMessage( message, user, Self.name, type.ToUpper() ).time=time
		Next
		
	End
	
	Method SaveHistory()
		Local log:String
		
		For Local m:=Eachin Self.messages
			If m.type<>"PRIVMSG" And m.type<>"QUIT" And m.type<>"PART" And m.type<>"JOIN" And m.type<>"NICK" Then Continue
			
			log+=m.type+">"+m.time+" "+m.fromUser+":"+m.text+"~n"
		Next
		
		If log.Length>2 Then
			CreateFile( LogPath(), True )
			SaveString( log, LogPath() )
		Endif
	End
	
	Method Remove() Virtual
		parent.messageContainers.Remove(Self)
	End
	
	Method GetUser:IRCUser(nick:String)
		nick=nick.ToLower()
		For Local u:=Eachin Self.users
			If u.name.ToLower()=nick Then Return u
		Next
		Return Null
	End
	
	'Add a message to this container
	Method AddMessage:IRCMessage(msg:String,fromUser:String="",toUser:String="",type:String="",hostname:string="")
		Local nM:=New IRCMessage
		nM.parent=Self
		nM.text=msg
		nM.fromUser=fromUser
		nM.toUser=toUser
		nM.type=type
		nM.hostname=hostname
		messages.AddLast(nM)
		Return nM
	End
	
	'Sort the userlist
	Method SortUsers()
		Self.users.Sort(Lambda:Int(x:IRCUser,y:IRCUser)
			Return CompareNames(x.name,y.name)
		End)
	End
	
	'Compare usernnames (for sorting)
	Function CompareNames:Int(lhs:String,rhs:String)
		if lhs.StartsWith("@") and rhs.StartsWith( "@" ) return lhs<=>rhs
		if lhs.StartsWith("@") return -1
		if rhs.StartsWith("@") return +1
		if lhs.StartsWith("+") and rhs.StartsWith( "+" ) return lhs<=>rhs
		if lhs.StartsWith("+") return -1
		if rhs.StartsWith("+") return +1
		Return lhs<=>rhs
	End
End

'A single chat message
'Used by message containers
Class IRCMessage
	Field parent:IRCMessageContainer
	Field text:String
	Field fromUser:String
	Field toUser:String
	Field type:String
	Field hostname:String
	Field time:String
	
	Function CurrentTime:String()
		Local timePtr:=std.time.Time.Now()
		Return timePtr.Hours+":"+timePtr.Minutes
	End
	
	Method New()
		Self.time=CurrentTime()
	End
End

'A single user
'Used by message containers
Class IRCUser
	Field parent:IRCMessageContainer
	Field name:String
End

'=IRC VIEW=

'Highlighter for IRC history text
Function IrcTextHighlighter:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )
	Local i0:=sol
	Local msgStep:Int
	Local userColor:Int
	Local userStart:Int
	Local userEnd:Int
	Local userDone:Bool
	
	While i0<eol
		Local chr:=text[i0]
		
		If userDone Then 
			colors[i0]=0
		Else
			colors[i0]=1
		Endif
		
		'Reset
		If chr=110 And msgStep=6 Then 'n
			msgStep=0
			userDone=False
		Elseif msgStep=6 And chr<>110
			msgStep=5
		Endif
		If chr=126 And msgStep=5 Then '~
			msgStep=6
		Endif
		
		'Detect username
		If chr=9 And msgStep=2 Then 'Tab
			userStart=i0
			msgStep=3
			userColor=0
		Elseif msgStep=2 And chr<>9 Then
			msgStep=5
		Endif
		If chr=32 And msgStep=4 Then 'Space after :
			userEnd=i0-1
			msgStep=5
			userDone=True
			For Local i1:Int=userStart Until userEnd
				colors[i1]=2 + (userColor Mod 5)
			Next
		Elseif msgStep=4 And chr<>32 Then
			msgStep=5
		Endif
		If chr=58 And msgStep=3 Then ':
			msgStep=4
		Endif
		
		If msgStep=3 Then userColor+=chr
		
		'Detect time
		If chr=91 And msgStep=0 Then '[
			msgStep=1
		Endif
		If msgStep=1 Then colors[i0]=1
		
		If chr=93 And msgStep=1 Then ']
			msgStep=2
		Endif
		
		i0+=1
	Wend
	
	Return state
End

'This is a pre-made IRC client, ready to be used in any MojoX application
Class IRCView Extends DockingView
	Field ircHandler:IRC
	
	Field introScreen:IRCIntroView
	Field chatScreen:DockingView
	
	Field topicField:TextField
	Field historyField:TextView
	Field bottomDocker:DockingView
	Field inputField:TextField
	Field nicknameLabel:Label
	Field userList:ListView
	Field serverTree:TreeView
	Field selectedTreeNode:TreeView.Node
	Field selectedServer:IRCServer
	Field selectedMessageContainer:IRCMessageContainer
	
	Field maxHistory:Int=50
	
	Property Intro:IRCIntroView()
		Return introScreen
	End
	
	Method New()
		Super.New()
		
		introScreen=New IRCIntroView(Self)
		chatScreen=New DockingView
		
		'We move to chat screen by default and intro screen if it's used!
		Self.ContentView=chatScreen
		
		'LAYOUT
		
		'Chat history field
		historyField=New TextView
		historyField.Document.TextHighlighter=IrcTextHighlighter
		historyField.ReadOnly=True
		historyField.WordWrap=True
		chatScreen.ContentView=historyField
		
		'User list
		userList=New ListView
		chatScreen.AddView(userList,"right",Style.Font.TextWidth("arandomusername!"),True)
		userList.ItemDoubleClicked+=Lambda(item:ListView.Item)
			If selectedServer And selectedServer.accepted Then
				selectedMessageContainer=selectedServer.AddMessageContainer(item.Text,ContainerType.User)
				If selectedMessageContainer Then
					UpdateServerTree()
					serverTree.NodeClicked(GetMessageContainerNode(item.Text,selectedServer.name))
				Endif
			Endif
		End
		
		'Server tree list
		serverTree=New TreeView
		chatScreen.AddView(serverTree,"left",Style.Font.TextWidth("irc.randomserver.com"),True)
		
		serverTree.NodeRightClicked+=Lambda(node:TreeView.Node)
			serverTree.NodeClicked(node) 'Select node we right clicked
			If Not selectedServer Or Not selectedMessageContainer Then Return
			
			Local menu:=New Menu
			
			'Is this a root node?
			If node=serverTree.RootNode Then
				'Nothing special
			Else
				'Is this is server node?
				If selectedServer=selectedMessageContainer Then
					
					menu.AddAction("Add Channel").Triggered=Lambda()
						New Fiber(Lambda()
							Local chan:=RequestString("Enter channel name","Add new channel")
							If chan Then
								While chan.StartsWith("#") Or chan.StartsWith(" ")
									chan=chan.Slice(1)
								Wend
								selectedServer.SendString("JOIN #"+chan)
							Endif
						End)
					End
					
					menu.AddAction("Rename").Triggered=Lambda()
						New Fiber(Lambda()
							Local name:=RequestString("Enter new name","Change server name")
							If name Then
								'Does this name already exist?
								Local exists:Bool
								For Local s:=Eachin ircHandler.servers
									If name.ToLower()=s.name.ToLower() Then
										Notify("Name already exists","This name is already in use")
										exists=True
										Exit
									Endif
								Next
								
								If Not exists Then 
									selectedServer.name=name
									node.Text=name
								Endif
							Endif
						End)
					End
					
					If selectedServer.Connected Then
						menu.AddAction("Disconnect").Triggered=Lambda()
							selectedServer.Disconnect()
						End
					Else
						menu.AddAction("Connect").Triggered=Lambda()
							selectedServer.Connect()
						End
						
						menu.AddAction("Remove").Triggered=Lambda()
							selectedServer.Remove()
							selectedMessageContainer=Null
							selectedServer=Null
							UpdateHistory()
							node.Remove()
							UpdateServerTree()
						End
					Endif
					
				Else
					'Public room
					If selectedMessageContainer.type=ContainerType.Room
						menu.AddAction("Leave").Triggered=Lambda()
							selectedServer.SendString("PART "+selectedMessageContainer.name)
						End
					Else 'Private room
						menu.AddAction("Close").Triggered=Lambda()
							selectedMessageContainer.Remove()
							selectedMessageContainer=selectedServer
							UpdateHistory()
							node.Remove()
						End
					Endif
				Endif
			Endif
			
			'Always have the option to add a new server
			menu.AddAction("Add Server").Triggered=Lambda()
				New Fiber(Lambda()
					Local serv:=RequestString("Server address","Add new server")
					Local port:Int
					Local nick:String
					If serv Then
						port=RequestInt("Server port","Add new server",6667)
						If port Then
							nick=RequestString("Nickname","Add new server")
							If nick Then ircHandler.AddServer(nick,serv,serv,port)
						Endif
					Endif
				End)
			End
			
			menu.Open( )
		End
		
		serverTree.NodeClicked+=Lambda(node:TreeView.Node)
			If Not node Then Return
			selectedTreeNode=node
			
			'Deselect everything except clicked node!
			For Local s:=Eachin serverTree.RootNode.Children
				s.Selected=False
				For Local c:=Eachin s.Children 'Deselect kids too
					c.Selected=False
				Next
			Next
			
			'Select clicked node
			node.Selected=True
			node.Icon=Null
			
			'Find the root server
			If node.Parent=serverTree.RootNode Then
				For Local s:=Eachin ircHandler.servers
					If s.name=node.Text Then
						selectedServer=s
						Exit
					Endif
				Next
			Endif
			
			'Find the actual message container we've clicked (can return the server itself!)
			If selectedServer Then
				selectedMessageContainer=selectedServer.GetMessageContainer(node.Text)
			Endif
			
			UpdateHistory()
			UpdateUsers()
		End
		
		'Topic field
		topicField=New TextField()
		topicField.BlockCursor=False
		topicField.CursorType=CursorType.Line
		topicField.ReadOnly=True
		chatScreen.AddView(topicField,"top")
		
		'Bottom stuff
		bottomDocker=New DockingView
		chatScreen.AddView(bottomDocker,"bottom")
		
		'Nickname label
		nicknameLabel=New Label()
		bottomDocker.AddView(nicknameLabel,"left")
		nicknameLabel.Clicked=Lambda()
			If selectedServer And selectedServer.accepted Then
				New Fiber(Lambda()
					Local newNick:String=RequestString("Enter new nickname","Change nickname")
					newNick=newNick.Trim()
					If selectedServer.nickname<>newNick Then selectedServer.SendString("NICK "+newNick)
				End)
			Endif
		End
		
		'User input field
		inputField=New TextField
		inputField.BlockCursor=False
		inputField.CursorType=CursorType.Line
		inputField.CursorBlinkRate=2.5
		inputField.MaxLength=512
		inputField.Entered+=Lambda()
			SendInput(inputField.Text)
			inputField.Text=Null
		End
		App.KeyEventFilter+=Lambda( event:KeyEvent )
			If App.KeyView=inputField And event.Key=Key.KeypadEnter
				SendInput(inputField.Text)
				inputField.Text=Null
			Endif
		End
		
		
		bottomDocker.ContentView=inputField
		
		'Setup IRC
		ircHandler=New IRC
		ircHandler.OnMessage=OnMessageIRC
		ircHandler.OnUserUpdate=OnUserUpdateIRC
		ircHandler.OnNewContainer=OnNewContainerIRC
		ircHandler.OnRemoveContainer=OnRemoveContainerIRC
	End
	
	'Add and connect to a new IRC server
	'Nickname is your user name to connect with
	'Name/Description of server, can by anything you want
	'Server is IP/address
	'Port is server... port...
	Method AddServer:IRCServer(nickname:String,name:String,server:String,port:Int)
		Local nS:IRCServer
		
		If ircHandler Then
			For Local s:=Eachin ircHandler.servers
				If name.ToLower()=s.name.ToLower() Then
					Notify("Name already exists","A server with this name already exists")
					Return Null
				Endif
			Next
			
			nS=ircHandler.AddServer(nickname,name,server,port)
		Endif
		
		Return nS
	End
	
	Method SendInput(text:String)
		If Not selectedMessageContainer Then Return
		
		text=text.Trim().Replace("~n","").Replace("~r","").Replace("~t","")
		If text.Length<=0 Then Return
		
		'Make this a PRIVMSG automatically?
		If text.StartsWith("/") Then
			'Nope, send raw
			text=text.Right(text.Length-1)
			selectedMessageContainer.AddMessage(selectedServer.nickname+": "+text)
		Else
			'Yep, add PRIVMSG and send!
			selectedMessageContainer.AddMessage( text, selectedServer.nickname, selectedMessageContainer.name, "PRIVMSG" )
			text="PRIVMSG "+selectedMessageContainer.name+" :"+text
		Endif
		
		ircHandler.servers.First.SendString(text)
		AddChatMessage(selectedMessageContainer.messages.Last)
	End
	
	Method SaveAllHistory()
		For Local s:IRCServer=Eachin Self.ircHandler.servers
		For Local c:IRCMessageContainer=Eachin s.messageContainers
			c.SaveHistory()
		Next
		Next
	End
	
	Method Quit(message:String=Null)
		SaveAllHistory()
		
		For Local s:IRCServer=Eachin Self.ircHandler.servers
			s.SendString("QUIT :"+message)
			s.Disconnect()
		Next
	End
	
	Method OnMessageIRC(message:IRCMessage,container:IRCMessageContainer,server:IRCServer)
		'For message information, visit: https://tools.ietf.org/html/rfc2812
		Local doNotify:Bool 'Should we notify the user?
		
		Select message.type
			Case "332" 'TOPIC
				container.AddMessage("Topic for "+container.name+" is: "+message.text)
				
			Case "JOIN"
				If message.fromUser=server.nickname Then
					UpdateHistory()
					container.AddMessage("You are now talking in "+container.name)
				Else
					container.AddMessage( message.text, message.fromUser, container.name, message.type)
				Endif
				
			Case "PART"
				container.AddMessage( message.text, message.fromUser, container.name, message.type)
				
			Case "QUIT"
				container.AddMessage( message.text, message.fromUser, container.name, message.type)
				
			Case "NICK"
				Local wasSelf:Bool
				If container=server And selectedMessageContainer Then
					wasSelf=true
					container=selectedMessageContainer
				Endif
				
				container.AddMessage( message.text, message.fromUser, message.toUser, message.type)
				
				If wasSelf Then UpdateUsers()
				
			Case "PRIVMSG"
				container.AddMessage( message.text, message.fromUser, container.name, message.type)
				doNotify=True
			
			Case "NOTICE"
				container.AddMessage( message.text, message.fromUser, container.name, message.type)
			
			Default
				container.AddMessage( message.text, message.fromUser, container.name, message.type)
				doNotify=True
		End
		
		'Display message if we're in that container right now
		If container=selectedMessageContainer Then
			AddChatMessage(container.messages.Last)
		Elseif doNotify Then
			Local node:TreeView.Node=GetMessageContainerNode(container.name,server.name)
			If node Then node.Icon=App.Theme.OpenImage("irc/notice.png")
		Endif
	End
	
	Method OnUserUpdateIRC(container:IRCMessageContainer,server:IRCServer)
		If container=selectedMessageContainer Then UpdateUsers()
	End
	
	Method OnNewContainerIRC(container:IRCMessageContainer,server:IRCServer)
		UpdateServerTree()
		If container.type<>ContainerType.User Then
			SelectMessageContainer(container.name,server.name)
		Endif
	End
	
	Method OnRemoveContainerIRC(container:IRCMessageContainer,server:IRCServer)
		UpdateServerTree()
		If container=selectedMessageContainer Then
			selectedMessageContainer=Null
			If container=server Then 
				selectedServer=Null
			Else
				SelectMessageContainer(server.name)
			Endif
		Endif
	End
	
	Method GetMessageContainerNode:TreeView.Node(serverName:String)
		serverName=serverName.ToLower()
		
		For Local s:=Eachin serverTree.RootNode.Children
			If s.Text.ToLower()=serverName Then Return s
		Next
		
		Return Null
	End
	
	Method GetMessageContainerNode:TreeView.Node(containerName:String,serverName:String)
		serverName=serverName.ToLower()
		containerName=containerName.ToLower()
		
		For Local s:=Eachin serverTree.RootNode.Children
			If s.Text.ToLower()=serverName Then
				For Local c:=Eachin s.Children
					If c.Text.ToLower()=containerName Then Return c
				Next
			Endif
		Next
		
		Return Null
	End
	
	Method SelectMessageContainer(serverName:String)
		Local foundNode:=GetMessageContainerNode(serverName)
		If foundNode Then serverTree.NodeClicked(foundNode)
	End
	
	Method SelectMessageContainer(containerName:String,serverName:String)
		Local foundNode:=GetMessageContainerNode(containerName,serverName)
		If foundNode Then serverTree.NodeClicked(foundNode)
	End
	
	Method UpdateServerTree()
		serverTree.RootNode.Text="No Server"
		serverTree.RootNode.Expanded=True
		
		If ircHandler.servers.Count()>0 Then
			serverTree.RootNodeVisible=False
		Else
			serverTree.RootNodeVisible=True
			Return
		Endif
		
		Local serverExists:Bool
		Local channelExists:Bool
		Local serverNode:TreeView.Node
		Local channelNode:TreeView.Node
		
		'Scan for old removed nodes
		For Local s:=Eachin serverTree.RootNode.Children
			serverExists=False
			
			'Does this server still exist?
			For Local is:=Eachin ircHandler.servers
				If s.Text=is.name Then
					serverExists=True
					
					'Does it channels exist?
					For Local c:=Eachin s.Children
						channelExists=False
						
						For Local ic:=Eachin is.messageContainers
							If c.Text=ic.name Then
								channelExists=True
								Exit
							Endif
						Next
						
						If Not channelExists Then
							'Remove the channel
							c.Remove()
						Endif
					Next
					
					Exit
				Endif
			Next
			
			'Well, does it exist?
			If Not serverExists Then
				'NOPE! Remove it and all channels
				s.Remove()
			Endif
		Next
		
		'Look for new servers and channels
		For Local is:=Eachin ircHandler.servers
			serverExists=False
			
			'Does this exist in the tree view already?
			For Local s:=Eachin serverTree.RootNode.Children
				If is.name=s.Text Then
					serverNode=s
					serverExists=True
					Exit
				Endif
			Next
			
			'...Well?
			If Not serverExists Then
				'NOPE! Add it to the tree view
				serverNode=New TreeView.Node(is.name,serverTree.RootNode)
				serverNode.Expanded=True
			Endif
			
			'Are all the channels there?
			For Local ic:=Eachin is.messageContainers
				channelExists=False
				
				For Local c:=Eachin serverNode.Children
					If ic.name=c.Text Then
						channelNode=c
						channelExists=True
						Exit
					Endif
				Next
				
				If Not channelExists Then
					channelNode=New TreeView.Node(ic.name,serverNode)
					serverNode.Expanded=True
				Endif
			Next
		Next
		
		If Not selectedMessageContainer And serverTree.RootNode.Children.Length>0 Then
			selectedTreeNode=serverTree.RootNode.Children[0]
			serverTree.NodeClicked(selectedTreeNode)
		Endif
	End
	
	Method UpdateUsers()
		userList.RemoveAllItems()
		If Not selectedMessageContainer Then Return
		For Local u:=Eachin selectedMessageContainer.users
			userList.AddItem(u.name)
		Next
		
		'Update own interface username
		If selectedServer Then
			nicknameLabel.Text=selectedServer.nickname+":"
		Endif
	End
	
	Method UpdateHistory()
		historyField.Clear()
		
		If Not selectedMessageContainer Then Return
		
		'Limit message count
		While selectedMessageContainer.messages.Count()>maxHistory
			selectedMessageContainer.messages.Remove(selectedMessageContainer.messages.First)
		Wend
		
		For Local m:=Eachin selectedMessageContainer.messages
			AddChatMessage(m)
		Next
	End
	
	Function PadTime:String(timeStr:String)
		If Not timeStr.Contains(":") Return timeStr
		
		Local t:=timeStr.Split(":")
		If t[0].Length<=1 Then t[0]="0"+t[0]
		If t[1].Length<=1 Then t[1]="0"+t[1]
		
		Return t[0]+":"+t[1]
	End
	
	Method AddChatMessage(message:IRCMessage)
		Local time:String="["+PadTime(message.time)+"]~t"
		
		Select message.type.ToUpper()
			
			Case "JOIN"
				historyField.AppendText( time + message.fromUser + " joined " + message.toUser + "~n" )
				
			Case "PART"
				If message.text Then
					historyField.AppendText( time + message.fromUser + " left " + message.toUser + " (Reason " + message.text + ")~n" )
				Else
					historyField.AppendText( time + message.fromUser + " left " + message.toUser + "~n" )
				Endif
				
			Case "QUIT"
				If message.text Then
					historyField.AppendText( time + message.fromUser + " quit (Reason '" + message.text + "')~n" )
				Else
					historyField.AppendText( time + message.fromUser + " quit~n" )
				Endif
				
			Case "NICK"
				historyField.AppendText( time + message.fromUser + " is now known as " + message.text + "~n" )
				
			Case "MODE"
				'historyField.AppendText( time + message.fromUser + " sets MODE " + message.text + "~n" )
				
			Case "NOTICE"
				historyField.AppendText( time + message.fromUser + ": <NOTICE> " + message.text + "~n" )
				
			Default
				If message.fromUser Then
					historyField.AppendText( time + message.fromUser + ": " + message.text + "~n" )
				Else
					historyField.AppendText( time + message.text + "~n" )
				Endif
		End
		
	End
	
	Method OnRender(canvas:Canvas) Override
		Super.OnRender(canvas)
		
		If selectedMessageContainer Then
			'Hide or show topic field or
			If topicField.Text<>selectedMessageContainer.topic Then
				topicField.Text=selectedMessageContainer.topic
			Endif
			' always hide topic to get more useful space
			topicField.Visible=False '(topicField.Text.Length>0)
			
			'Hide or show user list
			If selectedMessageContainer.users.Count()>0 Then
				userList.Visible=True
			Else
				userList.Visible=False
			Endif
		Else
			topicField.Visible=False
			userList.Visible=False
		Endif
	End
End

Class IRCIntroView Extends DockingView
	Field parent:IRCView
	Field text:String
	Field introLabel:Label
	Field servers:=New List<IRCServer>
	Field roomScroller:ScrollableView
	Field nickBox:DockingView
	Field nickField:TextField
	Field nickLabel:Label
	Field checkboxes:=New List<CheckButton>
	Field connectButton:Button
	
	Field OnConnect:Void()
	Field OnNickChange:Void(nick:String)
	
	Property Text:String()
		Return text
	Setter(str:String)
		text=str
	End
	
	Property IsConnected:Bool()
		Return _connected
	End
	
	Method New(owner:IRCView)
		Super.New()
		Self.parent=owner
	End
	
	Method AddOnlyServer:IRCServer( nickname:String,name:String,server:String,port:Int,rooms:String )
		
		servers.Clear()
		
		Local nS:IRCServer
		
		For Local s:=Eachin servers
			If name.ToLower()=s.name.ToLower() Then
				Notify("Name already exists","A server with this name already exists")
				Return Null
			Endif
		Next
		
		nS=New IRCServer(nickname,name,server,port,False)
		nS.AutoJoinRooms+=rooms
		
		servers.AddLast(nS)
		UpdateInterface()
		parent.ContentView=Self
		Return nS
	End
	
	Method AddServer:IRCServer(nickname:String,name:String,server:String,port:Int)
		Local nS:IRCServer
	
		For Local s:=Eachin servers
			If name.ToLower()=s.name.ToLower() Then
				Notify("Name already exists","A server with this name already exists")
				Return Null
			Endif
		Next
		
		nS=New IRCServer(nickname,name,server,port,False)
		
		servers.AddLast(nS)
		UpdateInterface()
		parent.ContentView=Self
		Return nS
	End
	
	Method UpdateInterface()
		
		Self.RemoveAllViews()
		
		introLabel=New Label(text)
		introLabel.TextGravity=New Vec2f(0.5,0.5)
		Self.AddView(introLabel,"top")
		
		nickBox=New DockingView
		nickBox.Layout="fill-y"
		Self.AddView(nickBox,"top")
		
		nickLabel=New Label("Nickname")
		nickBox.AddView(nickLabel,"left")
		
		nickField=New TextField
		nickField.BlockCursor=False
		nickField.TextChanged+=Lambda()
			OnNickChange(nickField.Text)
		End
		nickBox.ContentView=nickField
		
		roomScroller=New ScrollableView
		roomScroller.Layout="fill-y"
		Self.ContentView=roomScroller
		
		For Local s:=Eachin Self.servers
			If Not nickField.Text And s.nickname Then nickField.Text=s.nickname
			Local chans:=s.AutoJoinRooms.Split("#")
			For Local c:=Eachin chans
				If Not c Then Continue
				checkboxes.AddLast(New CheckButton(s.name+" - #"+c))
				checkboxes.Last.Checked=True
				roomScroller.AddView(checkboxes.Last,"top")
			Next
		Next
		
		connectButton=New Button("Connect")
		roomScroller.AddView(connectButton,"top")
		connectButton.Clicked=Lambda()
			Connect()
		End
	End
	
	Method Connect()
		
		'Is nickname set?
		If Not nickField.Text Notify( "","Please, enter your nickname." ) ; Return
		
		'Local server:=AddServer( _nick,_server,_server,_port )
		'If server Then server.AutoJoinRooms+=_rooms
		
		Local serv:String
		Local chan:String
		Local didHaveChans:Bool
		
		'Reset all auto join  strings
		For Local s:=Eachin servers
			s.AutoJoinRooms=Null
		Next
		
		'Loop throught all checkboxes and get the server and channel 
		For Local c:=Eachin Self.checkboxes
			If Not c.Checked Then Continue 'Skip boxes that aren't checked
			serv=c.Text.Split(" - ")[0].ToLower()
			chan=c.Text.Split(" - ")[1].ToLower()
			For Local s:=Eachin servers
				If serv=s.name.ToLower() Then
					didHaveChans=True
					s.AutoJoinRooms+=chan
				Endif
			Next
		Next
		
		'Did we have ANY channels to join?
		If Not didHaveChans Then Return
		
		'Send all servers
		For Local s:=Eachin servers
			If Not s.AutoJoinRooms Then Continue
			Local serv:=parent.AddServer(nickField.Text,s.name,s.serverAddress,s.serverPort)
			serv.AutoJoinRooms=s.AutoJoinRooms
		Next
		
		'Set the parent IRC view to display the chat screen now
		parent.ContentView=parent.chatScreen
		
		_connected=True
		OnConnect()
	End
	
	
	Private
	
	Field _connected:Bool
	
End

#rem
'=EXAMPLE=
Class MyWindow Extends Window
	Field ircView:IRCView
	
	Method New(title:String="IRC Test",width:Int=1280*0.85,height:Int=720*0.85,flags:WindowFlags=WindowFlags.Resizable)
		Super.New(title,width,height,flags)
		
		'Create our IRC view
		ircView=New IRCView
		ContentView=ircView
		
		'Add a new server and connect to it
		Local nick:="M2_TestUser"
		Local desc:="freenode"
		Local server:="irc.freenode.net"'"irc.du.se"
		Local port:=6667
		Local serv:IRCServer
		
		'Add a server to our intro scren
		serv=ircView.introScreen.AddServer(nick,desc,server,port)
		
		'Select title for our intro screen
		ircView.introScreen.Text="koreIRC Example"
		
		'You can skip the intro screen by adding the server directly to the IRC view
		'serv=ircView.AddServer(nick,desc,server,port)
		
		'Add rooms to connect to at start
		If serv Then
			serv.AutoJoinRooms+="#monkey2#heztest"
			'serv.AutoJoinRooms+="#heztest"
			
			'You'll want to update the intro interface after adding rooms
			ircView.introScreen.UpdateInterface()
		Endif
	End
	
	Method OnRender( canvas:Canvas ) Override
		App.RequestRender()
	End
End
#end