
Namespace ted2go


Class Plugin

	Property Name:String() Virtual
	
		Return "<untitled plugin>"
	End
	
	Function PluginsOfType<T>:T[]() Where T Extends Plugin
		
		Return Plugins<T>.Plugins().ToArray()
	End
	
	
	Protected
	
	Method New()

		AddPlugin( Self )
	End
	
	Method AddPlugin<T>( plugin:T ) Where T Extends Plugin
	
		Plugins<T>.Plugins().Add( plugin )
	End
	
	Method OnCreate() Virtual
	
	End


	Private
	
	Struct Plugins<T>
		Global _plugins:Stack<T>
		
		Function Plugins:Stack<T>()
			If Not _plugins _plugins=New Stack<T>
			Return _plugins
		End
	End

End


Class PluginDependsOnFileType Extends Plugin Implements IDependsOnFileType

	Property Name:String() Override
		Return "PluginDependsOnFileType"
	End
	
	Method New()
		_types=New String[]( "*" )
	End
	
	Method GetFileTypes:String[]() Virtual
		Return _types
	End
	
	Method GetMainFileType:String() Virtual
		Return _types[0]
	End

	Method CheckFileTypeSuitability:Bool( fileType:String )
		
		If fileType Then fileType=fileType.ToLower()
		
		If GetMainFileType() = "*" Return True 'any files
		Return Utils.ArrayContains( GetFileTypes(),fileType )
	End
	
	
	Protected
	
	Field _types:String[]
	
End


Interface IDependsOnFileType

	Method GetFileTypes:String[]()
	Method GetMainFileType:String()
	
End
