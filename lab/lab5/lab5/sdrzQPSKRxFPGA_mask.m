function varargout = sdrzQPSKRxFPGA_mask(block, action, varargin)
% sdrzQPSKRxFPGA_mask  Sets up workspace variables for the SDRZ QPSK Rx example

%   Copyright 2014 The MathWorks, Inc.

%**************************************************************************
% --- Action switch -- Determines which of the callback functions is called
%**************************************************************************
myException = [];
switch(action)
    
    case 'cbShowHideSettingOptions'
        
        settingCtrl = get_param(block, 'SettingCtrl');
        Vis         = get_param(block, 'maskVisibilities');
        En          = get_param(block, 'maskEnables');
        oldEnOptions  = strcat(En{2}, En{4}, En{6}, En{8});
        
        switch settingCtrl            
            case 'Automatic gain control settings'
                Vis(4:8) = mat2cell(repmat('off',length(Vis(4:8)),1),ones(size(Vis(4:8))),3);
                En(4:8)  = mat2cell(repmat('off',length( En(4:8)),1),ones( size(En(4:8))),3);
                Vis(2:3) = mat2cell(repmat('on', length(Vis(2:3)),1),ones(size(Vis(2:3))),2);
                En(2:3)  = mat2cell(repmat('on', length( En(2:3)),1),ones( size(En(2:3))),2);

            case 'Fine frequency compensation settings'
                Vis([2:3 6:8]) = mat2cell(repmat('off',length(Vis([2:3 6:8])),1),ones(size(Vis([2:3 6:8]))),3);
                En([2:3 6:8])  = mat2cell(repmat('off',length( En([2:3 6:8])),1),ones(size( En([2:3 6:8]))),3);
                Vis(4:5) = mat2cell(repmat('on',length(Vis(4:5)),1),ones(size(Vis(4:5))),2);
                En(4:5)  = mat2cell(repmat('on',length( En(4:5)),1),ones(size( En(4:5))),2);
                
            case 'Timing recovery settings'                
                Vis([2:5 8]) = mat2cell(repmat('off',length(Vis([2:5 8])),1),ones(size(Vis([2:5 8]))),3);
                En([2:5 8])  = mat2cell(repmat('off',length( En([2:5 8])),1),ones(size( En([2:5 8]))),3);
                Vis(6:7) = mat2cell(repmat('on',length(Vis(6:7)),1),ones(size(Vis(6:7))),2);
                En(6:7)  = mat2cell(repmat('on',length( En(6:7)),1),ones(size( En(6:7))),2);
                
            case 'Data decoding settings'                
                Vis(2:7) = mat2cell(repmat('off',length(Vis(2:7)),1),ones(size(Vis(2:7))),3);
                En(2:7)  = mat2cell(repmat('off',length( En(2:7)),1),ones( size(En(2:7))),3);
                Vis(8) = mat2cell(repmat('on', length(Vis(8)),1),ones(size(Vis(8))),2);
                En(8)  = mat2cell(repmat('on', length( En(8)),1),ones( size(En(8))),2);
                
            otherwise
                % No other actions to take
                
        end
                
        currentEnOptions  = strcat(En{2}, En{4}, En{6}, En{8});
        
        if (~strcmpi(oldEnOptions, currentEnOptions))
            set_param(block, 'MaskEnables', En, 'MaskVisibilities', Vis);
        end
    
    case 'init'
        myException = updateAGCLoopGain(block);
        if (~isempty(myException)), varargout{1} = myException; return; end
        
        myException = updateAGCMaxGain(block);
        if (~isempty(myException)), varargout{1} = myException; return; end
                
        myException = updateFineFreqNormalizedBW(block);
        if (~isempty(myException)), varargout{1} = myException; return; end
        
        myException = updateFineFreqDampingFactor(block);
        if (~isempty(myException)), varargout{1} = myException; return; end
        
        myException = updateTimeRecNormalizedBW(block);
        if (~isempty(myException)), varargout{1} = myException; return; end
        
        myException = updateTimeRecDampingFactor(block);
        if (~isempty(myException)), varargout{1} = myException; return; end
        
        myException = updateDataDetectingThreshold(block);
        if (~isempty(myException)), varargout{1} = myException; return; end
        
    otherwise
        % No other actions to take
        
end

varargout{1} = myException;

%*********************************************************************
% Function Name:    updateAGCLoopGain
% Description:      Set the Loop Gain in Automatic Gain Control
%*********************************************************************
function myException = updateAGCLoopGain(block)
AGCLoopGain = str2double(get_param(block, 'AutoGainCtrlLoopGain'));
if isnan(AGCLoopGain) || ~isreal(AGCLoopGain) || AGCLoopGain<=0
    error(message('SDR:qpskrxmask:PositiveAutoGainCtrlLoopGain'));
end
% Assign parameter to the block
AutoGainCtrlblock = [bdroot '/QPSK Receiver/HDLRx' ...
        '/Automatic Gain' sprintf('\n') 'Control'];
myException = updateTgtParamFromEditSdrzQPSKRxHDL(block, AutoGainCtrlblock, 'AGCLoopGain', 'AutoGainCtrlLoopGain');

% %*********************************************************************
% % Function Name:    updateAGCMaxGain
% % Description:      Set the Maximum Gain in Automatic Gain Control
% %*********************************************************************
function myException = updateAGCMaxGain(block)
AGCMaxGain = str2double(get_param(block, 'AutoGainCtrlMaxGain'));
if isnan(AGCMaxGain) || ~isreal(AGCMaxGain) || AGCMaxGain<=0
    error(message('SDR:qpskrxmask:PositiveAutoGainCtrlMaximumGain'));
end
% Assign parameter to the block
AutoGainCtrlblock = [bdroot '/QPSK Receiver/HDLRx' ...
        '/Automatic Gain' sprintf('\n') 'Control'];
