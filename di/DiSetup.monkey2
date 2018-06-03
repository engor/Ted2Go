
Namespace ted2go

' place where all our types are created
'
Function SetupDiContainer()
	
	Di.Bind( Lambda:DocsTabView()
		Return New DocsTabView( TabViewFlags.DraggableTabs|TabViewFlags.ClosableTabs )
	End )
	
	Di.Bind<DocBrowserView>()
	Di.Bind<OutputConsole>()
	Di.Bind<BuildConsole>()
	
	Di.Bind( Lambda:DocumentManager()
		Return New DocumentManager(
			Di.Resolve<DocsTabView>(), ' views shouldn't be here!
			Di.Resolve<DocBrowserView>() )
	End )
	
	Di.Bind( Lambda:ProjectView()
		Return New ProjectView(
			Di.Resolve<DocumentManager>(),
			Di.Resolve<BuildActions>() )
	End )
	
	Di.Bind( Lambda:DebugView()
		Return New DebugView( 
			Di.Resolve<DocumentManager>(),
			Di.Resolve<OutputConsole>() )
	End )
	
	Di.Bind( Lambda:BuildActions()
		Return New BuildActions( 
			Di.Resolve<DocumentManager>(),
			Di.Resolve<BuildConsole>(),
			Di.Resolve<DebugView>() )
	End )
	
	Di.Bind<HelpView>()
	
	Di.Bind( Lambda:HelpTreeView()
		Local view:=New HelpTreeView(
			Di.Resolve<HelpView>() )
		view.Init()
		Return view
	End )
	
End


' some necessarily overhead
'
' ideally all classes with business logic must have interfaces
' and we must works with interfaces
'
Class DocsTabView Extends TabViewExt
	Method New( flags:TabViewFlags=TabViewFlags.DraggableTabs )
		Super.New( flags )
	End
End

Class DocBrowserView Extends DockingView
End

Class BuildConsole Extends ConsoleExt
End

Class OutputConsole Extends ConsoleExt
End

Class HelpView Extends HtmlViewExt
End