
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
	Alias_
End


Enum AccessMode
	Private_,
	Protected_,
	Public_
End



Interface ICodeParser

	Method RefineRawType( item:CodeItem )
	Method ParseFile:String( filePath:String,pathOnDisk:String )
	'Method ParseJson( json:String,filePath:String )
	Method IsPosInsideOfQuotes:Bool( text:String,pos:Int )
	Method CanShowAutocomplete:Bool( line:String,posInLine:Int )
	Method GetScope:CodeItem( docPath:String,docLine:Int )
	Method ItemAtScope:CodeItem( ident:String,filePath:String,docLine:Int )
	
	Method GetItemsForAutocomplete( ident:String,filePath:String,docLine:Int,target:List<CodeItem> )
	
	Property Items:List<CodeItem>()
	Property ItemsMap:StringMap<List<CodeItem>>()
	
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
	
	Method ParseFile:String( filePath:String,pathOnDisk:String )
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
	Method GetItemsForAutocomplete( ident:String,filePath:String,docLine:Int,target:List<CodeItem> )
	End
	
	Private
	
	Field _items:=New List<CodeItem>
	Field _itemsMap:=New StringMap<List<CodeItem>>
	
End
