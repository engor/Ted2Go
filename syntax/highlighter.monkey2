
Namespace ted2


Class Highlighter

	Const COLOR_NONE:=0
	Const COLOR_IDENT:=1
	Const COLOR_KEYWORD:=2
	Const COLOR_STRING:=3
	Const COLOR_NUMBER:=4
	Const COLOR_COMMENT:=5
	Const COLOR_PREPROC:=6
	Const COLOR_OTHER:=7
	
	'use it like a property, as readonly
	Field Painter:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )
	
End


Class HighlighterPlugin Extends Plugin Implements IDependsOnFileType

	Property Highlighter:Highlighter()
		Return _hl
	End
	
	Method GetFileTypes:String[]() Virtual
		Return Null
	End
	
	Method GetMainFileType:String() Virtual
		Return "*"
	End
	
	
	Protected
	
	Method New()
		AddPlugin(Self)
	End
		
	Field _hl:Highlighter
	Field _keywords:IKeywords
	
End


Class HighlightersManager
	
	Function Get:Highlighter(fileType:String)
		Local plugins := Plugin.PluginsOfType<HighlighterPlugin>()
		For Local p := Eachin plugins
			If p.CheckFileTypeSuitability(fileType) Then Return p.Highlighter
		Next
		Return _empty
	End
	
	Private
	
	Global _empty := New Highlighter
	
End
