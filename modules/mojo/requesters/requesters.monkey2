
Namespace mojo.requesters

#If __TARGET__="desktop"

#Import "native/requesters.h"

#If __HOSTOS__="windows"
#Import "native/requesters.cpp"
#Import "<libcomdlg32.a>"
#Endif

#If __HOSTOS__="macos"
#Import "native/requesters.mm"
#Endif

#If __HOSTOS__="linux"
#Import "native/requesters.cpp"
#Endif

Extern

Function Notify:Void( title:String,text:String,serious:Bool=False )="bbRequesters::Notify"

Function Confirm:Bool( title:String,text:String,serious:Bool=False )="bbRequesters::Confirm"

Function Proceed:Int( title:String,text:String,serious:Bool=False )="bbRequesters::Proceed"

Function RequestFile:String( title:String,filter:String="",save:Bool=False,file:String="" )="bbRequesters::RequestFile"

Function RequestDir:String( title:String,dir:String="" )="bbRequesters::RequestDir"

Function OpenUrl( url:String )="bbRequesters::OpenUrl"

#Else

Function Notify( title:String,text:String,serious:Bool=False )
End

Function Confirm:Bool( title:String,text:String,serious:Bool=False )
	Return False
End

Function Proceed:Int( title:String,text:String,serious:Bool=False )
	Return -1
End

Function RequestFile:String( title:String,filter:String="",save:Bool=False,file:String="" )
	Return ""
End

Function RequestDir:String( title:String,dir:String="" )
	Return ""
End

#Endif
