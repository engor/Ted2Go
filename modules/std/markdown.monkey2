
Namespace std.markdown

#Import "<hoedown.monkey2>"

Using hoedown

Function MarkdownToHtml:String( markdown:String )

	Local ob:=hoedown_buffer_new( 4096 )
	
	Local r:=hoedown_html_renderer_new( HOEDOWN_HTML_NONE,10 )
	
	Local doc:=hoedown_document_new( r,HOEDOWN_EXT_TABLES|HOEDOWN_EXT_FENCED_CODE,10 )
		
	hoedown_document_render( doc,ob,markdown,markdown.Utf8Length )
	
	Local html:=String.FromCString( hoedown_buffer_cstr( ob ) )
	
	hoedown_document_free( doc )
	
	hoedown_html_renderer_free( r )
	
	hoedown_buffer_free( ob )
	
	Return html

End
