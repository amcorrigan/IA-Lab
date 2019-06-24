function wk = nuclearPropertiesWorkflow(outputfolder,parserObj)

% Input parsing
if nargin<1
    outputfolder = [];
end

if nargin<2
    parserObj = [];
end
if ischar(parserObj)
    parserObj = ParserYokogawa(parserObj);
end


nucchan = 1;

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
isettings = {'max','max','max'}; % make sure that the images are processed in 2D, even if they have z-slices
ss.supplyInputSettings(isettings);

% create a nuclear segmentation object with initial settings
% The input arguments are specific to each segmentation class - in this
% case the inputs are:
% 1) the typical size of nuclei
% 2) the intensity threshold
%
nuclearSeg = DoGNucAZSeg(16,0.08);

% the segmentation stage is then added to the segmentation manager, along
% with the image channel to be used.  The third input, left empty here, is
% used if a prior label matrix is required for the segmentation (see
% cytoplasm segmentation below)
% SegmentationManager.addProcess(AZSeg object, input image channels, input label channels)
ss.addProcess(nuclearSeg,nucchan,[]);

% add a second segmentation object to segment the cell area
% In this experiment there is no cellular stain, so perform pseudo
% segmentation by expanding around the nuclear labels. Inputs are:
% 1) The distance by which to expand the labels
% 2) The weighting given to the image intensity, if an image channel is
%    supplied
%
cytoSeg = PseudoCytoAZSeg(50,0.8);

% adding the cytoplasm segmentation to the manager.
% In this case, the image channel is left empty to denote that no image
% data is supplied, and the third input (1) denotes that the 1st label
% should be passed (ie the label output from the nuclear segmentation
% above)
% SegmentationManager.addProcess(AZSeg object, input image channels, input label channels)
ss.addProcess(cytoSeg,[],1);


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
nucMorphMeas = NucStatsAZMeasure('Nuc');

% For measurements, we supply the indices of the labels to be used (1 =
% nuclear segmentation result), and the image indices (DAPI channel)
% MeasurementManager.addMeasurement(AZMeasure object, input label channels, input image channels)
mm.addMeasurement(nucMorphMeas,1,nucchan);

% add further measurements
mm.addMeasurement(BasicIntensityAZMeasure('NucInt'),1,1:3);
mm.addMeasurement(BasicIntensityAZMeasure('Cyto'),2,1:3);

% Finally, an ExportManager handles the output of results as tables,
% mat-files and QC images
ee = ExportManager(outputfolder);

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
ee.addExporter(DelimitedExport(),@multiCSVFile_OneFile); % defaults to tsv

% also include QC images for each segmentation step
% The QCImageAZExport class exports images overlaid with segmentation
% results, the syntax is:
% QCImageAZExport(image channel(s), segmentation label channel(s), image colours RGB, label colours RGB)
QC1 = QCImageAZExport(1,1,[1,1,1],[0.4,0.4,1]);

% the naming function determines the filename as well as the image type, in
% this case the ixQCFile generates png filenames
ee.addExporter(QC1,@(x)ixQCFile(x,'Nuc_'))

% export QC of cell segmentation
QC2 = QCImageAZExport([1,2],2,{[0,0,1];[0,1,0]},[1,0.4,1]);
ee.addExporter(QC2,@(x)ixQCFile(x,'Cell_'))


% at the end the managers are brought together into a workflow
% the HCWorkFlow object encapsulates the code for batch running, running in
% parallel, and linking together the steps of the workflow
wk = HCWorkFlow(ss,mm,ee,[],'Nuclear properties Assay');
% % wk.ParallelSplitFields = {'PlateID','Well'}; % this isn't required yet

% A parser object stores the architecture of the imaging experiment.  If we
% know what experiment the workflow will be applied to, it can be added to
% the workflow here
if ~isempty(parserObj)
    wk.addParser(parserObj);
end



