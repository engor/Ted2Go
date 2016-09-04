
Namespace ted2

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
