
Namespace ted2go


Class OptionsField Extends DockingView

	Field CurrentChanged:Void()

	Method New( options:String[],current:Int=0 )
	
		_options=options
		
		_current=current
		
		_group=New CheckGroup
		
		_group.CheckedChanged+=Lambda()
		
			For Local i:=0 Until _checks.Length
				If _group.Checked=_checks[i]
					_current=i
					CurrentChanged()
					Return
				Endif
			Next
			
		End

		_checks=New CheckButton[options.Length]
		
		For Local i:=0 Until options.Length
		
			_checks[i]=New CheckButton( _options[i],,_group )
			
			AddView( _checks[i],"left" )
		
		Next
		
		_checks[_current].Checked=True
	End
	
	Property Current:Int()
	
		Return _current
	
	Setter( current:Int )
	
		_current=current
		
		_checks[_current].Checked=True
	End
	
	Private

	Field _options:String[]
	
	Field _current:Int
	
	Field _group:CheckGroup
	
	Field _checks:CheckButton[]
	
End

Class FilePathField Extends DockingView

	Field FilePathChanged:Void()

	Method New( path:String="",fileType:FileType=FileType.File )
	
		_fileType=fileType

		_textField=New TextField( path )
		
		_textField.TextChanged+=Lambda()
		
			FilePathChanged()
		End

		_pathButton=New PushButton( "..." )
		
		_pathButton.Clicked=Lambda()
		
			New Fiber( Lambda()
		
				Local future:=New Future<String>
			
				App.Idle+=Lambda()
					If _fileType=FileType.Directory
						future.Set( requesters.RequestDir( "Select Directory",_textField.Text ) )
					Else
						future.Set( requesters.RequestFile( "Select File",_textField.Text ) )
					Endif
				End
				
				Local path:=future.Get()
				If Not path Return
				
				_textField.Text=path
				
				FilePathChanged()
			End )
		End
		
		AddView( _pathButton,"right" )

		ContentView=_textField

		MaxSize=New Vec2i( 320,0 )
	End
	
	Property FilePath:String()
	
		Return _textField.Text
	
	Setter( path:String )
	
		_textField.Text=path
	End
	
	Property FileType:FileType()
	
		Return _fileType
	
	Setter( fileType:FileType )
	
		_fileType=fileType
	End
	
	Private
	
	Field _textField:TextField
	Field _pathButton:PushButton
	Field _fileType:FileType

End

Class ProductVar

	Field name:String
	Field value:String
	Field type:String
		
	Method New( name:String,value:String,type:String="string" )
		Self.name=name
		Self.value=value
		Self.type=type
	End
	
	Method CreateFieldView:View()
	
		Local fieldView:View
		
		Select type
		Case "string"
		
			Local view:=New TextField( value )
			
			view.TextChanged+=Lambda()
				value=view.Text
			End
			
			fieldView=view
			
		Case "directory"
		
			Local view:=New FilePathField( value,FileType.Directory )
			
			view.FilePathChanged=Lambda()
				value=view.FilePath
			End
			
			fieldView=view
			
		Default
		
			If type.StartsWith( "options:" )

				Local opts:=type.Slice( 8 ).Split( "|" )
				
				Local current:=0
				For Local i:=0 Until opts.Length
					If value<>opts[i] Continue
					current=i
					Exit
				Next

				Local view:=New OptionsField( opts,current )

				view.CurrentChanged+=Lambda()

					value=opts[view.Current]
				End
			
				fieldView=view

			Endif
		End
		
		Return fieldView
	End
		
End

Class EditProductDialog Extends Dialog

	Method New( title:String,vars:Stack<ProductVar> )
	
		Title=title
		
		_vars=vars
		
		_table=New TableView
		_table.AddColumn( "Setting" )
		_table.AddColumn( "Value" )
		
		_table.AddRows( _vars.Length )
		
		For Local i:=0 Until _vars.Length
			Local pvar:=_vars[i]
			
			_table[0,i]=New Label( pvar.name )
			_table[1,i]=pvar.CreateFieldView()
		End
		
		ContentView=_table
		
		AddAction( "Okay" ).Triggered=Lambda()

			_result.Set( True )
		End
		
		AddAction( "Cancel"  ).Triggered=lambda()
			
			_result.Set( False )
		End
	End
	
	Method Run:Bool()
	
		Open()
		
		App.BeginModal( Self )
		
		Local result:=_result.Get()
		
		App.EndModal()
		
		Close()
		
		Return result
	End
	
	Private
	
	Field _table:TableView
	
	Field _vars:Stack<ProductVar>
	
	Field _result:=New Future<Bool>

End
