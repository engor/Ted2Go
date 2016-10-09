
Namespace ted2go


#Rem monkeydoc Add file extensions to open with CodeDocument.
All plugins with keywords should use this func inside of them OnCreate() callback.
#End
Function RegisterCodeExtensions(exts:String[])
	
	Local plugs := Plugin.PluginsOfType<CodeDocumentType>()
	If plugs = Null Return
	Local p := plugs[0]
	CodeDocumentTypeBridge.AddExtensions(p, exts)
	 
End


Class CodeDocumentView Extends Ted2CodeTextView

	Method New( doc:CodeDocument )
	
		_doc=doc
		
		Document=_doc.TextDocument
		
		ContentView.Style.Border=New Recti( -4,-4,4,4 )
		
		AddView( New GutterView( Self ),"left" )

		'very important to set FileType for init
		'formatter, highlighter and keywords
		FileType = doc.FileType
		FilePath = doc.Path
		
		'AutoComplete
		If AutoComplete = Null Then AutoComplete = New AutocompleteDialog("")
		AutoComplete.OnChoosen += Lambda(text:String)
			If App.KeyView = Self
				SelectText(Cursor,Cursor-AutoComplete.LastIdentPart.Length)
				ReplaceText(text)
			Endif
		End
			
	End
	
	Property CharsToShowAutoComplete:Int()
		Return 2
	End
	
	Protected
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		Local color:=canvas.Color
		
		If _doc._errors.Length
		
			canvas.Color=New Color( .5,0,0 )
			
			For Local err:=Eachin _doc._errors
				canvas.DrawRect( 0,err.line*LineHeight,Width,LineHeight )
			Next
			
		Endif
		
		If _doc._debugLine<>-1

			Local line:=_doc._debugLine
			If line<0 Or line>=Document.NumLines Return
			
			canvas.Color=New Color( 0,.5,0 )
			canvas.DrawRect( 0,line*LineHeight,Width,LineHeight )
			
		Endif
		
		canvas.Color=color
		
		Super.OnRenderContent( canvas )
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		'ctrl+space - show autocomplete list
		If event.Type = EventType.KeyDown
			Select event.Key
			Case Key.Space
				If event.Modifiers & Modifier.Control
					Return
				Endif
			Case Key.Backspace
				If AutoComplete.IsOpened
					Local ident := IdentBeforeCursor()
					ident = ident.Slice(0,ident.Length-1)
					If ident.Length > 0
						ShowAutocomplete(ident)
					Else
						HideAutocomplete()
					Endif
				Endif
			End
			
		Elseif event.Type = EventType.KeyChar And event.Key = Key.Space And event.Modifiers & Modifier.Control
			If CanShowAutocomplete()
				ShowAutocomplete()
			Endif
			Return
		Endif
				
		Super.OnKeyEvent( event )
		
		'show autocomplete list after some typed chars
		If event.Type = EventType.KeyChar
			If CanShowAutocomplete()
				'preprocessor
				If event.Text = "#"
					ShowAutocomplete("#")
				Else
					Local ident := IdentBeforeCursor()
					If ident.Length >= CharsToShowAutoComplete
						ShowAutocomplete(ident)
					Else
						HideAutocomplete()
					Endif
				Endif
			Endif
		Endif
		
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Select event.Type
			Case EventType.MouseClick
				HideAutocomplete()
		End
		
		Super.OnContentMouseEvent(event)
		
	End
	
	
	Private
	
	Method CanShowAutocomplete:Bool()
		
		Local line := Document.FindLine(Cursor)
		Local text := Document.GetLine(line)
		Local posInLine := Cursor-Document.StartOfLine(line)
		
		Local can := AutoComplete.CanShow(text, posInLine, FileType)
		Return can
		
	End
	
	Method ShowAutocomplete(ident:String = "")
		'check ident
		If ident = "" Then ident = IdentBeforeCursor()
		
		'show
		Local line := Document.FindLine(Cursor)
		AutoComplete.Show(ident, FilePath, FileType, line)
		
		If AutoComplete.IsOpened
			Local frame := AutoComplete.Frame
			
			Local w := frame.Width
			Local h := frame.Height
			
			frame.Left = Frame.Left-Scroll.x+CursorRect.Left+100
			frame.Right = frame.Left+w
			frame.Top = CursorRect.Top - Scroll.y
			frame.Bottom = frame.Top+h
			' fit dialog into window
			If frame.Bottom > Self.Frame.Bottom
				Local dy := frame.Bottom - Self.Frame.Bottom + 5
				frame.Top -= dy
				frame.Bottom -= dy
			Endif
			AutoComplete.Frame = frame
		Endif
		
	End
	
	Method HideAutocomplete()
		AutoComplete.Hide()
	End
	
	
	Field _doc:CodeDocument

End


