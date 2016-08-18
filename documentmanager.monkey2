
Namespace ted2

Class DocumentManager

	Field nextDocument:Action
	Field prevDocument:Action

	Field CurrentDocumentChanged:Void()
	
	Field DocumentAdded:Void( doc:Ted2Document )
	Field DocumentRemoved:Void( doc:Ted2Document )

	Method New( tabView:TabView )
	
		_tabView=tabView
		
		_tabView.CurrentChanged+=Lambda()
			CurrentDocument=FindDocument( _tabView.CurrentView )
		End
		
		_tabView.Dragged+=Lambda()
			Local docs:=New Stack<Ted2Document>
			For Local i:=0 Until _tabView.NumTabs
				docs.Push( FindDocument( _tabView.TabView( i ) ) )
			Next
			_openDocs=docs
		End
		
		nextDocument=New Action( "Next File" )
		nextDocument.Triggered=OnNextDocument
		nextDocument.HotKey=Key.Tab
		nextDocument.HotKeyModifiers=Modifier.Control

		prevDocument=New Action( "Previous File" )
		prevDocument.Triggered=OnPrevDocument
		prevDocument.HotKey=Key.Tab
		prevDocument.HotKeyModifiers=Modifier.Control|Modifier.Shift
		
		App.Activated+=Lambda()
			New Fiber( OnAppActivated )
		End
	End
	
	Property TabView:TabView()

		Return _tabView
	End

	Property CurrentDocument:Ted2Document()
	
		Return _currentDoc
		
	Setter( doc:Ted2Document )
	
		If doc=_currentDoc Return
		
		_currentDoc=doc
		
		If doc _tabView.CurrentView=CurrentView
		
		'Can't change window title on a fiber on at least windows!
		'
		App.Idle+=Lambda()
			If _currentDoc
				MainWindow.Title="Ted2 - "+_currentDoc.Path
			Else
				MainWindow.Title="Ted2"
			Endif
		End
		
		CurrentDocumentChanged()
	End
	
	Property CurrentTextView:TextView()
		
		If _currentDoc Return _currentDoc.TextView
		
		Return Null
	End
	
	Property CurrentView:View()
	
		If _currentDoc Return _currentDoc.View
		
		Return Null
	End
	
	Property OpenDocuments:Ted2Document[]()
	
		Return _openDocs.ToArray()
	End
	
	Method AddDocument( doc:Ted2Document,index:Int=-1 )
	
		doc.DirtyChanged+=Lambda()
			UpdateTabLabel( doc )
		End
		
		doc.StateChanged+=Lambda()
			UpdateTabLabel( doc )
		End

		doc.Closed+=Lambda()
		
			Local index:=_tabView.TabIndex( doc.View )

			_tabView.RemoveTab( index )
			_openDocs.Remove( doc )
			
			If doc=_currentDoc
				If _tabView.NumTabs
					If index=_tabView.NumTabs index-=1
					CurrentDocument=FindDocument( _tabView.TabView( index ) )
				Else
					CurrentDocument=Null
				Endif
			Endif
			
			DocumentRemoved( doc )
		End
		
		If index=-1
		
			_tabView.AddTab( DocumentTabLabel( doc ),doc.View )
			
			_openDocs.Add( doc )
		
		Else
			_tabView.SetTabView( index,doc.View )
			
			_openDocs.Insert( index,doc )
			
		Endif
		
		DocumentAdded( doc )
	End
	
	Method OpenDocument:Ted2Document( path:String,makeCurrent:Bool=False,index:Int=-1 )
	
		path=RealPath( path )
		
		Local doc:=FindDocument( path )
		If doc 
			If makeCurrent CurrentDocument=doc
			Return doc
		Endif
		
		Local ext:=ExtractExt( path ).ToLower()
			
		Select ext
		Case ".monkey2"
		Case ".png",".jpg",".bmp"
		Case ".wav",".ogg"
		Case ".h",".hpp",".hxx",".c",".cpp",".cxx",".m",".mm",".s",".asm"
		Case ".html",".js",".css",".php",".md",".json",".xml",".ini"
		Case ".sh",".bat"
		Case ".glsl"
		Case ".txt"
		Default
			Alert( "Unrecognized file type extension for file '"+path+"'" )
			Return Null
		End
		
		Select ext
		Case ".monkey2"
			doc=New Monkey2Document( path )
		Case ".png",".jpg"
			doc=New ImageDocument( path )
		Case ".wav",".ogg"
			doc=Ted2DocumentType.CreateDocument( path )
		Case ".json"
			doc=New JsonDocument( path )
		Default
			doc=New PlainTextDocument( path )
		End
		
		If GetFileType( path )<>FileType.File Or Not doc.Load()
			Return Null
		End
		
		AddDocument( doc,index )
		
		If makeCurrent CurrentDocument=doc
		
		Return doc
	End
	
	Method FindDocument:Ted2Document( path:String )
	
		For Local doc:=Eachin _openDocs
			If doc.Path=path Return doc
		Next
		
		Return Null
	End
	
	Method FindDocument:Ted2Document( view:View )
	
		For Local doc:=Eachin _openDocs
			If doc.View=view Return doc
		Next
		
		Return Null
	End
	
	Method SaveState( jobj:JsonObject )
		
		Local docs:=New JsonArray
		For Local doc:=Eachin _openDocs

			If MainWindow.IsTmpPath( doc.Path ) And Not doc.Dirty Continue
			
			docs.Add( New JsonString( doc.Path ) )
		Next
		jobj["openDocuments"]=docs
		
		If _currentDoc jobj["currentDocument"]=New JsonString( _currentDoc.Path )
	End
		
	Method LoadState( jobj:JsonObject )
		
		If Not jobj.Contains( "openDocuments" ) Return
		
		For Local doc:=Eachin jobj["openDocuments"].ToArray()
		
			Local path:=doc.ToString()
			If GetFileType( path )<>FileType.File Continue
			
			Local tdoc:=OpenDocument( doc.ToString() )
			If tdoc And MainWindow.IsTmpPath( path ) tdoc.Dirty=True
		Next
		
		If jobj.Contains( "currentDocument" )
			Local path:=jobj["currentDocument"].ToString()
			Local doc:=FindDocument( path )
			If doc CurrentDocument=doc
		Endif
		
		If Not _currentDoc And _openDocs.Length
			CurrentDocument=_openDocs[0]
		Endif
		
	End

	Method Update()
		nextDocument.Enabled=_openDocs.Length>1
		prevDocument.Enabled=_openDocs.Length>1
	End
	
	Private
	
	Field _tabView:TabView
	
	Field _currentDoc:Ted2Document
	
	Field _openDocs:=New Stack<Ted2Document>
	
	Method DocumentTabLabel:String( doc:Ted2Document )
	
		Local label:=StripDir( doc.Path )
		
		If ExtractExt( doc.Path ).ToLower()=".monkey2"  label=StripExt( label )
		
		'If IsTmpPath( doc.Path ) label="<"+label+">"
		
		label=doc.State+label
		
		If doc.Dirty label+="*"
		
		Return label
	End
	
	Method UpdateTabLabel( doc:Ted2Document )
		If doc _tabView.SetTabText( doc.View,DocumentTabLabel( doc ) )
	End
	
	Method OnNextDocument()
	
		If _openDocs.Length<2 Return
		
		Local i:=_tabView.CurrentIndex+1
		If i=_tabView.NumTabs i=0
		
		Local doc:=FindDocument( _tabView.TabView( i ) )
		If Not doc Return
		
		CurrentDocument=doc
	End
	
	Method OnPrevDocument()
		
		If _openDocs.Length<2 Return
		
		Local i:=_tabView.CurrentIndex-1
		If i=-1 i=_tabView.NumTabs-1
		
		Local doc:=FindDocument( _tabView.TabView( i ) )
		If Not doc Return
		
		CurrentDocument=doc
	End
	
	Method OnAppActivated()
	
		Local docs:=_openDocs.ToArray()
		
		For Local doc:=Eachin docs
		
			Select GetFileType( doc.Path )
			Case FileType.File
			
				If GetFileTime( doc.Path )>doc.ModTime
				
					doc.Dirty=True
					
					CurrentDocument=doc
					
					Select TextDialog.Run( "File modified","File '"+doc.Path+"' has been modified!~n~nReload new version?",New String[]( "Reload","Close document without saving","Ignore" ) )
					Case 0 'Reload
						doc.Load()
					Case 1 'Close
						doc.Close()
					Case 2 'Ignore
					End
				
				Endif
				
			Case FileType.Directory
			
				doc.Dirty=True
				
				CurrentDocument=doc
				
				Alert( "File '"+doc.Path+"' has mysteriously turned into a directory!" )
			
			Case FileType.None
			
				doc.Dirty=True

				CurrentDocument=doc
				
				Alert( "File '"+doc.Path+"' has been deleted!" )
				
			End
		
		Next
		
	End
	
End
