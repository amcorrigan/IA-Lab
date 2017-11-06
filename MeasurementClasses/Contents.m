% MEASUREMENTCLASSES
%
% Files
%   AZMeasure                    - Interface for measurement classes
%   AZMeasurePixels              - parent class allowing pixel size information to be passed to the measurement class.
%   BasicIntensityAZMeasure      - Measure the mean intensity, max and min, and also area so that total intensity can be calculated.
%   BasicMeasure_Cell            - Basic shape measurements - area, aspect, solidity, etc
%   BlurMetricAZMeasure          - operate on a whole image, to determine if there is a lot of blurring
%   CentroidIntensityAZMeasure   - take the intensity at the centroid of the segmented regions
%   DelaunayEntropyAZMeasure     - Measure cell organisation using the entropy of Delaunay triangle areas.
%   IntensityFocusAZMeasure      - Measure how focussed the intensity
%   Measure_OpticArtefacts       - Calculate the magnitude of optical artefacts in the image
%   MeasureExtractCellomics      - Extract Cellomics segmentation results from the object files
%   MeasurementManager           - Manager for the measurements, which passing the correct channels to each measurement module and combining the outputs.
%   MicroNucleiAZMeasure         - Calculate statistics of micro-nuclei - area, intensity and distance from the nucleus.
%   NucStats3DAZMeasure          - Measure Nuclear properties from 3D labels
%   NucStatsAZMeasure            - Measure Nuclear properties, including total DNA content for cell-cycle.
%   PixelClusterAZMeasure        - (Deprecated) Measure the extent of clustering from the radial distribution function.
%   RingIntensityAZMeasure       - Measure intensity in rings inside and outside the nucleus (or other objects).
%   ShapeBinsAZMeasure           - Statistics reflecting the cell shape, using the histogram of the cell boundary distance transform.
%   ShapeStatsAZMeasure          - Measure shape properties for the segmented regions
%   Spheroid2DStatsAZMeasure     - Measure shape properties for the segmented spheroid (note that this expects one spheroid per image).
%   SpotCountAZMeasure           - count how many spots (label 2) are in each object (label 1)
%   SpotStatsAZMeasure           - Statistics of spots (label 2) in each object (label 1) (number, location, intensity).
%   SubcellIntensityAZMeasure    - Intensity by subdividing the cell into regions based on the distance from the cell edge.
%   SubNucCellIntensityAZMeasure - Intensity by subdividing the cell into regions based on the distance from the cell and nucleus edges.
%   TouchingEdgeAZMeasure        - How much of each label is touching the border of the image.
