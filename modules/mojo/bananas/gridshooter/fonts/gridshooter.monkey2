
#Import "renderwindow/renderwindow"
#Import "gamegraphics/gamegraphics"

#Import "fonts/classic_sans.ttf"
#Import "images/grid.png"
#Import "images/starfield.png"
#Import "images/hero.png"
#Import "images/jet.png"
#Import "images/bullet.png"

Using mojo..
Using std..

Class Game Extends RenderWindow

	Field bg:Background
	Field bgGrid:Background
	Field smallFont:Font
	Field heroSprite:Sprite
	Field jetSprite:Sprite
	Field bulletSprite:Sprite
	
	Field x:Double, y:Double, speed:= 2.0
	Field oldX:Float, oldY:Float
	Field anim:= "idle"
	
	Field cameraSpeed := 5.0
	Field colorTint:= New Color( 0.25, 1.0, 0.5 )
	
	Field allBullets := New Stack<Bullet>
	Field lastFired := 0
	
	Method New()					
		Super.New( "Test", 480, 270, False, True )		'name, width, height, filterTextures, renderToTexture
	End
	
	Method OnStart() Override
		canvas.Font = Font.Load( "asset::classic_sans.ttf", 10 )
		bg = New Background( "asset::starfield.png", False )
		bgGrid = New Background( "asset::grid.png", False )
		
		heroSprite = New Sprite( "asset::hero.png", 3, 32, 32, False )
		heroSprite.AddAnimationClip( "idle", New Int[]( 0 ) )
		heroSprite.AddAnimationClip( "up", New Int[]( 1 ) )
		heroSprite.AddAnimationClip( "down", New Int[]( 2 ) )
		
		jetSprite = New Sprite( "asset::jet.png", 2, 16, 16, False )
		jetSprite.AddAnimationClip( "idle", New Int[]( 0,1 ) )
		jetSprite.frameRate = 30
		
		bulletSprite = New Sprite( "asset::bullet.png", 4, 32, 32, False )
		bulletSprite.AddAnimationClip( "idle", New Int[] ( 0 ) )
		bulletSprite.AddAnimationClip( "hit", New Int[] ( 1,2,3 ) )
		
		For Local n := 0 Until 10
			allBullets.Push( New Bullet )
		Next
	End
	
	Method OnUpdate() Override
		camera.X += cameraSpeed		
		x += cameraSpeed
		
		If Keyboard.KeyHit( Key.D ) Then debug = Not debug

		If Keyboard.KeyDown( Key.Left )
			x -= speed
		Else If Keyboard.KeyDown( Key.Right )
			x += speed
		End
		If Keyboard.KeyDown( Key.Up )
			y -= speed * 2
			camera.Y -= speed
		Else If Keyboard.KeyDown( Key.Down )
			y += speed * 2
			camera.Y += speed
		End
		
		If Keyboard.KeyHit( Key.Space )
			Local bullet := allBullets.Get( lastFired )
			bullet.visible = True
			bullet.x = x + 16
			bullet.y = y + 4
			lastFired += 1
			If lastFired > 9 Then lastFired = 0
		End
		
		x = Clamp( x, camera.Left, camera.Right )
		y = Clamp( y, camera.Top, camera.Bottom )
		
		If y > oldY
			anim = "down"
		Elseif y < oldY
			anim = "up"
		Else
			anim = "idle"
		End
		oldY = y
	End
	
	Method OnDraw() Override
		canvas.Color = colorTint
		
		canvas.Alpha = 1.0
		Parallax = 0.05
		bg.Draw( canvas, 0, 0, 1.0, CameraRect )
		
		canvas.Alpha = 0.25
		Parallax = 0.2
		bgGrid.Draw( canvas, 32, 32, 1.0, CameraRect )
		
		canvas.Alpha = 0.5
		Parallax = 1.0
		bgGrid.Draw( canvas, 0, 0, 1.0, CameraRect )
		
		canvas.Alpha = 1.0
		canvas.Color= Color.White
		jetSprite.Draw( canvas, "idle", x-16, y+2 )
		heroSprite.Draw( canvas, anim, x, y )
		
		For Local b := Eachin allBullets
			If b.visible
				bulletSprite.Draw( canvas, "idle", b.x, b.y )
				b.x += b.speed
				If b.x > ( x + Width ) Then b.visible = False
			End
		Next
	End

End

Class Bullet
	Field visible := False
	Field x:Float, y:Float, speed:Float = 15.0
End

Function Main()
	New AppInstance
	New Game()
	App.Run()
End


