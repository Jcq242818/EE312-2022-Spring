function sdrzWalkieTalkieTxHelper_ModelParamsMask(action)
%SDRZWALKIETALKIETXHELPER_MODELPARAMSMASK Mask control for walkie-talkie example
%
% This function, and its associated 'Model Parameters' block in the
% sdrzWalkieTalkieTx example, is used to:
%     1) Control the display of parameters in the mask for the 'Model
%        Parameters' block.
%     2) Perform basic error checks on the values entered on the mask.
%     3) Take the validated values, calculate any dependent parameters and
%        apply all the necessary values to the required blocks in the
%        model.
%
% For the 'Model Parameters' block to function correctly, the 'PostLoadFcn'
% and 'InitFcn' callbacks of the model, and the 'Initialization' callback
% for the 'Model Parameters' block mask, should include the line:
%     sdrzWalkieTalkieTxHelper_ModelParamsMask('applyParametersToModel');
%
% Additionally, the callback for parameters in the 'Model Parameters' mask
% that show/hide other parameters should include the line:
%     sdrzWalkieTalkieTxHelper_ModelParamsMask('maskDisplayUpdate');
%
% The 'Model Parameters' block MUST be in the model root.
%
% The blocks with parameters controlled by the 'Model Parameters' block
% MUST have a name that is unique in the model workspace.

%  Copyright 2014 The MathWorks, Inc.

modelParametersBlockPath = [bdroot '/Model Parameters'];
switch action
    case 'applyParametersToModel'
        applyParametersToModel(modelParametersBlockPath); 
    case 'maskDisplayUpdate'
        maskDisplayUpdate(modelParametersBlockPath);
    otherwise
        error('Invalid action')
end

end


function [] = applyParametersToModel(modelParametersBlockPath) 
%APPLYPARAMTERSTOMODEL take the Model Parameters settings and apply to the blocks in the model 
%
% INPUTS:
%     modelParametersBlockPath - path to the 'Model Parameters' block

% Validate all the supplied values are valid
maskParameters = getMaskParameters(modelParametersBlockPath);
validateMaskParameters(maskParameters);

% Apply the new values to the appropriate blocks in the model
switch maskParameters.audioSource
    case 'Pure tone'
        SourceSelection = 1;
    case 'Chirp'
        SourceSelection = 2;
    case 'Sound file'
        SourceSelection = 3;
    otherwise
        % Should never be called as audioSource is a drop down selection
        % from a limited list.
        error('Invalid audio source selected')
end
sourceSelectionBlock = find_system(bdroot, 'Name', 'Source Selection');
set_param(sourceSelectionBlock{1}, 'value', num2str(SourceSelection));

sineWaveSourceBlock = find_system(bdroot, 'Name', 'Sine Wave Source');
set_param(sineWaveSourceBlock{1}, 'frequency', ...
          maskParameters.toneFrequency);

chirpSourceBlock = find_system(bdroot, 'Name', 'Chirp Source');
set_param(chirpSourceBlock{1}, 't1', maskParameters.targetSweepTime, ...
          'Tsweep', maskParameters.targetSweepTime);
 
FMTransmitPowerBlock = find_system(bdroot, 'Name', 'FM Transmit Power');
set_param(FMTransmitPowerBlock{1}, 'value', ...
          maskParameters.normalizedTransmitPower);

% The mask parameters from here down are not applied directly to the model.
% Instead, their value is used to calculate a corresponding value for a
% parameter in a block. E.g. CTCSSCode has to be converted to a frequency
% in Hertz. Notice that the parameter is set as a string, not numeric
% values.
CTCSSTone = sdrzWalkieTalkieHelper_CTCSSCode2Tone( ...
                 str2double(maskParameters.CTCSSCode));
CTCSSToneGeneratorBlock = find_system(bdroot, 'Name', ...
                                      'CTCCS Tone Generator');
set_param(CTCSSToneGeneratorBlock{1}, 'frequency', num2str(CTCSSTone), ...
          'amplitude', maskParameters.CTCSSAmplitude);

