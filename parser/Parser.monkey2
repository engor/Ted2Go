
Namespace ted2go


Interface ICodeParser

	Method RefineRawType( item:CodeItem )
	Method ParseFile:String( filePath:String,pathOnDisk:String,isModule:Bool )
	'Method ParseJson( json:String,filePath:String )
	Method IsPosInsideOfQuotes:Bool( text:String,pos:Int )
	Method CanShowAutocomplete:Bool( line:String,posInLine:Int )
	Method GetScope:CodeItem( docPath:String,docLine:Int )
	Method ItemAtScope:CodeItem( ident:String,filePath:String,docLine:Int )
	
	Method GetItemsForAutocomplete( ident:String,filePath:String,docLine:Int,target:Stack<CodeItem>,usingsFilter:Stack<String> =Null )
	Method CheckStartsWith:Bool( ident1:String,ident2:String )
	
	Method GetItem:CodeItem( ident:String )
	
	Method SetEnabled( enabled:Bool )
	
	Property Items:Stack<CodeItem>()
	Property ItemsMap:StringMap<Stack<CodeItem>>()
	Property UsingsMap:StringMap<UsingInfo>()
	Property ExtraItemsMap:StringMap<Stack<CodeItem>>()
	
End

Class ParsersManager
	
	Function Get:ICodeParser( fileType:String )
		Local plugins:=Plugin.PluginsOfType<CodeParserPlugin>()
		For Local p:=Eachin plugins
			If p.CheckFileTypeSuitability( fileType ) Then Return p
		Next
		Return _empty
	End

	Function DisableAll()
		
		Local plugins:=Plugin.PluginsOfType<CodeParserPlugin>()
		For Local p:=Eachin plugins
			p.SetEnabled( False )
		Next
	End
	
	
	Private
	
	Global _empty:=New EmptyParser
	
End


Function StripGenericType:String( ident:String )
	Local i:=ident.Find("<")
	If i > 0 Return ident.Slice( 0,i )
	Return ident
End


Private

Class EmptyParser Implements ICodeParser

	Property Items:Stack<CodeItem>()
		Return _items
	End
	
	Property ItemsMap:StringMap<Stack<CodeItem>>()
		Return _itemsMap
	End
	
	Property UsingsMap:StringMap<UsingInfo>()
		Return _usingsMap
	End
	
	Property ExtraItemsMap:StringMap<Stack<CodeItem>>()
		Return _extraItemsMap
	End
	
	Method ParseFile:String( filePath:String,pathOnDisk:String,isModule:Bool )
		'do nothing
		Return Null
	End
	Method IsPosInsideOfQuotes:Bool( text:String,pos:Int )
		Return False
	End
	Method CanShowAutocomplete:Bool( line:String,posInLine:Int )
		Return True
	End
	Method GetScope:CodeItem( docPath:String,docLine:Int )
		Return Null
	End
	Method ItemAtScope:CodeItem( ident:String,filePath:String,docLine:Int )
		Return Null
	End
	Method RefineRawType( item:CodeItem )
	End
	Method GetItemsForAutocomplete( ident:String,filePath:String,docLine:Int,target:Stack<CodeItem>,usingsFilter:Stack<String> =Null )
	End
	Method CheckStartsWith:Bool( ident1:String,ident2:String )
		Return False
	End
	Method GetItem:CodeItem( ident:String )
		Return Null
	End
	Method SetEnabled( enabled:Bool )
	End
	
	Private
	
	Field _items:=New Stack<CodeItem>
	Field _itemsMap:=New StringMap<Stack<CodeItem>>
	Field _usingsMap:=New StringMap<UsingInfo>
	Field _extraItemsMap:=New StringMap<Stack<CodeItem>>
End
