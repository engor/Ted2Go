
Namespace std.markdown

Function MarkdownToHtml:String( markdown:String )

	Local help:=LoadString( "asset::help.markdown" )
	Local html:=LoadString( "asset::markdown.html" )
	html=html.Replace( "${CONTENT}",HtmlView.MarkdownToHtml( help ) )

End
