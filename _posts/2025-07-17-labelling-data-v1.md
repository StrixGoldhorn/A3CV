---
layout: default
title:  "Labelling Data v1"
---
# Labelling Data v1

In this post, we will cover:

- YOLO data format
- Reading and extracting data from the ARMA log file in python
- Drawing bounding boxes on screenshot (for visualisation)
- Save screenshot to either `images/train` or `images/val`
- Generate labels and write to either `labels/train` or `labels/val`

We will be referring to the file [ExtractAndDraw.py](https://github.com/StrixGoldhorn/A3CV/blob/main/scripts%20and%20stuff/ExtractAndDraw.py) throughout this post.

**DISCLAIMER**: I am aware that using f-strings to generate a filepath is not a good practive. But this is your own data that you input, so just don't fill in anything dumb and you should be good to go.

<br/><br/><br/>

### YOLO data format

YOLO expects training data to be provided as such:

1. A `init.yaml` file with the root path, path for training images, path for validation images, and classes indexed by integers.
2. An `images` folder, with `train` as a subfolder, and training images within the `train` subfolder.
3. A `labels` folder, with `train` as a subfolder, and training images within the `train` subfolder.

Folder structure should look something like this
```
root_dir
|
|---images
|   |---train
|   |   |---train_img1.png
|   |   |---train_img2.png
|   |---val
|   |   |---val_img1.png
|   |   |---val_img2.png
|
|---labels
|   |---train
|   |   |---train_img1.txt
|   |   |---train_img2.txt
|   |---val
|   |   |---val_img1.txt
|   |   |---val_img2.txt
```

`init.yaml` should look something like this
```yaml
path: '/content/gdrive/My Drive/A3CV dataset 1' # dataset root dir
train: images/train  # train images (relative to 'path')
val: images/val  # val images (relative to 'path')

# Classes
names:
  0: LSV
  1: MRAP
  2: Pickup_Truck
  3: Civvie_Car
  4: Misc
```

Images should **NOT** have bounding boxes drawn on them.

For the labels, each of the filename should correspond to the respective image filename, with only the extension changed (to `.txt`)

Each label file should be in the format:

```txt
5 0.5538333333333334 0.020530564814814814 0.030437500000000006 0.029869240740740738
5 0.7546302083333333 0.4589490740740741 0.12382291666666667 0.11877222222222217
4 0.95740625 0.1870027777777778 0.038833333333333275 0.03665555555555555
2 0.6756666666666666 0.0698575462962963 0.05017708333333348 0.05935527777777778
2 0.6067526041666667 0.011118115740740741 0.037744791666666666 0.02134062037037037
3 0.8094375 0.10876527777777778 0.035947916666666746 0.04304907407407406
0 0.7264583333333334 0.04278518518518518 0.028270833333333356 0.03956259259259258
1 0.21263958333333333 0.04888886111111111 0.06232500000000002 0.08592820370370371
```

Each row is in the format `class x_center y_center width height`, with `x_center y_center width height` being normalized.

<br/><br/><br/>

### Reading and extracting data from the ARMA log file in python

Luckily, we saved the data in a "custom" format. In case you don't remember, we saved it as such.

```log
20:25:18 """---START-CV-DATA-FRAME---"""
20:25:18 """""""O_G_Offroad_01_armed_F""""|891.191|558.857|1317.49|894.316|""""20250625202518480"""""""
20:25:18 """""""O_G_Offroad_01_AT_F""""|682.094|32.8631|928.484|254.214|""""20250625202518480"""""""
20:25:18 """""""I_MRAP_03_gmg_F""""|1963.72|60.5509|2190.05|149.924|""""20250625202518480"""""""
20:25:18 """""""Land_Flush_Light_green_F""""|1413.64|13.6794|1430.97|21.4241|""""20250625202518480"""""""
20:25:18 """""""Land_Flush_Light_green_F""""|1747.42|201.867|1765.87|210.75|""""20250625202518480"""""""
20:25:18 """""""Land_Flush_Light_green_F""""|2186.72|451.54|2206.57|462.046|""""20250625202518480"""""""
20:25:18 """""""Land_Flush_Light_green_F""""|1277.01|941.161|1302.12|955.228|""""20250625202518480"""""""
20:25:18 """""""Land_Flush_Light_green_F""""|2163.18|781.835|2185.62|794.689|""""20250625202518480"""""""
20:25:18 """""""Land_Flush_Light_green_F""""|430.441|1091.79|458.455|1107.05|""""20250625202518480"""""""
20:25:19 """---END-CV-DATA-FRAME---"""
```

We can read through the file, and search for each instance of `---START-CV-DATA-FRAME---` and `---END-CV-DATA-FRAME---`. Thereafter, we can process each line between the start and end.

Each line is in the format `<time> """""""<object name>""""|<xmin>|<ymin>|<xmax>|<ymax>|""""<timestamp>"""""""`.

Recalling that we named each screenshot as the timestamp as well, we can match each data line to its respective screenshot.

Below is an extract from [ExtractAndDraw.py](https://github.com/StrixGoldhorn/A3CV/blob/main/scripts%20and%20stuff/ExtractAndDraw.py).

```py
curr_reading_frame = False
with open(filepath, "r") as f:
    for line in f:
        # Check if start header detected
        if "START-CV-DATA-FRAME" in line:
            # If somehow already reading frame, must be an error.
            if curr_reading_frame:
                pass
            else:
                draw_data_arr = []
                write_data_arr = []
                curr_reading_frame = True
                
        elif "END-CV-DATA-FRAME" in line and curr_reading_frame:
            # Call functions to draw on image to:
            # - Visualise bounding box,
            # - Save to image folder,
            # - Generate and write text file with bounding box
            draw()
            save()
            write()
            curr_reading_frame = False
                
        elif curr_reading_frame:
            try:
                # Extract data, object name, timestamp
                data = str(line[:-1])[12:-3].split("|")
                obj_name = str(class_dict[data[0][4:-4]])
                current_time = str(data[5][4:-4])
                
                # Normalize coords
                xmin = float(data[1][:8])/usr_w
                ymin = float(data[2][:8])/usr_h
                xmax = float(data[3][:8])/usr_w
                ymax = float(data[4][:8])/usr_h
                
                # Conver to YOLO format (requires: xctr, yctr, wdith, height)
                xctr = (xmax+xmin) / 2
                yctr = (ymax+ymin) / 2
                width = abs(xmax-xmin)
                height = abs(ymax-ymin)
                
                # Write to array for the current frame
                draw_data_arr.append([obj_name, data[1], data[2], data[3], data[4], current_time])
                write_data_arr.append([obj_name, xctr, yctr, width, height, current_time])
            except:
                pass
```

The result of the code above is that we will get the arrays  `draw_data_arr` and `write_data_arr` with the data being the object and its bounding box's coordinates in their respective format.

<br/><br/><br/>

### Drawing bounding boxes on screenshot (for visualisation)

For drawing on images, we use `PIL`. Since we already have the non-normalized coords in the form `xmin, ymin, xmax, ymax`, we can just use it to draw directly on the image. We loop through the data array to draw all the bounding boxes on the image before saving it.

Below is an extract from [ExtractAndDraw.py](https://github.com/StrixGoldhorn/A3CV/blob/main/scripts%20and%20stuff/ExtractAndDraw.py).

```py
 with Image.open(f"{sspath}/testedited.png") as im:
    for data in draw_data_arr:
        x0 = round(float(data[1]))
        y0 = round(float(data[2]))
        x1 = round(float(data[3]))
        y1 = round(float(data[4]))
        
        draw = ImageDraw.Draw(im)
        draw.rectangle([(x0, y0), (x1, y1)], fill=None, outline=(255, 0, 0), width=5)
            
        # write to stdout
    im.save(f"{sspath}/testedited.png", "PNG")
```

<br/><br/><br/>

### Save screenshot to either `images/train` or `images/val`

Saving screenshots is even easier, as we only have to copy it to the correct destination folder.

```py
with Image.open(f"{sspath}/{draw_data_arr[0][5]}.png") as im:
            im.save(f"{savepath}/images/{train_or_val}/{draw_data_arr[0][5]}.png", "PNG")
```

<br/><br/><br/>

### Generate labels and write to either `labels/train` or `labels/val`

For writing, since we have generated the normalized coords when processing the data, we now only need to write it to a file and save it to the correct destination folder.

For this, we iterate through the data array, and use an f-string for each line to write it in the correct format.

```py
with open(f"{savepath}/labels/{train_or_val}/{write_data_arr[0][5]}.txt", "w") as f:
    for data in write_data_arr:
        obj_name = data[0]
        xctr = data[1]
        yctr = data[2]
        width = data[3]
        height = data[4]
        f.write(f"{obj_name} {xctr} {yctr} {width} {height}\n")
print(f"Written to {savepath}/labels/{train_or_val}/{write_data_arr[0][5]}.txt")
```