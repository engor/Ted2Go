
Namespace ted2go


Class CodeListViewItem Implements ListViewItem
	
	Method New(item:CodeItem)
		_item = item
		_icon = CodeItemIcons.GetIcon(item)
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		Local dx := 0.0
		If _icon <> Null
			canvas.DrawImage(_icon, x-_icon.Width*handleX, y-_icon.Height*handleY)
			dx = _icon.Width+8
		Endif
		canvas.DrawText(Text, x+dx, y, handleX, handleY)
	End
	
	Property CodeItem:CodeItem()
		Return _item
	End
	
	Property Text:String()
		Return _item.Text
	End
	
	
	Private
	
	Field _item:CodeItem
	Field _icon:Image
	
End



Class AutocompleteDialog Extends DialogExt
	
	Field OnChoosen:Void(text:String)
	
	Method New(title:String)
		Self.New(title,280,480)
	End
	
	Method New(title:String,width:Int,maxHeight:Int)
	
		Title = title
		
		_view = New ListView(20,width,maxHeight)
		
		ContentView = _view
		
		_keywords = New StringMap<List<ListViewItem>>
		_parsers = New StringMap<ICodeParser>
		
		_view.OnItemChoosen += Lambda()
			OnItemChoosen(_view.CurrentItem)
		End
		
		App.KeyEventFilter += Lambda(event:KeyEvent)
			OnKeyFilter(event)
		End
		
	End
	
	Property LastIdentPart:String()
		Return _lastIdentPart
	End
	
	Property FullIdent:String()
		Return _fullIdent
	End
	
	Method CanShow:Bool(line:String, posInLine:Int, fileType:String)
	
		Local parser := GetParser(fileType)
		Return parser.CanShowAutocomplete(line, posInLine)
		
	End
	
	Method Show(ident:String, filePath:String, fileType:String, docLine:Int)
		
		Local result := New List<ListViewItem>
		Local idents := ident.Split(".")
				
		' using lowerCase for keywords
		Local lastIdent := idents[idents.Length-1].ToLower()
		
		Local starts := ident.ToLower().StartsWith(_fullIdent.ToLower())
		
		'if typed ident starts with previous
		'need to simple filter items
		If IsOpened And starts 'And Not ident.EndsWith(".")
			
			Local items := _view.Items
			For Local i := Eachin items
				
				If i.Text.ToLower().StartsWith(lastIdent)
					result.AddLast(i)
				Endif
				
			Next
			
			' some "copy/paste" code
			_fullIdent = ident
			_lastIdentPart = lastIdent
			If IsOpened Then Hide() 'hide to re-layout on open
			
			'nothing to show
			If result.Empty 
				Return
			Endif
						
			_view.Reset()'reset selIndex
			_view.SetItems(result)
			
			Show()
			
			Return
		End
		
		
		_fullIdent = ident
		_lastIdentPart = lastIdent
		
		Local parser := GetParser(fileType)
		Local onlyOne := (idents.Length = 1)
		
		'-----------------------------
		' add keywords
		'-----------------------------
		If onlyOne
			Local kw := GetKeywords(fileType)
			For Local i := Eachin kw
				Local txt := i.Text.ToLower()
				If txt.StartsWith(lastIdent)
					result.AddLast(i)
				End
			Next
		Endif
		
		'check current scope
