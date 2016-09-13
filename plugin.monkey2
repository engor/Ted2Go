
Namespace ted2go


Class Plugin

	Property Name:String() Virtual
	
		Return "<unititled plugin>"
	End
	
	Function PluginsOfType<T>:T[]() Where T Extends Plugin
		
		Return Plugins<T>.Plugins().ToArray()
	End
	
	'***** INTERNAL *****
	Function CreatePlugins()
	
		For Local plugin:=Eachin PluginsOfType<Plugin>()
			plugin.OnCreate()
		Next
	
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
	
	Method GetFileTypes:String[]() Virtual
		Return Null
	End
	
	Method GetMainFileType:String() Virtual
		Return "*"
	End

	Method CheckFileTypeSuitability:Bool(fileType:String)
		If GetMainFileType() = "*" Return True 'any files
		Return Utils.ArrayContains( GetFileTypes(),fileType )
	End
	
End


Interface IDependsOnFileType
	Method GetFileTypes:String[]()
	Method GetMainFileType:String()
End
