
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
		
		Super.New( doc )
		
		_doc=doc
		
		ContentView.Style.Border=New Recti( -4,-4,4,4 )
		
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
					Local i1:=Cursor-AutoComplete.LastIdentPart.Length
					Local i2:=Cursor
					If result.byTab
						Local i:=Cursor
						While i<Text.Length And IsIdent( Text[i] )
							i+=1
						Wend
						i2=i
					Endif
					SelectText( i1,i2 )
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
	
	Method OnThemeChanged() Override
		
		_doc.HideAllPopups()
		
		Super.OnThemeChanged()
	End
	
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
		Local menu:=(event.Modifiers & Modifier.Menu)
		
		'ctrl+space - show autocomplete list
		Select event.Type
		Case EventType.KeyDown,EventType.KeyRepeat
			
			Local key:=FixNumpadKeys( event )
			
			Select key
				
'				#If __TARGET__="macos"
'				Case Key.K
'					If ctrl 
'						If shift
'							DeleteLineAtCursor()
'						Else
'							DeleteToEnd()
'						Endif
'						Return
'					Endif
'				#Endif
				
				Case Key.Space
					If ctrl
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
						
'						#If __TARGET__="macos"
'						If menu
'							DeleteToBegin()
'						Elseif ctrl
'							DeleteWordBeforeCursor()
'						Endif
'						#Else
'						If ctrl
'							If shift
'								DeleteToBegin()
'							Else
'								DeleteWordBeforeCursor()
'							Endif
'						Endif
'						#Endif
						
					Endif
				
				'Case Key.F11
				'
				'	ShowJsonDialog()
					
					
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
					Elseif ctrl
						If CanCopy Then OnCopy()
					Elseif Not alt
						' text overwrite mode
						MainWindow.OverwriteTextMode=Not MainWindow.OverwriteTextMode
					Endif
					Return
			
			
				Case Key.KeyDelete
			
					If shift 'shift+del - cut selected
						If ctrl
'							DeleteToEnd()
						Elseif CanCopy
							OnCut()
						Endif
'					Else If ctrl 'ctrl w/o shift
'						DeleteWordAfterCursor()
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
				Case Key.A 'smart Home behaviour
			
					If ctrl
						SmartHome( shift )
						Return
					Endif
			
				Case Key.E
			
					If ctrl
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
					
					CheckFormat( event )
					
					Return
			
			
				Case Key.V
			
					If CanPaste And ctrl
						SmartPaste()
						Return
					Endif
			
			
				#If __TARGET__="macos"
				
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
			
			If event.Key = Key.Space And ctrl
				If _doc.CanShowAutocomplete()
					Local ident:=IdentBeforeCursor()
					If ident Then _doc.ShowAutocomplete( ident,True )
				Endif
				Return
			Endif
			
			If CanCopy And Prefs.EditorSurroundSelection
				' surround selection 
				Local txt:=event.Text
				
				Local k1:=(txt="~q")
				Local k2:=(txt="(")
				Local k3:=(txt="[")
				
				If k1 Or k2 Or k3
					Local ins:=k1 ? "~q" Else (k2 ? ")" Else "]")
					Local i1:=Min( Anchor,Cursor )
					Local i2:=Max( Anchor,Cursor )
					ReplaceText( txt + Text.Slice( i1,i2 ) + ins )
					Return
				Endif
				
			Endif
			
			' try to auto-pair chars
			If Prefs.EditorAutoPairs
				
				Local txt:=event.Text
				
				Local k1:=(txt="~q")
				Local k2:=(txt="(")
				Local k3:=(txt="[")
				Local k21:=(txt=")")
				Local k31:=(txt="]")
				
				If k1 Or k2 Or k3 Or k21 Or k31
					
					Local s:=LineTextAtCursor
					Local p:=PosInLineAtAnchor
					
					' skip if this char is already right after cursor
					If p<s.Length
						If (k1 And s[p]=Chars.DOUBLE_QUOTE) Or (k21 And s[p]=Chars.CLOSED_ROUND_BRACKET) Or (k31 And s[p]=Chars.CLOSED_SQUARE_BRACKET)
							SelectText( Cursor+1,Cursor+1 )
							Return
						Endif
					Endif
					
					' just insert our char
					ReplaceText( txt )
					
					If k21 Or k31 Return
					
					Local skip:=False
					If k1
						skip=_doc.Parser.IsPosInsideOfQuotes( s,p )
					ElseIf k2
						'skip=p<s.Length And s[p]=Chars.CLOSED_ROUND_BRACKET
						skip=Not IsCursorAtTheEndOfLine
					Elseif k3
						skip=p<s.Length And s[p]=Chars.CLOSED_SQUARE_BRACKET
					Endif
					If Not skip ' auto-pair it
						Local ins:=k1 ? "~q" Else (k2 ? ")" Else "]")
						ReplaceText( ins )
						SelectText( Cursor-1,Cursor-1 )
					Endif
					
					Return
					
				Else
