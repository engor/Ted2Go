
Namespace ted2go


#Rem monkeydoc Add file extensions to open with CodeDocument.
All plugins with keywords should use this func inside of them OnCreate() callback.
#End
Function RegisterCodeExtensions( exts:String[] )
	
	Local plugs:=Plugin.PluginsOfType<CodeDocumentType>()
	If plugs = Null Return
	Local p:=plugs[0]
	CodeDocumentTypeBridge.AddExtensions( p,exts )
	
End


Function DrawCurvedLine( canvas:Canvas,x1:Float,x2:Float,y:Float )
	
	Local i:=0
	Local dx:=3,dy:=1
	For Local xx:=x1 Until x2 Step dx*2
		'Local dy := (i Mod 2 = 0) ? -1 Else 1
		canvas.DrawLine( xx,y+dy,xx+dx,y-dy )
		canvas.DrawLine( xx+dx,y-dy,xx+dx*2,y+dy )
	Next
	
End


Class CodeDocumentView Extends Ted2CodeTextView
	
	
	Method New( doc:CodeDocument )
	
		_doc=doc
		
		Document=_doc.TextDocument
		
		ContentView.Style.Border=New Recti( -4,-4,4,4 )
		
		'very important to set FileType for init
		'formatter, highlighter and keywords
		FileType=doc.FileExtension
		FilePath=doc.Path
		
		'AutoComplete
		If Not AutoComplete Then AutoComplete=New AutocompleteDialog
		AutoComplete.OnChoosen+=Lambda( result:AutocompleteResult )
			If App.KeyView = Self
				
				Local ident:=result.ident
				Local text:=result.text
				
				If result.isTemplate
					
					InsertLiveTemplate( AutoComplete.LastIdentPart,text )
					
				Else
					
					Local item:=result.item
					Local bySpace:=result.bySpace
					
					text=_doc.PrepareForInsert( ident,text,Not bySpace,LineTextAtCursor,PosInLineAtCursor,item )
					SelectText( Cursor,Cursor-AutoComplete.LastIdentPart.Length )
					ReplaceText( text )
				Endif
			Endif
		End
		
		UpdateThemeColors()
		UpdatePrefs()
	End
	
	Property Gutter:CodeGutterView()
		Return _gutter
	End
	
	Property CharsToShowAutoComplete:Int()
		
		Return Prefs.AcShowAfter
	End
	
	Method UpdatePrefs()
		
		ShowWhiteSpaces=Prefs.EditorShowWhiteSpaces
		
		Local visible:Bool
		
		'gutter view
		visible=Prefs.EditorGutterVisible
		If visible
			If Not _gutter
				_gutter=New CodeGutterView( _doc )
				AddView( _gutter,"left" )
			Endif
		Endif
		If _gutter Then _gutter.Visible=visible
		
		'codemap view
		visible=Prefs.EditorCodeMapVisible
		If visible
			If Not _codeMap
				_codeMap=New CodeMapView( Self )
				AddView( _codeMap,"right" )
			Endif
		Endif
		If _codeMap Then _codeMap.Visible=visible
		
		_doc.ArrangeElements()
	End
	

	Protected
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		Local color:=canvas.Color
		Local xx:=Scroll.x
		' whole current line
		Local r:=CursorRect
		r.Left=xx
		r.Right=Width
		canvas.Color=_lineColor
		canvas.DrawRect( r )
		
		If _doc._debugLine<>-1
			
			Local line:=_doc._debugLine
			'If line<0 Or line>=Document.NumLines Return
			
			canvas.Color=New Color( 0,.5,0 )
			canvas.DrawRect( xx,line*LineHeight,Width,LineHeight )
			
		Endif
		
		canvas.Color=color
		
		Super.OnRenderContent( canvas )
		
		If _doc._errors.Length
		
			canvas.Color=Color.Red
			For Local err:=Eachin _doc._errors
				Local s:=Document.GetLine( err.line )
				Local indent:=Utils.GetIndent( s )
				Local indentStr:=(indent > 0) ? s.Slice( 0, indent ) Else ""
				If indent > 0 Then s=s.Slice(indent)
				Local x:=RenderStyle.Font.TextWidth( indentStr )*TabStop
				Local w:=RenderStyle.Font.TextWidth( s )
				DrawCurvedLine( canvas,x,x+w,(err.line+1)*LineHeight )
			Next
			
		Endif
		
	End
	
	Field _arrAddonIndents:=New String[]("else","for ","method ","function ","class ","interface ","select ","try ","catch ","case ","default","while","repeat","property ","getter","setter","enum ","struct ")
	Field _arrIf:=New String[]("then "," return"," exit"," continue")
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		_doc.HideHint_()
		
		Local alt:=(event.Modifiers & Modifier.Alt)
		Local ctrl:=(event.Modifiers & Modifier.Control)
		Local shift:=(event.Modifiers & Modifier.Shift)
		
		'ctrl+space - show autocomplete list
		Select event.Type
		Case EventType.KeyDown,EventType.KeyRepeat
			
			Local key:=event.Key
			
			'map keypad nav keys...
			If Not (event.Modifiers & Modifier.NumLock)
				Select key
				Case Key.Keypad1 key=Key.KeyEnd
				Case Key.Keypad2 key=Key.Down
				Case Key.Keypad3 key=Key.PageDown
				Case Key.Keypad4 key=Key.Left
				Case Key.Keypad6 key=Key.Right
				Case Key.Keypad7 key=Key.Home
				Case Key.Keypad8 key=Key.Up
				Case Key.Keypad9 key=Key.PageUp
				Case Key.Keypad0 key=Key.Insert
				End
			Endif
			
			Select key
			
				Case Key.Space
					If event.Modifiers & Modifier.Control
						Return
					'Else
					'	if AutoComplete.IsOpened And Prefs.AcUseSpace Return
					Endif
				
				Case Key.Backspace
					
					If AutoComplete.IsOpened
						Local ident:=IdentBeforeCursor()
						ident=ident.Slice( 0,ident.Length-1 )
						If ident.Length > 0
							_doc.ShowAutocomplete( ident )
						Else
							_doc.HideAutocomplete()
						Endif
						
					Else
						
						#If __TARGET__="macos"
						If ctrl
							DeleteLineAtCursor()
						Endif
						#Endif
						
					Endif
				
				Case Key.F11
				
					ShowJsonDialog()
					
					
				#If __TARGET__="windows"
				Case Key.E 'delete whole line
					If ctrl
						DeleteLineAtCursor()
						Return
					Endif
				#Endif
			
			
				Case Key.X
			
					If ctrl 'nothing selected - cut whole line
						OnCut( Not CanCopy )
						Return
					Endif
			
			
				Case Key.C
			
					If ctrl 'nothing selected - copy whole line
						OnCopy( Not CanCopy )
						Return
					Endif
			
			
				Case Key.Insert 'ctrl+insert - copy, shift+insert - paste
			
					If shift
						SmartPaste()
					Elseif ctrl And CanCopy
						OnCopy()
					Endif
					Return
			
			
				Case Key.KeyDelete
			
					If shift 'shift+del - cut selected
						If CanCopy Then OnCut()
					Else
						If Anchor = Cursor
							Local len:=Text.Length
							If Cursor < len
								Local ends:=Cursor+1
								If Text[Cursor] = 10 ' do we delete \n ?
									Local i:=Cursor+1
									While i<len And Text[i]<32 And Text[i]<>10
										i+=1
									Wend
									ends=i
								Endif
								SelectText( Cursor,ends )
								ReplaceText( "" )
							Endif
						Else
							ReplaceText( "" )
						Endif
					Endif
					Return
			
			
				Case Key.Enter,Key.KeypadEnter 'auto indent
			
					If _typing Then DoFormat( False )
			
					Local line:=CursorLine
					Local text:=Document.GetLine( line )
					Local indent:=GetIndent( text )
					Local posInLine:=PosInLineAtCursor
					'fix 'bug' when we delete ~n at the end of line.
					'in this case GetLine return 2 lines, and if they empty
					'then we get double indent
					'need to fix inside mojox
			
					Local beforeIndent:=(posInLine<=indent)
			
					If indent > posInLine Then indent=posInLine
			
					Local s:=(indent ? text.Slice( 0,indent ) Else "")
			
					' auto indentation
					If Prefs.EditorAutoIndent And Not beforeIndent
						text=text.Trim().ToLower()
						If text.StartsWith( "if" )
							If Not Utils.BatchContains( text,_arrIf,True )
								s="~t"+s
							Endif
						Elseif Utils.BatchStartsWith( text,_arrAddonIndents,True )
							
							If text.ToLower().EndsWith( "abstract" )
								' nothing
							Else
								Local scope:=_doc.Parser.GetScope( FilePath,LineNumAtCursor )
								If scope And scope.Kind=CodeItemKind.Interface_
									' nothing
								Else
									s="~t"+s
								Endif
							Endif
						Endif
					Endif
			
					ReplaceText( "~n"+s )
			
					Return
			
				#If __TARGET__="macos"
				Case Key.Left 'smart Home behaviour
			
					If event.Modifiers & Modifier.Menu
						SmartHome( shift )
						Return
					Endif
			
				Case Key.Right
			
					If event.Modifiers & Modifier.Menu
						SmartEnd( shift )
						Return
					Endif
			
				Case Key.Up '
			
					If event.Modifiers & Modifier.Menu
						If shift 'selection
							SelectText( 0,Anchor )
						Else
							SelectText( 0,0 )
						Endif
						Return
					Endif
			
				Case Key.Down '
			
					If event.Modifiers & Modifier.Menu
						If shift 'selection
							SelectText( Anchor,Text.Length )
						Else
							SelectText( Text.Length,Text.Length )
						Endif
						Return
					Endif
			
				#Else
			
				Case Key.Home 'smart Home behaviour
			
					If ctrl
						If shift 'selection
							SelectText( 0,Anchor )
						Else
							SelectText( 0,0 )
						Endif
					Else
						SmartHome( shift )
					Endif
					Return
				#Endif
			
				Case Key.Tab
			
					If Cursor = Anchor 'has no selection
			
						' live templates by tab!
						Local ident:=IdentBeforeCursor()
						If InsertLiveTemplate( ident ) Return
						
						' usual tab behaviour
						If Not shift
							ReplaceText( "~t" )
						Else
							If Cursor > 0 And Document.Text[Cursor-1]=Chars.TAB
								SelectText( Cursor-1,Cursor )
								ReplaceText( "" )
							Endif
						Endif
			
					Else 'block tab/untab
			
						Local minPos:=Min( Cursor,Anchor )
						Local maxPos:=Max( Cursor,Anchor )
						Local min:=Document.FindLine( minPos )
						Local max:=Document.FindLine( maxPos )
			
						' if we are at the beginning of bottom line - skip it
						Local strt:=Document.StartOfLine( max )
						If maxPos = strt
							max-=1
						Endif
			
						Local lines:=New StringStack
			
						For Local i:=min To max
							lines.Push( Document.GetLine( i ) )
						Next
			
						Local go:=True
						Local shiftFirst:=0,shiftLast:=0
			
						If shift
			
							Local changes:=0
							For Local i:=0 Until lines.Length
								If lines[i].StartsWith( "~t" )
									lines[i]=lines[i].Slice( 1 )+"~n"
									changes+=1
									If i=0 Then shiftFirst=-1
									if i=lines.Length-1 Then shiftLast=-1
								Else
									lines[i]+="~n"
								Endif
							Next
			
							go=(changes > 0)
						Else
							shiftFirst=1
							shiftLast=1
							For Local i:=0 Until lines.Length
								lines[i]="~t"+lines[i]+"~n"
							Next
						Endif
			
						If go
							Local minStart:=Document.StartOfLine( min )
							Local maxStart:=Document.StartOfLine( max )
							Local maxEnd:=Document.EndOfLine( max )
			
							Local p1:=minPos+shiftFirst 'absolute pos
							Local p2:=maxPos-maxStart+shiftLast 'pos in line
							SelectText( minStart,maxEnd+1 )
							ReplaceText( lines.Join( "" ) )
							p2+=Document.StartOfLine( max )
							' case when cursor is between tabs and we move both of them, so jump to prev line
							p1=Max( p1,Document.StartOfLine( min ) )
							SelectText( p1,p2 )
						Endif
			
					Endif
					Return
			
			
				Case Key.Up,Key.Down
			
					DoFormat( True )
			
			
				Case Key.V
			
					If CanPaste And ctrl
						SmartPaste()
						Return
					Endif
			
			
				Case Key.Insert
			
					If CanPaste And shift
						SmartPaste()
						Return
					Endif
			
				Case Key.KeyDelete
			
					If shift
						OnCut()
						Return
					Endif
			
				#If __TARGET__="macos"
				'smart Home behaviour
				Case Key.Left
			
					If event.Modifiers & Modifier.Menu
						SmartHome( True )
			
						Return
					Endif
			
			
				Case Key.Right
			
					If event.Modifiers & Modifier.Menu
						SmartHome( False )
			
						Return
					Endif
			
				Case Key.Z
			
					If event.Modifiers & Modifier.Menu
			
						If shift
							Redo()
						Else
							Undo()
						Endif
						Return
					Endif
			
				#Endif
			
			End
			
				
		Case EventType.KeyChar
			
			If event.Key = Key.Space And event.Modifiers & Modifier.Control
				If _doc.CanShowAutocomplete()
					Local ident:=IdentBeforeCursor()
					If ident Then _doc.ShowAutocomplete( ident,True )
				Endif
				Return
			Endif
			
		End
		
		Super.OnKeyEvent( event )
		
		'show autocomplete list after some typed chars
		If event.Type = EventType.KeyChar
		
			If _doc.CanShowAutocomplete()
				'preprocessor
				If event.Text = "#"
					_doc.ShowAutocomplete( "#" )
				Else
					Local ident:=IdentBeforeCursor()
					If ident.Length >= CharsToShowAutoComplete
						_doc.ShowAutocomplete( ident )
					Else
						_doc.HideAutocomplete()
					Endif
				Endif
			Endif
		Endif
		
		' after super processed
		If event.Type = EventType.KeyDown
		
			Select event.Key
			
				Case Key.Left
					If AutoComplete.IsOpened And Not alt
						Local ident:=IdentBeforeCursor()
						If ident Then _doc.ShowAutocomplete( ident ) Else _doc.HideAutocomplete()
					Endif
					
				Case Key.Right
					If AutoComplete.IsOpened And Not alt
						Local ident:=IdentBeforeCursor()
						If ident Then _doc.ShowAutocomplete( ident ) Else _doc.HideAutocomplete()
					Endif
			End
		
		Endif
		
		' text overwrite mode
		If event.Key=Key.Insert And Not (shift Or ctrl Or alt)
			
			MainWindow.OverwriteTextMode=Not MainWindow.OverwriteTextMode
		Endif
		
	End
	
	Method ShowJsonDialog()
	
		New Fiber( Lambda()
		
			Local cmd:="~q"+MainWindow.Mx2ccPath+"~q makeapp -parse -geninfo ~q"+_doc.Path+"~q"
			
			Local str:=LoadString( "process::"+cmd )
			Local i:=str.Find( "{" )
			If i=-1 Return
			str=str.Slice( i )
			
			Local jobj:=JsonObject.Parse( str )
			If Not jobj Return
			
			Local jsonTree:=New JsonTreeView( jobj )
			
			Local dock:=New DockingView
			dock.ContentView=jsonTree
			Local tv:=New TextView
			tv.MaxSize=New Vec2i( 512,480 )
			tv.WordWrap=True
			tv.Text=str
			dock.AddView( tv,"bottom",200,True )
			
			
			Local dialog:=New Dialog( "ParseInfo",dock )
			dialog.AddAction( "Close" ).Triggered=dialog.Close
			dialog.MinSize=New Vec2i( 512,600 )
			
			dialog.Open()
		
		End )
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Select event.Type
			
			Case EventType.MouseClick
				
				_doc.HideAutocomplete()
			
			Case EventType.MouseMove
				
				'Print "mouse: "+event.Location
				
				If _doc.HasErrors
					Local line:=LineAtPoint( event.Location )
					Local s:=Document.GetLine( line )
					Local indent:=Utils.GetIndent( s )
					Local indentStr:=(indent > 0) ? s.Slice( 0, indent ) Else ""
					If indent > 0 Then s=s.Slice(indent)
					Local x:=RenderStyle.Font.TextWidth( indentStr )*TabStop
					Local w:=RenderStyle.Font.TextWidth( s )
					If event.Location.x >= x And event.Location.x <= x+w
						Local s:=_doc.GetStringError( line )
						If s <> Null
							_doc.ShowHint_( s,event.Location )
						Else
							_doc.HideHint_()
						Endif
					Else
						_doc.HideHint_()
					Endif
				Endif
				
		End
		
		Super.OnContentMouseEvent( event )
		
	End
	
	Private
	
	Field _doc:CodeDocument
	Field _prevErrorLine:Int
	Field _lineColor:Color
	Field _gutter:CodeGutterView
	Field _codeMap:CodeMapView
	
	Method UpdateThemeColors() Override
		
		Super.UpdateThemeColors()
		
		_lineColor=App.Theme.GetColor( "textview-cursor-line" )
		
		Local newFont:Font
		Local fontPath:=Prefs.GetCustomFontPath()
		If fontPath
			Local size:=Prefs.GetCustomFontSize()
			newFont=App.Theme.OpenFont( fontPath,size )
		Endif
		If Not newFont Then newFont=App.Theme.GetStyle( Style.Name ).Font
		
		RenderStyle.Font=newFont
	End
	
	Method InsertLiveTemplate:Bool( ident:String,templ:String=Null )
		
		If Not templ Then templ=LiveTemplates[FileType,ident]
		If templ
			templ=PrepareSmartPaste( templ )
			Local start:=Cursor-ident.Length
			Local cursorOffset:=templ.Find( "${Cursor}" )
			If cursorOffset <> -1 Then templ=templ.Replace( "${Cursor}","" )
			SelectText( start,Cursor )
			ReplaceText( templ )
			If cursorOffset <> -1 Then SelectText( start+cursorOffset,start+cursorOffset )
			Return True
		Endif
		
		Return False
	End
	
	Method DeleteLineAtCursor()
		
		Local line:=Document.FindLine( Cursor )
		SelectText( Document.StartOfLine( line ),Document.EndOfLine( line )+1 )
		ReplaceText( "" )
	End
	
