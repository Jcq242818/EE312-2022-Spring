function zynqRadioWLAN80211BeaconRxFPGAAD9361AD9364SL_params(mode, varargin)
% zynqRadioWLAN80211BeaconRxFPGAAD9361AD9364SL_params manages the HDL Optimized
% 802.11 Beacon Frame receiver model
% (zynqRadioWLAN80211BeaconRxFPGAAD9361AD9364) with AD9361/AD9364 RF Hardware. 
  
%   Copyright 2015 The MathWorks, Inc.

% This script depends on the initialization scripts for the
% 'zynqRadioWLAN80211BeaconRxAD9361AD9364SL'and 'commwlan80211BeaconRxhdl' Beacon
% Receiver models.

% 'init' - Initializes the values at PostLoad callback and when the Model
% Parameter block gets assigned new values
% 'scope' - same strucuture as the original HDL model, except names changed
% to reflect the enabled subsystem.
% 'retarget_scope' - scopes for the HDLRx subsystem are unavailable in the
% retargeted model as that went to live in the FPGA fabric. This only
% brings up the remaining existing scopes (SFD synchro and received
% symbols).

switch mode
  case 'init'
      
      % Define the p80211 structure
      % Samples per chip is usually set to 2 for these examples.
      sampsPerChip = 2;
      p80211 = commwlan80211BeaconParams(sampsPerChip);
      
      % Initialize the HDL model parameters (shouldn't change)
      p80211hdl = hdlcommwlan80211BeaconHDLInit(p80211);
      assignin('base', 'p80211hdl', p80211hdl);
      
      % Initialize the radio and tunable HDLRx block parameters
      argvals = l_parseArgs(varargin{:});
      p80211  = zynqRadioWLAN80211BeaconRxModelParamsAD9361AD9364SL(argvals);
      assignin('base', 'p80211', p80211);
 
  case 'scope'
    screenSize = get(0,'screensize');
    if screenSize < 1190
      maxWidth = screenSize(3);
    else
      maxWidth = 1190;
    end
    marginH = 20;
    marginV = 120;
    marginB = 60;
    scopeWidth = floor((maxWidth - 7*marginH)/4);
    xPos = 20:scopeWidth+marginH:maxWidth-20;
    scopeHeight = floor((screenSize(4)-marginV)/3);
    yPos = screenSize(4) - scopeHeight - marginV;
        
    modelname = bdroot; % sdrzwlan80211BeaconRxFPGAFMC234
    agcScope = [modelname ...
      '/802.11 WLAN Beacon Frame Receiver/HDLRx/HDLRx Front End/AGC Results/AGC Scope'];
    freqOffsetScope = [modelname ...
      '/802.11 WLAN Beacon Frame Receiver/HDLRx/HDLRx Front End/Frequency Offset'];
    syncScope = [modelname ...
      '/802.11 WLAN Beacon Frame Receiver/HDLRx/HDLRx Controller/Sync Results/Synchronization Scope'];
    sfdSyncScope = [modelname ...
      '/802.11 WLAN Beacon Frame Receiver/Detector/SFD Synchronization Scope'];
    symbolsSP = [modelname ...
      '/802.11 WLAN Beacon Frame Receiver/Frame Buffer/Received Symbols'];
  

    hagcScope = get_param(agcScope,'ScopeConfiguration');
    hagcScope.Position = [xPos(1) yPos scopeWidth scopeHeight];
    hfreqOffsetScope = get_param(freqOffsetScope,'ScopeConfiguration');
    hfreqOffsetScope.Position = [xPos(2) yPos scopeWidth scopeHeight];
    hsyncScope = get_param(syncScope,'ScopeConfiguration');
    hsyncScope.Position = [xPos(3) yPos scopeWidth scopeHeight];
    hsfdSyncScope = get_param(sfdSyncScope,'ScopeConfiguration');
    hsfdSyncScope.Position = [xPos(4) yPos scopeWidth scopeHeight];
    scatterWidth = floor(0.9*scopeWidth);
    scatterHeight = scatterWidth;
    yPosScat = yPos-scatterHeight - marginV;
    xPosScat = [xPos(1) xPos(1)+marginH+scatterWidth];
    set_param(symbolsSP, 'FigPos', ...
      mat2str([xPosScat(1) yPosScat scatterWidth scatterHeight]));
    xPosMPDU = xPosScat(2)+2*marginH+scatterWidth;
    mpduWidth = (xPos(4)+scopeWidth) - xPosMPDU;
    mpduHeight = yPos - marginH - marginB;
    if mpduHeight > 530
      mpduHeight = 530;
    end
    assignin('base', 'mpduFigPos', [xPosMPDU marginB mpduWidth mpduHeight]);
    
  % Added only for the retargeted example.
  case 'retarget_scope'
    screenSize = get(0,'screensize');
    if screenSize < 1190
      maxWidth = screenSize(3);
    else
      maxWidth = 1190;
    end
    marginH = 20;
    marginV = 120;
    marginB = 60;
    scopeWidth = floor((maxWidth - 7*marginH)/4);
    xPos = 20:scopeWidth+marginH:maxWidth-20;
    scopeHeight = floor((screenSize(4)-marginV)/3);
    yPos = screenSize(4) - scopeHeight - marginV;
        
    modelname = bdroot; % sdrzwlan80211BeaconRxFPGAFMC234retarget
    sfdSyncScope = [modelname ...
      '/802.11 WLAN Beacon Frame Receiver/Detector/SFD Synchronization Scope'];
    symbolsSP = [modelname ...
      '/802.11 WLAN Beacon Frame Receiver/Frame Buffer/Received Symbols'];

    hsfdSyncScope = get_param(sfdSyncScope,'ScopeConfiguration');
    hsfdSyncScope.Position = [xPos(1) yPos scopeWidth scopeHeight];
    scatterWidth = floor(0.9*scopeWidth);
    scatterHeight = scatterWidth;
    yPosScat = yPos-scatterHeight - marginV;
    xPosScat = [xPos(1) xPos(1)+marginH+scatterWidth];
    set_param(symbolsSP, 'FigPos', ...
      mat2str([xPosScat(1) yPosScat scatterWidth scatterHeight]));
    xPosMPDU = xPosScat(2)+2*marginH+scatterWidth;
    mpduWidth = (xPos(4)+scopeWidth) - xPosMPDU;
    mpduHeight = yPos - marginH - marginB;
    if mpduHeight > 530
      mpduHeight = 530;
    end
    assignin('base', 'mpduFigPos', [xPosMPDU marginB mpduWidth mpduHeight]);
        
    
end

function argvals = l_parseArgs(varargin)
    
    args = inputParser;

    % These input arguments are determined by the values specified in the
    % 'Model Parameters' block. The AGC amd CorrThreshold parameters will
    % directly affect the parameters of the HDLRx subsystem used for
    % targeting.
    % 
    args.addParameter('AGCLoopGain',       0.05, ...
                        @(x) validateattributes(x, {'numeric'}, {'real','positive','scalar', '<', 1}) ...
                      );
    args.addParameter('AGCMaxGain',        400, ...
                        @(x) validateattributes(x, {'numeric'}, {'real','positive','scalar'}) ...
                      );
    args.addParameter('CorrThreshold',     1400, ...
                        @(x) validateattributes(x, {'numeric'}, {'real','positive','scalar', 'nonnan', 'finite'}) ...
                      );
    args.addParameter('ChannelNumber',     1, ...
                        @(x) validateattributes(x,{'numeric'},{'real','nonempty','scalar','integer','>=',1,'<=',11}) ...
                      );
    args.addParameter('RadioGain',         30, ...
                        @(x) validateattributes(x,{'numeric'},{'real','nonempty','scalar','nonnan','finite'}) ...
                      );
    args.addParameter('RadioFreqOffset',   0, ...
                        @(x) validateattributes(x,{'numeric'},{'real','nonempty','scalar','nonnan','finite'}) ...
                      );
    args.parse(varargin{:});
    argvals = args.Results;
end

end


