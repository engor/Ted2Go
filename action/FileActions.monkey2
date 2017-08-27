
Namespace ted2go


Class FileActions

	Field new_:Action
	Field open:Action
	Field close:Action
	Field closeOthers:Action
	Field closeToRight:Action
	Field closeAll:Action
	Field save:Action
	Field saveAs:Action
	Field saveAll:Action
	Field quit:Action
	Field prefs:Action
	
	Method New( docs:DocumentManager )
	
		_docs=docs
		
		new_=New Action( "New file" )
#if __TARGET__="macos"
		new_.HotKey=Key.T
		new_.HotKeyModifiers=Modifier.Menu
#else
		new_.HotKey=Key.N
		new_.HotKeyModifiers=Modifier.Menu
#endif
		new_.Triggered=OnNew
		
		open=New Action( "Open file" )
		open.HotKey=Key.O
		open.HotKeyModifiers=Modifier.Menu
		open.Triggered=OnOpen
		
		close=New Action( "Close tab" )
		close.HotKey=Key.W
		close.HotKeyModifiers=Modifier.Menu
		close.Triggered=OnClose
		
		closeOthers=New Action( "Close other tabs" )
		closeOthers.Triggered=OnCloseOthers
		
		closeToRight=New Action( "Close tabs to the right" )
		closeToRight.Triggered=OnCloseToRight
		
		closeAll=New Action( "Close all tabs" )
		closeAll.Triggered=Lambda()
			CloseFiles( _docs.OpenDocuments )
		End
		
		save=New Action( "Save" )
		save.HotKey=Key.S
		save.HotKeyModifiers=Modifier.Menu
		save.Triggered=OnSave

		saveAs=New Action( "Save as..." )
		saveAs.Triggered=OnSaveAs

		saveAll=New Action( "Save all" )
		saveAll.HotKey=Key.S
		saveAll.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		saveAll.Triggered=OnSaveAll
		
		quit=New Action( "Quit" )
		quit.Triggered=OnQuit
		
#If __TARGET__="windows"
		quit.HotKey=Key.F4
		quit.HotKeyModifiers=Modifier.Alt|Modifier.Ignore
#Elseif __TARGET__="macos"
		quit.HotKey=Key.Q
		quit.HotKeyModifiers=Modifier.Menu|Modifier.Ignore
#Elseif __TARGET__="linux"
		quit.HotKey=Key.F4
		quit.HotKeyModifiers=Modifier.Alt|Modifier.Ignore
#endif		

		prefs=New Action( "Preferences..." )
		prefs.Triggered=OnPrefs
#if __TARGET__="macos"
		prefs.HotKey=Key.Comma
#Else
		prefs.HotKey=Key.P
