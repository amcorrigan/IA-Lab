% SEGMENTATIONCLASSES
%
% Files
%   AZSeg                    - interface for segmentation classes
%   BasicNucAZSeg            - Basic nuclei detection, based on smoothing and thresholding
%   CellMaskAZSeg            - expand around a foreground marker to find the cell cytoplasm in 2D
%   ClusterGradMaskAZSeg     - same procedure as the cluster nuclei, but starting from the nuclear
%   CytoFibreAZSeg           - expand around nuclei using the inverse of intensity as a distance
%   CytoMonolayer3DAZSeg     - Perform 3D segmentation of 3D cells in a monolayer from cellmask and nuclear labels
%   CytoRoughAZSeg           - expand around nuclei using the inverse of intensity as a distance
%   DenseCellMaskAZSeg       - expand around nuclei using the inverse of intensity as a distance
%   DenseCellNoNucAZSeg      - Densely clustered cells with cell marker but no nucleus marker.
%   DenseNucAZSeg            - Difference of Gaussians to find centres, gradient watershed for segmentation.
%   DoGNucAZSeg              - Segmentation of nuclei based on gradient of intensity at edges
%   FaintNucAZSeg            - first build of segmentation class, taking faint nuclei as an example
%   GradNucAZSeg             - Nuclear segmentation - finding regional maxima and separating them using gradient watershed.
%   LabelCombineAZSeg        - Combine two labels, using the specified function
%   LabelMorphAZSeg          - Expansion or contraction of label regions from the boundary
%   LowMagNucAZSeg           - Segmentation of small and clustered nuclei
%   MicroNucleiAZSeg         - Detect micronuclei, separate from the main nucleus
%   NucMonolayer3DAZSeg      - Perform 3D segmentation of nuclei in a monolayer from a 3D image
%   OneStageAZSeg            - sub class for a single stage of segmentation, with a possible
%   PseudoCytoAZSeg          - Pseudo-cytoplasm segmentation
%   SegmentationManager      - first attempt at stand-alone segmentation manager
%   SpotDetect3DAZSeg        - Detection of spots (eg DNA damage, FISH transcription spots) in 3D, within cells/objects.
%   SpotDetect3DNoLabelAZSeg - Detection of spots (eg DNA damage, FISH transcription spots) in 3D, without masking by cell/object region.
%   TestNucAZSeg             - first build of segmentation class, taking faint nuclei as an example
%   ThresholdAZSeg           - Basic thresholding and labelling - don't expect this will be very useful.
%   TwoStageAZSeg            - Sub class for segmentation cases which can be logically separated into two
%   TwoStageSeedAZSeg        - two stages of segmentation, for instance nuclei segmentation followed
