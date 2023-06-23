MIT License

Copyright (c) 2023 john

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


# Raymarching Experiments
 Gpu experiments
The purpose of this repository is to explore the capabilities of raymarching in real time graphics. 

#Lattice Boltzmann Simulation
Compute shader implementation can be found in LBMTesting
#Water Raymarching
Raymarch shader inside Waves file

Usage: 
The fluid simulation grabs the terrain texture specified and applies the heightmap changes to a specified material,
particles stream based on the velocities registered on the velocity texture


TODO
Particle waves and smoothing
Add foam based on flow map and divergence of the fluid

Acknowledgments:

Project was inspired by :
https://80.lv/articles/river-editor-water-simulation-in-real-time/  
this whole project is an effort to recreate this.

For all raymarching raymarching related:
https://iquilezles.org/ 

Water scattering:
https://www.alanzucconi.com/2017/10/10/atmospheric-scattering-1/

CPU impementation and starting point:
https://forum.unity.com/threads/fluid-simulation-tests.311908/

https://developer.nvidia.com/gpugems/gpugems2/part-vi-simulation-and-numerical-algorithms/chapter-47-flow-simulation-complex

Wave Particles:
http://www.cemyuksel.com/research/waveparticles/

Lattice javascript implementation, visualization was referenced from here
https://physics.weber.edu/schroeder/fluids/

https://archive.org/details/GDC2008Fischer
https://visualcomputing.ist.ac.at/publications/2018/WSW/

