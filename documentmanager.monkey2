
Namespace ted2go


Class DocumentManager

	Field nextDocument:Action
	Field prevDocument:Action

	Field CurrentDocumentChanged:Void()
	
	Field DocumentAdded:Void( doc:Ted2Document )
	Field DocumentRemoved:Void( doc:Ted2Document )

	Method New( tabView:TabViewExt,browser:DockingView )
	
		_tabView=tabView
		_browser=browser
		
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
		
		nextDocument=New Action( "Next file" )
		nextDocument.Triggered=OnNextDocument
		nextDocument.HotKey=Key.Tab
		nextDocument.HotKeyModifiers=Modifier.Control

		prevDocument=New Action( "Previous file" )
		prevDocument.Triggered=OnPrevDocument
		prevDocument.HotKey=Key.Tab
		prevDocument.HotKeyModifiers=Modifier.Control|Modifier.Shift
		
		App.Activated+=Lambda()
			New Fiber( OnAppActivated )
		End
	End
	
	Property TabView:TabViewExt()

		Return _tabView
	End

	Property CurrentDocument:Ted2Document()
	
		Return _currentDoc
		
	Setter( doc:Ted2Document )
	
		If doc=_currentDoc Return
		
		_currentDoc=doc
		
		If _currentDoc
			_tabView.CurrentView=CurrentView
			_browser.ContentView=_currentDoc.BrowserView
		Else
			_browser.ContentView=Null
		Endif
		
		UpdateWindowTitle( doc )
		
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
	
	Method OpenDocument:Ted2Document( path:String,makeCurrent:Bool=False )
	
		path=RealPath( path )
		
		Local doc:=FindDocument( path )
		If doc 
			If makeCurrent CurrentDocument=doc
			Return doc
		Endif
		
		If GetFileType( path )<>FileType.File Return Null
		
		Local docType:=Ted2DocumentType.ForExtension( ExtractExt( path ) )
		If Not docType Return Null
		
		doc=docType.CreateDocument( path )
		If Not doc.Load() Return Null

		InitDoc( doc )
	
		_openDocs.Add( doc )
		_tabView.AddTab( TabText( doc ),doc.View )
		
		DocumentAdded( doc )
		
		If makeCurrent CurrentDocument=doc
		
		Return doc
	End
	
	'Currently also saves doc.
	'
	Method RenameDocument:Ted2Document( doc:Ted2Document,newPath:String )
	
		For Local i:=0 Until _openDocs.Length
			If doc<>_openDocs[i] Continue
			
			Local newType:=Ted2DocumentType.ForExtension( ExtractExt( newPath ) )
			If Not newType Return Null
			
			Local oldPath:=doc.Path
			doc.Rename( newPath )
			If Not doc.Save()
				doc.Rename( oldPath )
				Return Null
			Endif
			
			If newType=Ted2DocumentType.ForExtension( ExtractExt( oldPath ) )
				UpdateWindowTitle( doc )
				Return doc
			Endif
			
			Local newDoc:=newType.CreateDocument( newPath )
			If Not newDoc.Load() Return Null
			
			InitDoc( newDoc )
			
			_openDocs[i]=newDoc
			_tabView.SetTabText( i,TabText( newDoc ) )
			_tabView.SetTabView( i,newDoc.View )
			
			doc.Close()
			
			DocumentRemoved( doc )
			
			DocumentAdded( newDoc )
			
			If doc=_currentDoc CurrentDocument=newDoc

			Return newDoc
		Next
		
		Return Null
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
			docs.Add( New JsonString( doc.Path ) )
		Next
		jobj["openDocuments"]=docs
		
		If _currentDoc jobj["currentDocument"]=New JsonString( _currentDoc.Path )
	End
		
	Method LoadState( jobj:JsonObject )
		
		If Not jobj.Contains( "openDocuments" ) Return
		
		For Local doc:=Eachin jobj.GetArray( "openDocuments" )
		
			Local path:=doc.ToString()
			If GetFileType( path )<>FileType.File Continue
			
			Local tdoc:=OpenDocument( doc.ToString() )
			If tdoc And MainWindow.IsTmpPath( path ) tdoc.Dirty=True
		Next
		
		Local path:=jobj.GetString( "currentDocument" )
		If path
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
	
	Field _tabView:TabViewExt
	Field _browser:DockingView
	
	Field _currentDoc:Ted2Document
	
	Field _openDocs:=New Stack<Ted2Document>
	
	Method InitDoc( doc:Ted2Document )
	
		doc.DirtyChanged+=Lambda()
		
			UpdateTabLabel( doc )
		End
		
		doc.StateChanged+=Lambda()
		
			UpdateTabLabel( doc )
		End

		doc.Closed+=Lambda()
		
			Local index:=_tabView.TabIndex( doc.View )
			If index=-1 Return	'in case doc already removed via Rename.

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
		
		Local tv:=doc.TextView
		If tv
			tv.CursorMoved+=Lambda()
				MainWindow.ShowStatusBarLineInfo( tv )
			End
		Endif
	End
	
	Method TabText:String( doc:Ted2Document )
	
		Local label:=StripDir( doc.Path )
		
		If ExtractExt( doc.Path ).ToLower()=".monkey2"  label=StripExt( label )
		
		label=doc.State+label
		
		If doc.Dirty label+="*"
		
		Return label
	End
	
	Method UpdateTabLabel( doc:Ted2Document )
	
		If doc _tabView.SetTabText( doc.View,TabText( doc ) )
	End
	
	Method UpdateWindowTitle( doc:Ted2Document )
		
		'Can't change window title on a fiber on at least windows!
		'
		App.Idle+=Lambda()
			If doc
				MainWindow.Title = AppTitle+" - "+doc.Path
			Else
				MainWindow.Title = AppTitle
			Endif
		End
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
		
		Local reloadAll:=False
		
		For Local doc:=Eachin docs
		
			Select GetFileType( doc.Path )
			Case FileType.File
			
				If GetFileTime( doc.Path )>doc.ModTime
				
					doc.Dirty=True
					
					'CurrentDocument=doc
					
					Local result:=0
					If Not reloadAll Then result=TextDialog.Run( "File modified","File '"+doc.Path+"' has been modified!~n~nReload new version?",New String[]( "Reload","Reload All","Close document without saving","Ignore" ) )
					
					Select result
					Case 0 'Reload
						doc.Load()
					Case 1 'Reload All
						doc.Load()
						reloadAll=True
					Case 2 'Close
						doc.Close()
					Case 3 'Ignore
					
					End
				
				Endif
				
			Case FileType.Directory
			
				doc.Dirty=True
				
				'CurrentDocument=doc
				
				Alert( "File '"+doc.Path+"' has mysteriously turned into a directory!" )
			
			Case FileType.None
			
				doc.Dirty=True

				'CurrentDocument=doc
				
				Alert( "File '"+doc.Path+"' has been deleted!" )
				
			End
		
		Next
		
	End
	
End
