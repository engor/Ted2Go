
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
	
	Method OnCreate() Override
		
		'ParseModules()
		
	End
	
	Method Parse(text:String, filePath:String)
			
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
	Field _access := AccessMode.PublicInFile
	Field _indent:Int
	Field _namespace:String
	Field _filePath:String, _fileDir:String
	Field _files := New StringMap<FileInfo>
	Field _itemsMap := New StringMap<ICodeItem> 'for fast checking of duplicates
	Field _insideRem := False 'is rem block opened
	Field _insideEnum := False
	Field _insideInterface := False
	Field _params := New List<String>
	
	
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
		
		text = text.Slice(indent) 'remove indent
		
		Local comPos := IndexOfCommentChar(text)
		If comPos = 0 Return 'starts with comment
		
		If comPos > 0
			text = text.Slice(0, comPos) 'remove all after comment
		Endif
		
		text = text.TrimEnd()
		
		Local p := text.Find(" ")
				
		Local word := (p > 0) ? text.Slice(0,p) Else text 'first word
		
		If word = "" Return
						
		word = word.ToLower()
		
		'Print "word: '"+word+"'"
		
		'commented block
		If _insideRem
			If word = "#end"
				_insideRem = False
			Endif
			Return
		Endif
		
		'enum values
		If _insideEnum
			If word = "end"
				_insideEnum = False
				PopScope()
				Return
			Endif
			Local t := text.Trim()
			Local arr := t.Split(",")
			For Local i := Eachin arr
				i = i.Trim()
				If i <> ""
					AddItem(New CodeItem(i))
				Endif
			Next
			Return
		Endif
		
		Local postfix := text.Slice(p+1).Trim()
		
		_indent = indent
		
		'simple extract ident
		'ExtractIdent(word, postfix)
		
		Local item:CodeItem = Null
		Local isScope := False
		
		
		Select word
		
		Case "namespace"
			
			_namespace = postfix
			GetFileInfo(_filePath).namespac = _namespace
			Return
			
						
		Case "#rem"
			
			_insideRem = True
			Return
		
		
		Case "#import"
			Local file := postfix.Slice(1,postfix.Length-1) 'skip quotes
			If file.StartsWith("<") Return 'skip <module> 
			If Not file.EndsWith(".monkey2") Then file += ".monkey2" 'parse only ".monkey2"
			file = _fileDir+file 'full path
			If GetFileType(file) = FileType.File
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
		
		
		Case "end"
			
			If _scope <> Null
				'If _insideInterface And _scope._kind = CodeItemKind.Interfacee
					_insideInterface = False
				'Endif
				'If _scope.Indent > indent
				'	Print "scope: "+_scope.Scope+", "+ _scope.Indent+", "+ indent
				'Endif
				If _scope.Indent = indent
					PopScope() 'go up 
				Endif
				
			Endif
					
			Return
			
			
		Case "class", "struct"
			
			Local ident := ParseIdent(postfix)
			item = New CodeItem(ident)
			'item._kind = CodeItemKind.Classs
			isScope = True
			If _scope <> Null
				Print "class: "+ident+", "+_scope.Ident
			Endif
			
		Case "interface"
			
			Local ident := ParseIdent(postfix)
			item = New CodeItem(ident)
			'item._kind = CodeItemKind.Interfacee
			isScope = True
			_insideInterface = True
			
		Case "enum"
			
			Local ident := ParseIdent(postfix)
			item = New CodeItem(ident)
			'item._kind = CodeItemKind.Enumm
			'isScope = True
			_insideEnum = True
			
			
		Case "method", "function", "property"
			
			Local ident := ParseIdent(postfix)
			item = New CodeItem(ident)
			'item._kind = CodeItemKind.Functionn
			isScope = Not _insideInterface
			
			
		Case "field", "global", "local", "const", "param"
			
			' here we try to split idents by comma
			_params.Clear()
			ExtractParams(postfix, _params)
			
			' read types and try to parse ':=' expr
			For Local s := Eachin _params
				
				's = s.Replace(" ","") 'remove spaces
				
				Local p0 := s.Find(":=")
				Local p1 := s.Find(":")
				Local p2 := s.Find("=")
				Local p3 := s.Find("[")
				Local p4 := s.Find("~q")
				
				Local ident:String
				Local type:String
				
				':= not in string
				If p0 > 0 And p0 < p4
					
					ident = s.Slice(0,p0).Trim()
					type = s.Slice(p0+1).Trim()
					
					If type.StartsWith("New")
					
						type = type.Slice(3).Trim()
						Local typeIdent := ParseIdent(type)
						
						If type.StartsWith("~q") Or typeIdent = "String"
							type = "String"
						Elseif typeIdent = "Int"
							type = "Int"
						Elseif typeIdent = "Float"
							type = "Float"
						Elseif typeIdent = "Bool"
							type = "Bool"
						Elseif IsDigit(type[0]) Or type[0] = CHAR_DOT
							If type.Contains(".")
								type = "Float"
							Else
								type = "Int"
							Endif
						Endif
						
					Else
					
						Local typeIdent := ParseIdent(type)
						
						If typeIdent = "True" Or typeIdent = "False"
							type = "Bool"
						Elseif typeIdent = "Int"
							type = "Int"
						Elseif typeIdent = "Float"
							type = "Float"
						Elseif typeIdent = "Bool"
							type = "Bool"
						Endif
							
					Endif
					
				Else
					
				Endif
				
				item = New CodeItem(ident)
				item.Type = type
				
				' also need to check arrays
				' and types which requires refining after parsing all file
				
				If item <> Null
					item.Namespac = _namespace
					item.Indent = _indent
					item.FilePath = _filePath
					
					AddItem(item)
					
					item = Null
					
				Endif
				
			Next
			
			'Local ident := ParseIdent(postfix)
			'Local item := New CodeItem(ident)
			'item._kind = CodeItemKind.Globall
			
			
						
		
		End 'Select word
		
		
		If item <> Null

			item.Namespac = _namespace
			item.Indent = _indent
			item.FilePath = _filePath

			AddItem(item)
			
			If isScope
				PushScope(item)
			Endif
			
		Endif
		
	End
	
	Method PushScope(item:ICodeItem)
		'Print "push scope"
		If _scope <> Null
			_stack.Push(_scope)
			item.Parent = _scope
			'Print "push stack"
		Endif
		_scope = item
		
	End
	
	Method PopScope()
		'Print "pop scope"
		If _stack.Length > 0
			_scope = _stack.Pop()
		Else
			_scope = Null
		Endif
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
		item.Namespac = _namespace
		
		AddItem(item)
		
		'Print "add ident: "+ident
		
	End
	
	Method AddItem(item:ICodeItem)
	
		'Local key := item.Namespac+item.Ident
		'Local key := item.Ident
		'If _itemsMap[key] <> Null Return 'already in list
		
		'_itemsMap[key] = item
		
		If _scope <> Null
			_scope.AddChild(item)
		Else
			Items.AddLast(item)
		Endif
		
	End
	
	Method RemoveItem(item:ICodeItem)
	
		'Local key := item.Namespac+item.Ident
		Local key := item.Ident
		
		_itemsMap.Remove(key)
		Items.Remove(item)
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
	
	Method IsPosInsideOfQuotes:Bool(text:String, pos:Int)
	
		Local i := 0
		Local n := text.Length
		if pos = 0 Or pos >= n Return False
		Local quoteCounter := 0
		While i < n
			Local c := text[i]
			If i = pos
				If quoteCounter Mod 2 = 0 'not inside of string
					Return False
				Else 'inside
					Return True
				Endif
			Endif
			If c = CHAR_DOUBLE_QUOTE
				quoteCounter += 1
			Endif
			i += 1
		Wend
		Return False
	End	
	
	Function ParseIdent:String(line:String)
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
	
	' check if char(') is inside of string or not
	Function IndexOfCommentChar:Int(text:String)
	
		Local i := 0
		Local n := text.Length
		Local quoteCounter := 0, lastCommentPos := -1
		
		While i < n
			Local c := text[i]
			If c = CHAR_DOUBLE_QUOTE
				quoteCounter += 1
			Endif
			If c = CHAR_SINGLE_QUOTE
				If quoteCounter Mod 2 = 0 'not inside of string, so comment starts from here
					lastCommentPos = i
					Exit
				Else 'comment char is between quoters, so that's regular string
					lastCommentPos = -i
				Endif
			Endif
			i += 1
		Wend
		return lastCommentPos
	End
	
	#Rem split the line @text with params by comma and put result into @target
	#End
	Function ExtractParams(text:String, target:List<String>)
	
		Local i := 0, prev := 0
		Local n := text.Length
		Local quoteCounter := 0, lessCounter := 0, squareCounter := 0, roundCounter := 0
		
		While i < n
			
			Local c := text[i]
			
			Select c
			
			Case CHAR_DOUBLE_QUOTE
				
				' check for end of string
				i += 1
				While i < n And text[i] <> CHAR_DOUBLE_QUOTE
					i += 1
				Wend
			
			Case CHAR_LESS_BRACKET
				
				lessCounter += 1
			
			Case CHAR_MORE_BRACKET
				
				lessCounter -= 1
			
			Case CHAR_OPENED_SQUARE_BRACKET
				
				squareCounter += 1
			
			Case CHAR_CLOSED_SQUARE_BRACKET
				
				squareCounter -= 1
			
			Case CHAR_OPENED_ROUND_BRACKET
				
				roundCounter += 1
			
			Case CHAR_CLOSED_ROUND_BRACKET
				
				roundCounter -= 1
			
			Case CHAR_COMMA
				
				' if we inside of <...> or [...] or (...)
				If lessCounter <> 0 Or squareCounter <> 0 Or roundCounter <> 0
					i += 1
					Continue
				Endif
				
				Local s := text.Slice(prev, i).Trim()
				target.AddLast(s)
				prev = i+1
				
			End
			i += 1
		Wend
		
		' add last part
		If i > prev
			Local s := text.Slice(prev, n).Trim()
			target.AddLast(s)
		Endif
		
	End
	
End


Private

Const CHAR_SINGLE_QUOTE := 39
Const CHAR_DOUBLE_QUOTE := 34
Const CHAR_COMMA := 44
Const CHAR_DOT := 46
Const CHAR_EQUALS := 61
Const CHAR_LESS_BRACKET := 60
Const CHAR_MORE_BRACKET := 62
Const CHAR_OPENED_SQUARE_BRACKET := 91
Const CHAR_CLOSED_SQUARE_BRACKET := 93
Const CHAR_OPENED_ROUND_BRACKET := 40
Const CHAR_CLOSED_ROUND_BRACKET := 41


Class FileInfo
	
	Field lastModified:Long
	Field namespac:String
	Field uses := New List<String>
	
End
