function SimParams = sdrzqpsktx_init
% Set simulation parameters
% SimParams = sdrzqpsktx_init

%   Copyright 2014 The MathWorks, Inc.

%SDR receiver parameters
SimParams.RadioIntermediateFrequency = 3e6;
SimParams.RadioDACRate = 98.304e6;
SimParams.RadioInterpolationFactor = 492;
SimParams.RadioFrontEndSampleRate = SimParams.RadioDACRate / SimParams.RadioInterpolationFactor;
SimParams.RadioFrontEndSamplePeriod = 1 / SimParams.RadioFrontEndSampleRate;

% General simulation parameters
SimParams.Upsampling = 4; % Upsampling factor
SimParams.Fs = SimParams.RadioFrontEndSampleRate; % Sample rate
SimParams.Ts = SimParams.RadioFrontEndSamplePeriod; % Sample time
SimParams.FrameSize = 100; % Number of modulated symbols per frame
SimParams.FrameTime = SimParams.Ts * SimParams.FrameSize * SimParams.Upsampling;
% Tx parameters
SimParams.BarkerLength = 13; % Number of Barker code symbols
SimParams.DataLength = (SimParams.FrameSize - SimParams.BarkerLength)*2; % Number of data payload bits per frame
SimParams.MsgLength = 105; % Number of message bits per frame, 7 ASCII characters

SimParams.RxBufferedFrames = 10; % Received buffer length (in frames)
SimParams.RCFiltSpan = 10; % Group delay of Raised Cosine Tx Rx filters (in symbols)

