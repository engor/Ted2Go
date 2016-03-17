
#Import "<std.monkey2>"

Using std.time

Function Main()

	Print "Seconds() at start="+Seconds()

	Print "CLOCKS_PER_SEC="+libc.CLOCKS_PER_SEC
	
	Local start:=Seconds()
	Print "Waiting 5 seconds..."
	While Seconds()<start+5
	Wend
	Print "Done!"

	Local time:=Time.Now()
	
	Print time.Seconds
	Print time.Minutes
	Print time.Hours
	Print time.Day
	Print time.Month
	Print time.Year
	Print "Daylight savings="+(time.DaylightSavings ? "true" Else "false")
	
	Print time.ToString()

	start=Seconds()
	While Seconds()<start+1
	Wend
		
	Local time2:=Time.Now()
	
	Print time<=>time2		'-1
	Print time2<=>time		'1
	
End
