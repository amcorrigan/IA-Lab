function wk = culture3DWorkflow(outputFolder,parserObj)

% Input parsing
if nargin<1
    outputFolder = [];
end

if nargin<2
    parserObj = [];
end
if ischar(parserObj)
    parserObj = ParserYokogawa(parserObj);
end


nucchan = 1;
cytochan = 2;

% Set up segmentation part of workflow
% Individual segmentation steps, eg nuclear segmentation, are written as
% classes.  This allows common functionality, eg graphical interface for
% interactive parameter adjustment, to be stored in the parent class, and
% used by any segmentation classes, including newly written ones.

% A SegmentationManager handles which channels are passed to each
% segmentation stage, and organises the output label matrices
ss = SegmentationManager();

% A further reason for using a managing class to handle the input and
% output channels is so that the individual segmentation classes do not
% need to know about the overall experimental setup, and can therefore be
% used outside the framework on individual image and label matrices

% supply pre-processing options for each of the input channels
isettings = {'full','full'}; % make sure that the images are processed in 2D, even if they have z-slices
ss.supplyInputSettings(isettings);

% create a nuclear segmentation object with initial settings
% The input arguments are specific to each segmentation class - in this
% case the inputs are:
% 1) the typical size of nuclei
% 2) the intensity threshold
%
nuclearSeg = NucMonolayer3DAZSeg(35,0.1);

% the segmentation stage is then added to the segmentation manager, along
% with the image channel to be used.  The third input, left empty here, is
% used if a prior label matrix is required for the segmentation (see
% cytoplasm segmentation below)
% SegmentationManager.addProcess(AZSeg object, input image channels, input label channels)
ss.addProcess(nuclearSeg,nucchan,[]);

% add a second segmentation object to segment the cell area

cytoSeg = CytoMonolayer3DAZSeg(0.1);

% adding the cytoplasm segmentation to the manager.
% In this case, the cellmask channel (cytochan) is the image channel
% and the third input (1) denotes that the 1st label
% should be passed (ie the label output from the nuclear segmentation
% above)
% SegmentationManager.addProcess(AZSeg object, input image channels, input label channels)
ss.addProcess(cytoSeg,cytochan,1);


% Optionally, can change the display styles for each segmentation step
% In this case, we change the nuclear segmentation results to be displayed
% as a rendered volume, rather than orthogonal slices (default).
ss.setDisplayChoice(@RenderDisplay3D,1)

% Set up the measurements
mm = MeasurementManager;
% Similar to the segmentation, measurements to be made from the images or
% segmentation results are handled by a MeasurementManager object, which
% handles the channels to be passed to each measurement class, and merges the
% outputs together into a single cell population structure

% create a measurement class to measure nuclear morphology statistics
% Typically for AZMeasure classes, the first input denotes a prefix to be
% added to the start of the names of measurements made by the class, to be
% stored in the output structure
nucMorphMeas = NucStats3DAZMeasure('Nuc');

% For measurements, we supply the indices of the labels to be used (1 =
% nuclear segmentation result), and the image indices (DAPI channel)
% MeasurementManager.addMeasurement(AZMeasure object, input label channels, input image channels)
mm.addMeasurement(nucMorphMeas,1,nucchan);

% add further measurements

mm.addMeasurement(BasicIntensityAZMeasure('Cyto'),2,1:2);

% Finally, an ExportManager handles the output of results as tables,
% mat-files and QC images
ee = ExportManager(outputFolder);

% the syntax for adding export objects is:
% ExportManager.addExporter(AZExport object, naming function, statsType)
% As a first export type, save the segmentation results in a mat-file
% MatLabelAZExport is a class which saves the label matrices to mat-files
% the second input argument is a handle to a naming function, which uses
% the information stored in each image object (Well location, field number,
% etc), to generate the filename for the save.
% As an example, multiLabelFile generates names in the format:
% /__labels/PLATE/label_A01_f1.mat
% This can be used as a template to create custom filename schemes.
ee.addExporter(MatLabelAZExport(),@multiLabelFile);

% Add export of the measurements to mat-files
% Inputs
% 1) AZExport object
% 2) naming function
% 3) which measurements to export
% The third input is used to determine which set of measurements should be
% saved, the options are 'SingleCell','Field', or 'Both'
ee.addExporter(MatStatsAZExport(),@multiStatsFile,'both');

% Export results to csv file (in this case tab-separated-value)
% % ee.addExporter(SemicolonSeparatedAZExport(),@multiCSVFile_OneFile);
ee.addExporter(DelimitedExport(),@multiCSVFile_OneFile);

% at the end the managers are brought together into a workflow
% the HCWorkFlow object encapsulates the code for batch running, running in
% parallel, and linking together the steps of the workflow
wk = HCWorkFlow(ss,mm,ee,[],'3D Monolayer Assay');
% % wk.ParallelSplitFields = {'PlateID','Well'}; % this isn't required yet

% A parser object stores the architecture of the imaging experiment.  If we
% know what experiment the workflow will be applied to, it can be added to
% the workflow here
if ~isempty(parserObj)
    wk.addParser(parserObj);
end