'		Local target := New List<ICodeItem>
		Local rootScope := parser.GetScope(filePath, docLine)
		Local scope := rootScope
		
		'If rootScope <> Null Print "cursor scope: "+rootScope.Text
		
		'-----------------------------
		' what the first ident is?	
		'-----------------------------
		Local firstIdent := idents[0]
		Local item:CodeItem = Null
		Local isSelf := (firstIdent.ToLower() = "self")
		Local items := New List<CodeItem>
		
		If isSelf
		
			item = scope.Root
			
		Else ' not 'self' ident
			
			' check in 'this' scope
			While scope <> Null
	
				GetAllItems(scope, items, parser)
				
				If Not items.Empty
					For Local i := Eachin items
						If Not CheckIdent(i.Ident, firstIdent, onlyOne) Continue
						If Not CheckAccess(i, filePath, scope) Continue
						' additional checking for the first ident
						If IsLocalMember(i) And i.ScopeStartLine > docLine Continue
						If Not onlyOne
							item = i
							Exit
						Else
							parser.RefineRawType(i)
							result.AddLast(New CodeListViewItem(i))
						Endif
					Next
				Endif
				'found item
				If item <> Null Exit
				
				scope = scope.Parent '￑if inside of func then go to class' scope
				
			Wend
		
		Endif
		'If scope <> Null Print "found: "+scope.Text
		
		' and check in global scope
		If item = Null Or onlyOne
			For Local i := Eachin parser.Items
				If Not CheckIdent(i.Ident, firstIdent, onlyOne) Continue
				If Not CheckAccess(i, filePath) Continue
				If IsLocalMember(i) And i.ScopeStartLine > docLine Continue
				If Not onlyOne
					item = i
					Exit
				Else
					parser.RefineRawType(i)
					result.AddLast(New CodeListViewItem(i))
				Endif
			Next
		Endif
		
		'If item <> Null Print "first: "+item.Text
		
		' var1.var2.var3...
		If Not onlyOne And item <> Null
			
			Local staticOnly := (Not isSelf And item.Kind = CodeItemKind.Class_)
					
			' start from the second ident part here
			For Local k := 1 Until idents.Length
				
				parser.RefineRawType(item)
				
				' need to check by ident type
				Local type := item.Type
				scope = item
				'Print "idnt: "+item.Ident+" : "+type+" : "+item.KindStr
				item = Null
				For Local i := Eachin parser.Items
					If i.Ident = type
						item = i
						Exit
					Endif
				Next
				If item = Null Then Exit
				
				Local identPart := idents[k]
				Local last := (k = idents.Length-1)
				
				' extract all items from item
				GetAllItems(item, items, parser)
				
				If Not items.Empty
					For Local i := Eachin items
						If Not CheckIdent(i.Ident, identPart, last) Continue
						If Not CheckAccess(i, filePath, scope) Continue
						item = i
						If last
							If Not staticOnly Or IsStaticMember(i)
								parser.RefineRawType(i)
								result.AddLast(New CodeListViewItem(i))
							Endif
						Else
							Exit
						Endif
					Next
				Endif
				
				If item = Null Then Exit
			Next
			
		Endif

		
		If IsOpened Then Hide() 'hide to re-layout on open
		
		'nothing to show
		If result.Empty 
			Return
		Endif
		
		
		SortResults(result)
		
		_view.Reset()'reset selIndex
		_view.SetItems(result)
		
		Show()
				
	End
	
		
	Private
	
	Field _view:ListView
	Field _keywords:StringMap<List<ListViewItem>>
	Field _lastIdentPart:String, _fullIdent:String
	Field _parsers:StringMap<ICodeParser>
	Field sorter:Int(lhs:ListViewItem, rhs:ListViewItem)
	
	
	Method New()
	End
	
	Method GetAllItems(item:CodeItem, target:List<CodeItem>, parser:ICodeParser)
		
		' add self children
		If item.Children <> Null
			target.AddAll(item.Children)
		Endif
		
		' add from super classes / ifaces
		If item.SuperTypes = Null Return
		
		For Local t := Eachin item.SuperTypes
			' find class / iface
			Local result:CodeItem = Null
			For Local i := Eachin parser.Items
				If i.Ident = t
					result = i
					Exit
				Endif
			Next
			If result = Null Continue
			Local items := result.Children
			If items = Null Continue
			For Local i := Eachin items
				' need to add unique
				Local s := i.Text
				Local exists := False
				For Local ii := Eachin target
					If ii.Text = s
						exists = True
						Exit
					Endif
				End
				If Not exists
					target.AddLast(i)
					'Print "add from super: "+i.Text
				Endif
			Next
		Next
		
	End
	
	Method IsLocalMember:Bool(item:CodeItem)
		Return item.Kind = CodeItemKind.Local_ Or item.Kind = CodeItemKind.Param_
	End
	
	Method IsStaticMember:Bool(item:CodeItem, checkPublic:Bool=True)
		
		If item.Access <> AccessMode.Public_ Return False
		Select item.Kind
		Case CodeItemKind.Function_, CodeItemKind.Global_, CodeItemKind.Const_, CodeItemKind.Class_, CodeItemKind.Enum_, CodeItemKind.Struct_
			Return True
		End
		Return False
		
	End
	
	Method SortResults(list:List<ListViewItem>)
		
		If sorter = Null
			sorter = Lambda:Int(lhs:ListViewItem, rhs:ListViewItem)
				Return lhs.Text <=> rhs.Text
			End
		Endif
		
		list.Sort(sorter)
		
	End
	
	Method GetParser:ICodeParser(fileType:String)
		If _parsers[fileType] = Null Then UpdateParsers(fileType)
		Return _parsers[fileType]
	End
	
	Method GetKeywords:List<ListViewItem>(fileType:String)
		If _keywords[fileType] = Null Then UpdateKeywords(fileType)
		Return _keywords[fileType]
	End
	
	Method CheckAccess:Bool(item:CodeItem, filePath:String, parent:CodeItem=Null)
		
		' if item is a class, need to show only static members - func, global and const
		'If parent <> Null And parent.Kind = CodeItemKind.Class_
		'	Return item.Kind = CodeItemKind.Function_ Or item.Kind = CodeItemKind.Global_ Or item.Kind = CodeItemKind.Const_
		'Endif
		
		' always show public members of vars
		Local a := item.Access
		If a = AccessMode.Public_
			Return True
		Endif
		
		' if global scope
		If item.Parent = Null
			Return item.FilePath = filePath
		Endif
		
		' if this item is exactly inside of this parent
		If item.Parent = parent
			'Print "if1"
			Return True
		Endif
		
		' for non public - item scope must be equals item type
		Local type := item.Type
		Local i := item.Parent
		Local last:CodeItem = Null
		
		While i <> Null
			last = i
			'Print "try: "+i.Ident+", "+type
			If i.Ident = type
				'Print "if2: "+type
				' need to extend logic for 'protected'
				Return True
			Endif
			i = i.Parent
		Wend
		
		If last <> Null
			 'inside of the same class
			
			Local has := last.HasSuchParent(type)
			Print "has: "+Int(has)+", "+last.Ident+", "+item.Ident
			Return has
		Endif
		
		Return False
	End
	
	Method CheckIdent:Bool(ident1:String, ident2:String, startsOnly:Bool)
		If ident2 = "" Return True
		If startsOnly
			Return ident1.ToLower().StartsWith(ident2.ToLower())
		Else
			Return ident1 = ident2
		Endif
	End
	
	Method ItemsAtScopeInternal(scope:CodeItem, ident:String, startsOnly:Bool, findInParents:Bool, target:List<CodeItem>)
		
		Local item := scope
		While item <> Null
			If (startsOnly And item.Ident.ToLower().StartsWith(ident)) Or (Not startsOnly And item.Ident = ident)
				target.AddLast(item)
			Endif
			
			Local items := item.Children
			If items <> Null
				For Local i := Eachin items
					If (startsOnly And i.Ident.ToLower().StartsWith(ident)) Or (Not startsOnly And i.Ident = ident)
						target.AddLast(i)
					Endif
				Next
			Endif
			If findInParents
				item = item.Parent
			Else
				Return
			Endif
		Wend
		
	End
	
	Method OnKeyFilter(event:KeyEvent)
		If Not IsOpened Return
		If event.Type = EventType.KeyDown Or event.Type = EventType.KeyRepeat
			Select event.Key
			Case Key.Escape
				Hide()
				event.Eat()
			Case Key.Up
				_view.SelectPrev()
				event.Eat()
			Case Key.Down
				_view.SelectNext()
				event.Eat()
			Case Key.Home
				_view.SelectFirst()
				event.Eat()
			Case Key.KeyEnd
				_view.SelectLast()
				event.Eat()
			Case Key.Enter, Key.KeypadEnter
				OnItemChoosen(_view.CurrentItem)
				event.Eat()
			Case Key.Backspace
			Case Key.CapsLock
			Case Key.LeftShift, Key.RightShift
			Case Key.LeftControl, Key.RightControl
			Case Key.LeftAlt, Key.RightAlt
				'do nothing, skip filtering
			Default
				'Hide()
			End
			
		Endif
	End
	
	Method OnItemChoosen(item:ListViewItem)
		Local si := Cast<CodeListViewItem>(item)
		Local t := ""
		If si <> Null
			t = si.CodeItem.Ident
		Else
			t = item.Text
		End
		
		OnChoosen(t)
		Hide()
	End
	
	Method UpdateKeywords(fileType:String)
		'keywords
		Local kw := KeywordsManager.Get(fileType)
		Local list := New List<ListViewItem>
		For Local i := Eachin kw.Values()
			list.AddLast(New StringListViewItem(i))
		Next
		'preprocessor
		'need to load it like keywords
		Local s := "#If ,#Rem,#End,#Endif,#Import "
		Local arr := s.Split(",")
		For Local i := Eachin arr
			list.AddLast(New StringListViewItem(i))
		Next
		_keywords[fileType] = list
	End
	
	Method UpdateParsers(fileType:String)
		_parsers[fileType] = ParsersManager.Get(fileType)
	End
	
End
