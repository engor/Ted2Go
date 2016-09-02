
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
		
		new_=New Action( "New" )
		new_.HotKey=Key.N
		new_.HotKeyModifiers=Modifier.Menu
		new_.Triggered=OnNew
		
		open=New Action( "Open" )
		open.HotKey=Key.O
		open.HotKeyModifiers=Modifier.Menu
		open.Triggered=OnOpen
		
		close=New Action( "Close" )
#if __HOSTOS__="macos"
		close.HotKey=Key.W
		close.HotKeyModifiers=Modifier.Menu
#else
		close.HotKey=Key.F4
		close.HotKeyModifiers=Modifier.Menu
#endif		
		close.Triggered=OnClose
		
		closeOthers=New Action( "Close Others" )
		closeOthers.Triggered=OnCloseOthers

		closeAll=New Action( "Close All" )
		closeAll.Triggered=OnCloseAll
		
		save=New Action( "Save" )
		save.HotKey=Key.S
		save.HotKeyModifiers=Modifier.Menu
		save.Triggered=OnSave

		saveAs=New Action( "Save As..." )
		saveAs.Triggered=OnSaveAs

		saveAll=New Action( "Save All" )
		saveAll.HotKey=Key.S
		saveAll.HotKeyModifiers=Modifier.Menu|Modifier.Shift
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
	
	Method SaveAs:Ted2Document()
	
		Local doc:=_docs.CurrentDocument
		If Not doc Return Null
		
		Local path:=MainWindow.RequestFile( "Save As","",True )
		If Not path Return Null
				
		If Not ExtractExt( path ) path+=ExtractExt( doc.Path )
		
		Return _docs.RenameDocument( doc,path )
	End

	Method CanClose:Ted2Document( doc:Ted2Document )
	
		If Not doc.Dirty Return doc
		
		_docs.CurrentDocument=doc
				
		Local buttons:=New String[]( "Save","Discard Changes","Cancel" )
			
		Select TextDialog.Run( "Close File","File '"+doc.Path+"' has been modified.",buttons )
		Case 0
			If MainWindow.IsTmpPath( doc.Path )
				Return SaveAs()
			Else
				If Not doc.Save() Return Null
			Endif
		Case 2
			Return Null
		End
		
		Return doc
	End
	
	Method CloseAll:Bool( except:Ted2Document )

		For Local doc:=Eachin _docs.OpenDocuments
			If doc=except Continue
			
			If Not CanClose( doc ) Return False
		Next
		
		For Local doc:=Eachin _docs.OpenDocuments
			If doc=except Continue
			
			doc.Close()
		Next
		
		Return True
	End
	
	Method OnNew()
	
		Local path:=MainWindow.AllocTmpPath( ".monkey2" )
		If Not path
			Alert( "Can't allocate temporary file" )
			Return
		Endif

		SaveString( "",path )
		
		_docs.OpenDocument( path,True )
	End
		
	Method OnOpen()
	
		Local path:=MainWindow.RequestFile( "Open File","",False )
		If Not path Return
		
		path=RealPath( path )
		
		_docs.OpenDocument( path,True )
	End
	
	Method OnClose()
	
		Local doc:=_docs.CurrentDocument
		If Not doc Return
		
		doc=CanClose( doc )
		If Not doc return
		
		doc.Close()
	End
	
	Method OnCloseOthers()
	
		CloseAll( _docs.CurrentDocument )
	End
	
	Method OnCloseAll()
	
		CloseAll( Null )
	End
	
	Method OnSave()
	
		Local doc:=_docs.CurrentDocument
		If Not doc Return
		
		If MainWindow.IsTmpPath( doc.Path )
			SaveAs()
		Else
			doc.Save()
		Endif
	End
	
	Method OnSaveAs()
	
		SaveAs()
	End
	
	Method OnSaveAll()
	
		For Local doc:=Eachin _docs.OpenDocuments

			If MainWindow.IsTmpPath( doc.Path )
				_docs.CurrentDocument=doc
				If Not SaveAs() Return
			Else
				doc.Save()
			Endif
		Next
	End
	
	Method OnQuit()
	
		For Local doc:=Eachin _docs.OpenDocuments
		
			If MainWindow.IsTmpPath( doc.Path )
				If Not doc.Save() Return
			Else
				If Not CanClose( doc ) Return
			Endif
		Next
		
		MainWindow.Terminate()
	End
End
