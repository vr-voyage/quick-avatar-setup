# THIS SOFTWARE IS IN ALPHA STATE.  
# ! USE IT AT YOUR OWN RISK !  
# MAKE A BACKUP OF ANY MODEL YOU INTEND TO USE THIS TOOL WITH

Quick Avatar Setup
-------------------------

This is a tool put in place to quickly setup simple avatars features.  
The setup is then saved as a JSON file, which is supposed to be read by various
importers.  
The first importer, to be released ASAP, should allow you to use the saved setup
on VRChat SDK 3.0 avatars.

For the moment, this only supports setting up "emotions", which are just
blendshapes configurations.

Limitations
---------------

This is tool is currently extremely limited.

* **WORKSFORME EDITION**  
I only tested this for myself, so things might go very wrong on the models
you're trying to use them on.  
I'm ok with you opening a bug report, but only if the model you're testing
this on is publicly available and useable without issues.

* **RIGHT NOW, THIS TOOL ONLY SUPPORTS GLB**  
If you have FBX files, you'll need to convert them using FBX2GLTF tools, or by
importing them in Blender and reexporting them as GLB.  
Note that only GLB files are supported at the moment. GLTF support should
come very soon, along with VRM support.  
Native support for FBX might come after.

* **MODEL LOADING IS DONE ON THE MAIN THREAD**  
Meaning that the program will get stuck until it finishes loading the model
you're providing.  
Threaded model loading will be added afterwards.

* **SUPPORTED HEIGHT IS LIMITED TO 2.5 meters**  
Meaning, no Godzilla avatar support at the moment. If you're converting FBX
files, scale them down before or when exporting them.  
When using Blender, remember to do `CTRL+A -> Apply Scale` after rescaling,
before exporting the model.

* **THE CAMERA SETUP IS HORRIBLE**  
No mouse support, moving down and forward requires to play with the sliders,
it's just horrible.  
Mouse support will be provided on the next release.  
Automatic camera setup might take a while, though.

* **ONLY BLENDSHAPES ARE SUPPORTED AT THE MOMENT**  
Since it's by far the most used feature. The second one being animations with
sound and particle effects, I'm planning to support them at some point.

* **ONLY TESTED ON WINDOWS AT THE MOMENT**  
I'll try to setup an automated build using Docker and/or Github actions, in order
to build executables for Linux, Mac OS X and maybe HTML5 + Android, though
those two will require database support for the configuration, IMHO.

Also, I need to restate this :
**THIS IS AN ALPHA VERSION. THINGS MIGHT GO HORRIBLY WRONG.**

Usage
--------

* Launch the program.
* Drag and drop a GLB file on the window, and the program will start loading
  your model.  
  The program will start to load the provided model, and will be stuck until
  it finishes the loading process, whether it succeeds or not.  
  The program will also write a JSON file named : 
  "model_filename.glb.avatar_setup.json" alongside your GLB file.  
  This file is used to save the current avatar setup, so make sure the program can
  write inside the directory you're loading the GLB from.
* When done, setup the camera using the two sliders on the bottom the 3D View.  
The top slider sets the height (up/down).  
The bottom one sets the depth (forward/backward).  
You can switch between a (supposedly) face camera and a (supposedly) full body
camera using the two buttons at the top.
* Click on 'Add' to add an 'Emotion'.
* In the emotion editor (**Blendshapes** tab) :
  * Setup the blendshapes.
  * Set the name at the top.
 * And then click on the Save button. Doing this will bring you back to the
 'Emotions list' (the main pane).
* To edit a saved emotion, double click on it, then procceds just like when you
added it.
* To delete a saved emotion, select it and click on the 'Delete' button.
* When finished, close the program and use the generated JSON file with an
appropriate importer.

Importers
-------------

* For Unity and the VRChat SDK 3.0 : https://github.com/vr-voyage/quick-avatar-setup-importer-vrchat  
  Note, the SDK is not provided. You need to install it before, and add a
   VRC Avatar Descriptor before hand.
