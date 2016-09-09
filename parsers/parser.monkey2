
Namespace ted2go


Class CodeParser

End


Class CodeParserPlugin Extends PluginDependsOnFileType

	Property Name:String() Override
		Return "CodeParserPlugin"
	End
	
	Property Parser:CodeParser()
		Return _parser
	End
	
	Protected
	
	Method New()
		AddPlugin(Self)
	End
	
	
	Private
	
	Field _parser:CodeParser
	
End
