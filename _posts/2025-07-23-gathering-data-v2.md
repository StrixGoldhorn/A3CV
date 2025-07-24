---
layout: default
title:  "Gathering Data v2"
---
# Gathering Data v2

In this post, we will cover:

- a BETTER way to get an object's bounding box

<br/><br/><br/>

### Better way to obtain bounding box

Keeping in mind that `boundingBoxReal` returns `[[xmin, ymin, zmin], [xmax, ymax, zmax], boundingSphereRadius]`, we can make use of the min and max for each xyz coord.

An updated sample code would be as such.

```sqf
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
```

<br/><br/><br/>

#### Code Explanation

First, we call `boundingBoxReal`, and save the xyz min and xyz max coords to `_p1` and `_p2` respectively.

From there, we can calculate the xyz that we need to add to the object's coordinates in order to get the bounding box in the object's coordinates. This is represented by the variables `_maxWidth`, `_maxLength`, and `_maxHeight`.

To convert from the object's coordinates to world coordinates, we can use the function `modelToWorld`. This allows us to get the corners of the bounding box in world coordinates.

This was the only significant change made to the code.

<br/><br/><br/>

#### Resulting Bounding Boxes

![](
https://raw.githubusercontent.com/StrixGoldhorn/A3CV/refs/heads/main/_posts/assets/gathering-data-v2/20250721124449296.png)

![](
https://raw.githubusercontent.com/StrixGoldhorn/A3CV/refs/heads/main/_posts/assets/gathering-data-v2/20250721124447179.png)

![](
https://raw.githubusercontent.com/StrixGoldhorn/A3CV/refs/heads/main/_posts/assets/gathering-data-v2/BB%20Drawn/20250721124449296.png)

![](
https://raw.githubusercontent.com/StrixGoldhorn/A3CV/refs/heads/main/_posts/assets/gathering-data-v2/BB%20Drawn/20250721124447179.png)