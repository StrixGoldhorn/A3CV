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
	// key O
	if ((_this select 1) == 24) then {
		private _currentTime = systemTime apply {
			if (_x < 10) then {
				"0" + str _x
			} else {
				str _x
			}
		};
		private _currentTimeStr = "";
		_currentTime apply {
			_currentTimeStr = _currentTimeStr + _x
		};
		systemChat str(_currentTimeStr);
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
	0 spawn {
		private _currentTime = systemTime apply {
			if (_x < 10) then {
				"0" + str _x
			} else {
				str _x
			}
		};
		private _currentTimeStr = "";
		_currentTime apply {
			_currentTimeStr = _currentTimeStr + _x
		};

		diag_log str("---START-CV-DATA-FRAME---");
		private _saveSSName = _currentTimeStr + ".png";
		// screenshot "test.png";
		screenshot _saveSSName;
		systemChat "Screenshot taken!";
		systemChat _saveSSName;
		{
			private _convertedCoords = [(_x select 4), (_x select 0), (_x select 1)] call GetLargestAndSmallestXYOnScreen;
			// if _convertedCoords is a bool (aka it returned false), means is not on screen, so we skip it
			if (typeName _convertedCoords == "bool") then {} else {
				private _convertedxmin = _convertedCoords select 0;
				private _convertedymin = _convertedCoords select 1;
				private _convertedxmax = _convertedCoords select 2;
				private _convertedymax = _convertedCoords select 3;
				diag_log str(str(_x select 1) + "|" + str (_convertedxmin) + "|" + str (_convertedymin) + "|" + str (_convertedxmax) + "|" + str (_convertedymax) + "|" + str (_currentTimeStr));
			};
		} forEach (cameraOn nearTargets DetectionRange_GlobalVariable); // distance in meters
		diag_log str("---END-CV-DATA-FRAME---");
	};
	// WriteToFile_Trigger_GlobalVariable = true;
	// call HintNearbyTargets;
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
	// systemChat str (positionCameraToWorld [0, 0, 0]);
};

// returns xmin, ymin, xmax, ymax array if obj is on screen, else returns false
GetLargestAndSmallestXYOnScreen = {
	params ["_obj", "_objpos", "_objname"];

	private _output = false;
	// Only continue if it is on screen
	if (_obj call CheckOnScreen) then {
		private _min = [];
		private _max = [];

		private _bbr = boundingBoxReal _obj;
		private _p1 = _bbr select 0;
		private _p2 = _bbr select 1;
		private _maxWidth = (abs ((_p2 select 0) - (_p1 select 0))) / 2;
		private _maxLength = (abs ((_p2 select 1) - (_p1 select 1))) / 2;
		private _maxHeight = (abs ((_p2 select 2) - (_p1 select 2))) / 2;

		_corners = [
			_obj modelToWorld [_maxWidth, _maxLength, _maxHeight],
			_obj modelToWorld [_maxWidth, _maxLength, -_maxHeight],
			_obj modelToWorld [-_maxWidth, _maxLength, -_maxHeight],
			_obj modelToWorld [_maxWidth, -_maxLength, -_maxHeight],
			_obj modelToWorld [_maxWidth, -_maxLength, _maxHeight],
			_obj modelToWorld [-_maxWidth, _maxLength, _maxHeight],
			_obj modelToWorld [-_maxWidth, -_maxLength, _maxHeight],
			_obj modelToWorld [-_maxWidth, -_maxLength, -_maxHeight]
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
	private _min = [];
	private _max = [];

	private _bbr = boundingBoxReal _obj;
	private _p1 = _bbr select 0;
	private _p2 = _bbr select 1;
	private _maxWidth = (abs ((_p2 select 0) - (_p1 select 0))) / 2;
	private _maxLength = (abs ((_p2 select 1) - (_p1 select 1))) / 2;
	private _maxHeight = (abs ((_p2 select 2) - (_p1 select 2))) / 2;

	_corners = [
		_obj modelToWorld [_maxWidth, _maxLength, _maxHeight],
		_obj modelToWorld [_maxWidth, _maxLength, -_maxHeight],
		_obj modelToWorld [-_maxWidth, _maxLength, -_maxHeight],
		_obj modelToWorld [_maxWidth, -_maxLength, -_maxHeight],
		_obj modelToWorld [_maxWidth, -_maxLength, _maxHeight],
		_obj modelToWorld [-_maxWidth, _maxLength, _maxHeight],
		_obj modelToWorld [-_maxWidth, -_maxLength, _maxHeight],
		_obj modelToWorld [-_maxWidth, -_maxLength, -_maxHeight]
	];

	// Define edges (pairs of corner indices)
	_edges = [
		[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7],
		[1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7],
		[2, 3], [2, 4], [2, 5], [2, 6], [2, 7],
		[3, 4], [3, 5], [3, 6], [3, 7],
		[4, 5], [4, 6], [4, 7],
		[5, 6], [5, 7],
		[6, 7]
	];

	// Draw edges
	{
		_start = _corners select (_x select 0);
		_end = _corners select (_x select 1);
		drawLine3D [_start, _end, [1, 0, 0, BBLineWidth_GlobalVariable]]; // Red lines
	} forEach _edges;
};