'					
'					
'					Local skip:=False
'					If k21
'						skip=p<s.Length And s[p]=Chars.CLOSED_ROUND_BRACKET
'					If k3
'						skip=p<s.Length And s[p]=Chars.CLOSED_SQUARE_BRACKET
'					Endif
'					If Not skip ' auto-pair it
'						Local ins:=k1 ? "~q" Else (k2 ? ")" Else "]")
'						ReplaceText( ins )
'						SelectText( Cursor-1,Cursor-1 )
'					Endif
					
				Endif
			
			Endif
			
		End
		
		Super.OnKeyEvent( event )
		
		CheckFormat( event )
		
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
	
End


Class CodeDocument Extends Ted2Document
	
	Method New( path:String )
		
		Super.New( path )
		
		' if file type was changed
		Renamed+=Lambda( newPath:String,oldPath:String )
			
			InitParser()
			ResetErrors()
		End
		
		_view=New DockingView
		
		' Editor
		_codeView=New CodeDocumentView( Self )
		_codeView.LineChanged += OnLineChanged
		
		_doc=_codeView.Document
		
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
		
		_doc.TextChanged+=Lambda()
		
			Dirty=True
			OnTextChanged()
			_codeView.TextChanged()
		End
		
		_codeView.CursorMoved+=OnCursorChanged
		
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
'		Monkey2Parser.OnDoneParseModules+=Lambda( deltaMs:Int )
'			UpdateCodeTree()
'		End
		
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
		
		If ident<>text And item And item.IsLikeFunc 'not a keyword
			
			Local i:=textLine.Find( "Method " ) 'to simplify overriding - insert full text
			If i <> -1 And i < cursorPosInLine
				Local i2:=textLine.Find( "(" ) 'is inside of params?
				If i2 = -1 Or i2 > cursorPosInLine
					Local ovr:=Not text.StartsWith( "New(" )
					If ovr And item.Parent And item.Parent.Kind=CodeItemKind.Interface_ Then ovr=False
					Return ovr ? text+" Override" Else text
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
		
		If Not _parsingEnabled Return
		
		Local ident:=_codeView.FullIdentAtCursor
		Local line:=TextDocument.FindLine( _codeView.Cursor )
		Local item:=_parser.ItemAtScope( ident,Path,line )
		
		If item
			Local pos:=item.ScopeStartPos
			JumpToPosition( item.FilePath,pos )
		Endif
	End
	
	Method JumpToPosition( filePath:String,pos:Vec2i )
		
		Local cur:=_codeView.CursorPos
		If pos=cur
			_codeView.MakeKeyView()
			Return
		Endif
		
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
		
		' is inside of comment?
		Local state:=TextDocument.LineState( line )
		If state & 255 <> 255 Return False
		
		Local text:=TextDocument.GetLine( line )
		Local posInLine:=_codeView.Cursor-TextDocument.StartOfLine( line )
		
		Local can:=AutoComplete.CanShow( text,posInLine,FileExtension )
		Return can
		
	End
	
	Method ShowAutocomplete( ident:String="",byCtrlSpace:Bool=False )
		
		If ident = "" Then ident=_codeView.IdentBeforeCursor()
		
		Print "ident: "+ident
		
		'show
		Local lineNum:=TextDocument.FindLine( _codeView.Cursor )
		Local lineStr:=TextDocument.GetLine( lineNum )
		Local posInLine:=_codeView.Cursor-TextDocument.StartOfLine( lineNum )
		
		If byCtrlSpace And AutoComplete.IsOpened
			AutoComplete.DisableUsingsFilter=Not AutoComplete.DisableUsingsFilter
		Endif
		
		AutoComplete.Show( ident,Path,FileExtension,lineNum,lineStr,posInLine )
		
		If Not AutoComplete.IsOpened Return
		
		Local frame:=AutoComplete.Frame
		
		Local w:=frame.Width
		Local h:=frame.Height
		
		Local cursorRect:=_codeView.CursorRect
		Local scroll:=_codeView.Scroll
		Local tvFrame:=_codeView.RenderRect
		Local yy:=tvFrame.Top+cursorRect.Top-scroll.y
		yy+=ScaledVal( 26 ) 'magic offset :)
		Local xx:=tvFrame.Left+cursorRect.Left-scroll.x'+100
		xx+=ScaledVal( 46 ) 'magic
		frame.Left=xx
		frame.Right=frame.Left+w
		frame.Top=yy
		frame.Bottom=frame.Top+h
		' fit dialog into window
		If frame.Bottom > MainWindow.RenderRect.Bottom
			Local dy:=frame.Bottom-MainWindow.RenderRect.Bottom-ScaledVal( 128 )
			frame.MoveBy( ScaledVal( 50 ),dy )
		Endif
		AutoComplete.Frame=frame
		
	End
	
	Function HideAutocomplete()
	
		AutoComplete?.Hide()
	End
	
	Function HideAllPopups()
	
		AutoComplete?.Hide()
		ParamsHint?.Hide()
	End
	
	#Rem monkeydocs Return true if ParamsHint was actually closed.
	#End
	Function HideParamsHint:Bool()
		
		If ParamsHint And ParamsHint.Visible
			ParamsHint.Hide()
			Return True
		Endif
		
		Return False
	End
	
	Method GoBack()
		
		Navigator.TryBack()
	End
	
	Method GoForward()
		
		Navigator.TryForward()
	End
	
	Method Comment()
	
		Local event:=New KeyEvent( EventType.KeyChar,_codeView,Key.Apostrophe,Key.Apostrophe,Modifier.Control,"'" )
		_codeView.OnKeyEvent( event )
	End
	
	Method Uncomment()
	
		Local event:=New KeyEvent( EventType.KeyChar,_codeView,Key.Apostrophe,Key.Apostrophe,Modifier.Control|Modifier.Shift,"'" )
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
	Field _parsingEnabled:Bool
	
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
	
		Local text:=stringio.LoadString( Path )
		
		_doc.Text=text
		Dirty=False
		
		InitParser()
		
		ParsingDoc() 'start parsing right after loading, not by timer
		
		' grab lines after load
		_doc.LinesModified+=Lambda( first:Int,removed:Int,inserted:Int )
			
			MainWindow.OnDocumentLinesModified( Self,first,removed,inserted )
		End
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		'ResetErrors()
		
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
		
		If AutoComplete.IsOpened Then AutoComplete.Hide()
		
		If Not _parsingEnabled Return
		
		OnUpdateCurrentScope()
	End
	
	Method OnUpdateCurrentScope()
		
		Local scope:=_parser.GetNearestScope( Path,_codeView.LineNumAtCursor+1,True )
		If scope
			_treeView.SelectByScope( scope )
		Endif
	End
	
	Method UpdateCodeTree()
		
		_treeView.Fill( FileExtension,Path )
		OnUpdateCurrentScope()
	End
	
	Method InitParser()
		
		_parser=ParsersManager.Get( FileExtension )
		_parsingEnabled=Not ParsersManager.IsFake( _parser )
	End
	
	Field _timeDocParsed:=0
	Field _timeTextChanged:=0
	Method ParsingOnTextChanged()
		
		If Not _parsingEnabled Return
		
		_timeTextChanged=Millisecs()
		
		If Not _timer Then _timer=New Timer( 1,Lambda()
		
			If _parsing Return
			
			Local msec:=Millisecs()
			If msec<_timeDocParsed+1000 Return
			If _timeTextChanged=0 Or msec<_timeTextChanged+1000 Return
			_timeTextChanged=0
			
			ParsingDoc()
		
		End )
		
	End
	
	Method ParsingDoc()
		
		If _parsing Return
		
		_parsing=True
		
		New Fiber( Lambda()
			
			Local dirty:=Dirty
			
			Local filePath:=Path
			If dirty
				filePath=MainWindow.AllocTmpPath( "_mx2cc_parse_",".monkey2" )
				SaveString( _doc.Text,filePath )
			Endif
			
			ParsingFile( filePath )
		
			If dirty Then DeleteFile( filePath )
			
			_parsing=False
			
			_timeDocParsed=Millisecs()
			
		End )
		
	End
	
	Method ParsingFile( pathOnDisk:String )
		
		If MainWindow.IsTerminating Return
		
		ResetErrors()
		
		Local errors:=_parser.ParseFile( Path,pathOnDisk,"" )
		
		If MainWindow.IsTerminating Return
		
		If errors
			
			If errors="#"
				Return
			Endif
			
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
		
		ParsingOnTextChanged()
		
	End
	
	Method OnCursorChanged()
		
		' try to show hint for method parameters
		
		If Not Prefs.EditorShowParamsHint Return
		
		Global _storedPos:=-1,_storedIdent:=""
		Global opts:=New ParserRequestOptions
		Global results:=New Stack<CodeItem>
		
		'If _codeView.CanCopy Print "can copy, exit" ; Return ' has selection
		
		Local line:=_codeView.LineTextAtCursor
		Local pos:=_codeView.PosInLineAtCursor
		Local lower:=line.Trim().ToLower()
		Local skip:=lower.StartsWith( "function " ) Or lower.StartsWith( "method " ) Or 
						lower.StartsWith( "operator " ) Or lower.StartsWith( "property " )
		If Not skip
			Local i1:=line.Find( "(" )
			skip=(i1<0 Or i1>=pos)
		Endif
		If skip
			ParamsHint?.Hide()
			_storedPos=-1
			Return
		Endif
		
		Local brackets:=0,quotes:=0
		Local part:ParamsPart
		Local parts:=New Stack<ParamsPart>
		
		For Local i:=0 Until pos
			Local c:=line[i]
			Select c
				Case Chars.OPENED_ROUND_BRACKET
					
					If quotes Mod 2 <> 0 Continue
					
					brackets+=1
					' skip spaces
					Local j:=i-1
					While j>=0 And line[j]<=32
						j-=1
					Wend
					j+=1
					Local pair:=GetIndentBeforePos_Mx2( line,j,True )
					Local ident:=pair.Item1
					'Print "ident: "+ident'+", paramIndex: "+paramIndex+", isNew: "+isNew
					If ident
						part=New ParamsPart
						parts.Add( part )
						part.ident=ident
						part.ranges=New Stack<Vec2i>
						part.ranges.Add( New Vec2i( i,0 ) )
						
						' check for 'New' keyword
						j=pair.Item2-1 'where ident starts
						While j>=0 And line[j]<=32
							j-=1
						Wend
						'j+=1
						Local s:=""
						While j>=0 And IsAlpha( line[j] )
							s=String.FromChar( line[j] )+s
							j-=1
						Wend
						part.isNew=(s.ToLower()="new")
					Endif
					
				Case Chars.CLOSED_ROUND_BRACKET
					
					If quotes Mod 2 <> 0 Continue
					
					brackets-=1
					If brackets>0 And brackets<parts.Length
						part=parts[brackets-1]
						Local r:=part.current
						r.y=i
						part.current=r
					Endif
					
				Case Chars.DOUBLE_QUOTE
					
					quotes+=1
					
				Case Chars.SINGLE_QUOTE 'comment char
					
					If quotes Mod 2 = 0
						Exit
					Endif
					
				Case Chars.COMMA
					
					If quotes Mod 2 = 0 And part<>Null
						Local r:=part.current
						r.y=i
						part.current=r
						r=New Vec2i( i+1,0 )
						part.ranges.Add( r )
						part.index+=1
					Endif
					
			End
		Next
		
		If brackets<=0 Or 	' outside of brackets
			part=Null 		' found brackets w/o idents - in expressions
			
			ParamsHint?.Hide()
			_storedPos=-1
			Return
		Endif
		