myException = updateTgtParamFromEditSdrzQPSKRxHDL(block, AutoGainCtrlblock, 'AGCUpperLimit', 'AutoGainCtrlMaxGain');

%*********************************************************************
% Function Name:    updateFineFreqNormalizedBW
% Description:      Set the normalized bandwidth in the Fine Frequency 
%                   Compensation PLL, normalized to f_{symbol}
%*********************************************************************
function myException = updateFineFreqNormalizedBW(block)
% Parameter check 
FineFreqNormalizedBW = str2double(get_param(block, 'FineFreqNormalizedLoopBW'));
if isnan(FineFreqNormalizedBW) || ~isreal(FineFreqNormalizedBW) || FineFreqNormalizedBW<=0
    error(message('SDR:qpskrxmask:PositiveFineFreqNormalizedBW'));
end
% Assign parameter to the block
FineFreqCompblock = [bdroot '/QPSK Receiver/HDLRx' ...
        '/Fine Frequency' sprintf('\n') 'Compensation/Loop Filter'];
myException = updateTgtParamFromEditSdrzQPSKRxHDL(block, FineFreqCompblock, 'BnTs', 'FineFreqNormalizedLoopBW');

%*********************************************************************
% Function Name:    updateFineDampingFactor
% Description:      Set the damping factor in the Fine Frequency Compensation PLL
%*********************************************************************
function myException = updateFineFreqDampingFactor(block)
% Parameter check 
FineFreqDampFactor = str2double(get_param(block, 'FineFreqDampingFactor'));
if isnan(FineFreqDampFactor) || ~isreal(FineFreqDampFactor) || FineFreqDampFactor<=0
    error(message('SDR:qpskrxmask:PositiveFineFreqDampFactor'));
end
% Assign parameter to the block
FineFreqCompblock = [bdroot '/QPSK Receiver/HDLRx' ...
        '/Fine Frequency' sprintf('\n') 'Compensation/Loop Filter'];
myException = updateTgtParamFromEditSdrzQPSKRxHDL(block, FineFreqCompblock, 'zeta', 'FineFreqDampingFactor');

%*********************************************************************
% Function Name:    updateTimeRecNormalizedBW
% Description:      Set the normalized bandwidth in the Timing Recovery PLL,
%                   normalized to f_{symbol} 
%*********************************************************************
function myException = updateTimeRecNormalizedBW(block)
% Parameter check 
TimeRecNormalizedBW = str2double(get_param(block, 'TimeRecNormalizedLoopBW'));
if isnan(TimeRecNormalizedBW) || ~isreal(TimeRecNormalizedBW) || TimeRecNormalizedBW<=0
    error(message('SDR:qpskrxmask:PositiveTimeRecNormalizedBW'));
end
% Assign parameter to the block
TimeRecLoopFilterblock = [bdroot '/QPSK Receiver/HDLRx' ...
        '/Timing Recovery/Loop Filter'];
myException = updateTgtParamFromEditSdrzQPSKRxHDL(block, TimeRecLoopFilterblock, 'BnTs', 'TimeRecNormalizedLoopBW');

%*********************************************************************
% Function Name:    updateTimeRecDampingFactor
% Description:      Set the damping factor in the Timing Recovery PLL
%*********************************************************************
function myException = updateTimeRecDampingFactor(block)
% Parameter check 
TimeRecDampFactor = str2double(get_param(block, 'TimeRecDampingFactor'));
if isnan(TimeRecDampFactor) || ~isreal(TimeRecDampFactor) || TimeRecDampFactor<=0
    error(message('SDR:qpskrxmask:PositiveTimeRecDampFactor'));
end
% Assign parameter to the block
TimeRecLoopFilterblock = [bdroot '/QPSK Receiver/HDLRx' ...
        '/Timing Recovery/Loop Filter'];
myException = updateTgtParamFromEditSdrzQPSKRxHDL(block, TimeRecLoopFilterblock, 'zeta', 'TimeRecDampingFactor');

%*********************************************************************
% Function Name:    updateDataDetectingThreshold
% Description:      Set the Threshold in the Data Decoding
%*********************************************************************
function myException = updateDataDetectingThreshold(block)
DDthreshold = str2double(get_param(block, 'DataDecThreshold'));
if isnan(DDthreshold) || ~isreal(DDthreshold) || DDthreshold<=0
    error(message('SDR:qpskrxmask:PositiveThreshold'));
end
% Assign parameter to the block
DataDecodingblock = [bdroot '/QPSK Receiver/HDLRx/Data Decoding'];
myException = updateTgtParamFromEditSdrzQPSKRxHDL(block, DataDecodingblock, 'Threshold', 'DataDecThreshold');   
     


function myException = ...
    updateTgtParamFromEditSdrzQPSKRxHDL(block, targetBlock, param, editName )
% UPDATETGTPARAMFROMEDIT Update target parameters in a target block from an
%                        edit control.
%
% Inputs: block       - the 'Model Parameters' block
%         targetBlock - the block to receive the parameter
%         param       - name of the parameter in the targetBlock to be 
%                       changed
%         editName    - name of the parameter in the 'Model Parameters' 
%                       block whose value will be written to 'param'
%
% Outputs: myException - mException object in case of set_param failure
%
% See also UPDATETGTPARAMFROMPOPUP.

%   Copyright 2014 The MathWorks, Inc.

myException = [];
% -- Get variables from mask
WsVar = get_param(block, 'MaskWsVariables');

% -- get selected value
idx = strncmp(editName, {WsVar.Name}, length(editName));  
valNew = WsVar(idx).Value;

try
    set_param(targetBlock, param, num2str(valNew));
catch myException
end

% [EOF]
