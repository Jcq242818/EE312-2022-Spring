function SimParams = sdrzqpskrx_init
% Set simulation parameters
% SimParams = sdrzqpskrx_init

%   Copyright 2014 The MathWorks, Inc.

%SDR receiver parameters
SimParams.RadioIntermediateFrequency = 3e6;
SimParams.RadioADCRate = 98.304e6;
SimParams.RadioDecimationFactor = 492;
SimParams.RadioFrontEndSampleRate = SimParams.RadioADCRate / SimParams.RadioDecimationFactor;
SimParams.RadioFrontEndSamplePeriod = 1 / SimParams.RadioFrontEndSampleRate;

% General simulation parameters
SimParams.M = 4; % M-PSK alphabet size
SimParams.Upsampling = 4; % Upsampling factor
SimParams.Downsampling = 2; % Downsampling factor
SimParams.Fs = SimParams.RadioFrontEndSampleRate; % Sample rate
SimParams.Ts = SimParams.RadioFrontEndSamplePeriod; % Sample time
SimParams.FrameSize = 100; % Number of modulated symbols per frame

% Tx parameters
SimParams.BarkerLength = 13; % Number of Barker code symbols
SimParams.DataLength = (SimParams.FrameSize - SimParams.BarkerLength)*2; % Number of data payload bits per frame
SimParams.MsgLength = 105;

% Rx parameters
SimParams.RxBufferedFrames = 10; % Received buffer length (in frames)
SimParams.RCFiltSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)
SimParams.RadioFrameSize = SimParams.Upsampling * SimParams.FrameSize * SimParams.RxBufferedFrames;
K = 1;
A = 1/sqrt(2);
% Look into model for details for details of PLL parameter choice.
SimParams.FineFreqPEDGain = 2*K*A^2+2*K*A^2; % K_p for Fine Frequency Compensation PLL, determined by 2KA^2 (for binary PAM), QPSK could be treated as two individual binary PAM
SimParams.FineFreqCompensateGain = 1; % K_0 for Fine Frequency Compensation PLL
SimParams.TimingRecTEDGain = 2.7*2*K*A^2+2.7*2*K*A^2; % K_p for Timing Recovery PLL, determined by 2KA^2*2.7 (for binary PAM), QPSK could be treated as two individual binary PAM, 2.7 is for raised cosine filter with roll-off factor 0.5
SimParams.TimingRecCompensateGain = -1; % K_0 for Timing Recovery PLL, fixed due to modulo-1 counter structure

