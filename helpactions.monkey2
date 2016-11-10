
Namespace ted2go


Class HelpActions

	Field onlineHelp:Action
	Field viewManuals:Action
	Field uploadModules:Action
	Field about:Action
	Field aboutTed2go:Action

	Method New()
	
		onlineHelp=New Action( "Online help" )
		onlineHelp.Triggered=lambda()
		
			OpenUrl( "http://monkey2.monkey-x.com/modules-reference/" )
		End
		
		viewManuals=New Action( "Browse manuals" )
		viewManuals.Triggered=Lambda()
		
			OpenUrl( RealPath( "docs/index.html" ) )
		End
		
		uploadModules=New Action( "Upload module" )
		uploadModules.Triggered=Lambda()
		
			Alert( "Now taking you to the module manager page at monkey2.monkey-x.com~n~nNote: You must have an account at monkey2.monkey-x.com and be logged in to upload modules" )
		
			OpenUrl( RealPath( "http://monkey2.monkey-x.com/module-manager/" ) )
		End

		about=New Action( "About monkey2" )
		about.Triggered=Lambda()
		
			Local htmlView:=New HtmlView
			htmlView.Go( "asset::ted2/about.html" )
	
			Local dialog:=New Dialog( "About monkey2" )
			dialog.ContentView=htmlView

			dialog.MinSize=New Vec2i( 640,600 )

			dialog.AddAction( "Okay!" ).Triggered=dialog.Close
			
			dialog.Open()
		End

		aboutTed2go=New Action( "About ted2go" )
		aboutTed2go.Triggered=Lambda()
		
			Local htmlView:=New HtmlView
			htmlView.Go( "asset::ted2/aboutTed2Go.html" )
	
			Local dialog:=New Dialog( "About ted2go" )
			dialog.ContentView=htmlView

			dialog.MinSize=New Vec2i( 640,600 )

			dialog.AddAction( "Okay!" ).Triggered=dialog.Close
			
			dialog.Open()
		End
		
	End

End
