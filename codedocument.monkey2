
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
		
		AddView( New CodeGutterView( _doc ),"left" )

		'very important to set FileType for init
		'formatter, highlighter and keywords
		FileType=doc.FileType
		FilePath=doc.Path
		
		'AutoComplete
		If AutoComplete = Null Then AutoComplete=New AutocompleteDialog( "" )
		AutoComplete.OnChoosen+=Lambda( text:String )
			If App.KeyView = Self
				
				text = _doc.PrepareForInsert( text,LineTextAtCursor,PosInLineAtCursor )
				
				SelectText( Cursor,Cursor-AutoComplete.LastIdentPart.Length )
				ReplaceText( text )
			Endif
		End
		
	End
	
	Property CharsToShowAutoComplete:Int()
		Return 2
	End
	
	Protected
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		Local color:=canvas.Color
		
		If _doc._debugLine<>-1

			Local line:=_doc._debugLine
			If line<0 Or line>=Document.NumLines Return
			
			canvas.Color=New Color( 0,.5,0 )
			canvas.DrawRect( 0,line*LineHeight,Width,LineHeight )
			
		Endif
		
		canvas.Color=color
		
		Super.OnRenderContent( canvas )
		
		If _doc._errors.Length
		
			canvas.Color=New Color( 1,0,0 )
			
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
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		_doc.HideHint_()
		
		Local alt:=(event.Modifiers & Modifier.Alt)
		
		'ctrl+space - show autocomplete list
		If event.Type = EventType.KeyDown
			
			Select event.Key
				
				Case Key.Space
					If event.Modifiers & Modifier.Control
						Return
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
					Endif
				
				Case Key.Left
					If alt 
						_doc.GoBack()
						Return
					Else
						If AutoComplete.IsOpened
							_doc.ShowAutocomplete()
						Endif
					Endif
					
				Case Key.Right
					If alt
						_doc.GoForward()
						Return
					Else
						If AutoComplete.IsOpened
							Local ident:=IdentBeforeCursor()
							If ident Then _doc.ShowAutocomplete() Else _doc.HideAutocomplete()
						Endif
					Endif
				
				Case Key.F11
				
					ShowJsonDialog()
			End
				
		Elseif event.Type = EventType.KeyChar
			
			If event.Key = Key.Space And event.Modifiers & Modifier.Control
				If _doc.CanShowAutocomplete()
					Local ident:=IdentBeforeCursor()
					If ident Then _doc.ShowAutocomplete()
				Endif
				Return
			Endif
		Endif
		
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
						If ident
							_doc.ShowAutocomplete( ident )
						Else
							_doc.HideAutocomplete()
						Endif
					Endif
					
				Case Key.Right
					If AutoComplete.IsOpened And Not alt
						_doc.ShowAutocomplete()
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
	
End


