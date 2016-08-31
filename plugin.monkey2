
Namespace ted2

Class Plugin

	Property Name:String() Virtual
	
		Return "<unititled plugin>"
	End

	Function PluginsOfType<T>:T[]() Where T Extends Plugin
		
		Return Plugins<T>.Plugins().ToArray()
	End
	
	Method CheckFileTypeSuitability:Bool(fileType:String)
		Local dep := Cast<IDependsOnFileType>(Self)
		If Not dep Return True
		If dep.GetMainFileType() = "*" Return True 'any files
		Local types := dep.GetFileTypes()
		Return Utils.ArrayContains(types,fileType)
	End
	
	
	Protected
	
	Method New()

		AddPlugin( Self )
	End
	
	Method AddPlugin<T>( plugin:T ) Where T Extends Plugin
	
		Plugins<T>.Plugins().Add( plugin )
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


Interface IDependsOnFileType
	Method GetFileTypes:String[]()
	Method GetMainFileType:String()
End
