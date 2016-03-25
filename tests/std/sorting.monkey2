
#Import "<std>"

Using std.random
Using std.collections

Function Shuffle( deck:Int[] )
	Local n:=deck.Length
	For Local i:=0 Until n
		Local j:=Int( Rnd()*10 )
		Local t:=deck[i]
		deck[i]=deck[j]
		deck[j]=t
	Next
End

Function Test<T>()

	Local deck:=New Int[100]
	For Local i:=0 Until 100
		deck[i]=i
	Next

	Local list:=New T<Int>
	
	For Local n:=0 Until 100
	
		Shuffle( deck )
	
		list.Clear()
		For Local i:=0 Until 100
			list.Add( deck[i] )
		Next
		
		list.Sort()
		Local t:=-1
		For Local i:=Eachin list
			If i<t Print "***** SORT ERROR! *****"
			t=i
		Next
		
	Next

End


Function Main()

	Print "Testing Stack"
	Test< Stack >()
	
	Print "Testing List"
	Test< List >()

End
