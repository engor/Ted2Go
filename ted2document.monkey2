
Namespace ted2

Class Ted2Document

	Field DirtyChanged:Void()	'also triggered by save/rename
	
	Field StateChanged:Void()

	Field Closed:Void()

	Method New( path:String )
	
		_path=path
		
		_modTime=GetFileTime( _path )
	End
	
	Property Path:String()

		Return _path
	End
	
	Property ModTime:Long()
	
		Return _modTime
	End
	
	Property State:String()
	
		Return _state
	
	Setter( state:String )
	
		_state=state
		
		StateChanged()
	End
	
	Property View:View()
	
		If Not _view _view=OnCreateView()
		
		Return _view
	End
	
	Property TextView:TextView()
	
		Return OnGetTextView( View )
	End
	
	Property Dirty:Bool()
	
		Return _dirty
	
	Setter( dirty:Bool)

		If dirty=_dirty Return
		
		_dirty=dirty
		
		DirtyChanged()
	End
	
	Method Load:Bool()
	
		If Not OnLoad() 
			MainWindow.ReadError( _path )
			Return False
		Endif
		
		_modTime=GetFileTime( _path )

		Dirty=False
		
		Return True
	End
	
	Method Save:Bool()
	
		If Not _dirty Return True
		
		If Not OnSave()
			MainWindow.WriteError( _path )
			Return False
		Endif
		
		_modTime=GetFileTime( _path )
		
		Dirty=False

		Return True
	End
	
	Method Rename( path:String )
	
		_path=path
		
		Dirty=True
	End
	
	Method Close()
	
		OnClose()
		
		Closed()
	End
	
	Protected

	Method OnLoad:Bool() Virtual
	
		Return False
	End
	
	Method OnSave:Bool() Virtual
	
		Return False
	End
	
	Method OnCreateView:View() Virtual
	
		Return Null
	End
	
	Method OnGetTextView:TextView( view:View ) virtual
	
		Return Cast<TextView>( view )
	End
	
	Method OnClose() Virtual
	End
	
	Private

	Field _dirty:Bool
	Field _path:String
	Field _modTime:Long
	Field _state:String
	Field _view:View
	
End