End


Class CodeDocument Extends Ted2Document
	
	Method New( path:String )
		
		Super.New( path )
	
		_doc=New TextDocument
		
		_doc.LinesModified+=Lambda( first:Int,removed:Int,inserted:Int )
		
			Local put:=0
			For Local get:=0 Until _errors.Length
				Local err:=_errors[get]
				If err.line>=first
					If err.line<first+removed 
						err.removed=True
						Continue
					Endif
					err.line+=(inserted-removed)
				Endif
				_errors[put]=err
				put+=1
			Next
			_errors.Resize( put )
			
			' also move debug line
			If _debugLine>=first
				_debugLine+=(inserted-removed)
			Endif
		End

		_view=New DockingView
		
		' Editor
		_codeView=New CodeDocumentView( Self )
		_codeView.LineChanged += OnLineChanged
		
		_doc.TextChanged+=Lambda()
			Dirty=True
			OnTextChanged()
			_codeView.TextChanged()
		End
		
		' bar + editor
		_content=New DockingView
		_content.ContentView=_codeView
		
		_view.ContentView=_content
		
		OnCreateBrowser()
		
		' process navigation back / forward
		Navigator.OnNavigate += Lambda( nav:NavCode )
		
			MainWindow.GotoCodePosition( nav.filePath,nav.pos )
		End
		
		' update 
		Monkey2Parser.OnDoneParseModules+=Lambda( deltaMs:Int )
			UpdateCodeTree()
		End
		
		ArrangeElements()
	End
	
	Method ArrangeElements()
		
		If Not _content Return
		
		_content.RemoveView( _toolBar )
		
		If Prefs.EditorToolBarVisible
			_toolBar=GetToolBar()
			_content.AddView( _toolBar,"top" )
		Endif
		
	End
	
	Method OnCreateBrowser:View() Override
		
		If _browserView Return _browserView
			
		' sorting toolbar
		_browserView=New DockingView
		
		Local bar:=New ToolBarExt
		bar.Style=App.Theme.GetStyle( "SourceToolBar" )
		bar.MaxSize=New Vec2i( 10000,30 )
		Local btn:ToolButtonExt
		
		btn = bar.AddIconicButton( ThemeImages.Get( "sourcebar/sort_alpha.png" ),
			Lambda()
			End,
			"Sort by type")
		btn.ToggleMode=True
		btn.IsToggled=Prefs.SourceSortByType
		btn.Toggled+=Lambda( state:Bool )
			' true - sort by alpha, false - sort by source
			Prefs.SourceSortByType=state
			_treeView.SortByType=state
			UpdateCodeTree()
		End
		btn = bar.AddIconicButton( ThemeImages.Get( "sourcebar/filter_inherited.png" ),
			Lambda()
			End,
			"Show inherited members")
		btn.ToggleMode=True
		btn.IsToggled=Prefs.SourceShowInherited
		btn.Toggled+=Lambda( state:Bool )
			Prefs.SourceShowInherited=state
			_treeView.ShowInherited=state
			UpdateCodeTree()
		End
		_browserView.AddView( bar,"top" )
		
		
		
		_treeView=New CodeTreeView
		_browserView.ContentView=_treeView
		
		_treeView.SortByType=Prefs.SourceSortByType
		_treeView.ShowInherited=Prefs.SourceShowInherited
		
		' goto item from tree view
		_treeView.NodeClicked+=Lambda( node:TreeView.Node )
		
			Local codeNode:=Cast<CodeTreeNode>( node )
			Local item:=codeNode.CodeItem
			JumpToPosition( item.FilePath,item.ScopeStartPos )
			
		End
		
		Return _browserView
	End
	
	' not multipurpose method, need to move into plugin
	Method PrepareForInsert:String( ident:String,text:String,addSpace:Bool,textLine:String,cursorPosInLine:Int,item:CodeItem )
		
		If FileExtension <> ".monkey2" Return ident
		
		If ident <> text And item And item.IsLikeFunc 'not a keyword
			
			Local i:=textLine.Find( "Method " ) 'to simplify overriding - insert full text
			If i <> -1 And i < cursorPosInLine
				Local i2:=textLine.Find( "(" ) 'is inside of params?
				If i2 = -1 Or i2 > cursorPosInLine
					Return text.StartsWith( "New(" ) ? text Else text+" Override"
				Endif
			Endif
			
			If cursorPosInLine = textLine.Length
				If text.EndsWith( "()" ) Return ident+"()"
				If text.EndsWith( ")" ) Return ident+"("
			Endif
			
			Return ident
		Endif
		
		If ident="Cast" Return ident+"<"
		If ident="Typeof" Return ident+"("
		
		' ---------------------------------------------------------
		' try to auto-add properly lambda definition
		' ---------------------------------------------------------
		If ident="Lambda"
			
			Local indent:=Utils.GetIndent( textLine )
			Local result:=text+"()"
			
			textLine=textLine.Trim()
			
			If Not textLine.StartsWith( "'" )
				
				Local i0:=textLine.Find( "(" )
				
				If i0 = -1 'don't process func params yet
					Local i1:=textLine.Find( "=" )
					Local i2:=textLine.Find( "+=" )
					If i1 <> -1
						If i2 <> -1 And i2 < i1 Then i1=i2
						Local s:=textLine.Slice( 0,i1 ).Trim()
						s=Utils.GetIndentBeforePos( s,s.Length )
						
						Local item:=_parser.ItemAtScope( s,Path,_codeView.LineNumAtCursor )
						If item
							' strip ident
							s=item.Text.Slice( item.Ident.Length )
							' and add some formatting
							s=s.Replace( " ","" )
							If s<>"()" 'if have params
								s=s.Replace( "(","( " )
								s=s.Replace( ")"," )" )
							Endif
							result="Lambda"+s
						Endif
					Endif
				Endif
			Endif
			
			result+="~n"+Utils.RepeatStr( "~t",indent+1 )+"~n"
			result+=Utils.RepeatStr( "~t",indent )+"End"
			Return result
		Endif
		
		If Not addSpace Return ident
		
		Select ident
			
			' try to add space
			Case "Namespace","Using","Import","New","Eachin","Where","Alias","Const","Local","Global","Field","Method","Function","Property","Operator ","Enum","Class","Interface","Struct","Extends","Implements","If","Then","Elseif","While","Until","For","To","Step","Select","Case","Catch","Throw","Print"
			
				Local len:=textLine.Length
				
				' end or line
				If cursorPosInLine >= len-1 Then Return ident+" "
				
				If textLine[cursorPosInLine] <> Chars.SPACE
					Return ident+" "
				Endif
			
		End
		
		Return ident 'as is
	End
	
	Property TextDocument:TextDocument()
	
		Return _doc
	End
	
	Property DebugLine:Int()
	
		Return _debugLine
	
	Setter( debugLine:Int )
		If debugLine=_debugLine Return
		
		_debugLine=debugLine
		If _debugLine=-1 Return
		
		_codeView.GotoLine( _debugLine )
	End
	
	Property Errors:Stack<BuildError>()
	
		Return _errors
	End
	
	Property HasErrors:Bool()
		Return Not _errors.Empty
	End
	
	Property Parser:ICodeParser()
	
		Return _parser
	End
	
	Method HasErrorAt:Bool( line:Int )
	
		Return _errMap.Contains( line )
	End
	
	Method AddError( error:BuildError )
	
		_errors.Push(error)
		Local s:=_errMap[error.line]
		s = (s <> Null) ? s+error.msg Else error.msg
		_errMap[error.line]=s
	End
	
	Method GetStringError:String( line:Int )
		Return _errMap[line]
	End
	
	Method ResetErrors()
		_errors.Clear()
		_errMap.Clear()
	End
	
	Method ShowHint_( text:String, position:Vec2i )
	
		position+=New Vec2i(10,10)-TextView.Scroll
		
		ShowHint( text,position,TextView )
	End
	
	Method HideHint_()
		
		HideHint()
	End
	
	Method GotoDeclaration()
	
		Local ident:=_codeView.FullIdentAtCursor()
		Local line:=TextDocument.FindLine( _codeView.Cursor )
		Local item:=_parser.ItemAtScope( ident,Path,line )
		Print "go decl: "+ident
		If item
			Print "item found"
			Local pos:=item.ScopeStartPos
			JumpToPosition( item.FilePath,pos )
		Endif
	End
	
	Method JumpToPosition( filePath:String,pos:Vec2i )
		
		Local cur:=_codeView.CursorPos
		If pos=cur Return
		
		' store navOp
		Local nav:=New NavCode
		nav.pos=cur
		nav.filePath=Path
		Navigator.Push( nav ) 'push current pos
		
		nav=New NavCode
		nav.pos=pos
		nav.filePath=filePath
		Navigator.Navigate( nav ) 'and navigate to new pos
	End
	
	Method CanShowAutocomplete:Bool()
		
		If Not Prefs.AcEnabled Return False
		
		Local line:=TextDocument.FindLine( _codeView.Cursor )
		Local text:=TextDocument.GetLine( line )
		Local posInLine:=_codeView.Cursor-TextDocument.StartOfLine( line )
		
		Local can:=AutoComplete.CanShow( text,posInLine,FileExtension )
		Return can
		
	End
	
	Method ShowAutocomplete( ident:String="",byCtrlSpace:Bool=False )
		
		If ident = "" Then ident=_codeView.IdentBeforeCursor()
		
		'show
		Local line:=TextDocument.FindLine( _codeView.Cursor )
		
		If byCtrlSpace And AutoComplete.IsOpened
			AutoComplete.DisableUsingsFilter=Not AutoComplete.DisableUsingsFilter
		Endif
		
		AutoComplete.Show( ident,Path,FileExtension,line )
		
		If Not AutoComplete.IsOpened Return
		
		Local frame:=AutoComplete.Frame
		
		Local w:=frame.Width
		Local h:=frame.Height
		
		Local cursorRect:=_codeView.CursorRect
		Local scroll:=_codeView.Scroll
		Local tvFrame:=_codeView.RenderRect
		Local yy:=tvFrame.Top+cursorRect.Top-scroll.y
		yy+=30 'magic offset :)
		Local xx:=tvFrame.Left+cursorRect.Left-scroll.x'+100
		xx+=46 'magic
		frame.Left=xx
		frame.Right=frame.Left+w
		frame.Top=yy
		frame.Bottom=frame.Top+h
		' fit dialog into window
		If frame.Bottom > MainWindow.RenderRect.Bottom
			
			Local dy:=frame.Bottom-MainWindow.RenderRect.Bottom-128
			frame.Top+=dy
			frame.Bottom+=dy
			frame.Left+=50
			frame.Right+=50
		Endif
		AutoComplete.Frame=frame
		
	End
	
	Function HideAutocomplete()
		AutoComplete.Hide()
	End
	
	Method GoBack()
		
		Navigator.TryBack()
	End
	
	Method GoForward()
		
		Navigator.TryForward()
	End
	
	Method Comment()
	
		Local event:=New KeyEvent( EventType.KeyDown,_codeView,Key.Apostrophe,Key.Apostrophe,Modifier.Control,"" )
		_codeView.OnKeyEvent( event )
	End
	
	Method Uncomment()
	
		Local event:=New KeyEvent( EventType.KeyDown,_codeView,Key.Apostrophe,Key.Apostrophe,Modifier.Control|Modifier.Shift,"" )
		_codeView.OnKeyEvent( event )
	End
	
	Property CodeView:CodeDocumentView()
		Return _codeView
	End
	
	Protected
	
	Method OnGetTextView:TextView( view:View ) Override
	
		Return _codeView
	End
	
	Private

	Field _doc:TextDocument

	Field _view:DockingView
	Field _codeView:CodeDocumentView
	Field _treeView:CodeTreeView
	Field _browserView:DockingView
	
	Field _errors:=New Stack<BuildError>
	Field _errMap:=New IntMap<String>
	
	Field _debugLine:Int=-1
	Field _parsing:Bool
	Field _timer:Timer
	Field _parser:ICodeParser
	Field _prevLine:=-1
	Field _prevScope:CodeItem
	
	Field _toolBar:ToolBarExt
	Field _content:DockingView
	
	Method GetToolBar:ToolBarExt()
		
		If _toolBar Return _toolBar
		
		Local commentTitle:=GetActionTextWithShortcut( MainWindow.GetActionComment() )
		Local uncommentTitle:=GetActionTextWithShortcut( MainWindow.GetActionUncomment() )
		Local findTitle:=GetActionTextWithShortcut( MainWindow.GetActionFind() )
		
		' Toolbar
		
		Local bar:=New ToolBarExt
		_toolBar=bar
		bar.Style=App.Theme.GetStyle( "EditorToolBar" )
		bar.MaxSize=New Vec2i( 10000,30 )
		bar.AddSeparator()
		bar.AddSeparator()
		bar.AddSeparator()
		bar.AddSeparator()
	
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/find_selection.png" ),
			Lambda()
				OnFindSelection()
			End,
			findTitle )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/find_previous.png" ),
			Lambda()
				OnFindPrev()
			End,
			"Find previous (Shift+F3)" )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/find_next.png" ),
			Lambda()
				OnFindNext()
			End,
			"Find next (F3)" )
		bar.AddSeparator()
		#Rem
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/previous_bookmark.png" ),
			Lambda()
				OnPrevBookmark()
			End,
			"Prev bookmark (Ctrl+,)" )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/next_bookmark.png" ),
			Lambda()
				OnNextBookmark()
			End,
			"Next bookmark (Ctrl+.)" )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/toggle_bookmark.png" ),
			Lambda()
				OnToggleBookmark()
			End,
			"Toggle bookmark (Ctrl+M)" )
		bar.AddSeparator()
		#End
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/shift_left.png" ),
			Lambda()
				OnShiftLeft()
			End,
			"Shift left (Shift+Tab)" )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/shift_right.png" ),
			Lambda()
				OnShiftRight()
			End,
			"Shift right (Tab)" )
		bar.AddSeparator()
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/comment.png" ),
			Lambda()
				Comment()
			End,
			commentTitle )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/uncomment.png" ),
			Lambda()
				Uncomment()
			End,
			uncommentTitle )
		
		Return _toolBar
	End
	
	Method OnLoad:Bool() Override
	
		_parser=ParsersManager.Get( FileExtension )
	
		Local text:=stringio.LoadString( Path )
		
		_doc.Text=text
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		ResetErrors()
		
		Local text:=_doc.Text
		
		Local ok:=stringio.SaveString( text,Path )
	
		Return ok
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method OnClose() Override
		
		If _timer Then _timer.Cancel()
	End
	
	Method OnLineChanged:Void( prevLine:Int,newLine:Int )
	
		Local scope:=_parser.GetScope( Path,_codeView.LineNumAtCursor+1 )	
		If scope And scope <> _prevScope
			Local classs := (_prevScope And scope.IsLikeClass And scope = _prevScope.Parent)
			_prevScope = scope
			If classs Return 'don't select parent class scope if we are inside of it
			_treeView.SelectByScope( scope )
			_prevScope = scope
		Endif
		
		If AutoComplete.IsOpened Then AutoComplete.Hide()
	End
	
	Method UpdateCodeTree()
		
		_treeView.Fill( FileExtension,Path )
	End
	
	Method BgParsing( pathOnDisk:String )
		
		If MainWindow.IsTerminating Return
		
		ResetErrors()
		
		Local errors:=_parser.ParseFile( Path,pathOnDisk,False )
		
		If MainWindow.IsTerminating Return
		
		If errors
			
			Local arr:=errors.Split( "~n" )
			For Local s:=Eachin arr
				Local i:=s.Find( "] : Error : " )
				If i<>-1
					Local j:=s.Find( " [" )
					If j<>-1
						Local path:=s.Slice( 0,j )
						Local line:=Int( s.Slice( j+2,i ) )-1
						Local msg:=s.Slice( i+12 )
						
						Local err:=New BuildError( path,line,msg )
					
						AddError( err )
						
					Endif
				Endif
			Next
			
			Return ' exit when errors
		Endif
		
		UpdateCodeTree()
		
	End
	
	Method OnTextChanged()
		
		' catch for common operations
		
		
		' -----------------------------------
		' catch for parsing
		
		If FileExtension <> ".monkey2" Return

		
		If _timer _timer.Cancel()
		
		_timer=New Timer( 1,Lambda()
		
			If _parsing Return
			
			_parsing=True
			
			New Fiber( Lambda()
			
				Local tmp:=MainWindow.AllocTmpPath( "_mx2cc_parse_",".monkey2" )
				Local file:=StripDir( Path )
				'Print "parsing:"+file+" ("+tmp+")"
				
				SaveString( _doc.Text,tmp )
			
				BgParsing( tmp )
				
				'Print "finished:"+file
				
				DeleteFile( tmp )
				
				_timer.Cancel()
				
				_timer=Null
				_parsing=False
				
			End )
		End )
		
	End
	
	Method OnFindSelection()
		MainWindow.OnFind()
	End
	
	Method OnFindPrev()
		MainWindow.OnFindPrev()
	End
	
	Method OnFindNext()
		MainWindow.OnFindNext()
	End
	
	Method OnPrevBookmark()
		Alert( "Not implemented yet." )
	End
	
	Method OnNextBookmark()
		Alert( "Not implemented yet." )
	End
	
	Method OnToggleBookmark()
		Alert( "Not implemented yet." )
	End
	
	Method OnShiftLeft()
		
		Local event:=New KeyEvent( EventType.KeyDown,_codeView,Key.Tab,Key.Tab,Modifier.Shift,"~t" )
		_codeView.OnKeyEvent( event )
	End
	
	Method OnShiftRight()
		
		Local event:=New KeyEvent( EventType.KeyDown,_codeView,Key.Tab,Key.Tab,Modifier.None,"~t" )
		_codeView.OnKeyEvent( event )
	End
				
