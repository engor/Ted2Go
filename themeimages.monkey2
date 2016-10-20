
Namespace ted2go


Class ThemeImages Extends Plugin

	Property Name:String() Override
		Return "ThemeImages Plugin"
	End
	
	Function Get:Image(key:String)
		Print "222 "+key
		If Not _images.Contains(key)
			Local img := Image.Load("theme::"+key)
			If img Then img.Scale = App.Theme.Scale
			_images[key] = img
			Return img
		Endif
		Return _images[key]
		
	End
	
	
	Private
	
	Global _images := New StringMap<Image>
	Global _inst := New ThemeImages
	
	Method New()
	End
	
	Method OnCreate() Override
		Print "111"
		App.ThemeChanged += Lambda()
			AdjustIconsScale()
		End
	End
	
	Function AdjustIconsScale()
		For Local i := Eachin _images.Values
			i.Scale = App.Theme.Scale
		Next
	End
	
End
