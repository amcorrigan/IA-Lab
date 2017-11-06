classdef NuclearPropertiesTest < matlab.unittest.TestCase
 
    properties
        TestFigure
    end
 
    methods(TestMethodSetup)
        function createWorkflow(testCase)
            
            % find out where the test images are stored
            parentfolder = fileparts(which('nuclearPropertiesWorkflow.m'));
            parser = ParserYokogawa(fullfile(parentfolder,'AssayPlate'));
            testCase.Workflow = nuclearPropertiesWorkflow('tempoutput',parser);
        end
    end
 
% %     methods(TestMethodTeardown)
% %         function closeFigure(testCase)
% %             close(testCase.TestFigure)
% %         end
% %     end
 
    methods(Test)
 
% %         function defaultCurrentPoint(testCase)
% %  
% %             cp = testCase.TestFigure.CurrentPoint;
% %             testCase.verifyEqual(cp, [0 0], ...
% %                 'Default current point is incorrect')
% %         end
% %  
% %         function defaultCurrentObject(testCase)
% %             import matlab.unittest.constraints.IsEmpty
% %  
% %             co = testCase.TestFigure.CurrentObject;
% %             testCase.verifyThat(co, IsEmpty, ...
% %                 'Default current object should be empty')
% %         end
        function testReproducibleStats(testCase)
            imobj = testCase.Workflow.BatchParser.ParserObj.getImageC2D('well','E03');
            testCase.verifyTrue(iscell(imobj));
            
            
        end
    end
 
end