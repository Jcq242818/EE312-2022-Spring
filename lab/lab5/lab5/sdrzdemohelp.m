function sdrzdemohelp
% SDRZDEMOHELP  Load HTML write-up for current loaded demo model
%
% LIMITATIONS: The info block calling this function
%              MUST be in the root of the demo model.

% Copyright 2014 The MathWorks, Inc.

% There are three categories of SDR demos
% 1) Regular demos and retarget demos with their dedicated write-ups
% 2) Retarget demos sharing the same write-up with the demos before
%    retargeting, currently default for retargeting demos
% 3) Frequency calibration demos which have one text (accompanied with the
%    TX model but two demo models (TX and RX). Both the TX and RX models link
%    the same text from the info block.

% List all sdrz retarget demos with their dedicated write-ups here
excludeRetargetmdls = {};

% Find the full path of the model name
mdl = get_param(gcb, 'Parent');

% special case for FMC234 since the modelnames are not properly chosen. 
% postUnderScoreStr = mdl(strfind(mdl, '_'):end);
% mdl = suffixstrip(mdl);
% if ~isempty(strfind(postUnderScoreStr, 'FMC234'))
%     mdl = [mdl, 'FMC234'];
% end
    
% If the current models is a retargeting model and is NOT listed in the
% exclusion list
if ~isempty(strfind(mdl, 'Retarget')) && isempty(intersect(excludeRetargetmdls,mdl))
    mdl = strrep(mdl, 'Retarget', '');
end

% If the model is the Frequency Offset Calibration Receiver, redirect to
% the Tx write-up
if ~isempty(strfind(mdl, 'FrequencyCalibrationRx'))
    mdl = strrep(mdl, 'Rx', 'Tx');
end

% If the model is the QPSK Transmit Repeat Recorder, redirect to the QPSK
% Txx doc
if ~isempty(strfind(mdl, 'TransmitRepeatRecordSL'))
    mdl = strrep(mdl, 'RecordSL', 'AD9361AD9364ML');
end

sdrzdoc(mdl);

function htmlfilename=suffixstrip(modelname)

htmlfilename = regexprep(modelname, '_.*$', '');
htmlfilename = regexprep(htmlfilename, 'Midi$', '');
% [EOF]




