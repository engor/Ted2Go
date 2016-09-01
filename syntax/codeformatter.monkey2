
Namespace ted2


Interface ICodeFormatter

	Method Format(document:CodeTextView, row:Int=-1)
	
End


'base wrapper for code formatter
Class CodeFormatterPlugin Extends Plugin Implements IDependsOnFileType, ICodeFormatter

	Property Name:String() Override
		Return "CodeFormatterPlugin"
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
	
End


Class FormattersManager
	
	Function Get:ICodeFormatter(fileType:String)
		Local plugins := Plugin.PluginsOfType<CodeFormatterPlugin>()
		For Local p := Eachin plugins
			If p.CheckFileTypeSuitability(fileType) Then Return p
		Next
		Return _empty
	End

	
	Private
	
	Global _empty := New EmptyFormatter
	
End


Private


Class EmptyFormatter Implements ICodeFormatter
	
	Method Format(document:CodeTextView, row:Int=-1)
		'do nothing
	End
	
End