Class CodeDocument Extends Ted2Document

	
	
	Method New( path:String )
		Super.New( path )
	
		_doc=New TextDocument
		
		_doc.TextChanged+=Lambda()
			Dirty=True
			OnTextChanged()
		End
		
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
		End

		_view=New DockingView
				
		' Editor
		_codeView=New CodeDocumentView( Self )
		_codeView.LineChanged += Lambda( prev:Int,cur:Int )
			If AutoComplete.IsOpened Then AutoComplete.Hide()
		End
				
		' Toolbar
		Local bar:=New ToolBarExt
		bar.Style=App.Theme.GetStyle( "EditorToolBar" )
		bar.MaxSize=New Vec2i( 10000,30 )
		bar.AddSeparator()
		bar.AddSeparator()
		bar.AddSeparator()
		bar.AddSeparator()
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/back.png" ),
			Lambda()
				GoBack()
			End,
			"Navigate back (Alt+Left)" )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/forward.png" ),
			Lambda()
				GoForward()
			End,
			"Navigate forward (Alt+Right)" )
		bar.AddSeparator()
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/find_selection.png" ),
			Lambda()
				OnFindSelection()
			End,
			"Find selection (Ctrl+F)" )
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
				OnComment()
			End,
			"Comment (Ctrl+')" )
		bar.AddIconicButton(
			ThemeImages.Get( "editorbar/uncomment.png" ),
			Lambda()
				OnUncomment()
			End,
			"Uncomment (Shift+Ctrl+')" )
			
				
		' bar + editor
		Local docker:=New DockingView
		docker.AddView( bar,"top" )
		docker.ContentView=_codeView
		
		_view.ContentView=docker
		
		OnCreateBrowser()
		
		' process navigation back / forward
		Navigator.OnNavigate += Lambda( nav:NavCode )
		
			MainWindow.GotoCodePosition( nav.filePath,nav.pos )
		End
		
	End
	
	Method OnCreateBrowser:View() Override
		
		' CodeTree
		If Not _treeView
			
			_treeView=New CodeTreeView
			_treeView.SortEnabled=True
			
			' goto item from tree view
			_treeView.NodeClicked+=Lambda( node:TreeView.Node )
			
				Local codeNode:=Cast<CodeTreeNode>( node )
				Local item:=codeNode.CodeItem
				Local pos:=item.ScopeStartPos
				
				JumpToPosition( Path,pos )
				
			End
		Endif
		
		Return _treeView
	End
	
	' not multipurpose method, need to move into plugin
	Method PrepareForInsert:String( word:String,textLine:String,cursorPosInLine:Int )
		
		If FileType <> ".monkey2" Return word
		
		Select word
			
			' try to add space
			Case "Namespace","Using","Import","New","Eachin","Where","Alias","Const","Local","Global","Field","Method","Function","Property","Operator ","Enum","Class","Interface","Struct","Extends","Implements","If","Then","Elseif","While","Until","For","To","Step","Select","Case","Catch","Throw","Print"
			
				Local len:=textLine.Length
				Print len+","+cursorPosInLine+","+textLine
				' end or line
				If cursorPosInLine >= len-1 Then Return word+" "
				
				If textLine[cursorPosInLine] <> Chars.SPACE
					Return word+" "
				Endif
			
			
			' try to add <
			Case "Cast"
			
				Return word+"<"
			
			
			' try to add (
			Case "Typeof"
			
				Return word+"("
				
		End
		
		Return word 'as is
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
	
		Local ident:=_codeView.FullIdentUnderCursor()
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
		
		Local line:=TextDocument.FindLine( _codeView.Cursor )
		Local text:=TextDocument.GetLine( line )
		Local posInLine:=_codeView.Cursor-TextDocument.StartOfLine( line )
		
		Local can:=AutoComplete.CanShow( text,posInLine,FileType )
		Return can
		
	End
	
	Method ShowAutocomplete( ident:String="" )
		'check ident
		If ident = "" Then ident=_codeView.IdentBeforeCursor()
		
		'show
		Local line:=TextDocument.FindLine( _codeView.Cursor )
		AutoComplete.Show( ident,Path,FileType,line )
		
		If Not AutoComplete.IsOpened Return
		
		Local frame:=AutoComplete.Frame
		
		Local w:=frame.Width
		Local h:=frame.Height
		
		Local cursorRect:=_codeView.CursorRect
		Local scroll:=_codeView.Scroll
		Local tvFrame:=_codeView.Frame
		frame.Left=tvFrame.Left-scroll.x+cursorRect.Left+100
		frame.Right=frame.Left+w
		frame.Top=cursorRect.Top-scroll.y
		frame.Bottom=frame.Top+h
		' fit dialog into window
		If frame.Bottom > tvFrame.Bottom
			Local dy:=frame.Bottom-tvFrame.Bottom+5
			frame.Top-=dy
			frame.Bottom-=dy
		Endif
		AutoComplete.Frame=frame
		
	End
	
	Method HideAutocomplete()
		AutoComplete.Hide()
	End
	
	Method GoBack()
		
		Navigator.TryBack()
	End
	
	Method GoForward()
		
		Navigator.TryForward()
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
	
	Field _errors:=New Stack<BuildError>
	Field _errMap:=New IntMap<String>
	
	Field _debugLine:Int=-1
	Field _parsing:Bool
	Field _timer:Timer
	Field _parser:ICodeParser
	Field _prevLine:=-1
	
	' global, to go through all docs
	Global _navOps:=New NavOps<NavCode>
	
	Property Navigator:NavOps<NavCode>()
		Return _navOps
	End
	
	Method OnLoad:Bool() Override
	
		_parser=ParsersManager.Get( FileType )
	
		Local text:=stringio.LoadString( Path )
		
		_doc.Text=text
		
		'code parser
		'ParseSources( Path )
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		ResetErrors()
		
		Local text:=_doc.Text
		
		Local ok:=stringio.SaveString( text,Path )
	
		'code parser - reparse
		'ParseSources( Path )
		
		Return ok
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method UpdateCodeTree()
		
		_treeView.Fill( FileType,Path )
	End
	
	Method BgParsing( pathOnDisk:String )
		
		ResetErrors()
		
		Local errors:=_parser.ParseFile( Path,pathOnDisk )
		
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
		
		' nothing yet
		
		
		' catch for parsing
		
		If FileType <> ".monkey2" Return
		
		If _timer _timer.Cancel()
		
		_timer=New Timer( 1,Lambda()
		
			If _parsing Return
			
			_parsing=True
			
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
	
	Method OnComment()
		
		Local event:=New KeyEvent( EventType.KeyDown,_codeView,Key.Apostrophe,Key.Apostrophe,Modifier.Control,"" )
		_codeView.OnKeyEvent( event )
	End
	
	Method OnUncomment()
		
		Local event:=New KeyEvent( EventType.KeyDown,_codeView,Key.Apostrophe,Key.Apostrophe,Modifier.Control|Modifier.Shift,"" )
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
			Case "const","interface","lambda","local","alias","operator"
				key=kind
			Case "param"
				key="*"
			'Case "
			Default
				If item.Ident.ToLower() = "new"
					kind="constructor"
				Endif
				key=kind+"_"+item.AccessStr
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
		
		_icons["const"]=Load( "const.png" )
		_icons["local"]=Load( "local.png" )
		_icons["keyword"]=Load( "keyword.png" )
		_icons["alias"]=Load( "alias.png" )
		_icons["operator"]=Load( "operator.png" )
		_icons["error"]=Load( "error.png" )
		_icons["warning"]=Load( "warning.png" )
				
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

