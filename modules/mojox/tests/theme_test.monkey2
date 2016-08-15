
#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"

#Import "assets/simple_theme.json"

Using std..
Using mojo..
Using mojox..

Class MyWindow Extends Window

	Method New()
		Super.New( "Theme Demo",640,480,WindowFlags.Resizable )
		
		Local theme1:=App.Theme
		Local theme2:=Theme.Load( "asset::simple_theme.json" )
		
		App.Theme=theme2

		ClearColor=App.Theme.GetColor( "windowClearColor" )
		
		New Fiber( Lambda()
		
			Repeat
			
				Alert( "Click me to change theme!" )
				
				App.Theme=App.Theme=theme1 ? theme2 Else theme1

				ClearColor=App.Theme.GetColor( "windowClearColor" )
			
			Forever

		End )
		
		App.Idle+=OnIdle
	End
	
	Method OnIdle()
	
		App.RequestRender()
		
		App.Idle+=OnIdle
	End

End


Function Main()

	Local config:=New StringMap<String>
	
'	config["initialTheme"]="asset::simple_theme.json"

	New AppInstance( config )
	
	New MyWindow
	
	App.Run()
End

