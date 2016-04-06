
Namespace std.time

Private

#rem monkeydoc @hidden Time class.
#end
Class Time

	#rem monkeydoc Seconds (0-61)
	
	May include 'leap' seconds.
	
	#end
	Property Seconds:Int()
		Return _tm.tm_sec
	End
	
	#rem monkeydoc Minutes (0-59)
	#end
	Property Minutes:Int()
		Return _tm.tm_min
	End
	
	#rem monkeydoc Hours since midnight (0-23)
	#end
	Property Hours:Int()
		Return _tm.tm_hour
	End
	
	#rem monkeydoc Day of the month (1-31)
	#end
	Property Day:Int()
		Return _tm.tm_mday
	End
	
	#rem monkeydoc Week day since Sunday (0-6)
	#end
	Property WeekDay:Int()
		Return _tm.tm_wday
	End
	
	#rem monkeydoc Days since January 1 (0-365)
	#end
	Property YearDay:Int()
		Return _tm.tm_yday
	End
	
	#rem monkeydoc Month since January (0-11)
	#end
	Property Month:Int()
		Return _tm.tm_mon
	End
	
	#rem monkeydoc Year
	#end
	Property Year:Int()
		Return _tm.tm_year+1900
	End
	
	#rem monkeydoc True if daylight savings is in effect.
	#end
	Property DaylightSavings:Bool()
		Return _tm.tm_isdst
	End
	
	#rem monkeydoc Converts time to a string.
	
	The string format is: WeekDay Day Month Year Hours:Minutes:Seconds
	
	#end
	Method ToString:String()
		Return _days[ WeekDay ]+" "+Day+" "+_months[ Month ]+" "+Year+" "+ Hours+":"+Minutes+":"+Seconds
	End

	#rem monkeydoc Overloaded compare operator.
	
	Time x is 'less than' time y if time x represents a time 'earlier' than time y.
	
	#end	
	Operator<=>:Int( time:Time )
		Return libc.difftime( _timer,time._timer )<=>0
	End
	
	#rem monkeydoc Gets current time.
	#end
	Function Now:Time()
		Local timer:=libc.time( Null )
		Local tm:=libc.localtime( Varptr timer )
		Return New Time( timer,tm )
	End

	Private
	
	Const _days:=New String[]( "Sun","Mon","Tue","Wed","Thu","Fri","Sat" )
	Const _months:=New String[]( "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec" )
	
	Field _timer:libc.time_t	
	Field _tm:libc.tm_t
	
	Method New( timer:libc.time_t,tm:libc.tm_t Ptr )
		_timer=timer
		_tm=tm[0]
	End
	
End

#rem monkeydoc @hidden Gets the number of seconds since the app started.
#end
Function Seconds:Double()
	Return Double(clock())/Double(CLOCKS_PER_SEC)
End

#rem monkeydoc Gets the number of milliseconds since the app started.
#end
Function Millisecs:Int()
	'Note:CLOCKS_PER_SECOND=1000000 on macos/linux, 1000 on windows...
	If CLOCKS_PER_SEC>=1000 Return clock()/(CLOCKS_PER_SEC/1000)
	Return clock()*(1000/CLOCKS_PER_SEC)	'is that right?!?
End
