
Namespace ted2go


Class LiveTemplateDialog
	
	Method New( rootPath:String )
	
		Title="Generate class"
	
		_table=New TableView
		_table.AddColumn( "Setting" )
		_table.AddColumn( "Value" )
	
		_table.Rows+=_vars.Length
	
		For Local i:=0 Until _vars.Length
			Local pvar:=_vars[i]
	
			_table[0,i]=New Label( pvar.name )
			_table[1,i]=pvar.CreateFieldView()
		End
	
		ContentView=_table
	
		Local okay:=AddAction( "Okay" )
		okay.Triggered=Lambda()
			_result.Set( True )
		End
		SetKeyAction( Key.Enter,okay )
	
		Local cancel:=AddAction( "Cancel"  )
		cancel.Triggered=lambda()
			_result.Set( False )
		End
		SetKeyAction( Key.Escape,cancel )
	
	End
	
	
	Private
	
	Field _path:String
	Field _table:TableView
	
End