'		Local i:=brackets-1
'		While part And _codeView.Keywords.Contains( part.ident )
'			i-=1
'			If i>=0
'				Print "part: "+part.ident+", "+i
'				part=parts[i]
'			Else
'				Return 'exit
'			Endif
'		Wend
		
		'If ident<>_storedIdent 'Or bracketPos<>_storedPos
			
			Local ident:=part.ident
			Local paramIndex:=part.index
			Local isNew:=part.isNew
			
			_storedIdent=ident
			'_storedPos=bracketPos
			
			opts.ident=ident
			opts.filePath=Path
			opts.docLineNum=_codeView.LineNumAtCursor
			opts.docLineStr=line
			opts.docPosInLine=pos
			opts.results=results
			
			results.Clear()
			
			If isNew
				
				Local item:=_parser.GetItem( ident )
				If item Then _parser.GetConstructors( item,results )
				
			Else
				
				_parser.GetItemsForAutocomplete( opts )
				
				Local parts:=ident.Split( "." )
				Local last:=parts[parts.Length-1]
				
				Local it:=results.All()
				While Not it.AtEnd
					If it.Current.Ident<>last
						it.Erase()
					Else
						it.Bump()
					Endif
				Wend
			Endif
			
			If results.Empty
				ParamsHint?.Hide()
				_storedPos=-1
				Return
			Endif
			
			If Not ParamsHint Then ParamsHint=New ParamsHintView
			
			Local startPos:=_codeView.StartOfLineAtCursor+part.ranges[0].x
			Local r:=_codeView.CharRect( startPos )
			Local location:=r.min-_codeView.Scroll
			location.x+=80*App.Theme.Scale.x
			
			ParamsHint.Show( results,location,_codeView )
			
		'Else
		'	Print "the same"
		'Endif
		
		ParamsHint?.SetIndex( paramIndex )
	End
	
	Class ParamsPart
		
		Field ident:String
		Field ranges:=New Stack<Vec2i>
		Field index:Int
		Field isNew:Bool
		
		Property current:Vec2i()
			Return ranges[index]
		Setter( value:Vec2i )
			ranges[index]=value
		End
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

