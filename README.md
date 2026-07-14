Load Milkshape MS3D files directly into Godot 3.6.
Currently only supports fully rigged and keyframed (meaning every frame must be a key) models.

###Installation:
1) Download the files
2) Put them into new folder and name it however you want
3) Copy this folder into "addons" folder in your project
4) Enable plugin in "Plugins" menu
5) Add your ms3d models into your project 

###Separating animation into several ones:
MS3D doesn't store info about different animations, it's all a single timeline. So, to split it into what you need you can provide a separate text file with ".anims" extension.
The name of this file must be the same as the model file and if it's absent the entire timeline will be created as a single animation

This file must contain definitions for animations you need:
```
animation Idle
frame 1 0.1
frame 2 0.1

animation Run loop
frame 4 0.1
frame 5 0.1
frame 6 0.1
frame 7 0.1
frame 8 0.1
frame 9 0.1
frame 10 0.1
frame 11 0.1
frame 12 0.1
frame 13 0.1
frame 14 0.1
frame 15 0.1
frame 16 0.1
```

Where:
-animation AnimationName Loop
is a definition for your animation. Everything after this line will be added to this defined animation until next "animation" is encountered. If you pass "loop" as the second parameter - animation will be looped.

-frame FrameIndex FrameDuration
is a frame definition. You have to provide its index (starting from 0 which is always the bind pose) and its duration (in seconds). Duration is necessary to calculate offsets in timeline (for now).