End



Class CodeDocumentType Extends Ted2DocumentType

	Property Name:String() Override
		Return "CodeDocumentType"
	End
	
	Protected
	
	Method New()
		AddPlugin( Self )
		
		'Extensions=New String[]( ".monkey2",".cpp",".h",".hpp",".hxx",".c",".cxx",".m",".mm",".s",".asm",".html",".js",".css",".php",".md",".xml",".ini",".sh",".bat",".glsl" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override

		Return New CodeDocument( path )
	End
	
		
	Private
	
	Global _instance:=New CodeDocumentType
	
End


Class CodeItemIcons
	
	Function GetIcon:Image( item:CodeItem )
	
		If Not _icons Then InitIcons()
		
		Local key:String
		Local kind:=item.KindStr
		
		Select kind
			Case "const","interface","lambda","local","alias","operator","inherited"
				key=kind
			Case "param"
				key="*"
			Default
				Local type:=item.Type
				If (kind="field" Or kind="global") And type<>Null And type.IsLikeFunc
					key="field_func"
				Else
					If item.Ident.ToLower() = "new" Then kind="constructor"
					key=kind+"_"+item.AccessStr
				Endif
		End
		
		Local ic:=_icons[key]
		If ic = Null Then ic=_iconDefault
		
		Return ic
		
	End

	Function GetKeywordsIcon:Image()
	
		If Not _icons Then InitIcons()
		Return _icons["keyword"]
	End
	
	Function GetIcon:Image(key:String)
	
		If Not _icons Then InitIcons()
		Return _icons[key]
	End

	Private

	Global _icons:Map<String,Image>
	Global _iconDefault:Image
	
	Function Load:Image( name:String )
		
		Return ThemeImages.Get( "codeicons/"+name )
	End
	
	Function InitIcons()
	
		_icons = New Map<String,Image>
		
		_icons["constructor_public"]=Load( "constructor.png" )
		_icons["constructor_private"]=Load( "constructor_private.png" )
		_icons["constructor_protected"]=Load( "constructor_protected.png" )
		
		_icons["function_public"]=Load( "method_static.png" )
		_icons["function_private"]=Load( "method_static_private.png" )
		_icons["function_protected"]=Load( "method_static_protected.png" )
		
		_icons["property_public"]=Load( "property.png" )
		_icons["property_private"]=Load( "property_private.png" )
		_icons["property_protected"]=Load( "property_protected.png" )
		
		_icons["method_public"]=Load( "method.png" )
		_icons["method_private"]=Load( "method_private.png" )
		_icons["method_protected"]=Load( "method_protected.png" )
		
		_icons["lambda"]=Load( "annotation.png" )
		
		_icons["class_public"]=Load( "class.png" )
		_icons["class_private"]=Load( "class_private.png" )
		_icons["class_protected"]=Load( "class_protected.png" )
		
		_icons["enum_public"]=Load( "enum.png" )
		_icons["enum_private"]=Load( "enum_private.png" )
		_icons["enum_protected"]=Load( "enum_protected.png" )
		
		_icons["struct_public"]=Load( "struct.png" )
		_icons["struct_private"]=Load( "struct_private.png" )
		_icons["struct_protected"]=Load( "struct_protected.png" )
		
		_icons["interface"]=Load( "interface.png" )
		
		_icons["field_public"]=Load( "field.png" )
		_icons["field_private"]=Load( "field_private.png" )
		_icons["field_protected"]=Load( "field_protected.png" )
		
		_icons["global_public"]=Load( "field_static.png" )
		_icons["global_private"]=Load( "field_static_private.png" )
		_icons["global_protected"]=Load( "field_static_protected.png" )
		
		_icons["field_func"]=Load( "field_func.png" )
		
		_icons["const"]=Load( "const.png" )
		_icons["local"]=Load( "local.png" )
		_icons["keyword"]=Load( "keyword.png" )
		_icons["alias"]=Load( "alias.png" )
		_icons["operator"]=Load( "operator.png" )
		_icons["error"]=Load( "error.png" )
		_icons["warning"]=Load( "warning.png" )
		_icons["inherited"]=Load( "class.png" )
				
		_iconDefault=Load( "other.png" ) 
		
	End
	
