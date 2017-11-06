function tests = nuclearPropertiesFunctionTest
tests = functiontests(localfunctions);

end
function setupOnce(testCase)

parentfolder = fileparts(which('nuclearPropertiesWorkflow.m'));
parser = ParserYokogawa(fullfile(parentfolder,'AssayPlate'));
testCase.TestData.Workflow = nuclearPropertiesWorkflow('tempoutput',parser);

end

function testReproducibleStats(testCase)

imobj = testCase.TestData.Workflow.BatchParser.ParserObj.getAC2DObj('well','E03');
testCase.verifyTrue(iscell(imobj));
testCase.verifyEqual(numel(imobj),1,'Should be 1 image object returned');

imdata = imobj{1}.getDataC2D();

testCase.verifyEqual(numel(imdata),3,'Should be 3 channels');



end
