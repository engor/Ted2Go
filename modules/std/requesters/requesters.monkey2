
Namespace std.requesters

#If __DESKTOP_TARGET__

#Import "native/requesters.h"

#If __TARGET__="macos"

	#Import "native/requesters.mm"

#Else

	#Import "native/requesters.cpp"
	
	#if __TARGET__="windows"

		#Import "<libComdlg32.a>"
'		#Import "<libole32.a>"

	#endif
	
#endif

Extern

Function Notify:Void( title:String,text:String,serious:Bool=False )="bbRequesters::Notify"

Function Confirm:Bool( title:String,text:String,serious:Bool=False )="bbRequesters::Confirm"

Function Proceed:Int( title:String,text:String,serious:Bool=False )="bbRequesters::Proceed"

Function RequestFile:String( title:String,filter:String="",save:Bool=False,file:String="" )="bbRequesters::RequestFile"

Function RequestDir:String( title:String,dir:String="" )="bbRequesters::RequestDir"

Function OpenUrl( url:String )="bbRequesters::OpenUrl"

#else

Function Notify:Void( title:String,text:String,serious:Bool=False )
End

Function Confirm:Bool( title:String,text:String,serious:Bool=False )
	Return False
End

Function RequestFile:String( title:String,filter:String="",save:Bool=False,file:String="" )
	Return ""
End

Function RequestDir:String( title:String,dir:String="" )
	Return ""
End

Function OpenUrl( url:String )
End

#endif
