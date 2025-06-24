BBOverlay_GlobalVariable = false;
BBLineWidth_GlobalVariable = 20;
DetectionRange_GlobalVariable = 500;

(findDisplay 46) displaySetEventHandler ["KeyDown", "_this call MY_KEYDOWN_FNC;
"];
(findDisplay 46) displaySetEventHandler ["KeyUp", "_this call MY_KEYUP_FNC;
"];

MY_KEYDOWN_FNC = {
	// key K
	if ((_this select 1) == 37) then {
		systemChat ("x" + str (safeZoneX));
		systemChat ("y" + str (safeZoneY));
		systemChat ("w" + str (safeZoneW));
		systemChat ("h" + str (safeZoneH));
	};
	// key L
	if ((_this select 1) == 38) then {
		systemChat "Standing by for screenshot";
	};
};

MY_KEYUP_FNC = {
	// key J
	if ((_this select 1) == 36) then {
		BBOverlay_GlobalVariable = !(BBOverlay_GlobalVariable);
		systemChat format ["BB Toggle: %1", if (BBOverlay_GlobalVariable) then {
			"ON"
		} else {
			"OFF"
		}];
		// if off
		if (!(BBOverlay_GlobalVariable)) then {
			hint "";
		};
	};

	// key L
	if ((_this select 1) == 38) then {
		call ScanAndSaveScene;
	};
};

0 spawn {
	onEachFrame {
		if (BBOverlay_GlobalVariable) then {
			call HintNearbyTargets;
		};
	};
};

ScanAndSaveScene = {
	systemChat str("Start " + str(diag_tickTime));
	diag_log str("---START-CV-DATA-FRAME---");
	0 spawn {
		screenshot "test.png";
		systemChat "Screenshot taken!";
		{
			private _convertedCoords = [(_x select 4), (_x select 0), (_x select 1)] call GetLargestAndSmallestXYOnScreen;
			// if _convertedCoords is a bool (aka it returned false), means is not on screen, so we skip it
			if (typeName _convertedCoords == "bool") then {} else {
				private _convertedxmin = _convertedCoords select 0;
				private _convertedymin = _convertedCoords select 1;
				private _convertedxmax = _convertedCoords select 2;
				private _convertedymax = _convertedCoords select 3;
				diag_log str(str(_x select 1) + "|" + str (_convertedxmin) + "|" + str (_convertedymin) + "|" + str (_convertedxmax) + "|" + str (_convertedymax));
			};
		} forEach (cameraOn nearTargets DetectionRange_GlobalVariable); // distance in meters
	};
	diag_log str("---START-CV-DATA-FRAME---");
	systemChat str("End " + str(diag_tickTime));
};

HintNearbyTargets = {
	private _outputstr = "";
	_outputstr = _outputstr + str diag_tickTime;
	{
		_outputstr = _outputstr + "\n";
		_outputstr = _outputstr + "\n" + str (_x select 1);
		_outputstr = _outputstr + "\nObj pos: " + str (_x select 0);
		_ifonscreen = [(_x select 4)] call CheckOnScreen;
		_outputstr = _outputstr + "\nOn screen: " + str (_ifonscreen);
		[(_x select 4), (_x select 0)] call DrawBB;
	} forEach (cameraOn nearTargets DetectionRange_GlobalVariable); // distance in meters
	hint _outputstr;
};

// returns xmin, ymin, xmax, ymax array if obj is on screen, else returns false
GetLargestAndSmallestXYOnScreen = {
	params ["_obj", "_objpos", "_objname"];

	private _output = false;
	// Only continue if it is on screen
	if (_obj call CheckOnScreen) then {
		_box = (2 boundingBoxReal _obj);

		private _min = [];
		private _max = [];

		for "_i" from 0 to 3 -1 do {
			_min pushBack ((_objpos select _i) - ((_box select 2)/4));
			_max pushBack ((_objpos select _i) + ((_box select 2)/4));
		};

		// 3d in-game coords
		_corners = [
			_min,
			[_max select 0, _min select 1, _min select 2],
			[_min select 0, _max select 1, _min select 2],
			[_max select 0, _max select 1, _min select 2],
			[_min select 0, _min select 1, _max select 2],
			[_max select 0, _min select 1, _max select 2],
			[_min select 0, _max select 1, _max select 2],
			_max
		];

		private _minX = 10;
		private _minY = 10;
		private _maxX = -10;
		private _maxY = -10;

		// convert each in-game corner to screen coords
		{
			private _retcoords = worldToScreen (_x);

			// check if _retcoords is on screen first
			if (((safeZoneX < (_retcoords select 0)) &&
			((_retcoords select 0) < safeZoneW)) &&
			((safeZoneY < (_retcoords select 1)) &&
			((_retcoords select 1) < safeZoneH)))
			then{
				// since it is on screen, we can then try to find the min and max
				// check if x is min
				_minX = if ((_retcoords select 0) < _minX) then {
					(_retcoords select 0)
				} else {
					_minX
				};
				// check if x is max
				_maxX = if ((_retcoords select 0) > _maxX) then {
					(_retcoords select 0)
				} else {
					_maxX
				};
				// check if y is min
				_minY = if ((_retcoords select 1) < _minY) then {
					(_retcoords select 1)
				} else {
					_minY
				};
				// check if y is max
				_maxY = if ((_retcoords select 1) > _maxY) then {
					(_retcoords select 1)
				} else {
					_maxY
				};
			} else {
				false;
			}
		} forEach _corners;

		// check if minX maxX minY maxY is still orginal value
		// if they are still original value, means the object is out of frame 
		if ((_minX != 10) &&
		(_maxX != -10) &&
		(_minY != 10) &&
		(_maxY != -10)) then {
			// convert minX maxX minY maxY to absolute screen coords.
			private _convertedxmin = (1920 / (abs safeZoneW)) * (_minX + abs safeZoneX);
			private _convertedxmax = (1920 / (abs safeZoneW)) * (_maxX + abs safeZoneX);
			private _convertedymin = (1080 / (abs safeZoneH)) * (_minY + abs safeZoneY);
			private _convertedymax = (1080 / (abs safeZoneH)) * (_maxY + abs safeZoneY);
			_output = [_convertedxmin, _convertedymin, _convertedxmax, _convertedymax];
			_output;
		} else {
			systemChat "Bounding Box OUT OF FRAME!";
			_output;
		};
	} else {
		_output;
	};
	_output;
};

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

// Draw "bounding box"
DrawBB = {
	params ["_obj", "_objpos"];
	_box = (2 boundingBoxReal _obj);

	private _min = [];
	private _max = [];

	for "_i" from 0 to 3 -1 do {
		_min pushBack ((_objpos select _i) - ((_box select 2)/4));
		_max pushBack ((_objpos select _i) + ((_box select 2)/4));
	};

	_corners = [
		_min,
		[_max select 0, _min select 1, _min select 2],
		[_min select 0, _max select 1, _min select 2],
		[_max select 0, _max select 1, _min select 2],
		[_min select 0, _min select 1, _max select 2],
		[_max select 0, _min select 1, _max select 2],
		[_min select 0, _max select 1, _max select 2],
		_max
	];

	// Define edges (pairs of corner indices)
	_edges = [
		[0, 1], [1, 3], [3, 2], [2, 0],
		[4, 5], [5, 7], [7, 6], [6, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]
	];

	// Draw edges
	{
		_start = _corners select (_x select 0);
		_end = _corners select (_x select 1);
		drawLine3D [_start, _end, [1, 0, 0, BBLineWidth_GlobalVariable]]; // Red lines
	} forEach _edges;
};