#Endif
		prefs.HotKeyModifiers=Modifier.Menu
		
	End
	
	Method Update()
	
		Local docs:=_docs.OpenDocuments

		Local n:=0
		Local anyDirty:Bool
		For Local doc:=Eachin docs
			If doc.Dirty anyDirty=True
			n+=1
		Next
	
		Local doc:=_docs.CurrentDocument

		close.Enabled=doc
		closeOthers.Enabled=n>1
		closeToRight.Enabled=doc And doc<>docs[docs.Length-1]
		closeAll.Enabled=n>0
		save.Enabled=doc And (doc.Dirty Or MainWindow.IsTmpPath( doc.Path ))
		saveAs.Enabled=doc
		saveAll.Enabled=anyDirty
	End
	
	Method CloseFiles( docs:Ted2Document[] )
		
		If Not docs.Length Return
		
		_saveAllFlag=False
		_discardAllFlag=False
	
		For Local doc:=Eachin docs
			If Not CanClose( doc,True ) Return
		Next
	
		For Local doc:=Eachin docs
			doc.Close()
		Next
	
	End
	
	
	Private
	
	Field _docs:DocumentManager
	Field _saveAllFlag:Bool,_discardAllFlag:Bool
	Field _quit:Bool
	
	
	Method SaveAs:Ted2Document()
	
		Local doc:=_docs.CurrentDocument
		If Not doc Return Null
		
		Local name:=StripDir( doc.Path )
		Local path:=MainWindow.RequestFile( "Save As",name,True )
		If Not path Return Null
				
		If Not ExtractExt( path ) path+=ExtractExt( doc.Path )
		
		Return _docs.RenameDocument( doc,path )
	End

	Method CanClose:Ted2Document( doc:Ted2Document,manyFiles:Bool=False )
	
		If Not doc.Dirty Return doc
		
		'_docs.CurrentDocument=doc
				
		Local buttons:String[]
		If manyFiles
			buttons=New String[]( "Save","Save All","Discard","Discard All","Cancel" )
		Else
			buttons=New String[]( "Save","Discard","Cancel" )
		Endif
			
		Local result:=-1
		If manyFiles
			If _saveAllFlag
				result=1
			Elseif _discardAllFlag
				result=3
			Endif
		Endif
		If result = -1 Then result=TextDialog.Run( "Close File","File '"+doc.Path+"' has been modified.",buttons )
		
		Select result
		Case 0 'save
			If MainWindow.IsTmpPath( doc.Path )
				Return SaveAs()
			Else
				If Not doc.Save() Return Null
			Endif
		Case 1 'saveAll or discard
			If manyFiles
				If MainWindow.IsTmpPath( doc.Path )
					Return SaveAs()
				Else
					If Not doc.Save() Return Null
				Endif
				_saveAllFlag=True
			Endif
		Case 2 'discard or cancel
			Return manyFiles ? doc Else Null
		Case 3 'discardAll
			_discardAllFlag=True
		Case 4 'cancel
			Return Null
		End
		
		Return doc
	End
	
	Method OnNew()
	
		Local path:=MainWindow.AllocTmpPath( "untitled",".monkey2" )
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
		If Not doc Return
		
		doc.Close()
	End
	
	Method OnCloseOthers()
	
		Local current:=_docs.CurrentDocument
		If Not current Return
	
		_saveAllFlag=False
		_discardAllFlag=False
		
		Local docs:=_docs.OpenDocuments
		
		For Local doc:=Eachin docs
			If doc<>current And Not CanClose( doc,True ) Return
		Next
		
		For Local doc:=Eachin docs
			If doc<>current doc.Close()
		Next
	End
	
	Method OnCloseToRight()
	
		Local current:=_docs.CurrentDocument
		If Not current Return
	
		_saveAllFlag=False
		_discardAllFlag=False
		
		Local docs:=_docs.OpenDocuments
		
		Local close:=False
		For Local doc:=Eachin docs
			If close
				If Not CanClose( doc,True ) Return
			Else
				If doc=current close=True
			Endif
		Next
		
		close=False
		For Local doc:=Eachin docs
			If close
				doc.Close()
			Else
				If doc=current close=True
			Endif
		Next
		
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
		
		If _quit Return
		_quit=True
		
		_saveAllFlag=False
		_discardAllFlag=False
		
		For Local doc:=Eachin _docs.OpenDocuments
		
			If MainWindow.IsTmpPath( doc.Path )
				If Not doc.Save() Then _quit=False ; Return
			Else
				If Not CanClose( doc,True ) Then _quit=False ; Return
			Endif
		Next
		
		MainWindow.Terminate()
	End
	
	Field _prefsDialog:PrefsDialog
	
	Method OnPrefs()
	
		If Not _prefsDialog
			_prefsDialog=New PrefsDialog
			
			_prefsDialog.Apply+=Lambda()
			
				For Local d:=Eachin _docs.OpenDocuments
					Local tv:=Cast<CodeDocumentView>( d.TextView )
					If tv Then tv.UpdatePrefs()
				Next
				
				MainWindow.OnPrefsChanged()
			End
			
		Endif
		_prefsDialog.Show()
	End
	
End