End


Class NavOps<T>
	
	Field OnNavigate:Void( target:T )
		
	Method Navigate( value:T )
		
		Push( value )
		
		OnNavigate( value )
	End
	
	Method Push( value:T )
		
		' remove all forwarded
		While _index<_count-1
			_items.Pop()
			_count-=1
		Wend
		
		' the same current value
		If _count > 0 And _items[_count-1] = value Return
		
		_items.Push( value )
		_index+=1
		_count+=1
	End
	
	Method TryBack()
		
		_index-=1
		If _index<0
			_index=0
			Return
		Endif
		Local value:=_items[_index]

		OnNavigate( value )
	End
	
	Method TryForward()
		
		_index+=1
		If _index>=_count
			_index=_count-1
			Return
		Endif
		Local value:=_items[_index]

		OnNavigate( value )
	End
	
	Property Current:T()
	
		Return _index>=0 ? _items[_index] Else Null
	End
	
	Property Empty:Bool()
	
		Return _index=-1
	End
	
	Method Clear()
	
		_items.Clear()
		_index=-1
		_count=0
	End
	
	Private
	
	Field _index:=-1,_count:Int
	Field _items:=New Stack<T>
	
End


' global, to go through all docs
Global Navigator:=New NavOps<NavCode>



Private

Global AutoComplete:AutocompleteDialog


Class CodeDocumentTypeBridge Extends CodeDocumentType
	
	Function AddExtensions( inst:CodeDocumentType,exts:String[] )
		inst.AddExtensions( exts )
	End
	
End


Class NavCode

	Field pos:Vec2i
	Field filePath:String
	
	Operator =:Bool(value:NavCode)
		Return pos=value.pos And filePath=value.filePath
	End
	
End

