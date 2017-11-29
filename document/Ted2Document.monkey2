
Namespace ted2go


Class Ted2Document

	Field DirtyChanged:Void()
	
	Field StateChanged:Void()

	Field Closed:Void()

	Method New( path:String )
	
		_path=path
		_fileExt=ExtractExt( _path )
				
		_modTime=GetFileTime( _path )
	End
	
	Property Path:String()

		Return _path
	End
	
	Property FileExtension:String()'file extension
		
		Return _fileExt
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
	
	Property BrowserView:View()
	
		If Not _browser _browser=OnCreateBrowser()
		
		Return _browser
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

	'DON'T USE YET!	
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
	
	Method OnCreateBrowser:View() Virtual
	
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
	Field _fileExt:String
	Field _browser:View
	
End

Class Ted2DocumentType Extends Plugin

	Property Name:String() Override
		Return "Ted2DocumentType"
	End
	
	Function ForExtension:Ted2DocumentType( ext:String )
	
		ext=ext.ToLower()

		Local types:=Plugin.PluginsOfType<Ted2DocumentType>()
		Local defaultType:Ted2DocumentType = Null
		
		For Local type:=Eachin types
		
			For Local ext2:=Eachin type.Extensions
			
				If ext=ext2 Return type
				If ext2 = ".*" Then defaultType = type
			Next
			
		Next
		
		If defaultType <> Null Return defaultType 'use it if there is no registered extension
		
		Return Null
	End
	
	Method CreateDocument:Ted2Document( path:String )
	
		Return OnCreateDocument( path )
	End

	Protected
	
	Method New()

		AddPlugin( Self )
	End
	
	Property Extensions:String[]()
	
		Return _exts.ToArray()
	
	Setter( exts:String[] )
	
		_exts.Clear()
		_exts.AddAll( exts )
	End
	
	Method AddExtensions( exts:String[] )
		
		For Local ext:=Eachin exts
			If Not _exts.Contains( ext )
				_exts.Add( ext )
			Endif
		Next
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Virtual
	
		Return Null	'should return hex editor!
	End

	Private
	
	Field _exts:=New StringStack
	
	
End
