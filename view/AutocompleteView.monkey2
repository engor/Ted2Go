
Namespace ted2go


Class CodeListViewItem Extends ListViewItem
	
	Method New( item:CodeItem )

		Super.New( item.Text )
		_item=item
		Icon=CodeItemIcons.GetIcon( item )
	End
		
	Property CodeItem:CodeItem()
		Return _item
	End
	
	
	Private
	
	Field _item:CodeItem
	
End


Class AutocompleteListView Extends ListViewExt
	
	Field word:String 'word to select
	
	Method New( lineHeight:Int,maxLines:Int )
		
		Super.New( lineHeight,maxLines )
		
		OnThemeChanged()
	End
	
	
	Protected
	
	Method OnThemeChanged() Override
		
		Super.OnThemeChanged()
		_selColor=App.Theme.GetColor( "completion-list-selected" )
		_markedBgColor=App.Theme.GetColor( "completion-list-marked-bg" )
		_markedTextColor=App.Theme.GetColor( "completion-list-marked-text" )
	End
	
	Method DrawItem( item:ListViewItem,canvas:Canvas,x:Float,y:Float,handleX:Float=0,handleY:Float=0 ) Override
		
		canvas.Color=App.Theme.DefaultStyle.TextColor
		
		Local txt:=item.Text
		Local icon:=item.Icon
		If icon <> Null
			canvas.Alpha=.8
			canvas.DrawImage( icon,x-icon.Width*handleX,y-icon.Height*handleY )
			x+=icon.Width+8
			canvas.Alpha=1
		Endif
		If Not word
			canvas.DrawText( txt,x,y,handleX,handleY )
			Return
		Endif
		
		Local fnt:=canvas.Font
		Local clr:Color
		Local ch:=word[0],index:=0,len:=word.Length
		
		For Local i:=0 Until txt.Length
			Local s:=txt.Slice( i,i+1 )
			Local w:=fnt.TextWidth( s )
			If ch<>-1 And s.ToLower()[0]=ch
				index+=1
				ch = index>=len ? -1 Else word[index]
				clr=canvas.Color
				canvas.Color=_markedBgColor
				canvas.DrawRect( x,y-LineHeight*handleY,w,LineHeight )
				canvas.Color=_markedTextColor
				canvas.DrawText( s,x,y,handleX,handleY )
				canvas.Color=clr
			Else
				canvas.DrawText( s,x,y,handleX,handleY )
			Endif
			x+=w
		Next
	End
	
	Private
	
	Field _markedBgColor:Color,_markedTextColor:Color
	
End


Struct AutocompleteResult
	
	Field ident:String
	Field text:String
	Field item:CodeItem
	Field bySpace:Bool
	Field byTab:Bool
	Field isTemplate:Bool
	
End


Class AutocompleteDialog Extends NoTitleDialog
	
	Field OnChoosen:Void( result:AutocompleteResult )
	
	Method New()
		
		Super.New()
		
		Local lineHg:=20,linesCount:=15
		
		_view=New AutocompleteListView( lineHg,linesCount )
		_view.MoveCyclic=True
		
		_etalonMaxSize=New Vec2i( 500,lineHg*linesCount )
		
		ContentView=_view
		
		_keywords=New StringMap<Stack<ListViewItem>>
		_templates=New StringMap<Stack<ListViewItem>>
		_parsers=New StringMap<ICodeParser>
		
		_view.OnItemChoosen+=Lambda()
			OnItemChoosen( _view.CurrentItem,Key.None )
		End
		
		App.KeyEventFilter+=Lambda( event:KeyEvent )
			OnKeyFilter( event )
		End
		
		OnHide+=Lambda()
			_disableUsingsFilter=False
		End
		
		OnValidateStyle()
	End
	
	Property DisableUsingsFilter:Bool()
		Return _disableUsingsFilter
	Setter( value:Bool )
		_fullIdent=""
		_disableUsingsFilter=value
	End
	
	Property LastIdentPart:String()
		Return _lastIdentPart
	End
	
	Property FullIdent:String()
		Return _fullIdent
	End
	
	Method CanShow:Bool( line:String,posInLine:Int,fileType:String )
	
		Local parser:=GetParser( fileType )
		Return parser.CanShowAutocomplete( line,posInLine )
		
	End
	
	Method Show( ident:String,filePath:String,fileType:String,docLineNum:Int,docLineStr:String,docPosInLine:Int )
		
		OnValidateStyle()
		
		Local dotPos:=ident.FindLast( "." )
		
		' using lowerCase for keywords
		Local lastIdent:=(dotPos > 0) ? ident.Slice( dotPos+1 ) Else ident
		Local lastIdentLower:=lastIdent.ToLower()
		
		_view.word=lastIdentLower
		
		Local starts:=(_fullIdent And ident.StartsWith( _fullIdent ))
		
		Local result:=New Stack<ListViewItem>
		
		Local parser:=GetParser( fileType )
		
		Local filter:=_disableUsingsFilter
		
		'-----------------------------
		' some optimization
		'-----------------------------
		'if typed ident starts with previous
		'need to simple filter items
		
