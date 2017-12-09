
Namespace ted2go


Class HelpActions

	Field quickHelp:Action
	Field onlineHelp:Action
	Field viewManuals:Action
	Field uploadModules:Action
	Field about:Action
	Field aboutTed2go:Action
	Field makeBetter:Action
	Field mx2homepage:Action
	Field bananas:Action
	
	
	Method New()
	
		quickHelp=New Action( "Quick help" )
		quickHelp.Triggered=OnQuickHelp
		quickHelp.HotKey=Key.F1
		
		onlineHelp=New Action( "Online help" )
		onlineHelp.Triggered=lambda()
		
			OpenUrl( MONKEY2_DOMAIN+"/monkey2-docs/" )
		End
		
		viewManuals=New Action( "Browse manuals" )
		viewManuals.Triggered=Lambda()
		
			OpenUrl( RealPath( "docs/index.html" ) )
		End
		
		uploadModules=New Action( "Upload module" )
		uploadModules.Triggered=Lambda()
		
			GotoUploadModulesPage()
		End
		
		about=New Action( "About monkey2" )
		about.Triggered=Lambda()
		
			OnAboutDialog( "About monkey2",MainWindow.AboutPagePath )
		End
		
		aboutTed2go=New Action( "About ted2go" )
		aboutTed2go.Triggered=Lambda()
			
			OnAboutDialog( "About ted2go","asset::ted2/aboutTed2Go.html" )
		End
		
		makeBetter=New Action( "Make this app better! (paypal)" )
		makeBetter.Triggered=Lambda()
		
			OpenUrl( "https://paypal.me/engor/10" )
		End
		
		mx2homepage=New Action( "Monkey2 homepage" )
		mx2homepage.Triggered=lambda()
		
			OpenUrl( MONKEY2_DOMAIN )
		End
		
		bananas=New Action( "Bananas showcase" )
		bananas.Triggered=lambda()
		
			MainWindow.ShowBananasShowcase()
		End
	End
	
	Private
	
	Field _docs:DocumentManager
	
	Method OnQuickHelp()
	
		MainWindow.ShowHelp()
	End
	
	Method OnAboutDialog( title:String,url:String,okButton:String="Okay!" )
	
		Local htmlView:=New HtmlView
		htmlView.Go( url )
	
		Local dialog:=New DialogExt( title,htmlView )
	
		dialog.MinSize=New Vec2i( 640,600 )
	
		dialog.AddAction( okButton ).Triggered=dialog.Hide
	
		dialog.FadeEnabled=True ' faded
	
		dialog.Show()
	
	End
	
End


Function GotoUploadModulesPage()
	
	Alert( "Now taking you to the module manager page at "+MONKEY2_DOMAIN+".~n~nNote: You must have an account at "+MONKEY2_DOMAIN+" and be logged in to upload modules." )
	
	OpenUrl( RealPath( MONKEY2_DOMAIN+"/module-manager/" ) )
	
End
