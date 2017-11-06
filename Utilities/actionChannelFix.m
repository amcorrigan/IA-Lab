function [label,chanLookup] = actionChannelFix(acMap)

% acMap is a logical array denoting which action-channel combinations are
% possible
% eg as created by 
% acMap = any(joinDimensions(M,{5,6}),3);
% for instance
% 
% ac =
% 
%      0     0     0     0     1
%      1     0     0     0     0
%      0     1     0     0     0
%      0     0     1     1     0
%
% means that action 1 has channel 5 only
% action 2 has channel 1 only,
% action 3 has channel 2 only,
% action 4 has channels 3 and 4
% 
% There is no clash here (unique channels), so the output should be
% label = {'1';'2';'3';'4';'5'}
% chanLookup = 
% 
%      0     0     0     0     5
%      1     0     0     0     0
%      0     2     0     0     0
%      0     0     3     4     0
%

hasClash = any(sum(acMap,1)>1);

inds = findn(acMap);

chanLookup = zeros(size(acMap));
label = cell(size(inds,1),1);

for ii = 1:size(inds,1)
    chanLookup(inds(ii,1),inds(ii,2)) = ii;
    if hasClash
        label{ii} = sprintf('A%dC%d',inds(ii,1),inds(ii,2));
    else
        label{ii} = num2str(inds(ii,2)); % inds(ii,2) should == ii
    end
end