
Namespace ted2go


Class FindActions

	Field find:Action
	Field findNext:Action
	field findPrevious:Action
	Field replace:Action
	Field replaceAll:Action
	Field findInFiles:Action
	Field findAllInFiles:Action
	
	Method New( docs:DocumentManager,projView:ProjectView,findConsole:TreeViewExt )
		
		_docs=docs
		_findConsole=findConsole
		_projView=projView
		
		find=New Action( "Find / Replace..." )
		find.Triggered=OnFind
		find.HotKey=Key.F
		find.HotKeyModifiers=Modifier.Menu
		
		findNext=New Action( "Find next" )
		findNext.Triggered=Lambda()
			OnFindNext()
		End
		findNext.HotKey=Key.F3
		
		findPrevious=New Action( "Find previous" )
		findPrevious.Triggered=OnFindPrevious
		findPrevious.HotKey=Key.F3
		findPrevious.HotKeyModifiers=Modifier.Shift
		
		replace=New Action( "Replace" )
		replace.Triggered=OnReplace
		
		replaceAll=New Action( "Replace all" )
		replaceAll.Triggered=OnReplaceAll
		
		findInFiles=New Action( "Find in files..." )
		findInFiles.Triggered=Lambda()
			OnFindInFiles()
		End
		findInFiles.HotKey=Key.F
		findInFiles.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		
		findAllInFiles=New Action( "Find all" )
		findAllInFiles.Triggered=OnFindAllInFiles
		
		_findDialog=New FindDialog( Self )
		_findInFilesDialog=New FindInFilesDialog( Self,projView )
	End
	
	Method Update()
	
		Local tv:=_docs.CurrentTextView
		findNext.Enabled=tv
		findPrevious.Enabled=tv
		replace.Enabled=tv
		replaceAll.Enabled=tv
	End
	
	Method FindByTextChanged( entireProject:Bool )
		
		If Not entireProject Then OnFindNext( False )
	End
	
	Method FindInFiles( folder:String )
	
		OnFindInFiles( folder )
	End
	
	
	Private
	
	Const NXT:=1
	Const PREV:=-1
	
	Field _docs:DocumentManager
	
	Field _findDialog:FindDialog
	Field _findInFilesDialog:FindInFilesDialog
	Field _findConsole:TreeViewExt
	Field _cursorPos:=0
	Field _projView:ProjectView
	
	Method OnFind()
		
		Local tv:=_docs.CurrentTextView
		If tv <> Null
			_cursorPos=Min( tv.Cursor,tv.Anchor )
			Local s:=""
			If tv.Cursor <> tv.Anchor
				Local min:=Min( tv.Cursor,tv.Anchor )
				Local max:=Max( tv.Cursor,tv.Anchor )
				s=tv.Text.Slice( min,max )
			Endif
			_findDialog.SetInitialText( s )
		Endif
		
		_findDialog.Show()
	End
	
	Method OnFindInFiles( folder:String=Null )
	
		Local tv:=_docs.CurrentTextView
		If tv <> Null
			If tv.Cursor <> tv.Anchor
				Local min:=Min( tv.Cursor,tv.Anchor )
				Local max:=Max( tv.Cursor,tv.Anchor )
				Local s:=tv.Text.Slice( min,max )
				_findInFilesDialog.SetInitialText( s )
			Endif
		Endif
		
		_findInFilesDialog.CustomFolder=folder
		_findInFilesDialog.Show()
	End
	
	Field _storedTextView:TextView
	Field _storedWhat:String
	Field _storedCaseSens:Bool
	Field _storedEntireProject:Bool
	Field _results:Stack<FileJumpData>
	Field _resultIndex:Int=-1
	Field _storedChanges:=0,_changesCounter:=0
	Field _storedLastCursor:=-1
	
	Method OnTextChanged()
		
		_changesCounter+=1
	End
	
	Method OnCursorChanged()
		
		Local tv:=_docs.CurrentTextView
		If tv
			_cursorPos=Min( tv.Cursor,tv.Anchor )
		Endif
	End
	
	Method OnFindNext( changeCursorPos:Bool=True )
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return
		
		Local doc:=_docs.CurrentDocument
		
		tv.Document.TextChanged-=OnTextChanged
		tv.Document.TextChanged+=OnTextChanged
		
		tv.CursorMoved-=OnCursorChanged
		tv.CursorMoved+=OnCursorChanged
		
		Local what:=_findDialog.FindText
		If Not what Return
		
		Local sens:=_findDialog.CaseSensitive
		
		If Not sens
			what=what.ToLower()
		Endif
		
		Local entire:=_findDialog.EntireProject
		
		' when typing request word we should everytime find from current cursor
		Local cursor:=_cursorPos
		If changeCursorPos
			cursor=Min( tv.Anchor,tv.Cursor )
			_cursorPos=cursor
		Endif
		
		Local theSame:=(what=_storedWhat And sens=_storedCaseSens And entire=_storedEntireProject)
		theSame = theSame And _storedChanges=_changesCounter
		
		If Not entire Then theSame=theSame And tv=_storedTextView
		
		_storedWhat=what
		_storedTextView=tv
		_storedCaseSens=sens
		_storedEntireProject=entire
		_storedChanges=_changesCounter
		
		If Not theSame Then _results=Null
		
		If Not _results
			
			_resultIndex=-1
			_storedLastCursor=-1
			
			' start new search
			If entire
				
				New Fiber( Lambda()
				
					Local proj:=""
					For Local p:=Eachin _projView.OpenProjects
						If doc.Path.Contains( p )
							proj=p
							Exit
						Endif
					End
					Local map:=FindInProject( what,proj,sens )
					If map
						CreateResultTree( _findConsole.RootNode,map,what,proj )
						MainWindow.ShowFindResults()
					Endif
					
					If Not map.Empty
						
						_results=New Stack<FileJumpData>
						
						' make current opened document as a first results
						Local curPath:=_docs.CurrentDocument ? _docs.CurrentDocument.Path Else ""
						If curPath
							Local vals:=map[curPath]
							If vals
								_results.AddAll( vals )
								map.Remove( curPath )
							Endif
						Endif
						
						For Local items:=Eachin map.Values
							_results.AddAll( items )
						End
						
					Endif
					
					Jump( NXT )
				End )
				
				Return
				
			Else
				
				_results=FindInFile( doc.Path,what,sens,tv.Document )
				
			Endif
			
		Endif
		
		Jump( NXT )
		
	End
	
	Method Jump( nxtOrPrev:Int )
		
		If Not _results Or _results.Length=0 Return
		
		If nxtOrPrev=NXT
			_resultIndex=(_resultIndex+1) Mod _results.Length
		Else
			_resultIndex-=1
			If _resultIndex<0 Then _resultIndex=_results.Length-1
		Endif
		
		Local jump:=_results[_resultIndex]
		
		If _storedEntireProject
			MainWindow.OpenDocument( jump.path )
		Endif
	
		Local tv:=_docs.CurrentTextView
		If tv
			Local i:=FixResultIndexByCursor( _docs.CurrentDocument,_resultIndex,nxtOrPrev )
			If i<>_resultIndex
				_resultIndex=i
				jump=_results[_resultIndex]
			Endif
			tv.SelectText( jump.pos,jump.pos+jump.len )
			_storedLastCursor=Min( tv.Cursor,tv.Anchor )
		Endif
	
	End
	
	Method FixResultIndexByCursor:Int( doc:Ted2Document,index:Int,nxtOrPrev:Int )
		
		Local tv:=doc.TextView
		Local theSameDoc:=(tv=_storedTextView)
		Local cursor:=Min( tv.Cursor,tv.Anchor )
		Local findFromCursor:=(theSameDoc And cursor<>_storedLastCursor)
		
		If Not findFromCursor Return index
		
		' take the first result accordingly to cursor
		If nxtOrPrev=NXT
			For Local i:=0 Until _results.Length
				Local jump:=_results[i]
				If jump.path=doc.Path And jump.pos>=cursor Return i
			Next
			Return 0
		Else
			For Local i:=_results.Length-1 To 0 Step -1
				Local jump:=_results[i]
				If jump.path=doc.Path And jump.pos<=cursor Return i
			Next
			Return _results.Length-1
		Endif
	End
	
	Method OnFindPrevious()
		
		Jump( PREV )
	End
	
	Method OnFindAllInFiles()
	
		If Not _findInFilesDialog.FindText
			ShowMessage( "","Please, enter text to find what." )
			Return
		Endif
		
		If Not _findInFilesDialog.SelectedProject
			ShowMessage( "","Please, select project in the list." )
			Return
		Endif
		
		'_findInFilesDialog.Hide()
		MainWindow.ShowFindResults()
		
		New Fiber( Lambda()
		
			Local what:=_findInFilesDialog.FindText
			Local proj:=_findInFilesDialog.SelectedProject
			Local sens:=_findInFilesDialog.CaseSensitive
			Local filter:=_findInFilesDialog.FilterText
			
			Local result:=FindInProject( what,proj,sens,filter )
			
			If result Then CreateResultTree( _findConsole.RootNode,result,what,proj )
		End)
		
	End
	
	Const DEFAULT_FILES_FILTER:="monkey2" ',txt,htm,html,h,cpp,json,xml,ini"
	
	Method FindInProject:StringMap<Stack<FileJumpData>>( what:String,projectPath:String,caseSensitive:Bool,filesFilter:String=DEFAULT_FILES_FILTER )
		
		If Not filesFilter Then filesFilter=DEFAULT_FILES_FILTER
		
		Local exts:=filesFilter.Split( "," )
		
		projectPath+="/"
		
		If Not caseSensitive Then what=what.ToLower()
		
		Local files:=New Stack<String>
		Utils.GetAllFiles( projectPath,exts,files )
		Local len:=what.Length
		
		Local result:=New StringMap<Stack<FileJumpData>>
		
		'Local counter:=1
		Local doc:=New TextDocument 'use it to get line number
		For Local f:=Eachin files
		
			Local text:=LoadString( f )
		
			If Not caseSensitive Then text=text.ToLower()
		
			doc.Text=text 'any needed replacing is here (\r\n -> \n)
			text=doc.Text
		
			Local i:=0
			Local items:=New Stack<FileJumpData>
			
			Repeat
				i=text.Find( what,i )
				If i=-1 Exit
				
				Local data:=New FileJumpData
				data.path=f
				data.pos=i
				data.len=len
				data.line=doc.FindLine( i )+1
				
				items.Add( data )
				
				i+=len
			Forever
			
			If Not items.Empty Then result[f]=items
			
			'If counter Mod 10 = 0
			'	' process 10 files per frame to save app responsibility
			'	App.WaitIdle()
			'Endif
			
		Next
		
		Return result
	End
	
	Method FindInFile:Stack<FileJumpData>( filePath:String,what:String,caseSensitive:Bool,doc:TextDocument=Null )
	
		Local len:=what.Length
		Local text:String
		
		If Not doc
			doc=New TextDocument
			text=LoadString( filePath )
			doc.Text=text 'any needed replacing is here (\r\n -> \n)
		Endif
		text=doc.Text
		If Not caseSensitive Then text=text.ToLower()
		
		Local i:=0
		Local result:=New Stack<FileJumpData>
		
		Repeat
			i=text.Find( what,i )
			If i=-1 Exit

			Local data:=New FileJumpData
			data.path=filePath
			data.pos=i
			data.len=len
			data.line=doc.FindLine( i )+1

			result.Add( data )

			i+=len
		Forever

		Return result
	End
	
	Method CreateResultTree( root:TreeView.Node,map:StringMap<Stack<FileJumpData>>,what:String,projectPath:String )
		
		root.RemoveAllChildren()
		
		root.Text="Results for '"+what+"'"
		
		Local subRoot:TreeView.Node
		
		For Local file:=Eachin map.Keys
			
			Local items:=map[file]
			
			subRoot=New TreeView.Node( file.Replace( projectPath+"/","" )+" ("+items.Length+")",root )
	
			For Local d:=Eachin items
				Local node:=New NodeWithData<FileJumpData>( " at line "+d.line,subRoot )
				node.data=d
			Next
		
		Next
		
		If root.NumChildren=0 Then New TreeView.Node( "not found :(",root )
		
		root.Expanded=True
		
	End
	
	Method OnReplace()
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return
		
		Local text:=_findDialog.FindText
		If Not text Return
		
		Local min:=Min( tv.Anchor,tv.Cursor )
		Local max:=Max( tv.Anchor,tv.Cursor )
		
		Local tvtext:=tv.Text.Slice( min,max )

		If Not _findDialog.CaseSensitive
			tvtext=tvtext.ToLower()
			text=text.ToLower()
		Endif
		
		If tvtext<>text Return
		
		tv.ReplaceText( _findDialog.ReplaceText )
		
		OnFindNext()

	End
	
	Method OnReplaceAll()
	
		Local tv:=_docs.CurrentTextView
		If Not tv Return
		
		Local text:=_findDialog.FindText
		If Not text Return
		
		Local rtext:=_findDialog.ReplaceText
		
		Local tvtext:=tv.Text

		If Not _findDialog.CaseSensitive
			tvtext=tvtext.ToLower()
			text=text.ToLower()
		Endif
		
		Local anchor:=tv.Anchor
		Local cursor:=tv.Cursor
		
		Local i:=0,t:=0
		Repeat
		
			i=tvtext.Find( text,i )
			If i=-1 Exit
			
			tv.SelectText( i+t,i+text.Length+t )
			tv.ReplaceText( rtext )
			
			t+=rtext.Length-text.Length
			i+=text.Length
			
		Forever
		
		tv.SelectText( anchor,cursor )
		
	End
	
End