% The channel parameter used depends on the protocol selection
switch maskParameters.walkieTalkieProtocol
    case 'FRS'
        channel = maskParameters.channelFRS;
    case 'PMR446'
        channel = maskParameters.channelPMR446;
    otherwise
        % Should never be called as audioSource is a drop down selection
        % from a limited list.
        error('Invalid protocol selected')
end
centerFrequency = sdrzWalkieTalkieHelper_Channel2Frequency( ...
                      maskParameters.walkieTalkieProtocol, ...
                      str2double(channel));
desiredCenterFrequencyBlock = find_system(bdroot, 'Name', ...
                                          'Desired Center Frequency');
set_param(desiredCenterFrequencyBlock{1}, 'value', ...
          num2str(centerFrequency));
end


function [] = maskDisplayUpdate(modelParametersBlockPath)
%MASKDISPLAYUPDATE Determine the visibility of parameters in the mask
%
% INPUTS:
%     modelParametersBlockPath - path to the 'Model Parameters' block
%
% The variables that control how the mask is displayed and which mask 
% variables they control display of are:
%     walkieTalkieProtocol
%         - channelFRS
%         - channelPMR446
%     audioSource
%         - toneFrequency
%         - targetSweepTime
%
% These controlling properties need to have their callback in the mask set
% to:
%     sdrzWalkieTalkieTxHelper_ModelParamsMask('maskDisplayUpdate');
%
% Potential improvements:
%     1) Pass a string that identifies the property that was changed,
%        instead of checking and updating all possible changed properties.
%        This would require having individualized callbacks on each
%        property, instead of just a generic call.
%     2) Add a check for the listed properties that control the display of
%        the mask to make sure they have the correct callback on them. It's
%        currently easy to forget to change the mask callbacks AND this
%        function as it is used between different models.

walkieTalkieProtocol = get_param(modelParametersBlockPath, ...
                           'walkieTalkieProtocol');
switch walkieTalkieProtocol
    case 'FRS'
        propertyList(1).name = 'channelFRS';
        propertyList(1).visible = true;
        propertyList(2).name = 'channelPMR446';
        propertyList(2).visible = false;
    case 'PMR446'
        propertyList(1).name = 'channelFRS';
        propertyList(1).visible = false;
        propertyList(2).name = 'channelPMR446';
        propertyList(2).visible = true;
    otherwise
        % Should never be called as walkieTalkieProtocol is a drop down
        % selection from a limited list.
        error('Invalid radio protocol selected')
end
changeVisibility(modelParametersBlockPath, propertyList);

audioSource = get_param(modelParametersBlockPath, 'audioSource');
switch  audioSource
    case 'Pure tone'
        propertyList(1).name = 'targetSweepTime';
        propertyList(1).visible = false;
        propertyList(2).name = 'toneFrequency';
        propertyList(2).visible = true;
    case 'Chirp'
        propertyList(1).name = 'targetSweepTime';
        propertyList(1).visible = true;
        propertyList(2).name = 'toneFrequency';
        propertyList(2).visible = false;
    case 'Sound file'
        propertyList(1).name = 'targetSweepTime';
        propertyList(1).visible = false;
        propertyList(2).name = 'toneFrequency';
        propertyList(2).visible = false;
    otherwise
        % Should never be called as audioSource is a drop down selection
        % from a limited list.
        error('Invalid audio source selected')
end
changeVisibility(modelParametersBlockPath, propertyList);

end


function [] = changeVisibility(block, propertyList)
%CHANGEVISIBILITY Update the Model Parameters block mask to show/hide a parameter
%
% INPUTS:
%     block        - path to the block to change mask visibilities of
%     propertyList - an array of structures with fields x.name and
%                    x.visible. 'name' should be the name of the property
%                    to change. 'visible' should be logical.

% Error check the propertyList structure. Make sure the property names
% exists in the mask and that 'visible' is logical.
maskNames = get_param(block, 'MaskNames');
for n = 1:length(propertyList)
    validateattributes(propertyList(n).visible, {'logical'}, ...
                       {'scalar', 'nonempty', 'nonnan'});
    validatestring(propertyList(n).name, maskNames);    
end

