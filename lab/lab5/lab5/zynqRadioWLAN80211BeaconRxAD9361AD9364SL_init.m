function zynqRadioWLAN80211BeaconRxAD9361AD9364SL_init(action, varargin)
% Validate parameter values, and create parameter structures for the
% 802.11 beacon receive demo. Also set parameter values on blocks
% immediately via set_params.

%  Copyright 2014-2015 The MathWorks, Inc.

switch action
    case 'init'
        l_setupModelParams(varargin{:});
    case 'scope'
        l_setupScopes();
end % end switch

end

function l_setupModelParams(varargin)
    argvals = l_parseArgs(varargin{:});
    p80211  = zynqRadioWLAN80211BeaconRxModelParamsAD9361AD9364SL(argvals);

    assignin('base', 'p80211', p80211);
end

function argvals = l_parseArgs(varargin)
    
    args = inputParser;

    % These input arguments are determined by the values specified in the
    % 'Model Parameters' block.
    %
    args.addParameter('AGCLoopGain',       0.05, ...
                        @(x) validateattributes(x, {'numeric'}, {'real','positive','scalar', '<', 1}, ...
                                                'zynqRadioWLAN80211BeaconRxModelParamsAD9361AD9364SL', '''AGC loop gain''') ...
                      );
    args.addParameter('AGCMaxGain',        20, ...
                        @(x) validateattributes(x, {'numeric'}, {'real','positive','scalar'}, ...
                                                'zynqRadioWLAN80211BeaconRxModelParamsAD9361AD9364SL', '''Maximum AGC gain''') ...
                      );
    args.addParameter('CorrThreshold',     1500, ...
                        @(x) validateattributes(x, {'numeric'}, {'real','positive','scalar', 'nonnan', 'finite'}, ...
                                                'zynqRadioWLAN80211BeaconRxModelParamsAD9361AD9364SL', '''Synchronization threshold''') ...
                      );
    args.addParameter('ChannelNumber',     1, ...
                        @(x) validateattributes(x,{'numeric'},{'real','nonempty','scalar','integer','>=',1,'<=',11}) ...
                      );
    args.addParameter('RadioGain',         5.0, ...
                        @(x) validateattributes(x,{'numeric'},{'real','nonempty','scalar','nonnan','finite'}) ...
                      );
    args.addParameter('RadioFreqOffset',   0, ...
                        @(x) validateattributes(x,{'numeric'},{'real','nonempty','scalar','nonnan','finite'}) ...
                      );
    args.addParameter('RxFrontendGain',    20, ...
                        @(x) validateattributes(x,{'numeric'},{'real','nonempty','scalar','nonnan','finite'}) ...
                      );
    args.parse(varargin{:});
    argvals = args.Results;
end

function l_setupScopes()
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

    modelname = bdroot;
    agcScope = [modelname ...
      '/Receiver/Rx Front End/AGC Scope'];
    freqOffsetScope = [modelname ...
      '/Receiver/Rx Front End/Estimated Frequency Offset'];
    syncScope = [modelname ...
      '/Receiver/Receiver Controller/Synchronization Scope'];
    sfdSyncScope = [modelname ...
      '/Receiver/Detector/SFD Synchronization Scope'];
    chipsSP = [modelname ...
      '/Receiver/Receiver Controller/Received Chips'];
    symbolsSP = [modelname ...
      '/Receiver/Receiver Controller/Received Symbols'];
  
  scatterWidth = floor(0.9*scopeWidth);
  scatterHeight = scatterWidth;
  yPosScat = yPos-scatterHeight - marginV;
  xPosScat = [xPos(1) xPos(1)+marginH+scatterWidth];
  set_param(chipsSP, 'FigPos', ...
      mat2str([xPosScat(1) yPosScat scatterWidth scatterHeight]));
  set_param(symbolsSP, 'FigPos', ...
      mat2str([xPosScat(2) yPosScat scatterWidth scatterHeight]));
   
  xPosMPDU = xPosScat(2)+2*marginH+scatterWidth;
  mpduWidth = (xPos(4)+scopeWidth) - xPosMPDU;
  mpduHeight = yPos - marginH - marginB;
  if mpduHeight > 530
      mpduHeight = 530;
  end
  assignin('base', 'mpduFigPos', [xPosMPDU marginB mpduWidth mpduHeight]);
   
    hagcScope = get_param(agcScope,'ScopeConfiguration');
    hagcScope.Position = [xPos(1) yPos scopeWidth scopeHeight];
    hfreqOffsetScope = get_param(freqOffsetScope,'ScopeConfiguration');
    hfreqOffsetScope.Position = [xPos(2) yPos scopeWidth scopeHeight];
    hsyncScope = get_param(syncScope,'ScopeConfiguration');
    hsyncScope.Position = [xPos(3) yPos scopeWidth scopeHeight];
    hsfdSyncScope = get_param(sfdSyncScope,'ScopeConfiguration');
    hsfdSyncScope.Position = [xPos(4) yPos scopeWidth scopeHeight];
   
   
end

% [EOF]
