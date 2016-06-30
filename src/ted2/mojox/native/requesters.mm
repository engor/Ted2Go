
#include "requesters.h"

#import <Cocoa/Cocoa.h>

namespace{

	typedef int (*AlertPanel)( 
		NSString *title,
		NSString *msg,
		NSString *defaultButton,
		NSString *alternateButton,
		NSString *otherButton );
	
	NSWindow *keyWin;
	
	void beginPanel(){
		keyWin=[NSApp keyWindow];
		if( !keyWin ) [NSApp activateIgnoringOtherApps:YES];
	}
	
	void endPanel(){
		if( keyWin ) [keyWin makeKeyWindow];
	}
	
	NSString *ConvString( bbString str ){
		return [NSString stringWithCharacters:(const unichar*)str.data() length:str.length()];
	}
	
	bbString ConvString( NSString *str ){
		int n=[str length];
		unichar *buf=new unichar[ n ];
		[str getCharacters:buf range:NSMakeRange( 0,n )];
		bbString t=bbString( buf,n );
		delete[] buf;
		return t;
	}
}

void bbRequesters::Notify( bbString title,bbString text,bbBool serious ){

	AlertPanel panel=(AlertPanel) ( serious ? (void*)NSRunCriticalAlertPanel : (void*)NSRunAlertPanel );
	
	beginPanel();
	
	panel( ConvString( title ),ConvString( text ),@"OK",0,0 );
	
	endPanel();
}

bbBool bbRequesters::Confirm( bbString title,bbString text,bbBool serious ){

	AlertPanel panel=(AlertPanel) ( serious ? (void*)NSRunCriticalAlertPanel : (void*)NSRunAlertPanel );
	
	beginPanel();
	
	int n=panel( ConvString( title ),ConvString( text ),@"OK",@"Cancel",0 );

	endPanel();
	
	switch( n ){
	case NSAlertDefaultReturn:return 1;
	}
	return 0;
}

int bbRequesters::Proceed( bbString title,bbString text,bbBool serious ){

	AlertPanel panel=(AlertPanel) ( serious ? (void*)NSRunCriticalAlertPanel : (void*)NSRunAlertPanel );
	
	beginPanel();
	
	int n=panel( ConvString( title ),ConvString( text ),@"Yes",@"No",@"Cancel" );
	
	endPanel();
	
	switch( n ){
	case NSAlertDefaultReturn:return 1;
	case NSAlertAlternateReturn:return 0;
	}
	return -1;
}

bbString bbRequesters::RequestFile( bbString title,bbString filter,bbBool save,bbString path ){

	bbString file,dir;
	int i=path.findLast( "\\" );
	if( i!=-1 ){
		dir=path.slice( 0,i );
		file=path.slice( 1+1 );
	}else{
		file=path;
	}
	
	NSMutableArray *nsfilter=0;
	bool allowOthers=true;

	if( filter.length() ){
	
		allowOthers=false;
	
		nsfilter=[NSMutableArray arrayWithCapacity:10];
		
		int i0=0;
		while( i0<filter.length() ){
		
			int i1=filter.find( ":",i0 )+1;
			if( !i1 ) break;
			
			int i2=filter.find( ";",i1 );
			if( i2==-1 ) i2=filter.length();
			
			while( i1<i2 ){
			
				int i3=filter.find( ",",i1 );
				if( i3==-1 ) i3=i2;
				
				bbString ext=filter.slice( i1,i3 );
				if( ext==BB_T("*") ){
					allowOthers=true;
				}else{
					[nsfilter addObject:ConvString( ext )];
				}
				i1=i3+1;
			}
			i0=i2+1;
		}
	}

	NSString *nsdir=0;
	NSString *nsfile=0;
	NSString *nstitle=0;
	NSMutableArray *nsexts=0;

	if( dir.length() ) nsdir=ConvString( dir );
	if( file.length() ) nsfile=ConvString( file );
	if( title.length() ) nstitle=ConvString( title );

	beginPanel();
	
	bbString str;

	if( save ){
		NSSavePanel *panel=[NSSavePanel savePanel];
		
		if( nstitle ) [panel setTitle:nstitle];
		
		if( nsfilter ){
			[panel setAllowedFileTypes:nsfilter];
			[panel setAllowsOtherFileTypes:allowOthers];
		}
		
		if( [panel runModalForDirectory:nsdir file:nsfile]==NSFileHandlingPanelOKButton ){
			str=ConvString( [panel filename] );
		}

	}else{
		NSOpenPanel *panel=[NSOpenPanel openPanel];

		if( nstitle ) [panel setTitle:nstitle];
		
		if( allowOthers ) nsfilter=0;
		
		if( [panel runModalForDirectory:nsdir file:nsfile types:nsfilter]==NSFileHandlingPanelOKButton ){
			str=ConvString( [panel filename] );
		}
	}
	endPanel();

	return str;
}

bbString bbRequesters::RequestDir( bbString title,bbString dir ){

	NSString *nsdir=0;
	NSString *nstitle=0;
	NSOpenPanel *panel;
	
	if( dir.length() ) nsdir=ConvString( dir );
	if( title.length() ) nstitle=ConvString( title );

	panel=[NSOpenPanel openPanel];
	
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanCreateDirectories:YES];
	
	if( nstitle ) [panel setTitle:nstitle];

	beginPanel();
	
	bbString str;
	
	if( [panel runModalForDirectory:nsdir file:0 types:0]==NSFileHandlingPanelOKButton ){
	
		str=ConvString( [panel filename] );
	}

	endPanel();
	
	return str;
}

