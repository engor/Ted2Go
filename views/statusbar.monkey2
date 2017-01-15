
Namespace ted2go


Class StatusBar Extends DockingView
	
	Field Cancelled:Void()
	
	Method New()
		
		Style=GetStyle( "StatusBar" )
		
		_labelText=New Label()
		_labelText.Style=GetStyle( "StatusBarText" )
		
		_labelIns=New Label( "INS")
		_labelIns.MinSize=New Vec2i( 44,0 )
		_labelIns.Style=GetStyle( "StatusBarIns" )
		AddView( _labelIns,"right" )
		
		_labelLineInfo=New Label( "0 : 0")
		_labelLineInfo.MinSize=New Vec2i( 200,0 )
		_labelLineInfo.Style=GetStyle( "StatusBarLineInfo" )
		AddView( _labelLineInfo,"right" )
		
		Local act:=New Action( Null,ThemeImages.Get( "cancel.png" ) )
		act.Triggered=OnCancel
		
		_progressCancel=New ToolButtonExt( act,"" ) '"Stop process" )
		AddView( _progressCancel,"right" )
		
		_progress=New ProgressBar
		_progress.MinSize=New Vec2i( 170,0 )
		_progress.MaxSize=New Vec2i( 170,16 )
		_progress.Layout="float"
		_progress.Style=GetStyle( "StatusBarProgress" )
		AddView( _progress,"right" )
		
		ContentView=_labelText
		
		HideProgress()
	End
	
	Method SetText( text:String )
		_labelText.Text=text
	End
	
	Method SetLineInfo( text:String )
		_labelLineInfo.Text=text
	End
	
	Method SetInsMode( ins:Bool )
		_labelIns.Text=ins ? "INS" else "OVR"
	End
	
	Method ShowProgress()
		_progress.Visible=True
		_progressCancel.Visible=True
	End
	
	Method HideProgress()
		_progress.Visible=False
		_progressCancel.Visible=False
	End
	
	
	Private
	
	Field _labelText:Label
	Field _labelLineInfo:Label
	Field _labelIns:Label
	Field _progress:ProgressBar
	Field _progressCancel:ToolButtonExt
	
	Method OnCancel()
		
		HideProgress()
		Cancelled()
	End
	
End
