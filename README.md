# A3CV
Messing around with computer vision within Arma 3

## Background
As early as 2016, researchers have used GTA V to train computer vision data (Refer to the paper: [Playing for Data: Ground Truth from Computer Games](https://arxiv.org/pdf/1608.02192)). By making use of the variablilty, realistic textures, and motions of games, they allow synthetic data to be used to train models, reducing the need to manually gather data from the real world. By injecting a wrapper between the game and the OS, the researchers were able to programatically gather data to be used for segmentation training.

The usage of video games allows for the ease of gathering data in:
- different environments (summer, winter, tropical)
- time of day (morning, noon, dusk, night)
- weather conditions (fog, light rain, thunderstorm)

Apart from that, labelling of the data with the help of in-game code may take up less time compared to manually labelling each image.

## Why Arma 3?
Arma 3 has been a staple of the milsim gaming community, with various mods adding different variations of vehicles, weapons, etc.

The variety of mods, along with the ease of creating mods, allows for differnet and custom data to be easily integrated into the game. This allows users to choose their own data to train their models on.

Arma 3 has strong modding support, with the developers adding a multitude of scripting functions. This allows us to easily get the bounding boxes of objects.

Arma 3 has the Eden Editor, which allows users to place their objects in desired scenarios, change the environment, time of day, weather conditions, etc easily.

## DEVLOG
Below is just a bunch of posts, explaining my thought process as well as parts of the code I created.

### Step 1: Gather Data
To train the CV model, we have to gather data. This means getting images and drawing bounding boxes around objects of interest. However, as we are using a game, we can use the scripting/modding support to help us gather these data, instead of manually having to label the images.

[Gathering Data v1 Part 1](2025/06/24/gathering-data-v1-part-1)