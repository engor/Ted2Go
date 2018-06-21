
Namespace ted2go


Class CodeParsing
	
	Function IsFileBuildable:Bool( path:String )
		
		Return ExtractExt( path )=".monkey2"
	End
	
	Method New( docs:DocumentManager,projView:ProjectView )
		
		_docsManager=docs
		
		_docsManager.DocumentAdded+=Lambda( doc:Ted2Document )
		
			Local codeDoc:=Cast<CodeDocument>( doc )
			If codeDoc
				StartWatching( codeDoc )
				
				codeDoc.Renamed+=Lambda( newPath:String,oldPath:String )
					
					' maybe now we have no parser for this file
					' so re-starting
					StopWatching( codeDoc )
					StartWatching( codeDoc )
				End
				Return
			Endif
			
'			If ProjectView.IsProjectFile( doc.Path )
'				
'			Endif
			
		End
		_docsManager.DocumentRemoved+=Lambda( doc:Ted2Document )
		
			Local codeDoc:=Cast<CodeDocument>( doc )
			If codeDoc Then StopWatching( codeDoc )
		End
		_docsManager.LockedDocumentChanged+=Lambda()
			
			' have we locked or active path?
			Local mainFile:=PathsProvider.GetActiveMainFilePath( False )
			If mainFile
				FindWatcher( mainFile )?.WakeUp()
			Else
				DocWatcher.WakeUpGlobal()
			Endif
		End
		
		DocWatcher.docsForUpdate=Lambda:CodeDocument[]()
			
			Return _docsManager.OpenCodeDocuments
		End
		
		DocWatcher.Init()
		
		projView.MainFileChanged+=Lambda( path:String,prevPath:String )
			
			DocWatcher.WakeUpGlobal()
		End
		
		projView.ActiveProjectChanged+=Lambda( proj:Monkey2Project )
			
			DocWatcher.WakeUpGlobal()
		End
	End
	
'	Method Parse()
'		
'		Local doc:=MainWindow.LockedDocument
'		If Not doc Then doc=Cast<CodeDocument>( _docsManager.CurrentDocument )
'		If doc
'			Local parser:=ParsersManager.Get( doc.CodeView.FileType )
'			DocWatcher.TryToParse( doc,parser )
'		Endif
'	End
	
	
	Private
	
	Field _docsManager:DocumentManager
	Field _watchers:=New Stack<DocWatcher>
	
	Method FindWatcher:DocWatcher( doc:CodeDocument )
		
		For Local i:=Eachin _watchers
			If i.doc=doc Return i
		Next
		
		Return Null
	End
	
	Method FindWatcher:DocWatcher( path:String )
	
		For Local i:=Eachin _watchers
			If i.doc.Path=path Return i
		Next
	
		Return Null
	End
	
	Method StartWatching( doc:CodeDocument )
		
		If Not IsFileBuildable( doc.Path ) Return
		
		If FindWatcher( doc ) Return ' already added
		
		Local watcher:=New DocWatcher( doc )
		_watchers.Add( watcher )
		
		watcher.WakeUp()
	End
	
	Method StopWatching( doc:CodeDocument )
	
		For Local i:=Eachin _watchers
			If i.doc=doc
				i.Dispose()
				_watchers.Remove( i )
				Return
			Endif
		Next
	End
	
	Method Dispose()
	
		DocWatcher.enabled=False
	End
	
End


Private

Class DocWatcher
	
	Global enabled:=True
	Field doc:CodeDocument
	Global docsForUpdate:CodeDocument[]()
	
	Method New( doc:CodeDocument )
		
		Self.doc=doc
		_view=doc.CodeView
		_parser=ParsersManager.Get( _view.FileType )
		Local canParse:=Not ParsersManager.IsFake( _parser )
		
		If canParse
			_view.Document.TextChanged+=OnTextChanged
			
			UpdateDocItems( doc,_parser ) ' refresh parser info for just opened document
		Endif
	End
	
	Method Dispose()
		
		_view.Document.TextChanged-=OnTextChanged
	End
	
	Method WakeUp()
	
		OnTextChanged()
	End
	
	Function WakeUpGlobal()
	
		_timeTextChanged=Millisecs()
	End
	
	Function Init()
	
		_timeTextChanged=Millisecs()
	End
	
	Private
	
	Field _view:CodeDocumentView
	Field _parser:ICodeParser
	Global _dirtyCounter:=0,_dirtyCounterLastParse:=0
	Global _timeDocParsed:=0
	Global _timeTextChanged:=0
	Global _timer:Timer
	Global _parsing:Bool
	Global _changed:=New Stack<CodeDocument>
	
	Method OnTextChanged()
		
		' skip whitespaces ?
		'
