function SimParams = sdrzQPSKTxFPGA_init
% Set simulation parameters
% SimParams =  sdrzQPSKTxFPGA_init()

%   Copyright 2014-2015 The MathWorks, Inc.

%SDR transmitter parameters
SimParams.DesiredRFCenterFrequency =  2.415e9;
SimParams.RadioIntermediateFrequency = 3e6;
SimParams.RadioCenterFrequency = SimParams.DesiredRFCenterFrequency - SimParams.RadioIntermediateFrequency;
SimParams.RadioDACRate = 98.304e6;
SimParams.RadioInterpolationFactor = 492; %SimParams.RadioDACRate/SimParams.Fs;
SimParams.RadioFrontEndSampleRate = SimParams.RadioDACRate / SimParams.RadioInterpolationFactor;

% General simulation parameters
SimParams.Upsampling =4; % Upsampling factor for root raised cosine transmit filter
SimParams.Fs = SimParams.RadioFrontEndSampleRate; % Sample rate
SimParams.Ts = 1/SimParams.Fs; % Sample time
SimParams.PacketSize = 100; % Number of modulated symbols per packet
SimParams.FrameSize = 100; % Number of modulated symbols per frame
SimParams.FrameTime = SimParams.Ts*SimParams.FrameSize*SimParams.Upsampling;

% Tx message parameters
SimParams.BarkerLength = 13; % Number of Barker code symbols
SimParams.DataLength = (SimParams.FrameSize - SimParams.BarkerLength)*2; % Number of data payload bits per frame
SimParams.MsgLength = 105; % Number of message bits per frame, 7 ASCII characters


% Generate square root raised cosine filter coefficients (required only for MATLAB example)
SimParams.RaisedCosineGroupDelay = 5; % Group delay of Raised Cosine Tx Rx filters (in symbols)
SimParams.SquareRootRaisedCosineFilterOrder = 2*SimParams.Upsampling*SimParams.RaisedCosineGroupDelay;
SimParams.RollOff = 0.5;

% Square root raised cosine receive filter
hRxFilt = fdesign.interpolator(SimParams.Upsampling/SimParams.Upsampling, ...
                'Square Root Raised Cosine', SimParams.Upsampling, ...
                'N,Beta', SimParams.SquareRootRaisedCosineFilterOrder, SimParams.RollOff);
hDRxFilt = design(hRxFilt, 'SystemObject', true);
SimParams.TransmitterFilterCoefficients = hDRxFilt.Numerator * 2; % multiply to match filter design coefficients from RRC block with linear gain of 1 

