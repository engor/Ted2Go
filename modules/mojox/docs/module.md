
# The mojox module.

The mojox module provides a simple but highly customizable gui system, built on top of mojo. Mojox also uses 'auto-layout' as much as possible, so you don't generally have to provide location/size of widgets, and can easily change fonts, skins etc without having to manually 're-layout' your gui.

Much of the core functionality of mojox is actually implemented in the mojo module by the [[mojo.app.AppInstance]] 
and [[mojo.app.View]] classes. The View class is the base class of all 'widgets' in mojo/mojox (including the mojo Window class), and mojox really just provides a set of useful view subclasses provide buttons, text views, dialogs etc.

Views are stored in a simple 'tree' structure, where each view has an optional parent, and 0 or more children.


## View style

Each view also has a 'style', which may be shared with other views of a similar type. A view's style contains information that affects its layout and rendering including:

* Padding, Border and Margin rects. These behave much like the identically name 'css' styling properties in that they provide a nested set of rects that surrounds the view contents. Note that the 'min' and 'max' values for these rects should typically be negative, eg: to add a 4 pixel padding border to a view, use something like view.Style.Padding=New Recti( -4,-4,4,4 ).

* BackgroundColor and BorderColor. Set alpha to 0 to prevent backgound or border from being rendered.

* Skin and SkinColor. A style can have an optional '9 patch' skin that is drawn outside of padding but inside the 
border and margin areas. If present, a skin actually provides another rect that goes around the padding rect.

* Font and TextColor. These are for any text drawn in the view.

* IconColor. This is for an any icons drawn in the view.

When a view is measured (see below), the padding, skin, border and margin rects are 'added' to the content rect (as returned by OnMeasure) to produce a final 'bounding' rect. This is the rect that is used to actually layout a view within its frame.

Here is a relatively crappy diagram that may or may not help!

<img src="${CD}/diag1.png">


## Gui Layout

Gui layout is a 2 step process:

* First, all views are measured by calling their [[View.OnMeasure]] method. This step occurs in 'bottom up' order so any view's whose size is dependant on a child view's size can be sure the child has been measured first. A view's OnMeasure method should return it's preferred size - that is, the size it would like to be. Once a view has been measured, you can use the [[View.LayoutSize]] property to retrieve a view's preferred layout size. Note that this is not the value returned by the view's OnMeasure method, but an adjusted size that takes the view's style into account.

* Once measuring is complete, layout is then performed by calling the [[View.OnLayout]] method for all views in 'top down' order. View's that are responsible for handling the layout of child views should set the [[View.Frame]] property of any child views they 'own' during OnLayout. A view may by further positioned and size within it's frame depending on its [[View.Layout]] property. For example, if a view's layout is "fill", the view is resized to completely fill its frame; if layout is "float", the view retains its measured size but is positioned within its frame according to its [[View.Gravity]].
