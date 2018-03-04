# Ted2Go
An IDE for Monkey2 programming language.

Binaries for MacOS and Windows are available at [itch.io](https://nerobot.itch.io/ted2go).

## Benefits & Goals
* Autocompletion for keywords, modules and user's code (WIP).
* On-the-fly parser - see errors w/o build (not all errors).
* "Find in project" dialog.
* CodeTree and NavigationList for comfortable code jumping (todo).
* Code folding and bookmarks (todo).
* Doc's hints directly inside of code area (todo).

## More info
Discuss on [forum page](http://monkeycoder.co.nz/forums/topic/ted2go-fork/).

## Monkey <-> money :)
Support me if you like this project:
* [PayPal](https://paypal.me/engor)
* Payed downloading [from itch.io](https://nerobot.itch.io/ted2go)
* Become a patron [on Patreon.com](https://www.patreon.com/nerobot)

## Notes for contributors
Please, take a look at code style. It based on original Ted2.

Will be super-cool if you can write the same style to make this project consistent.

`Local abc:="ABC"` ' there is no spaces in assignment

`digit=8`

`callSomeMethod( param1,param2 )` 'there are spaces in bracket bounds

```
Method check:Bool( value:Double ) 'spaces in declaration
                          ' empty line after method name (can ignore if there is one-line body)
   Return value > 1.75
End
```