'		If IsOpened And starts And Not ident.EndsWith(".")
'			
'			Local items:=_view.Items
'			For Local i:=Eachin items
'				
'				If parser.CheckStartsWith( i.Text,lastIdentLower )
'					result.Add( i )
'				Endif
'				
'			Next
'			
'			' some "copy/paste" code
'			_fullIdent=ident
'			_lastIdentPart=lastIdentLower
'			If IsOpened Then Hide() 'hide to re-layout on open
'			
'			'nothing to show
'			If result.Empty
'				Return
'			Endif
'			
'			CodeItemsSorter.SortByIdent( result,lastIdent )
'			
'			_view.Reset()'reset selIndex
'			_view.SetItems( result )
'			
'			Super.Show()
'			
'			_disableUsingsFilter=filter
'			Return
'		End
		
		
		_fullIdent=ident
		_lastIdentPart=lastIdentLower
		
		Local onlyOne:=(dotPos = -1)
		
		'-----------------------------
		' extract items
		'-----------------------------
		
		If Not Prefs.AcKeywordsOnly
		
			Local usings:Stack<String>
			
			If Not _disableUsingsFilter 'And onlyOne
				
				usings=New Stack<String>
				
				Local locked:=MainWindow.LockedDocument
				Local current:=Cast<CodeDocument>( MainWindow.DocsManager.CurrentDocument )
				
				If Not locked Then locked=current
				If locked
					Local info:=parser.UsingsMap[locked.Path]
					If info.nspace Or info.usings
						If info.nspace Then usings.Add( info.nspace+".." )
						If info.usings Then usings.AddAll( info.usings )
					Endif
				Endif
				
				If current And current <> locked
					Local info:=parser.UsingsMap[current.Path]
					If info.nspace
						Local s:=info.nspace+".."
						If Not usings.Contains( s ) Then usings.Add( s )
					Endif
					If info.usings Then usings.AddAll( info.usings )
				Endif
				
				If Not usings.Contains( "monkey.." ) Then usings.Add( "monkey.." )
			Endif
			
			'Print "usings: "+usings.Join( " " )
			
			_listForExtract.Clear()
			
			Global opts:=New ParserRequestOptions
			opts.ident=ident
			opts.filePath=filePath
			opts.cursor=New Vec2i( docLineNum,docPosInLine )
			opts.docLineStr=docLineStr
			opts.results=_listForExtract
			opts.usingsFilter=usings
			
			parser.GetItemsForAutocomplete( opts )
			
			CodeItemsSorter.SortByType( _listForExtract,True )
		Endif
		
		'-----------------------------
		' extract keywords
		'-----------------------------
		If onlyOne
			Local kw:=GetKeywords( fileType )
			For Local i:=Eachin kw
				If i.Text.ToLower().StartsWith( lastIdentLower )
					result.Add( i )
				Endif
			Next
		Endif
		
		'-----------------------------
		' remove duplicates
		'-----------------------------
		If Not Prefs.AcKeywordsOnly
			For Local i:=Eachin _listForExtract
				Local s:=i.Text
				Local exists:=False
				For Local ii:=Eachin result
					If ii.Text = s
						exists=True
						Exit
					Endif
				Next
				If Not exists
					result.Add( New CodeListViewItem( i ) )
				Endif
			Next
		Endif
		
		' hide to re-layout on open
		If IsOpened Then Hide()
		
		If lastIdent Then CodeItemsSorter.SortByIdent( result,lastIdent )
		
		'-----------------------------
		' live templates
		'-----------------------------
		If Prefs.AcUseLiveTemplates
			Local list:=GetTemplates( fileType )
			For Local i:=Eachin list
				Local templ:=i.Text
				Local withDot:=templ.StartsWith( "." )
				Local withDot2:=templ.StartsWith( ".." )
				If onlyOne And withDot2 Continue ' skip if it requires instance
				If Not onlyOne And Not withDot Continue ' skip if it doesn't require instance
				If withDot2
					templ=templ.Slice( 2 )
				Elseif withDot
					templ=templ.Slice( 1 )
				Endif
				If lastIdent And templ.StartsWith( lastIdent )
					result.Insert( 0,i )
				Endif
			Next
		Endif
		
		' nothing to show
		If result.Empty
			Return
		Endif
		
		_view.Reset()'reset selIndex
		_view.SetItems( result )
		
		Super.Show()
		
		_disableUsingsFilter=filter
	End
	
	
	Protected
	
	Method OnValidateStyle() Override
		
		_view.MaxSize=(App.Theme.Scale.x>1) ? _etalonMaxSize*App.Theme.Scale Else _etalonMaxSize
	End
	
	Private
	
	Field _etalonMaxSize:Vec2f
	Field _view:AutocompleteListView
	Field _keywords:StringMap<Stack<ListViewItem>>
	Field _templates:StringMap<Stack<ListViewItem>>
	Field _lastIdentPart:String,_fullIdent:String
	Field _parsers:StringMap<ICodeParser>
	Field _listForExtract:=New Stack<CodeItem>
	Field _listForExtract2:=New Stack<CodeItem>
	Field _disableUsingsFilter:Bool
	
	Method GetParser:ICodeParser( fileType:String )
		If _parsers[fileType] = Null Then UpdateParsers( fileType )
		Return _parsers[fileType]
	End
	
	Method GetKeywords:Stack<ListViewItem>( fileType:String )
		If _keywords[fileType] = Null Then UpdateKeywords( fileType )
		Return _keywords[fileType]
	End
	
	Method GetTemplates:Stack<ListViewItem>( fileType:String )
		If _templates[fileType] = Null
			UpdateTemplates( fileType )
			LiveTemplates.DataChanged+=Lambda( lang:String )
				If _templates[lang] 'recreate items only if them were in use
					UpdateTemplates( lang )
				Endif
			End
		Endif
		Return _templates[fileType]
	End
	
	Method IsItemInScope:Bool( item:CodeItem,scope:CodeItem )
		If scope = Null Return False
		Return item.ScopeStartPos.x >= scope.ScopeStartPos.x And item.ScopeEndPos.x <= scope.ScopeEndPos.x
	End
	
	Method OnKeyFilter( event:KeyEvent )
		
		If Not IsOpened Return
		
		Select event.Type
			
			Case EventType.KeyDown,EventType.KeyRepeat
				
				Local curItem:=_view.CurrentItem
				Local templ:=Cast<TemplateListViewItem>( curItem )
				
				Local key:=event.Key
				Select key
				
				Case Key.Escape
					Hide()
					event.Eat()
				
				Case Key.Home,Key.KeyEnd
					Hide()
				
				Case Key.Up
					_view.SelectPrev()
					event.Eat()
					
				Case Key.Down
					_view.SelectNext()
					event.Eat()
					
				Case Key.PageUp
					_view.PageUp()
					event.Eat()
					
				Case Key.PageDown
					_view.PageDown()
					event.Eat()
					
				Case Key.Enter,Key.KeypadEnter
					If Not templ
						If Prefs.AcUseEnter
							OnItemChoosen( curItem,key )
							If Not Prefs.AcNewLineByEnter Then event.Eat()
						Else
							Hide() 'hide by enter
						Endif
					Endif
					
				Case Key.Tab
					If Prefs.AcUseTab Or templ
						OnItemChoosen( curItem,key )
						event.Eat()
					Endif
					
				Case Key.Space
					If Not templ
						Local ctrl:=event.Modifiers & Modifier.Control
						If Prefs.AcUseSpace And Not ctrl
							OnItemChoosen( curItem,key )
							event.Eat()
						Endif
					Endif
					
				Case Key.Period
					If Not templ
						If Prefs.AcUseDot
							OnItemChoosen( curItem,key )
							event.Eat()
						Endif
					Endif
				
				Case Key.Backspace
				Case Key.CapsLock
				Case Key.LeftShift,Key.RightShift
				Case Key.LeftControl,Key.RightControl
				Case Key.LeftAlt,Key.RightAlt
					'do nothing,skip filtering
				Default
					'Hide()
				End
			
			Case EventType.KeyChar
				
				If Not IsIdent( event.Text[0] ) Then Hide()
				
		End
		
	End
	
	Method OnItemChoosen( item:ListViewItem,key:Key )
		
		Local siCode:=Cast<CodeListViewItem>( item )
		Local siTempl:=Cast<TemplateListViewItem>( item )
		Local ident:="",text:=""
		Local code:CodeItem=Null
		Local templ:=False
		If siCode
			ident=siCode.CodeItem.Ident
			text=siCode.CodeItem.TextForInsert
			code=siCode.CodeItem
		Elseif siTempl
			ident=siTempl.name
			text=siTempl.value
			templ=True
		Else
			ident=item.Text
			text=item.Text
		End
		Local result:=New AutocompleteResult
		result.ident=ident
		result.text=text
		result.item=code
		result.bySpace=(key=Key.Space)
		result.byTab=(key=Key.Tab)
		result.isTemplate=templ
		OnChoosen( result )
		Hide()
	End
	
	Method UpdateKeywords( fileType:String )
		
		'keywords
		Local kw:=KeywordsManager.Get( fileType )
		Local list:=New Stack<ListViewItem>
		Local ic:=CodeItemIcons.GetKeywordsIcon()
		For Local i:=Eachin kw.Values()
			Local si:=New ListViewItem( i,ic )
			list.Add( si )
		Next
		'preprocessor
		'need to load it like keywords
		Local s:=GetPreprocessorDirectives( fileType )
		If s
			Local arr:=s.Split( "," )
			For Local i:=Eachin arr
				list.Add( New ListViewItem( i ) )
			Next
		Endif
		_keywords[fileType]=list
	End
	
	Method UpdateTemplates( fileType:String )
	
		'live templates
		Local templates:=LiveTemplates.All( fileType )
		Local list:=New Stack<ListViewItem>
		If templates <> Null
			For Local i:=Eachin templates
				Local si:=New TemplateListViewItem( i.Key,i.Value )
				list.Add( si )
			Next
			list.Sort( Lambda:Int(l:ListViewItem,r:ListViewItem)
				Return l.Text<=>r.Text
			End )
		Endif
		_templates[fileType]=list
	End
	
	Method UpdateParsers( fileType:String )
		_parsers[fileType]=ParsersManager.Get( fileType )
	End
	
	Function GetPreprocessorDirectives:String( fileType: String )
		
		Select fileType
			Case ".monkey2"
				Return "#If ,#Rem,#End,#Endif,#Else,#Else If ,#Import ,#Reflect ,monkeydoc,__TARGET__,__MOBILE_TARGET__,__DESKTOP_TARGET__,__WEB_TARGET__,__HOSTOS__,__ARCH__,__DEBUG__,__RELEASE__,__CONFIG__,__MAKEDOCS__"
			Case ".cpp",".h",".hpp",".c"
				Return "#if ,#end,#endif,#else,#elif ,#define ,#undef ,#ifdef ,#ifndef "
		End
		
		Return ""
	End
	
End
