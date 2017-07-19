
Namespace ted2

Private

Const COLOR_NONE:=0
Const COLOR_IDENT:=1
Const COLOR_KEYWORD:=2
Const COLOR_STRING:=3
Const COLOR_NUMBER:=4
Const COLOR_COMMENT:=5
Const COLOR_PREPROC:=6
Const COLOR_OTHER:=7

Global Keywords:=New StringMap<String>

Function InitKeywords()

	Local kws:=""
	kws+="Namespace;Using;Import;Extern;"
	kws+="Public;Private;Protected;Internal;Friend;"
	kws+="Void;Bool;Byte;UByte;Short;UShort;Int;UInt;Long;ULong;Float;Double;String;CString;Variant;TypeInfo;DeclInfo;Object;Continue;Exit;"
	kws+="New;Self;Super;Eachin;True;False;Null;Where;"
	kws+="Alias;Const;Local;Global;Field;Method;Function;Property;Getter;Setter;Operator;Lambda;"
	kws+="Enum;Class;Interface;Struct;Extends;Implements;Virtual;Override;Abstract;Final;Inline;"
	kws+="Var;Varptr;Ptr;"
	kws+="Not;Mod;And;Or;Shl;Shr;End;"
	kws+="If;Then;Else;Elseif;Endif;"
	kws+="While;Wend;"
	kws+="Repeat;Until;Forever;"
	kws+="For;To;Step;Next;"
	kws+="Select;Case;Default;"
	kws+="Try;Catch;Throw;Throwable;"
	kws+="Return;Print;Static;Cast;Extension;"
	kws+="Typeof"
	
	For Local kw:=Eachin kws.Split( ";" )
		Keywords[kw.ToLower()]=kw
	Next
End

Function Monkey2TextHighlighter:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )

	Local i0:=sol
	
	Local icolor:=0
	Local istart:=sol
	Local preproc:=False

	'comment nest
	'
	Local cnest:=state & 255
	If cnest=255 cnest=-1
	
	'block string flag
	'	
	Local blkstr:=(state & 256)=0
	
	If cnest<>-1 
		icolor=COLOR_COMMENT
	Else If blkstr
		icolor=COLOR_STRING
	Endif
	
	While i0<eol
	
		Local start:=i0
		Local chr:=text[i0]
		i0+=1
		
		If IsSpace( chr ) Continue
		
		If blkstr
			If chr=34 blkstr=False
			Continue
		Endif
		
		If chr=35 And istart=sol
			preproc=True
			If cnest=-1 icolor=COLOR_PREPROC
			Continue
		Endif
		
		If preproc And (IsAlpha( chr ) Or chr=95)

			While i0<eol And (IsAlpha( text[i0] ) Or IsDigit( text[i0] )  Or text[i0]=95)
				i0+=1
			Wend
			
			Local id:=text.Slice( start,i0 )
			
			Select id.ToLower()
			Case "rem"
				cnest+=1
				icolor=COLOR_COMMENT
			Case "end"
				If cnest<>-1
					cnest-=1
					icolor=COLOR_COMMENT
				Endif
			End
			
			Exit
		
		Endif
		
		If cnest<>-1 Or preproc Exit
		
		Local color:=icolor
		
		If chr=39
		
			i0=eol
			
			color=COLOR_COMMENT
			
		Else If chr=34
		
			While i0<eol And text[i0]<>34
				i0+=1
			Wend
			If i0<eol
				i0+=1
			Else
				blkstr=True
			Endif
			
			color=COLOR_STRING
			
		Else If IsAlpha( chr ) Or chr=95

			While i0<eol And (IsAlpha( text[i0] ) Or IsDigit( text[i0] )  Or text[i0]=95)
				i0+=1
			Wend
			
			Local id:=text.Slice( start,i0 )
			
			If preproc And istart=sol
			
				Select id.ToLower()
				Case "rem"				
					cnest+=1
				Case "end"
					cnest=Max( cnest-1,-1 )
				End
				
				icolor=COLOR_COMMENT
				
				Exit
			Else
			
				color=COLOR_IDENT
				
				If Keywords.Contains( id.ToLower() ) color=COLOR_KEYWORD
			
			Endif
			
		Else If IsDigit( chr )
		
			While i0<eol And IsDigit( text[i0] )
				i0+=1
			Wend
			
			color=COLOR_NUMBER
			
		Else If chr=36 And i0<eol And IsHexDigit( text[i0] )
		
			i0+=1
			While i0<eol And IsHexDigit( text[i0] )
				i0+=1
			Wend
			
			color=COLOR_NUMBER
			
		Else
			
			color=COLOR_NONE
			
		Endif
		
		If color=icolor Continue
		
		For Local i:=istart Until start
			colors[i]=icolor
		Next
		
		icolor=color
		istart=start
	
	Wend
	
	For Local i:=istart Until eol
		colors[i]=icolor
	Next
	
	state=cnest & 255
	
	If Not blkstr state|=256
	
	Return state
End

Public

