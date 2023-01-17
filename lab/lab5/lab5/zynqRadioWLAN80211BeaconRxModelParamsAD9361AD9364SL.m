function p80211 = zynqRadioWLAN80211BeaconRxModelParamsAD9361AD9364SL(argvals)
%zynqRadioWLAN80211BeaconRxModelParamsAD9361AD9364SL Define 802.11b receiver demo parameters
%
% Copyright 2014-2015 The MathWorks, Inc.

% ----------------------------------------------
% Base model parameters for Rx processing
% ----------------------------------------------
sampsPerChip = 2;
p80211 = commwlan80211BeaconRxInit( ...
            argvals.AGCLoopGain, argvals.AGCMaxGain, ...
            argvals.CorrThreshold, sampsPerChip);

% FIXME: proper update is to commwlan80211BeaconParams
p80211.MaximumPayloadSymbols = 65535; % In bits (was 3000)
p80211.MaximumPayloadSamples = p80211.MaximumPayloadSymbols * ...
  p80211.SpreadingRate*p80211.SamplesPerChip;
p80211.PayloadBufferLength = p80211.MaximumPayloadSymbols + ...
  p80211.SymbolsPerChannelFrame + p80211.ScramblerAmbiguity;

% ----------------------------------------------
% Top level Model Assumptions
% ----------------------------------------------
% p80211.SamplesPerChip         = 2
% p80211.ChipRate               = 11e6
% p80211.SymbolsPerChannelFrame = 128
% p80211.SamplesPerChannelFrame = 2816
p80211.ProcessingRate   = p80211.SamplesPerChip * p80211.ChipRate;
    
% ----------------------------------------------
% Top level Model Arguments
% ----------------------------------------------
for argnamecell = fieldnames(argvals)'
    argname = argnamecell{1};
    p80211.(argname) = argvals.(argname);
end

% ----------------------------------------------
% Radio Parameters
% ----------------------------------------------
       
p80211.RadioBasebandRate        = 22e6;

% ----------------------------------------------
% More derived radio parameters
% ----------------------------------------------
% a radio framelength of 3660 represents 10 packets which is a reasonable number
% for efficient socket performance.  frame must be integer multiple of the
% resampler decimation factor.
% for common WAP setups, a beacon is sent every 100ms and lasts around 3ms.

p80211.RadioFrameLength = p80211.SamplesPerChannelFrame; 
frameTime               = p80211.RadioFrameLength/p80211.RadioBasebandRate;
p80211.RadioNumFramesInBurst    = ceil(103e-3/frameTime);
