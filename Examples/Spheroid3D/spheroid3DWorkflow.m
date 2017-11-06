function wkflow = spheroid3DWorkflow(IL,outputfolder)

if nargin<2 || isempty(outputfolder)
    outputfolder = '';
end
if nargin<1
    IL = [];
end

ss = SegmentationManager();
ss.supplyInputSettings({'raw','mean'}) % raw = keep full 3D image
                                       % mean = mean projection into 2D

ss.addProcess(AZSeg2DSpheroid(),2,[]);                         
ss.addProcess(NoisySpheroid3DAZSeg(0.01),1,1);
proc = SpheroidNucleiAZSeg(3,1.2,13);
proc.BgScale = 2;
ss.addProcess(proc,1,[]);

mm = MeasurementManager();
mm.addMeasurement(HemispheroidAZMeasure('',[]),2,[]);
mm.addMeasurement(HemispheroidSurfaceAZMeasure('',[]),[2,3],[]);
mm.addMeasurement(Spheroid2DStatsAZMeasure('Flat',[]),1,2);

ee = ExportManager(outputfolder);
% at the moment, the experiment will always be with Yokogawa images, but
% when that doesn't become the case, it might be possible to allow the
% parser to define what naming functions should be used
% % ee.addExporter(MatLabelAZExport(),@yokoLabelFile);
% % ee.addExporter(MatStatsAZExport(),@yokoStatsFile);
ee.addExporter(MatLabelAZExport(),@multiLabelFile);
ee.addExporter(MatStatsAZExport(),@multiStatsFile);

% no standard way of exporting 3D QC images as yet but perhaps the volumes
% should be exported to a spreadsheet?
% % sheetSettings.Include = {'MeanVol1','ErrorVol1'};
% % ee.addExporter(SemicolonSeparatedAZExport(sheetSettings),@yokoCSVFile);


wkflow = HCWorkFlow(ss,mm,ee,IL,'Spheroid3D');
