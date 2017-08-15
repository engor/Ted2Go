
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
		findInFiles.Triggered=OnFindInFiles
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
	
	
	Private
	
	Field _docs:DocumentManager
	
	Field _findDialog:FindDialog
	Field _findInFilesDialog:FindInFilesDialog
	Field _findConsole:TreeViewExt
	Field _cursorPos:=0
	Field _projView:ProjectView
	
	Method OnFind()
		
		_findDialog.Show()
		
		Local tv:=_docs.CurrentTextView
		If tv <> Null
			If tv.Cursor <> tv.Anchor
				Local min:=Min( tv.Cursor,tv.Anchor )
				Local max:=Max( tv.Cursor,tv.Anchor )
				Local s:=tv.Text.Slice( min,max )
				_findDialog.SetInitialText( s )
			Endif
			_cursorPos=Min( tv.Cursor,tv.Anchor )
		Endif
	End
	
	Method OnFindInFiles()
	
		_findInFilesDialog.Show()
	
		Local tv:=_docs.CurrentTextView
		If tv <> Null
			If tv.Cursor <> tv.Anchor
				Local min:=Min( tv.Cursor,tv.Anchor )
				Local max:=Max( tv.Cursor,tv.Anchor )
				Local s:=tv.Text.Slice( min,max )
				_findInFilesDialog.SetInitialText( s )
			Endif
		Endif
	End
	
	Field _storedTextView:TextView
	Field _storedWhat:String
	Field _storedCaseSens:Bool
	Field _storedEntireProject:Bool
	Field _results:Stack<FileJumpData>
	Field _resultIndex:Int=-1
	
	Method OnFindNext( changeCursorPos:Bool=True )
	
		Local doc:=_docs.CurrentDocument
		If Not doc Return
		
		Local tv:=doc.TextView
		If Not tv Return
		
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
			cursor=Max( tv.Anchor,tv.Cursor )
			_cursorPos=cursor
		Endif
		
		Local theSame:=(what=_storedWhat And sens=_storedCaseSens And entire=_storedEntireProject)
		
		If Not entire Then theSame=theSame And tv=_storedTextView
		
		_storedWhat=what
		_storedTextView=tv
		_storedCaseSens=sens
		_storedEntireProject=entire
		
		If Not theSame Then _results=Null
		
		If _results
			' use current search results
			If Not _results.Empty
				_resultIndex=(_resultIndex+1) Mod _results.Length
			Endif
			
		Else
			
			_resultIndex=-1
			
			' start new search
			If entire
				
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
					_resultIndex=0
				Endif
				
			Else
				
				_results=FindInFile( "",what,sens,tv.Document )
				
				If Not _results.Empty
					' take the first result accordingly to cursor
					For Local i:=0 Until _results.Length
						Local jump:=_results[i]
						If jump.pos>=cursor
							_resultIndex=i
							Exit
						Endif
					Next
					If _resultIndex=-1 Then _resultIndex=0 ' take from top of doc
				Endif
				
			Endif
			
		Endif
		
		If _resultIndex>=0
			
			Local jump:=_results[_resultIndex]
			
			If _storedEntireProject
				MainWindow.OpenDocument( jump.path )
				tv=_docs.CurrentTextView
			Endif
			
			If tv Then tv.SelectText( jump.pos,jump.pos+jump.len )
			
		Endif
		
	End
	
	Method OnFindPrevious()
		
		If _resultIndex>=0
			
			Local tv:=_docs.CurrentTextView
			If Not tv Return
			
			_resultIndex-=1
			If _resultIndex<0 Then _resultIndex=_results.Length-1
			
			Local jump:=_results[_resultIndex]
			
			If _storedEntireProject
				MainWindow.OpenDocument( jump.path )
				tv=_docs.CurrentTextView
			Endif
			
			If tv Then tv.SelectText( jump.pos,jump.pos+jump.len )
			
		Endif
	
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
		
		_findInFilesDialog.Hide()
		MainWindow.ShowFindResults()
		
		App.Idle+=Lambda()
			
			New Fiber( Lambda()
			
				Local what:=_findInFilesDialog.FindText
				Local proj:=_findInFilesDialog.SelectedProject
				Local sens:=_findInFilesDialog.CaseSensitive
				Local filter:=_findInFilesDialog.FilterText
				
				Local result:=FindInProject( what,proj,sens,filter )
				
				If result Then CreateResultTree( _findConsole.RootNode,result,what,proj )
			End)
		End
		
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