Class CodeDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
	
		_doc=New TextDocument
		
		_doc.TextChanged=Lambda()
			Dirty=True
		End
		
		_doc.LinesModified=Lambda( first:Int,removed:Int,inserted:Int )
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

		_view = New DockingView
		
		_treeView = New CodeTreeView
		_view.AddView( _treeView,"left",350,True )
		
		_codeView = New CodeDocumentView( Self )
		_view.ContentView = _codeView
		
		_treeView.SortEnabled = True
		' goto item from tree view
		_treeView.NodeClicked += Lambda(node:TreeView.Node)
			Local codeNode := Cast<CodeTreeNode>(node)
			Local item := codeNode.CodeItem
			_codeView.GotoLine( item.ScopeStartLine )
		End		
		
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

	Field _debugLine:Int=-1
	
	Method OnLoad:Bool() Override
	
		Local text:=stringio.LoadString( Path )
		
		_doc.Text=text
		
		'code parser
		ParseSources()
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local text:=_doc.Text
		
		Local ok := stringio.SaveString( text,Path )
	
		'code parser - reparse
		ParseSources()
				
		Return ok
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method ParseSources()
		ParsersManager.Get(FileType).Parse(_doc.Text, Path)
		_treeView.Fill(FileType, Path)
	End
	
End



Class CodeDocumentType Extends Ted2DocumentType

	Property Name:String() Override
		Return "CodeDocumentType"
	End
	
	Protected
	
	Method New()
		AddPlugin( Self )
		
		'Extensions=New String[]( ".monkey2",".cpp",".h",".hpp",".hxx",".c",".cxx",".m",".mm",".s",".asm",".html",".js",".css",".php",".md",".xml",".ini",".sh",".bat",".glsl")
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override

		Return New CodeDocument( path )
	End
	
		
	Private
	
	Global _instance:=New CodeDocumentType
	
End


Class CodeItemIcons
	
	Function GetIcon:Image(item:CodeItem)
	
		If icons = Null
			InitIcons()
		Endif
		
		Local key:String
		Local kind := item.KindStr
		
		Select kind
			Case "const", "interface", "lambda", "local", "alias", "operator"
				key = kind
			Case "param"
				key = "*"
			'Case "
			Default
				If item.Ident.ToLower() = "new"
					kind = "constructor"
				Endif
				key = kind+"_"+item.AccessStr
		End
		
		Local ic := icons[key]
		If ic = Null Then ic = iconDefault
		
		Return ic
		
	End

	Function GetKeywordsIcon:Image()
		Return icons["keyword"]
	End
	

	Private

	Global icons:Map<String,Image>
	Global iconDefault:Image
	
	Function InitIcons()
	
		icons = New Map<String,Image>
		
		icons["constructor_public"] = Image.Load("asset::ic/constructor.png")
		icons["constructor_private"] = Image.Load("asset::ic/constructor_private.png")
		icons["constructor_protected"] = Image.Load("asset::ic/constructor_protected.png")
		
		icons["function_public"] = Image.Load("asset::ic/method_static.png")
		icons["function_private"] = Image.Load("asset::ic/method_static_private.png")
		icons["function_protected"] = Image.Load("asset::ic/method_static_protected.png")
		
		icons["property_public"] = Image.Load("asset::ic/property.png")
		icons["property_private"] = Image.Load("asset::ic/property_private.png")
		icons["property_protected"] = Image.Load("asset::ic/property_protected.png")
		
		icons["method_public"] = Image.Load("asset::ic/method.png")
		icons["method_private"] = Image.Load("asset::ic/method_private.png")
		icons["method_protected"] = Image.Load("asset::ic/method_protected.png")
		
		icons["lambda"] = Image.Load("asset::ic/annotation.png")
		
		icons["class_public"] = Image.Load("asset::ic/class.png")
		icons["class_private"] = Image.Load("asset::ic/class_private.png")
		icons["class_protected"] = Image.Load("asset::ic/class_protected.png")
		
		icons["enum_public"] = Image.Load("asset::ic/enum.png")
		icons["enum_private"] = Image.Load("asset::ic/enum_private.png")
		icons["enum_protected"] = Image.Load("asset::ic/enum_protected.png")
		
		icons["struct_public"] = Image.Load("asset::ic/struct.png")
		icons["struct_private"] = Image.Load("asset::ic/struct_private.png")
		icons["struct_protected"] = Image.Load("asset::ic/struct_protected.png")
		
		icons["interface"] = Image.Load("asset::ic/interface.png")
		
		icons["field_public"] = Image.Load("asset::ic/field.png")
		icons["field_private"] = Image.Load("asset::ic/field_private.png")
		icons["field_protected"] = Image.Load("asset::ic/field_protected.png")
		
		icons["global_public"] = Image.Load("asset::ic/field_static.png")
		icons["global_private"] = Image.Load("asset::ic/field_static_private.png")
		icons["global_protected"] = Image.Load("asset::ic/field_static_protected.png")
		
		icons["const"] = Image.Load("asset::ic/const.png")
		icons["local"] = Image.Load("asset::ic/local.png")
		icons["keyword"] = Image.Load("asset::ic/keyword.png")
		icons["alias"] = Image.Load("asset::ic/alias.png")
		icons["operator"] = Image.Load("asset::ic/operator.png")
		
		
		iconDefault = Image.Load("asset::ic/other.png")
		
	End
	
End



Private

Global AutoComplete:AutocompleteDialog



Class CodeDocumentTypeBridge Extends CodeDocumentType
	
	Function AddExtensions(inst:CodeDocumentType, exts:String[])
		inst.AddExtensions(exts)
	End
	
End
