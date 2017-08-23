
Namespace ted2go


#Import "assets/liveTemplates.json"

Const LiveTemplates:=New LiveTemplatesClass

Class LiveTemplatesClass
	
	Method Load( jsonPath:String )
		
		Local txt:=LoadString( jsonPath ).Replace( "\n","~n" ).Replace( "\t","~t" )
		'Local txt
		Local langs:=JsonObject.Parse( txt ).All()
		For Local i:=Eachin langs
			Local map:=New StringMap<String>
			_items[i.Key]=map
			Local all:=i.Value.ToObject().All()
			For Local j:=Eachin all
				'Print j.Key+" <-> "+j.Value.ToString()
				map[j.Key]=j.Value.ToString()
			Next
		Next
	End
	
	Method LoadDefault()
		
		Load( "asset::liveTemplates.json" )
	End
		
	Operator []:String( fileType:String,name:String )
	
		Local map:=_items[fileType]
		Return map ? map[name] Else Null
	End
	
	Operator []=( fileType:String,name:String,value:String )
	
		Local map:=_items[fileType]
		If map Then map[name]=value
	End
	
	Method All:StringMap<String>.Iterator( fileType:String )
		
		Local map:=_items[fileType]
		Return map ? map.All() Else Null
	End
	
	Method Add( fileType:String,name:String,value:String )
	
		Local map:=_items[fileType]
		If map Then map.Add( name,value )
	End
	
	Method Remove( fileType:String,name:String )
	
		Local map:=_items[fileType]
		If map Then map.Remove( name )
	End
	
	
	Private
	
	Field _items:=New StringMap<StringMap<String>>
	
End


Class TemplateListViewItem Extends ListViewItem
	
	Field name:String
	Field value:String
	
	Method New( name:String,value:String )
		
		Super.New( name+"   (template)" )
		
		Self.name=name
		Self.value=value
	End
	
End
