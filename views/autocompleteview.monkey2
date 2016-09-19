
Namespace ted2go


Class CodeListViewItem Implements ListViewItem
	
	Method New(ident:String)
		_ident = ident
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		canvas.DrawText(_ident,x,y,handleX,handleY)
	End
	
	Property CodeItem:ICodeItem()
		Return _item
	End
	
	
	Private
	
	Field _ident:String
	Field _item:ICodeItem
	
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
	
	Property Ident:String()
		Return _ident
	End
	
	Method Show(ident:String, filePath:String, fileType:String, docLine:Int)
		
		'if typed ident starts with previous
		'need to  simple filter items
		If IsOpened And ident.StartsWith(_ident)
			
		End
		
		
		If _keywords[fileType] = Null Then UpdateKeywords(fileType)
		If _parsers[fileType] = Null Then UpdateParsers(fileType)
			
		Local parser := _parsers[fileType]
		
		Local result := New List<ListViewItem>
		
		'add keywords
		Local kw := _keywords[fileType]
		For Local i := Eachin kw
			Local txt := i.Text.ToLower()
			If txt.StartsWith(ident)
				result.AddLast(i)
			End
		Next
		
		Local idents := ident.Split(".")
		Local items:List<ICodeItem>
		Local firstIdent := idents[0]
		
		ident = idents[idents.Length-1]
		
		'check current scope
'		Local target := New List<ICodeItem>
		Local scope := parser.GetScope(filePath, docLine)

		' the first ident part
		Local onlyOne := (idents.Length = 1)
			
		If onlyOne
			
			Print "onlyOne"
			
			Local item := scope				
			While item <> Null

				If item.Ident.ToLower().StartsWith(firstIdent)
					result.AddLast(New StringListViewItem(item.Ident))
				Endif
					
				Local items := item.Children
				If items <> Null
					For Local i := Eachin items
						If i.Ident.ToLower().StartsWith(firstIdent)
							result.AddLast(New StringListViewItem(i.Ident))
						Endif
					Next
				Endif

				item = item.Parent
			Wend
			
			For Local i := Eachin parser.Items
				If i.Ident.ToLower().StartsWith(ident)
					result.AddLast(New StringListViewItem(i.Ident))
				Endif
			Next
			
		Else
			
			Print "not onlyOne"
			
			Local item := scope
			
			For Local k := 0 Until idents.Length
				
				Local identPart := idents[k]
				Local last := (k = idents.Length-1)
				Local found:ICodeItem = Null
								
				While item <> Null
	
					If CheckIdent(item.Ident, identPart, last)
						found = item
						If last
							result.AddLast(New StringListViewItem(found.Ident))
						Else
							Exit
						Endif
					Endif
						
					Local items := item.Children
					If items <> Null
						For Local i := Eachin items
							If CheckIdent(i.Ident, identPart, last)
								found = i
								If last
									result.AddLast(New StringListViewItem(found.Ident))
								Else
									Exit
								Endif
							Endif
						Next
					Endif
	
					item = item.Parent
				Wend
				
				If found <> Null
					item = found
				Else
					Exit
				Endif
				
			Next
			
		Endif


		If scope <> Null
		
			
			
			#rem
			Print "SCOPE: "+scope.Scope
			Local item := parser.ItemAtScope(scope, idents)
			If item <> Null 
				Local result:ICodeItem = Null
				Local item := scope
						
				'and other - go recursively into scope
				
				For Local k := 0 Until idents.Length
					Local s := idents[k]
					Local first := (k = 0)
					Local last := (k = idents.Length-1)					
					ItemsAtScopeInternal(item, s, last, first, target)
					If i = Null 'some part of ident not found
						If k = 0
							
						Else
							Exit 'first ident not found in this scope and in global scope
						Endif
					Endif
					item = i
					result = i
				Next
				If result <> Null Print "result: "+result.Ident		
				Return result
			Endif
			
			#end
		Endif
		
		If IsOpened Then Hide() 'hide to re-layout on open
		
		'nothing to show
		If result.Empty 
			Return
		Endif
		
		result.Sort(False)
		
		_view.Reset()'reset selIndex
		_view.SetItems(result)
		
		Show()
			
		_ident = ident
		
	End
	
		
	Private
	
	Field _view:ListView
	Field _keywords:StringMap<List<ListViewItem>>
	Field _ident:String
	Field _parsers:StringMap<ICodeParser>
	
	
	Method New()
	End
	
	Method CheckIdent:Bool(ident1:String, ident2:String, startsOnly:Bool)
		If ident2 = "" Return True
		If startsOnly
			Return ident1.ToLower().StartsWith(ident2)
		Else
			Return ident1 = ident2
		Endif
	End
	
	Method ItemsAtScopeInternal(scope:ICodeItem, ident:String, startsOnly:Bool, findInParents:Bool, target:List<ICodeItem>)
		
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
				Hide()
			End
			
		Endif
	End
	
	Method OnItemChoosen(item:ListViewItem)
		'Local si := Cast<StringItem>(item)
		'Local t := ""
		'If si <> Null
		'	t = si.Text
		'End
		
		OnChoosen(item.Text)
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


Private

Class KeywordWrapper
	
	Method New(word:String, fileType:String)
		_word = word
		_fileType = fileType
	End
	
	Property Word:String()
		Return _word
	End
	
	Property FileType:String()
		Return _fileType
	End
	
		
	Private
	
	Field _word:String
	Field _fileType:String
	
End