Function ScaledVal:Int( val:Int )
	
	Return val*App.Theme.Scale.x
End


Global ParamsHint:ParamsHintView

Class ParamsHintView Extends TextView

	Method New()
		
		Style=GetStyle( "ParamsHint" )
		ReadOnly=True
		Visible=False
		Layout="float"
		Gravity=New Vec2f( 0,1 )
		
		MainWindow.AddChildView( Self )
		
		OnThemeChanged()
	End
	
	Method Show( items:Stack<CodeItem>,location:Vec2i,sender:CodeTextView )
		
		Hide()
		
		_items=items
		_sender=sender
		
		Local s:=""
		For Local i:=Eachin _items
			If s Then s+="~n"
			Local params:=i.Params
			If Not params Then s+="<no params>" ; Continue
			For Local j:=0 Until params.Length
				If j>0 Then s+=", "
				s+=params[j].ToString()
			Next
		Next
		Text=s ' use it for TextView.OnMeasure
		
		Visible=True
		
		Local window:=sender.Window
		
		location=sender.TransformPointToView( location,window )
		'Local dy:=New Vec2i( 0,-10 )
		
		' fit into window area
'		Local size:=MeasureLayoutSize()
'		Local dx:=location.x+size.x-window.Bounds.Right
'		If dx>0
'			location=location-New Vec2i( dx,0 )
'		Endif
'		If location.y+size.y+dy.y>window.Bounds.Bottom
'			location=location-New Vec2i( 0,size.y )
'			'dy=-dy
'		Endif
		Offset=location'+dy
		
	End
	
	Method Hide()
		
		Visible=False
	End
	
	Method SetIndex( index:Int )
		
		_paramIndex=index
	End
	
	Private
	
	Field _items:Stack<CodeItem>
	Field _paramIndex:Int
	Field _color1:Color,_color2:Color
	Field _sender:CodeTextView
	
	Method OnRenderContent( canvas:Canvas ) Override
		
		Local stored:=canvas.Color
		
		Local x:Float,y:Float,s:=""
		Local font:=RenderStyle.Font
		For Local item:=Eachin _items
			
			Local params:=item.Params
			If Not params
				s="<no params>"
				canvas.Color=(_paramIndex=0) ? _color2 Else _color1
				canvas.DrawText( s,x,y )
			Else
				For Local i:=0 Until params.Length
					
					If i>0
						canvas.Color=_color1
						canvas.DrawText( ", ",x,y )
						x+=font.TextWidth( ", " )
					Endif
					
					s=params[i].ToString()
					canvas.Color=(i=_paramIndex) ? _color2 Else _color1
					canvas.DrawText( s,x,y )
					x+=font.TextWidth( s )
				Next
				
			Endif
			
			y+=font.Height
			x=0
		Next
		
		canvas.Color=stored
	End
	
	Method OnThemeChanged() Override
		
		_color1=App.Theme.GetColor( "params-hint-common" )
		_color2=App.Theme.GetColor( "params-hint-selected" )
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		If event.Type=EventType.MouseDown
			
'			Print App.MouseLocation
'			Local me:=New MouseEvent( event.Type,_sender,App.MouseLocation,event.Button,event.Wheel,event.Modifiers,event.Clicks )
'			CodeTextView_Bridge.OnContentMouseEvent( _sender,me )
			
			Hide()
		Endif
		
	End
	
End

'Class CodeTextView_Bridge Extends CodeTextView Final
'	
'	Function OnContentMouseEvent( view:CodeTextView,event:MouseEvent )
'		
'		view.OnContentMouseEvent( event )
'	End
'	
'End