% Get a list of the current visibility for mask properties and convert it
% to a logical matrix (as it is easier to work with)
maskVisibility = get_param(block, 'MaskVisibilities');
visibilityMask = strcmp(maskVisibility, 'on');

% Update the logical visibility mask for the input properties
for n = 1:length(propertyList)
    propertyIndex = strcmp(maskNames, propertyList(n).name);
    visibilityMask(propertyIndex) = propertyList(n).visible;
end

% Block mask visibility is a cell array of 'on' or 'off', so we need to
% update the original cell array maskVisibility based on our new logical
% visibility mask
maskVisibility(visibilityMask) = {'on'};
maskVisibility(~visibilityMask) = {'off'};

% Apply the updated maskVisibility to the block mask
set_param(block, 'MaskVisibilities',maskVisibility);

end


function maskParameters = getMaskParameters(modelParametersBlockPath)
%GETMASKPARAMETERS Return the current mask parameters
%
% INPUTS:
%     modelParametersBlockPath - path to the 'Model Parameters' block
%
% OUTPUTS:
%     maskParameters - a structure containing all the mask parameters
%
% Note that the mask parameters are returned as strings.

% The following parameters are strings and do not need evaluated
maskParameters.audioSource = ...
    get_param(modelParametersBlockPath, 'audioSource');
maskParameters.walkieTalkieProtocol = ...
    get_param(modelParametersBlockPath, 'walkieTalkieProtocol');

% The following parameters will need cast to get a numeric value
maskParameters.toneFrequency = ...
    get_param(modelParametersBlockPath, 'toneFrequency');
maskParameters.targetSweepTime = ...
    get_param(modelParametersBlockPath, 'targetSweepTime');
maskParameters.normalizedTransmitPower = ...
    get_param(modelParametersBlockPath, 'normalizedTransmitPower');
maskParameters.channelFRS = ...
    get_param(modelParametersBlockPath, 'channelFRS');
maskParameters.channelPMR446 = ...
    get_param(modelParametersBlockPath, 'channelPMR446');
maskParameters.CTCSSCode = ...
    get_param(modelParametersBlockPath, 'CTCSSCode');
maskParameters.CTCSSAmplitude = ...
    get_param(modelParametersBlockPath, 'CTCSSAmplitude');
end


function [] = validateMaskParameters(maskParameters)
%VALIDATEMASKPARAMETERS Check entered mask parameters are valid
%
% INPUTS:
%     maskParameters - a structure containing all the mask parameters
%
% Parameters from the mask are returned as strings. Some of these checks
% are strictly unnecessary (e.g. ensuring the value is numeric), due to the
% forced conversion using str2double().

%TODO '<=' errors don't display properly in the error dialog. Perhaps the
% '<' symbol is getting interpreted as an HTML flag? 
validateattributes( ...
    str2double(maskParameters.toneFrequency), ...
    {'numeric'}, ...
    {'scalar', 'real', '>=', 500, '<=', 3400}, ...
    'validateMaskParameters', 'Pure tone frequency');
validateattributes( ...
    str2double(maskParameters.targetSweepTime), ...
    {'numeric'}, ...
    {'scalar', 'real'});
validateattributes( ...
    str2double(maskParameters.normalizedTransmitPower), ...
    {'numeric'}, ...
    {'scalar', 'real', '>=', 0, '<=', 1});
validateattributes( ...
    str2double(maskParameters.CTCSSAmplitude), ...
    {'numeric'}, ...
    {'scalar', 'real', '>=', 0, '<=', 1});
validateattributes( ...
    str2double(maskParameters.CTCSSCode), ...
    {'numeric'}, ...
    {'scalar', 'real', '>=', 1, '<=', 38}, ...
    'validateMaskParameters', 'CTCSS Code');
validateattributes( ...
    str2double(maskParameters.channelFRS), ...
    {'numeric'}, ...
    {'scalar', 'real', '>=', 1, '<=', 14});
validateattributes( ...
    str2double(maskParameters.channelPMR446), ...
    {'numeric'}, ...
    {'scalar', 'real', '>=', 1, '<=', 8});
end