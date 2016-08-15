
#import "<std>"
#import "<mojo>"
#import "<mojox>"

#import "assets/about.html"

Using std..
Using mojo..
Using mojox..

Class MyWindow Extends Window

	Method New()
		Super.New( "HtmlView Demo",640,480,WindowFlags.Resizable )

		Local htmlView:=New HtmlView
		
		htmlView.Go( "assets::about.html" )
		
		ContentView=htmlView
		
		App.Idle+=OnIdle
	End
	
	Method OnIdle()
	
		App.RequestRender()
		
		App.Idle+=OnIdle
	End

End


Function Main()

	New AppInstance
	
	New MyWindow
	
	App.Run()
End

