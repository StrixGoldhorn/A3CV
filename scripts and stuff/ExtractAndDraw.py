# filepath of log file
filepath = "C:\\Users\\USERNAME\\AppData\\Local\\Arma 3\\Arma3_x64_2025-07-05_22-39-02.rpt"
# will extract those after timestamp
timestamp = "23:14:00"

# percent of training data (vs validation data)
percent = 0.98

# filepath of A3 screenshot folder
sspath = "C:/Users/USERNAME/Documents/Arma 3 - Other Profiles/ARMAUSER/Screenshots"

# filepath of save folder
savepath = sspath
drawfolder = "BB Drawn"
draw_BB = True

# classes for formatting
class_dict = {"B_T_LSV_01_armed_F":0, "B_T_LSV_01_unarmed_F":0, "B_T_LSV_01_AT_F":0,\
"O_LSV_02_armed_F":0, "O_LSV_02_AT_F":0, "O_LSV_02_unarmed_F":0, "O_T_LSV_02_unarmed_F":0,\
"O_MRAP_02_F":1, "O_MRAP_02_gmg_F":1, "O_MRAP_02_hmg_F":1,\
"I_MRAP_03_F":1, "I_MRAP_03_gmg_F":1, "I_MRAP_03_hmg_F":1,\
"O_G_Offroad_01_armed_F":2, "O_G_Offroad_01_AT_F":2, "O_G_Offroad_01_F":2,\
"C_Hatchback_01_F":3}

# screenshot width and height (to normalise for formatting)
usr_w = 1920
usr_h = 1080

from PIL import Image, ImageDraw
import random

draw_data_arr = []
write_data_arr = []

train_cnt = 0
val_cnt = 0

def main():
    print("Reading")
    readfile()
    print("DONE!")
    print(f"Total images saved: {train_cnt + val_cnt}")
    print(f"          Training: {train_cnt}")
    print(f"        Validation: {val_cnt}")

def readfile():
    global draw_data_arr, write_data_arr, train_cnt, val_cnt, draw_BB
    curr_reading_frame = False

    
    with open(filepath, "r") as f:
        
        for line in f:
            # Check if start header detected
            if "START-CV-DATA-FRAME" in line:
                # If somehow already reading frame, must be an error.
                if curr_reading_frame:
                    pass
                # Only set to true if is after timestamp
                elif line[:8] > timestamp:
                    draw_data_arr = []
                    write_data_arr = []
                    curr_reading_frame = True
                    
            elif "END-CV-DATA-FRAME" in line and curr_reading_frame:
                if len(draw_data_arr) > 0:
                    # decide if add to training or validation set
                    if (random.uniform(0, 1) < percent):
                        train_or_val = "train"
                        train_cnt += 1
                    else:
                        train_or_val = "val"
                        val_cnt += 1
                    if draw_BB:
                        print("Drawing")
                        draw()
                    else:
                        print(train_or_val)
                        print("Saving")
                        save(train_or_val)
                        print("Writing")
                        write(train_or_val)
                curr_reading_frame = False
                    
            elif curr_reading_frame:
                try:
                    # IF ANYTHING BREAK, TRY FIX HERE
                    data = str(line[:-1])[12:-3].split("|")
                    obj_name = str(class_dict[data[0][4:-4]])
                    current_time = str(data[5][4:-4])
                    
                    xmin = float(data[1][:8])/usr_w
                    ymin = float(data[2][:8])/usr_h
                    xmax = float(data[3][:8])/usr_w
                    ymax = float(data[4][:8])/usr_h
                    
                    # restrict to range
                    if xmin < 0: xmin = 0.01
                    if xmax > 1: xmax = 0.99
                    if ymin < 0: ymin = 0.01
                    if ymax > 1: ymax = 0.99
                    
                    xctr = (xmax+xmin) / 2
                    yctr = (ymax+ymin) / 2
                    width = abs(xmax-xmin)
                    height = abs(ymax-ymin)
                    
                    if xctr + width/2 > 1\
                    or xctr - width/2 < 0\
                    or yctr + height/2 > 1\
                    or yctr - height/2 < 0:
                        pass
                    else:                    
                        draw_data_arr.append([obj_name, data[1], data[2], data[3], data[4], current_time])
                        write_data_arr.append([obj_name, xctr, yctr, width, height, current_time])
                except:
                    pass
            
def save(train_or_val):
    '''
    Saves the screenshot.
    Saves to /images/train_or_val
    '''
    global sspath, draw_data_arr
    
    with Image.open(f"{sspath}/{draw_data_arr[0][5]}.png") as im:
            im.save(f"{savepath}/images/{train_or_val}/{draw_data_arr[0][5]}.png", "PNG")
    
    print(f"Saved to {savepath}/images/{train_or_val}/{draw_data_arr[0][5]}.png")
            
def write(train_or_val):
    '''
    Writes the formatted label file.
    Saves to /labels/train_or_val
    '''
    global sspath, write_data_arr
    
    with open(f"{savepath}/labels/{train_or_val}/{write_data_arr[0][5]}.txt", "w") as f:
    
        for data in write_data_arr:
            obj_name = data[0]
            xctr = data[1]
            yctr = data[2]
            width = data[3]
            height = data[4]
            # print(f'''
            # obj name:   {obj_name}\n\
            # xctr:       {xctr}\n\
            # yctr:       {yctr}\n\
            # width:       {width}\n\
            # height:       {height}\n\
            #             ''')
            # print(f"{obj_name} {xctr} {yctr} {width} {height}")
            
            f.write(f"{obj_name} {xctr} {yctr} {width} {height}\n")
    print(f"Written to {savepath}/labels/{train_or_val}/{write_data_arr[0][5]}.txt")
            
def draw():
    '''
    Draws bounding boxes based on Arma log.
    Saves in the same screenshot folder.
    '''
    global sspath, draw_data_arr, drawfolder
    
    with Image.open(f"{sspath}/{draw_data_arr[0][5]}.png") as im:
            im.save(f"{sspath}/testedited.png", "PNG")
        
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
            
    
    with Image.open(f"{sspath}/testedited.png") as im:
        im.save(f"{sspath}/{drawfolder}/{draw_data_arr[0][5]}.png", "PNG")
    print(f"Saved to {sspath}/{drawfolder}/{draw_data_arr[0][5]}.png")
            
main()