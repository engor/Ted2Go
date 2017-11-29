
Namespace ted2go


Class JsonDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_view=New JsonDocumentView( Self )
		
		_doc=_view.Document
		
		_browser=New JsonTreeView
		
		_browser.NodeClicked+=Lambda( node:TreeView.Node )
			
			Local i:=FindInText( node,-1 )
			
			If i=-1 Return
			
			Local from:=Min( _view.Cursor,_view.Anchor )
			
			If i=from
				i=FindInText( node,from )
				If i=-1 Return
			Endif
			
			Local name:=node.Text.Slice( 0,node.Text.Find( ":" ) )
			_view.SelectText( i,i+name.Length+2 ) '2 for quotes
			_view.MakeCentered()
		End
		
		_doc.TextChanged+=Lambda()
		
			_browser.Value=JsonValue.Parse( _doc.Text )
			
			Dirty=True
		End
		
	End

	Protected
	
	Method OnLoad:Bool() Override
	
		Local json:=stringio.LoadString( Path )
		
		_doc.Text=json
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local json:=_doc.Text
		
		Return stringio.SaveString( json,Path )
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method OnCreateBrowser:View() Override
	
		Return _browser
	End
	
	Method OnGetTextView:TextView( view:View ) Override
	
		Return Cast<TextView>( view )
	End
	
	Private
	
	Field _doc:TextDocument
	
	Field _view:JsonDocumentView
	
	Field _browser:JsonTreeView
	
	Method FindInText:Int( node:TreeView.Node,fromIndex:Int )
		
		Local nodes:=New Stack<TreeView.Node>
		While node And node.Text.Contains( ":" )
			If node.Text.Contains( ":[" )
				' skip array indexing nodes
				nodes.Erase( 0 )
			Endif
			nodes.Insert( 0,node )
			node=node.Parent
		Wend
		
		Local index:=fromIndex
		For Local n:=Eachin nodes
			Local s:=n.Text
			Local i:=s.Find( ":" )
			Local name:="~q"+s.Slice( 0,i )+"~q"
			i=_view.Text.Find( name,index+1 )
			If i=-1 Return -1
			index=i
		Next
		
		Return index
	End
	
End


Class JsonDocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".json" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New JsonDocument( path )
	End
	
	Private
	
	Global _instance:=New JsonDocumentType
	
End


Class JsonDocumentView Extends Ted2CodeTextView
	
	Method New( doc:Ted2Document )
		
		'very important to set FileType for init
		'formatter, highlighter and keywords
		FileType=doc.FileExtension
		FilePath=doc.Path
	End
	
End
