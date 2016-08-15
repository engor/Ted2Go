
Namespace ted2

Class FileActions

	Field new_:Action
	Field open:Action
	Field close:Action
	Field closeOthers:Action
	Field closeAll:Action
	Field save:Action
	Field saveAs:Action
	Field saveAll:Action
	Field quit:Action
	
	Method New( docs:DocumentManager )
	
		_docs=docs
		
#if __HOSTOS__="macos"
		Local menuCmd:=Modifier.Gui
#else		
		Local menuCmd:=Modifier.Control
#endif

		new_=New Action( "New" )
		new_.HotKey=Key.N
		new_.HotKeyModifiers=menuCmd
		new_.Triggered=OnNew
		
		open=New Action( "Open" )
		open.HotKey=Key.O
		open.HotKeyModifiers=menuCmd
		open.Triggered=OnOpen
		
		close=New Action( "Close" )
#if __HOSTOS__="macos"
		close.HotKey=Key.W
		close.HotKeyModifiers=menuCmd
#else
		close.HotKey=Key.F4
		close.HotKeyModifiers=menuCmd
#endif		
		close.Triggered=OnClose
		
		closeOthers=New Action( "Close Others" )
		closeOthers.Triggered=OnCloseOthers

		closeAll=New Action( "Close All" )
		closeAll.Triggered=OnCloseAll
		
		save=New Action( "Save" )
		save.HotKey=Key.S
		save.HotKeyModifiers=menuCmd
		save.Triggered=OnSave

		saveAs=New Action( "Save As" )
		saveAs.Triggered=OnSaveAs

		saveAll=New Action( "Save All" )
		saveAll.Triggered=OnSaveAll
		
		quit=New Action( "Quit" )
		quit.Triggered=OnQuit
		
	End
	
	Method Update()

		Local n:=0
		Local anyDirty:Bool
		For Local doc:=Eachin _docs.OpenDocuments
			If doc.Dirty anyDirty=True
			n+=1
		Next
	
		Local doc:=_docs.CurrentDocument

		close.Enabled=doc
		closeOthers.Enabled=n>1
		closeAll.Enabled=n>0
		save.Enabled=doc And doc.Dirty
		saveAs.Enabled=doc
		saveAll.Enabled=anyDirty
	End
	
	Private
	
	Field _docs:DocumentManager
	
	Method CanClose:Bool( doc:Ted2Document )
	
		If Not doc.Dirty Return True
		
		_docs.CurrentDocument=doc
				
		Local buttons:=New String[]( "Save","Discard Changes","Cancel" )
			
		Select TextDialog.Run( "Close All","File '"+doc.Path+"' has been modified.",buttons )
		Case 0 
			If Not doc.Save() Return False
		Case 2 
			Return False
		End
		
		Return True
	End
	
	Method CloseAll:Bool( except:Ted2Document )

		Local close:=New Stack<Ted2Document>
	
		For Local doc:=Eachin _docs.OpenDocuments
			If doc=except Continue
		
			If Not CanClose( doc ) Return False
			
			close.Add( doc )
		Next
		
		For Local doc:=Eachin close
			doc.Close()
		Next
		
		Return True
	End
	
	Method OnNew()
	
		Local path:=MainWindow.AllocTmpPath( ".monkey2" )
		If Not path
			Alert( "Can't create temporary file" )
			Return
		Endif

		SaveString( "",path )
		
		_docs.OpenDocument( path,True )
	End
		
	Method OnOpen()
	
		Local future:=New Future<String>
		
		App.Idle+=Lambda()
			Local path:=RequestFile( "Open file...","",False )
			future.Set( path )
		End
		
		Local path:=future.Get()
		If Not path Return
		
		path=RealPath( path )
		
		_docs.OpenDocument( path,True )
	End
	
	Method OnClose()
	
		Local doc:=_docs.CurrentDocument
		If Not doc Return
		
		If Not CanClose( doc ) Return
		
		doc.Close()
	End
	
	Method OnCloseOthers()
	
		If Not CloseAll( _docs.CurrentDocument ) Return
	End
	
	Method OnCloseAll()
	
		If Not CloseAll( Null ) Return
	End
	
	Method OnSave()
	
		Local doc:=_docs.CurrentDocument
		If Not doc Return
		
		If MainWindow.IsTmpPath( doc.Path )

			Local path:=RequestFile( "Save As","",True )
			If Not path Return
			
			doc.Rename( path )
		Endif
		
		doc.Save()
	End
	
	Method OnSaveAs()

		Local doc:=_docs.CurrentDocument
		If Not doc Return
			
		Local path:=RequestFile( "Save As","",True )
		If Not path Return
		
		Local index:=0
		For Local doc2:=Eachin _docs.OpenDocuments
			If doc=doc2 Exit
			index+=1
		Next

		doc.Rename( path )
		
		doc.Save()
		
		doc.Close()
		
		_docs.OpenDocument( path,True )
		
	End
	
	Method OnSaveAll()
	
		For Local doc:=Eachin _docs.OpenDocuments

			If MainWindow.IsTmpPath( doc.Path )
	
				Local path:=RequestFile( "Save As","",True )
				If Not path Return
				
				doc.Rename( path )
				
				doc.Save()
				
				doc.Close()
				
				_docs.OpenDocument( path,True )
				
			Else
			
				doc.Save()
			Endif
		Next
	End
	
	Method OnQuit()
	
		For Local doc:=Eachin _docs.OpenDocuments
		
			If Not CanClose( doc ) Return
		Next
		
		App.Terminate()
	End
End
