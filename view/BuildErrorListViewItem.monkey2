
Namespace ted2go


Class BuildErrorListViewItem Extends ListViewItem
	
	Field error:BuildError
	
	Method New( text:String,icon:Image )
		
		Super.New( text,icon )
	End
	
	Method New( err:BuildError )
	
		Super.New( err.msg )
		Text="["+(err.line+1)+"] "+err.msg.Trim()+" ("+err.path+")"
		error=err
	End
	
End
