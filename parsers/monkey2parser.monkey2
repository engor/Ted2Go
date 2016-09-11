
Namespace ted2go


Class Monkey2Parser Extends CodeParserPlugin

	Property Name:String() Override
		Return "Monkey2Parser"
	End
	
	Method GetFileTypes:String[]() Override
		Return _types
	End
	
	Method GetMainFileType:String() Override
		Return "monkey2"
	End
	
	Method Parse(text:String, filePath:String)
	
		If Not _inited
			_inited = True
			ParseModules()
		End
		
		'chech did we already parse this file
		Local time := GetFileTime(filePath)
		
		Local info := GetFileInfo(filePath)
		
		If time = info.lastModified
			'Print "file already parsed: "+filePath
			Return
		End
		info.lastModified = time
		
		'if already parsed - need to remove items of this file
		RemovePrevious(filePath)
		
		_filePath = filePath
		_fileDir = ExtractDir(filePath)
		_stack.Clear()
		
		'parse line by line
		
		If text = Null
			text = stringio.LoadString(filePath)
		Endif
		
		Local doc := New TextDocument
		doc.Text = text
		
		Local line := 0, numLines := doc.NumLines
		
		For Local k := 0 Until numLines
			
			Local txt := doc.GetLine(k)			
			ParseLine(txt)
			
		Next
		
	End
	
		
	Private
	
	Global _types := New String[]("monkey2")
	Global _instance := New Monkey2Parser
	Field _stack := New Stack<ICodeItem>
	Field _scope:ICodeItem
	Field _access := Access.PublicGlobal
	Field _indent:Int
	Field _namespace:String
	Field _filePath:String, _fileDir:String
	Field _files := New StringMap<FileInfo>
	Field _inited := False
	Field _itemsMap := New StringMap<ICodeItem> 'for fast checking of duplicates
	Field _rem := False 'is rem block opened
	
	
	Method GetFileInfo:FileInfo(path:String)
		Local info := _files[path]
		If info = Null
			info = New FileInfo
			_files[path] = info
		Endif
		Return info
	End
	
	Method ParseLine(text:String)
		Local n := 0
		'skip empty chars
		While n < text.Length And text[n] <= 32
			n += 1
		Wend
		Local indent := n
		
		text = text.Slice(indent)
		
		If text.StartsWith("'") Return 'starts with comment
		
		Local p := text.Find(" ")
		Local word := (p > 0) ? text.Slice(0,p) Else text 'first word
		
		If word = "" Return
		
		' skip if in module
		If _access = Access.PrivateGlobal
		
		Endif
		
		word = word.ToLower()
		
		Local postfix := text.Slice(p+1).Trim()
		
		_indent = indent
		
		If word = "namespace"
			_namespace = postfix
			GetFileInfo(_filePath).namespac = _namespace
			Return
		Endif
		
		If word = "#rem"
			_rem = True
			Return
		Endif
		
		If _rem
			If word = "#end"
				_rem = False
				Return
			Endif
		Endif
		
		If word = "#import"
			Local file := postfix.Slice(1,postfix.Length-1) 'skip quotes
			If file.StartsWith("<") Return 'skip <module> 
			If Not file.EndsWith(".monkey2") Then file += ".monkey2" 'parse only ".monkey2"
			file = _fileDir+file 'full path
			If GetFileType(file) = FileType.File
				'Print "#import: "+file
				'need to store current path and dir
				Local path := _filePath
				Local dir := _fileDir
				Local nspace := _namespace
				Parse(Null,file)
				_filePath = path
				_fileDir = dir
				_namespace = nspace
			Endif
			Return
		Endif
		
		
		'simple extract ident
		ExtractIdent(word, postfix)
		
		
		Select word
		Case "class"
			ParseClass(postfix)
		Case "interface"
			ParseInterface(postfix)
		Case "enum"
			ParseEnum(postfix)
		Case "struct"
			ParseStruct(postfix)
		Case "function"
			ParseFunction(postfix)
		Case "method"
			ParseMethod(postfix)
		Case "global"
			ParseGlobal(postfix)
		Case "local"
			ParseLocal(postfix)
		Case "field"
			ParseField(postfix)
		Case "const"
			ParseConst(postfix)
		Case "end"
			ParseConst(postfix)
		End
		
	End
	
	Method RemovePrevious(path:String)
		Local list := New List<ICodeItem>
		For Local i := Eachin Items
			If i.FilePath = path
				list.AddLast(i)
			Endif
		Next
		If list.Empty Return
		For Local i := Eachin list
			RemoveItem(i)
		Next
	End
	
	Method ExtractIdent(word:String, line:String)
		
		Select word
		Case "class","interface","struct","enum","global","const","method","function","property"
		Default
			Return
		End
		
		Local ident := ParseIdent(line)
		
		Local item := New CodeItem(ident)
		item._namespace = _namespace
		
		AddItem(item)
		
		'Print "add ident: "+ident
		
	End
	
	Method AddItem(item:ICodeItem)
	
		'Local key := item.Namespac+item.Ident
		Local key := item.Ident
		If _itemsMap[key] <> Null Return 'already in list
		
		_itemsMap[key] = item
		Items.AddLast(item)
	End
	
	Method RemoveItem(item:ICodeItem)
	
		'Local key := item.Namespac+item.Ident
		Local key := item.Ident
		
		_itemsMap.Remove(key)
		Items.Remove(item)
	End
	
	Method ParseClass(line:String)
		#Rem
		Local ident := ParseIdent(line)
		
		Local item := New CodeItem(ident)
		item._kind = CodeItemKind.Classs
		item._indent = _indent
		
		If _scope <> Null
			_stack.Push(_scope)
			item.SetParent(_scope)
			
		Endif
		#End
	End
	
	Method ParseInterface(line:String)
	
	End
	
	Method ParseEnum(line:String)
	
	End
	
	Method ParseStruct(line:String)
	
	End
	
	Method ParseFunction(line:String)
	
	End
	
	Method ParseMethod(line:String)
	
	End
	
	Method ParseGlobal(line:String)
	
	End
	
	Method ParseLocal(line:String)
	
	End
	
	Method ParseField(line:String)
	
	End
	
	Method ParseConst(line:String)
	
	End
	
	Method ParseIdent:String(line:String)
		Local n := 0
		'skip empty chars
		While n < line.Length And line[n] <= 32
			n += 1
		Wend
		Local indent := n
		While n < line.Length And IsIdent(line[n])
			n += 1
		Wend
		Return (n > indent ? line.Slice(indent,n) Else "")
	End
	
	Method ParseModules()
		
		Local modDir := CurrentDir()+"modules/"
		If GetFileType(modDir) <> FileType.Directory Return 'ide not working in this case, so unnecessary check :)
		
		Local dirs := LoadDir(modDir)
		
		For Local d := Eachin dirs
			If GetFileType(modDir+d) = FileType.Directory
				Local file := modDir + d + "/" + d + ".monkey2"
				'Print "module: "+file
				If GetFileType(file) = FileType.File
					Parse(Null,file)
				Endif
			Endif
		Next
		
	End
	
End


Private


Class FileInfo
	
	Field lastModified:Long
	Field namespac:String
	Field uses := New List<String>
	
End


Enum Access
	PublicGlobal,
	PublicClass,
	PrivateGlobal,
	PrivateClass,
	ProtectedClass
End
