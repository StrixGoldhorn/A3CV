# Gathering Data v1 Part 1

First, lets decide on what we need.

We need:
- a way to gather which nearby objects
- a way to gather the object's location in the game world

<br/>

- a way to translate that location into on-screen coords
- a way to check whether object is on screen

<br/>

(Below will be covered in Part 2)
- a way to get an object's bounding box
- a way to get the extreme coordinates of the bounding box

<br/>

- a way to take a screenshot
- a way to tag the locations gathered, to the screenshot taken

### Gathering nearby objects and its location

We can make use of the function `nearTargets`, where it returns an array of objects within a user-defined range (in the code below, `DetectionRange_GlobalVariable` is the variable for this range). The following code will write all the nearby targets as a hint. Part of the returned array is the object location in the game world. This will be useful later.

```sqf
HintNearbyTargets = {
    private _outputstr = "";
    _outputstr = _outputstr + str diag_tickTime;
    {
        _outputstr = _outputstr + "\n";
        _outputstr = _outputstr + "\n" + str (_x select 1);
        _outputstr = _outputstr + "\nObj pos: " + str (_x select 0);
        _ifonscreen = [(_x select 4)] call CheckOnScreen; // this will be discussed in the following section
        _outputstr = _outputstr + "\nOn screen: " + str (_ifonscreen);
        [(_x select 4), (_x select 0)] call DrawBB; // this will be discussed in another section
    } forEach (cameraOn nearTargets DetectionRange_GlobalVariable); // distance in meters
    hint _outputstr;
};
```

### Convert world position to screen position, and check whether object is on screen

Arma 3 provides a function, `worldToScreen`, which converts a world position to screen position. The user just needs to pass in the world location.

Even if the object is not on screen, Arma will sometime return a negative value. As such, we have to manually check whether the object exceeds the width of the screen.

The following code takes in an object, and returns `true` if the object is on screen, else returns `false`.

```sqf
// Check if _obj is on screen, returns true or false
CheckOnScreen = {
	params ["_obj"];
	private _retcoords = worldToScreen (position _obj); // returns [x, y]
	// if no return, means confirmed not on screen.

	if (count _retcoords isEqualTo 0) then {
		false;
	} else {
		x = safeZoneX;
		y = safeZoneY;
		w = safeZoneW;
		h = safeZoneH;
		if (((x < (_retcoords select 0)) &&
		((_retcoords select 0) < w)) &&
		((y < (_retcoords select 1)) &&
		((_retcoords select 1) < h)))
		then{
			true;
		} else {
			false;
		}
	};
};
```