# u-track3D
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10055024.svg)](https://doi.org/10.5281/zenodo.10055024)

[u-track goes 3D!](https://www.danuserlab-utsw.org/news-2023/december)

## Table of Contents

1.  [Associated paper](#org8dc205c)
2.  [Accessing and loading the code into matlab](#org7f73dce)
3.  [Description of example datasets:](#orgb573d6b)
4.  [Script usage](#orgbec14d8)
5.  [Reproducing the u-track3D paper with the tutorial scripts](#orga13ef72)
6.  [Performances](#org3698df1)
7.  [GUI walk-through (Beta version)](#orgb4cad95)
    1.  [Getting started and loading data](#org3e33b65)
    2.  [Detection, tracking and review on the whole volumetric sequence](#org0859d3f)
    3.  [Definition of DynROI and tracking in DynROI](#org80d3754)
8.  [Known issues](#orgb793bb7)
9.  [Milestones](#org58bde09)
10. [Software Requirements](#org09a5f97)


<a id="org8dc205c"></a>

## Associated paper

u-track3D tackles on-going challenges in the interpretation and quantitative analysis of large arrangements of 3D trajectories as it arises with the measurement of intracellular dynamics with light-sheet microscopy. The software is associated to the following publication. 

[**u-track3D: Measuring, navigating, and validating dense particle trajectories in three dimensions**](https://doi.org/10.1016/j.crmeth.2023.100655), *Cell Reports Methods*, 2023, written by 
[Philippe Roudot](https://centuri-livingsystems.org/p-roudot/), Wesley R Legant, Qiongjing Zou, Kevin M Dean, Tadamoto Isogai, Erik S Welf, Ana F David, Daniel W Gerlich, Reto Fiolka, Eric Betzig, and [Gaudenz Danuser](https://www.danuserlab-utsw.org/).


<a id="org7f73dce"></a>

## Accessing and loading the code into matlab

Download the code in the path of your choice: 

    git clone https://github.com/DanuserLab/u-track3D.git

Then in Matlab, one can import the code either through the matlab navigation panel (right click on code folder, add folder and subfolder) or through the command line as: 

    addpath(genpath('<path/to/code>'))


<a id="orgb573d6b"></a>

## Description of example datasets:

The tutorial scripts automatically download and process the following datasets:

[Endocytosis dataset](https://cloud.biohpc.swmed.edu/index.php/s/4gNCzmayPLdbw9s): Breast cancer cells  expressing eGFP-labelled alpha subunit of the AP-2 complex imaged with diaSLM by K. Dean (Dean et. al. 2016). The raw data has been cropped and limited to 50 time point (540MB).

[Mitosis dataset](https://cloud.biohpc.swmed.edu/index.php/s/5eceFNPcPB4iosa): HeLa cells undergoing mitosis and expressing eGFP-labeled EB3 and mCherry-labeled CENPA imaged in dual-channel lattice light-sheet microscopy by W. Legant (David et. al. 2019). The raw data has been cropped, the entire sequence has been made available. 


<a id="orgbec14d8"></a>

## Script usage

Scripting is generally recommended for the analysis of a large number of acquisitions due to its flexibility and automated rendering capabilities. At the moment, the scripting library also provides more features than the GUI: 

-   A larger set of dynROIs are available
-   Trackability computations
-   Fully automated mipping overlay and video production
-   Point cloud rendering for faster display of detection mask

After cloning the repo and adding the code folder path to Matlab, you will find the following tutorial script in the repository:

    tutoscript/tutoScriptBasicROI.m

This script demonstrates a generic workflow for detection, tracking and the
visualization of static ROIs defined automatically around randomly selected tracks. 
The example dataset describes endocytic pits in a moving cells. It is downloaded
automatically. The following features are demonstrated:

-   Detection
-   Tracking
-   Building dynROI automatically around tracks selected randomly
-   Rendering and exporting a visualization of tracking results

**Example dataset**: Endocytosis dataset

    tutoscript/tutoScriptAdvancedVisualization.m

This script demonstrates the various approaches available to visualize and create movies
of tracking results. Example dataset describes endocytic pits in a moving cells. It is
downloaded automatically. The following features are demonstrated:

-   Detection & Tracking rendering on orthogonal MIP with various rendering
    styles, exporting to gif, avi and pngs.
-   Exporting detection and trajectory for rendering in the Amira software.
-   Fast volume rendering through sparse point cloud representation.
-   Saving and Sideloading detection and tracking results

**Example dataset**: Endocytosis dataset

    tutoscript/tutoScriptDynROIFollowingTrackSet.m

This script demonstrates a workflow for detection, tracking and the definition of
dynROIs that fit and follows all the detected trajectories.  The example
dataset describes endocytic pits in a moving cells. It is downloaded automatically. The
following features are demonstrated:

-   Detection
-   Tracking
-   Building dynROI automatically around a set of tracks
-   Rendering and exporting a visualization of tracking results in the dynROI.

**Example dataset**: Endocytosis dataset

    tutoscript/tutoScriptTrackability.m

This script demonstrates a  workflow for detection, tracking and the
estimation of trackability on static ROI selected randomly.  The
example dataset describes endocytic pits in a moving cells. It is downloaded
automatically. The following features are demonstrated:

-   Detection
-   Tracking with trackability
-   Selecting a ROI automatically around a track selected randomly.
-   Rendering and exporting a visualization of tracking and trackability results
-   Plotting trackability scores for the ROI

**Example dataset**: Endocytosis dataset

    tutoscript/tutoScriptDualChannels.m

This script demonstrates detection, tracking and building dynROI accross multiple
channels. The example dataset describes a cell during early stages of mitosis, it is
downloaded automatically. The following features are demonstrated:

-   Detection and tracking with scale selectivity on the EB3 Channels  (channel 1)
-   Detection and tracking on the kinetochore channel (channel 2)
-   Sideloading previous detection and tracking results with process parameters
-   Building a dynROI between two trajectories measured on two different channels.
-   Rendering

**Example dataset**: Mitosis datasets

To improve computation time, you want to adjust the number of core available to performed parallelizable tasks. To do so, use the parpool(#) function with # the number of parallelizable core on your machine. 


<a id="orga13ef72"></a>

## Reproducing the u-track3D paper with the tutorial scripts

The scripts reproduce the majority of features used in numerical experiments presented in the u-track3D paper. Because of the large size of the datasets used in the paper, the script operates on smaller datasets that are amenable to direct download by the community. Here is the detail of the features that are demonstrated, their associated figures in the paper, and the script that reproduces them. One script can demonstrate several feature with a same dataset:

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">Feature</th>
<th scope="col" class="org-left">Figure</th>
<th scope="col" class="org-left">Script</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">Tracking Brownian motions described by endocytic events</td>
<td class="org-left">Fig 2</td>
<td class="org-left">tutoScriptBasicROI</td>
</tr>


<tr>
<td class="org-left">Building dynROI around tracks</td>
<td class="org-left">Fig 3</td>
<td class="org-left">tutoScriptDynROIFollowingTrackSet</td>
</tr>


<tr>
<td class="org-left">Multiscale Detections (Pole, KT, plus-ends)</td>
<td class="org-left">Fig 4</td>
<td class="org-left">tutoScriptDualChannels</td>
</tr>


<tr>
<td class="org-left">Building conical dynROI between MT Poles and Chromosomes</td>
<td class="org-left">Fig 4</td>
<td class="org-left">tutoScriptDualChannels</td>
</tr>


<tr>
<td class="org-left">Tracking restricted to a dynROI</td>
<td class="org-left">Fig 6</td>
<td class="org-left">tutoScriptTrackability</td>
</tr>


<tr>
<td class="org-left">Trackability</td>
<td class="org-left">Fig 6</td>
<td class="org-left">tutoScriptTrackability</td>
</tr>
</tbody>
</table>

Here is a list of the measurements that  cannot be reproduced with those scripts and datasets due to the size of the associated datasets: 

-   Endocytic events lifetime analysis on on Breast Cancer Cell imaging (Fig1.b,c)
-   Microtubule instability response to biochemical inhibition (Fig1.e,g).
-   Adhesion shape studies (Fig2.a-d).
-   Interpolar plane estimation from prometaphase to metaphase (Fig 2.f-i.)


<a id="org3698df1"></a>

## Performances

The software is CPU-optimized and has been tested on the following machines. 

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />

<col  class="org-left" />

<col  class="org-right" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">Computer main features</th>
<th scope="col" class="org-left">OS</th>
<th scope="col" class="org-left">script</th>
<th scope="col" class="org-right">Time (s)</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">Intel Xeon E5-2680 28 cores @ 2.4 GHz - 528 GB Ram</td>
<td class="org-left">Linux</td>
<td class="org-left">trackingEndocyticPits_visualLibraryDemo (incl. rendering)</td>
<td class="org-right">142</td>
</tr>


<tr>
<td class="org-left">Intel Xeon E5-2680 16 cores @ 2.7 GHz - 32 GB Ram</td>
<td class="org-left">Linux</td>
<td class="org-left">trackingEndocyticPits_visualLibraryDemo (incl. rendering)</td>
<td class="org-right">206</td>
</tr>
</tbody>
</table>


<a id="orgb4cad95"></a>

## GUI walk-through (Beta version)

The GUI is generally recommended for the analysis of a couple files and test the capacity of u-track3D on a given type of dataset. With straightforward data loading and a simplified execution pipeline, the GUI is designed toward an intuitive first experience. 

📺 Tutorial video: [How to Run u-track3D (YouTube)](https://youtu.be/8P1mZZxGhyI?si=n1tAmmT-KWFBMqIm)

<a id="org3e33b65"></a>

### Getting started and loading data

Create a parallel pool for parallel computing in matlab using either the [command line or the graphical interface](https://www.mathworks.com/help/parallel-computing/parpool.html). Add the code folder in Matlab path. Then launch the GUI in the command line with: 

    u_quantify()

Then click "new" to create a new movie

![img](tutosmaller/movieSelectorGUI.png)

If the data follows the bioformat standard, then open "Import Movie using Bioformat " and  select  the file, or first file of a sequence. If not, the format must be in a single tiff file per time point and each channel must be placed in a single folder. Use the "add channel" dialog to point to each channel folder

![img](tutosmaller/movieInfoInput.png)

Then launch the "u-track3D" application. 

![img](tutosmaller/startUtrack3d.PNG)

In order to keep the set of operation linear, u-track3D is organized in seven processes:

1.  Maximum Intensity Projection (MIP) rendering
2.  Detection on the full volume
3.  Tracking on the full volume
4.  Definition of a Dynamic Region Of Interest (DynROI)
5.  Maximum Intensity Projection (MIP) rendering in the DynROI
6.  Detection in the DynROI
7.  Tracking in the DynROI

![img](tutosmaller/blankSetup.PNG)


<a id="org0859d3f"></a>

### Detection, tracking and review on the whole volumetric sequence

Each process must be parameterized or "setup" before being run. Sometime it merely involves opening the setup dialog and accepting the defaults by clicking "apply", as for example below with the MIP rendering process in the case of a single channel. This step ensures that the users explore the capacity the algorithm to adapt the parameters to their datasets.

![img](./tutosmaller/MIPParam.png)

The detection parameters propose different algorithms for detection, the default approach being the one presented in the u-track3D paper. In this beta version, the "Scales" dialog define the scales used for filtering and the Alpha value define sensitivity. Further  improvement will be made to separate different type of algorithms. 

![img](./tutosmaller/DetetionParamaters.png)

Click "Apply" and then "Run" in the control pannel to run the first two processes, then review the results by clicking on "Results"  in step 2. Results can be seen overlayed over a MIP:

![img](tutosmaller/MIPDetectView.png)

Or by slicing the volume 

![img](tutosmaller/SliceBySliceDetectionView.png)

The parameterization of the tracking algorithm first provides control over the maximum gap size, the minimum track size to be considered among other several controls.

![img](tutosmaller/trackingParam.png)

The control of Frame-to-frame linking and gap closing is performered in separated views:

![img](tutosmaller/Frame-to-Frame-linking.png)

![img](tutosmaller/GAPParam.png)

Once tracks are computed ("Apply" parameter and click on "run"), trajectories can be reviewed similarly to the review of detections. 


<a id="org80d3754"></a>

### Definition of DynROI and tracking in DynROI

The estimation of trajectories open the door to the dynROI in step 4. Several variation of dynROI estimation are made available such as: 

-   **fitTrackSetFrameByFrame**: fit an optimal box following a group of tracks over time. Motions are estimated on a frame-by-frame basis, ideal when the structural changes are important over time, but local changes are smooth over a few frames.
-   **fitTrackSetRegistered**: fit an optimal box following a group of tracks over time. Motion are estimated with respect to the first frame, ideal when the structural changes are slow overtime but the local motions measured in the trajectories are highly stochastic.
-   **fitDetSetFrameByFrame**: same as "fitTrackSetFrameByFrame" using detection instead of tracks.
-   **fitDetSetRegister**: same as "fitTrackSetRegistered" using detection instead of tracks.

More dynROI types will be made available and documented in the near future. 

![img](tutosmaller/DynROIBuilding.png)

The review of dynROI location can be carried out using the MIP view in the Results panel: 

![img](tutosmaller/DynROILocation.png)

The voxels described by the dynROI can then be displayed by toggling on the "Dynamic ROI Raw Image" dialog. Here is a gif produced through the "save frames" dialog: 

![img](tutosmaller/frames.gif)

The last three remaining process 5 to 7 behave similarly to step 1 to 3, except that the dynROI built must be specified for the process to run properly using the "Build Dynamic ROI Process" drop-down menu as shown below for the detection process: 

![img](tutosmaller/SelectDynROIDetect.png)

and for tracking process:

![img](tutosmaller/TrackingSelectDynROI.png)


<a id="orgb793bb7"></a>

## Known issues

-   The set of parameters for detection is confusing. Further streamlining improvement will be made for a smaller set of parameters to be visible.
-   Detection and tracking sets used for dynROI estimation must be set manually, even when there is only one option.
-   The Detection set must be selected before the last tracking step. This problem is also being solved.


<a id="org58bde09"></a>

## Milestones

-   [X] Adding Amira trajectory export in addition to detection in example script
-   [X] Demonstrate trackability in the script
-   [X] Fix annoying requirement in the GUI work flow (cf. Known Issues)
-   [X] Adding a script for basic ROI randomely selected <span class="timestamp-wrapper"><span class="timestamp">&lt;2022-07-07 Thu&gt;</span></span>
-   [X] Adding a script for dual channel manipulation <span class="timestamp-wrapper"><span class="timestamp">&lt;2022-07-07 Thu&gt;</span></span>
-   [ ] A more complete test on mac and windows
-   [ ] Add an example of script-based Bioformat import
-   [ ] Adding more types of DynROI in the GUI


<a id="org09a5f97"></a>

## Software Requirements

-   This software requires the following Matlab toolboxes
    -   Matlab (tested on 2018a to 2022a)
    -   Computer Vision Toolbox
    -   Image Processing Toolbox
    -   Control System Toolbox
    -   Optimization Toolbox
    -   Statistics and Machine Learning Toolbox
    -   Curve Fitting Toolbox
    -   Computer Vision Toolbox
    -   Parallel Computing Toolbox

-   This software has been tested on the following OS
    -   Linux Red Hat 7
      
-   Other Dependencies
    -   GNU Scientific Library (GSL) – required for running the MEX files. Tested with gsl/1.15.

----------------------
[Danuser Lab Website](https://www.danuserlab-utsw.org/)

[Software Links](https://github.com/DanuserLab)
