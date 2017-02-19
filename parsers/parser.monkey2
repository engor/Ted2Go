
Namespace ted2go


Enum CodeItemKind
	Undefine_,
	Class_,
	Interface_,
	Enum_,
	EnumMember_,
	Struct_,
	Field_,
	Global_,
	Const_,
	Method_,
	Function_,
	Property_,
	Param_,
	Lambda_,
	Local_,
	Operator_,
	Inner_,
	Alias_,
	Inherited_
End


Enum AccessMode
	Private_,
	Protected_,
	Public_
End



Interface ICodeParser

	Method RefineRawType( item:CodeItem )
	Method ParseFile:String( filePath:String,pathOnDisk:String,isModule:Bool )
	'Method ParseJson( json:String,filePath:String )
	Method IsPosInsideOfQuotes:Bool( text:String,pos:Int )
	Method CanShowAutocomplete:Bool( line:String,posInLine:Int )
	Method GetScope:CodeItem( docPath:String,docLine:Int )
	Method ItemAtScope:CodeItem( ident:String,filePath:String,docLine:Int )
	
	Method GetItemsForAutocomplete( ident:String,filePath:String,docLine:Int,target:List<CodeItem>,usingsFilter:String[]=Null )
	Method CheckStartsWith:Bool( ident1:String,ident2:String )
	
	Method GetItem:CodeItem( ident:String )
	
	Property Items:List<CodeItem>()
	Property ItemsMap:StringMap<List<CodeItem>>()
	Property UsingsMap:StringMap<String[]>()
	
End

Class ParsersManager
	
	Function Get:ICodeParser( fileType:String )
		Local plugins:=Plugin.PluginsOfType<CodeParserPlugin>()
		For Local p:=Eachin plugins
			If p.CheckFileTypeSuitability( fileType ) Then Return p
		Next
		Return _empty
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

	Property Items:List<CodeItem>()
		Return _items
	End
	
	Property ItemsMap:StringMap<List<CodeItem>>()
		Return _itemsMap
	End
	
	Property UsingsMap:StringMap<String[]>()
		Return _usingsMap
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
	Method GetItemsForAutocomplete( ident:String,filePath:String,docLine:Int,target:List<CodeItem>,usingsFilter:String[]=Null )
	End
	Method CheckStartsWith:Bool( ident1:String,ident2:String )
		Return False
	End
	Method GetItem:CodeItem( ident:String )
		Return Null
	End
	
	
	Private
	
	Field _items:=New List<CodeItem>
	Field _itemsMap:=New StringMap<List<CodeItem>>
	Field _usingsMap:=New StringMap<String[]>
	
End
