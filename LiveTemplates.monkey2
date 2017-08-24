
Namespace ted2go


#Import "assets/liveTemplates.json"

Const LiveTemplates:=New LiveTemplatesClass

Class LiveTemplatesClass
	
	Field DataChanged:Void( lang:String )
	
	Method Load( jsonPath:String )
		
		Local langs:=Json_LoadObject( jsonPath ).All()
		For Local i:=Eachin langs
			Local lang:=i.Key
			Local map:=New StringMap<String>
			_items[lang]=map
			Local all:=i.Value.ToObject().All()
			For Local j:=Eachin all
				'Print j.Key+" <-> "+j.Value.ToString()
				map[j.Key]=j.Value.ToString().Replace( "~r~n","~n" ).Replace( "~r","~n" )
			Next
		Next
		NotifyDataChanged()
	End
	
	Method LoadDefault()
		
		Load( "asset::liveTemplates.json" )
	End
	
	Operator []:StringMap<String>( fileType:String )
	
		Return _items[fileType]
	End
		
	Operator []:String( fileType:String,name:String )
	
		Local map:=_items[fileType]
		Return map ? map[name] Else Null
	End
	
	Operator []=( fileType:String,name:String,value:String )
	
		Local map:=_items[fileType]
		If map
			map[name]=value
			OnChanged( fileType )
		Endif
	End
	
	Method All:StringMap<StringMap<String>>.Iterator()
	
		Return _items.All()
	End
	
	Method All:StringMap<String>.Iterator( fileType:String )
		
		Local map:=_items[fileType]
		Return map ? map.All() Else Null
	End
	
	Method Add( fileType:String,name:String,value:String )
	
		Local map:=_items[fileType]
		If map 
			map[name]=value
			OnChanged( fileType )
		Endif
	End
	
	Method Remove( fileType:String,name:String )
	
		Local map:=_items[fileType]
		If map
			map.Remove( name )
			OnChanged( fileType )
		Endif
	End
	
	Method NotifyDataChanged()
		
		For Local it:=Eachin All()
			DataChanged( it.Key )
		Next
		_dirty=False
	End
	
	
	Private
	
	Field _items:=New StringMap<StringMap<String>>
	Field _dirty:Bool
	
	Method OnChanged( lang:String )
		
		_dirty=True
	End
	
End


Class TemplateListViewItem Extends ListViewItem
	
	Field name:String
	Field value:String
	
	Method New( name:String,value:String )
		
		Super.New( GetCaption( name,value ) )
		
		Self.name=name
		Self.value=value
	End
	
	
	Private
	
	Method GetCaption:String( name:String,value:String )
		
		Local s:=value.Replace( "~n"," ... " ).Replace( "~t","" ).Replace( "${Cursor}","" )
		Return name+"   "+s
	End
End
