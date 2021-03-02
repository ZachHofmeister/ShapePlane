# ShapePlane
A generative art application written in Java using the Processing library. Generates a vector grid of shapes.

# Running the program
After downloading the sourcecode, you will need to set up Processing to run ShapePlane.
* Download Processing 3 here: https://processing.org/
* The required libraries are uploaded to this repo in libraries.zip.
  * I am unsure if the latest versions of these libraries are compatible, so I recommend using the ones here.
  * Sidenote: the dropbox API library is required but not used right now. Functions that use it are still included only as a display of the license verification system that is disabled.
* Follow this guide to install the libraries for Processing: https://github.com/processing/processing/wiki/How-to-Install-a-Contributed-Library
* In Processing you need to install processing-java, which can be found in the Tools tab.
  
Once processing-java and the libraries are installed, you're ready to run ShapePlane!

# Controls
* Left-arrow: Show/hide controls.
* Right-arrow: Generate new image with random seed.
* Down-arrow: Go back to the previous random seed and image.
* Up-arrow: Save image PDF and preset.

Saved images and presets can be found in the images and data folders respectively alongside the .pde file.

# Example images

![Hexagon Sunset](https://github.com/ZachHofmeister/ShapePlane/blob/main/example_images/ShapePlane-2.jpg?raw=true)

![Blue Triangle Subdivision](https://github.com/ZachHofmeister/ShapePlane/blob/main/example_images/ShapePlane%20blue.png?raw=true)

Example of the controls for the program.
![Controls](https://github.com/ZachHofmeister/ShapePlane/blob/main/example_images/ShapePlane%20Controls.jpg?raw=true)