Class Monkey2DocumentView Extends Ted2TextView

	Method New( doc:Monkey2Document )
		_doc=doc
		
		Document=_doc.TextDocument
		
		AddView( New GutterView( Self ),"left" )
	End
	
	Protected
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		Local color:=canvas.Color
		
		If _doc._errors.Length
		
			canvas.Color=New Color( .5,0,0 )
			
			For Local err:=Eachin _doc._errors
				Local r:=LineRect( err.line )
				r.min.x=0
				r.max.x=Width
				canvas.DrawRect( r )
			Next
			
		Endif
		
		If _doc._debugLine<>-1

			Local line:=_doc._debugLine
			If line<0 Or line>=Document.NumLines Return
			
			canvas.Color=New Color( 0,.5,0 )
			Local r:=LineRect( line )
			r.min.x=0
			r.max.x=Width
			canvas.DrawRect( r )
		Endif
		
		canvas.Color=color
		
		Super.OnRenderContent( canvas )
	End
	
	Private
	
	Field _doc:Monkey2Document
	
	Field _typing:Bool
	
	Method Capitalize( all:Bool )
	
		_typing=False
	
		Local cursor:=Cursor
		
		'ignore comments...
		'
		Local state:=Document.LineState( Document.FindLine( cursor ) )
		If state & 255 <> 255 Return
		
		Local text:=Text
		Local start:=cursor
		Local term:=all ? text.Length Else start

		'find start of ident
		'		
		While start And IsIdent( text[start-1] )
			start-=1
		Wend
		While start<cursor And IsDigit( text[start] )
			start+=1
		Wend
		If start>=term Or Not IsIdent( text[start] ) Return
		
		'only capitalize keywords and idents
		'
		Local color:=Document.Colors[start]
		If color<>COLOR_KEYWORD And color<>COLOR_IDENT
			'
			If color<>COLOR_PREPROC Return
			'
			'only do first ident on preproc line
			'
			Local i:=start
			While i And text[i-1]<=32
				i-=1
			Wend
			If Not i Or text[i-1]<>35 Return
			i-=1
			While i And text[i-1]<>10
				i-=1
				If text[i]>32 Return
			Wend
			'
		Endif

		'find end of ident
		Local ends:=start
		'
		While ends<term And IsIdent( text[ends] ) And text[ends]<>10
			ends+=1
		Wend
		If ends=start return

		Local ident:=text.Slice( start,ends )

		Local kw:=Keywords[ident.ToLower()]
		If Not kw Or kw=ident Return
		
		Document.ReplaceText( start,ends,kw )
		
	End
	
	Method IdentNearestCursor:String()
	
		Local text:=Text
		Local start:=Cursor
		
		If start And start=text.Length start-=1
		
		While start And Not IsIdent( text[start] ) And text[start-1]<>10
			start-=1
		Wend
		
		While start And IsIdent( text[start-1] ) And text[start-1]<>10
			start-=1
		Wend
		
		While start<text.Length And IsDigit( text[start] ) And text[start]<>10
			start+=1
		Wend
		
		Local ends:=start
		
		While ends<text.Length And IsIdent( text[ends] ) And text[ends]<>10
			ends+=1
		Wend
		
		Return text.Slice( start,ends )
	End
	
	Method OnKeyDown:Bool( key:Key,modifiers:Modifier ) Override
	
		Select key
		Case Key.F1
			
			Local ident:=IdentNearestCursor()
				
			If ident MainWindow.ShowQuickHelp( ident )
				
		Case Key.F2
			
			New Fiber( Lambda()
				
				Local cmd:="~q"+MainWindow.Mx2ccPath+"~q makeapp -parse -geninfo ~q"+_doc.Path+"~q"
					
				Local str:=LoadString( "process::"+cmd )
				Local i:=str.Find( "{" )
				If i=-1 Return
				str=str.Slice( i )
					
				Local jobj:=JsonObject.Parse( str )
				If Not jobj Return
					
				Local jsonTree:=New JsonTreeView( jobj )
					
				Local dialog:=New Dialog( "ParseInfo",jsonTree )
				dialog.AddAction( "Close" ).Triggered=dialog.Close
				dialog.MinSize=New Vec2i( 512,600 )
					
				dialog.Open()
				
			End )
				
		Case Key.Tab,Key.Enter
			
			If _typing Capitalize( False )
				
		Case Key.Left
			
			If _typing
				Local text:=Text
				Local cursor:=Cursor
				If cursor And Not IsIdent( text[cursor-1] )
					Capitalize( True )
				Endif
			Endif
				
		Case Key.Right
			
			If _typing
				Local text:=Text
				Local cursor:=Cursor
				If cursor<text.Length And Not IsIdent( text[cursor] )
					Capitalize( True )
				Endif
			Endif
				
		Case Key.Up,Key.Down
			
			Capitalize( True )	'in cased we missed anything...
		End
		
		Return Super.OnKeyDown( key,modifiers )
	End
	
	Method OnKeyChar( text:String ) Override

		If IsIdent( text[0] )
			_typing=True
		Else
			If _typing Capitalize( False )
		Endif
		
		Super.OnKeyChar( text )
	End
	
End

Class Monkey2Document Extends Ted2Document

	Method New( path:String )
		Super.New( path )
	
		InitKeywords()
		
		_doc=New TextDocument
		
		_doc.TextHighlighter=Monkey2TextHighlighter
		
		_browser=New Monkey2TreeView( _doc )
		
		_doc.TextChanged+=Lambda()
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

	
		_view=New Monkey2DocumentView( Self )
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
		
		_view.GotoLine( _debugLine )
	End
	
	Property Errors:Stack<BuildError>()
	
		Return _errors
	End
	
	Protected
	
	Method OnLoad:Bool() Override
	
		Local text:=stringio.LoadString( Path )
		
		_doc.Text=text
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local text:=_doc.Text
		
		Return stringio.SaveString( text,Path )
	
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method OnCreateBrowser:View() Override
	
		Return _browser
	End
	
	Private

	Field _doc:TextDocument

	Field _view:Monkey2DocumentView
	
	Field _browser:Monkey2TreeView

	Field _errors:=New Stack<BuildError>

	Field _debugLine:Int=-1
End

Class Monkey2DocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".monkey2",".ogg" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New Monkey2Document( path )
	End
	
	Private
	
	Global _instance:=New Monkey2DocumentType
	
End