'		Local char:=doc.CodeView?.LastTypedChar
'		Print "char: '"+char+"'"

		TryToParse( doc,_parser )
	End
	
	Function TryToParse( doc:CodeDocument,parser:ICodeParser )
		
		_timeTextChanged=Millisecs()
		
		If Not _changed.Contains( doc ) Then _changed.Add( doc )
		
		If _parsing Return
		
		If Not _timer Then _timer=New Timer( 1,Lambda()
			
			If _parsing Return
			
			Local msec:=Millisecs()
			If msec<_timeDocParsed+1000 Return
			If _timeTextChanged=0 Or msec<_timeTextChanged+1000 Return
			_timeTextChanged=0
			
			If Not enabled Return
			
			'Local mainFile:=PathsProvider.GetActiveMainFilePath( False )
			'If Not mainFile Return
			Local mainFile:=PathsProvider.GetActiveMainFilePath()
			
			_parsing=True
			
			Local docForParsing:CodeDocument
			Local dirty:=New String[_changed.Length]
			Local texts:=New String[_changed.Length]
			For Local i:=0 Until _changed.Length
				Local d:=_changed[i]
				If d.Dirty
					dirty[i]=d.Path
					texts[i]=d.CodeView.Text
				Endif
				docForParsing=d ' grab latest added doc
			Next
			_changed.Clear()
			
			Local params:=New ParseFileParams
			params.filePath=mainFile
			
			For Local i:=0 Until dirty.Length
				If dirty[i]
					dirty[i]=Monkey2Parser.GetTempFilePathForParsing( dirty[i] )
					SaveString( texts[i],dirty[i] )
				Endif
			Next
			
			Local errorStr:=parser.ParseFile( params )
			
			If Not enabled Return
			
			Local errors:=New Stack<BuildError>
			
			If errorStr And errorStr<>"#"
				
				Local arr:=errorStr.Split( "~n" )
				For Local s:=Eachin arr
					Local i:=s.Find( "] : Error : " )
					If i<>-1
						Local j:=s.Find( " [" )
						If j<>-1
							Local path:=s.Slice( 0,j )
							Local line:=Int( s.Slice( j+2,i ) )-1
							Local msg:=s.Slice( i+12 )
							path=path.Replace( ".mx2/","" )
							Local err:=New BuildError( path,line,msg )
							errors.Add( err )
						Endif
					Endif
				Next
				
			Endif
			
			OnDocumentParsed( docForParsing,parser,errors )
			
			For Local i:=0 Until dirty.Length
				If dirty[i] Then DeleteFile( dirty[i] )
			Next
			
			_parsing=False
			
			_timeDocParsed=Millisecs()
			
		End )
		
	End
	
	Function UpdateDocItems( doc:CodeDocument,parser:ICodeParser )
	
		Local items:=GetCodeItems( doc.Path,parser )
		doc.OnDocumentParsed( items,Null )
	End
	
	Function OnDocumentParsed( doc:CodeDocument,parser:ICodeParser,errors:Stack<BuildError> )
		
		If doc
			Local items:=GetCodeItems( doc.Path,parser )
			doc.OnDocumentParsed( items,GetErrors( doc.Path,errors ) )
		Endif
		
		Local docs:=docsForUpdate()
		If docs
			For Local d:=Eachin docs
				If d=doc Continue
				Local items:=GetCodeItems( d.Path,parser )
				d.OnDocumentParsed( items,GetErrors( d.Path,errors ) )
			Next
		Endif
		
	End
	
	Function GetErrors:Stack<BuildError>( path:String,errors:Stack<BuildError>)
		
		If errors.Empty Return errors
		
		Local st:=New Stack<BuildError>
		For Local i:=Eachin errors
			If i.path=path Then st.Add( i )
		Next
		Return st
	End
	
	Function GetCodeItems:Stack<CodeItem>( path:String,parser:ICodeParser )
		
		Local items:=New Stack<CodeItem>
		
		' extract all items in file
		Local list:=parser.ItemsMap[path]
		If list Then items.AddAll( list )
		
		' extensions are here too
		For Local lst:=Eachin parser.ExtraItemsMap.Values
			For Local i:=Eachin lst
				If i.FilePath=path
					If Not items.Contains( i.Parent ) Then items.Add( i.Parent )
				Endif
			Next
		Next
		
		Return items
	End
	
End
