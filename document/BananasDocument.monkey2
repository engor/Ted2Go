
Namespace ted2go


Class BananasDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_browser=New ListView
		
	End

	Protected
	
	Method OnLoad:Bool() Override
	
		Local xml:=stringio.LoadString( Path )
		
		_doc.Text=xml
		
		Return True
	End
	
	Method OnCreateBrowser:View() Override
	
		Return _browser
	End
	
	Private
	
	Field _browser:ListView
End

Class XmlDocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".xml" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New XmlDocument( path )
	End
	
	Private
	
	Global _instance:=New XmlDocumentType
	
End
