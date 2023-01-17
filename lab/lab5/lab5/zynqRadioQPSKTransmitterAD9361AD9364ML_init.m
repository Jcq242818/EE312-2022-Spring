function SimParams = zynqRadioQPSKTransmitterAD9361AD9364ML_init
% Set simulation parameters
% SimParams = zynqRadioQPSKTransmitterAD9361AD9364ML_init

%   Copyright 2014-2015 The MathWorks, Inc.

% SDR transmitter parameters
SimParams.RadioIP = '192.168.3.2';
SimParams.RadioCenterFrequency =  2.4e9;
SimParams.RadioFrontEndSampleRate = 520.841e3;
SimParams.RadioChannelMapping = 1;

% General simulation parameters
SimParams.Upsampling = 4; % Upsampling factor
SimParams.Fs = SimParams.RadioFrontEndSampleRate; % Sample rate
SimParams.Ts = 1/SimParams.Fs; % Sample time
SimParams.FrameSize = 100; % Number of modulated symbols per frame

% Tx parameters
SimParams.BarkerLength = 13; % Number of Barker code symbols
SimParams.DataLength = (SimParams.FrameSize - SimParams.BarkerLength)*2; % Number of data payload bits per frame
SimParams.MessageLength = 105; % Number of message bits per frame, 7 ASCII characters
SimParams.FrameCount = 100;

SimParams.TxBufferedFrames = 1; % Transmit buffer length (in frames)
SimParams.RaisedCosineGroupDelay = 5; % Group delay of Raised Cosine Tx Rx filters (in symbols)
SimParams.ScramblerBase = 2;
SimParams.ScramblerPolynomial = [1 1 1 0 1];
SimParams.ScramblerInitialConditions = [0 0 0 0];

% Generate square root raised cosine filter coefficients
SimParams.SquareRootRaisedCosineFilterOrder = 2*SimParams.Upsampling*SimParams.RaisedCosineGroupDelay;
SimParams.RollOff = 0.5;
hTxFilt = fdesign.interpolator(SimParams.Upsampling, ...
                'Square Root Raised Cosine', SimParams.Upsampling, ...
                'N,Beta', SimParams.SquareRootRaisedCosineFilterOrder, SimParams.RollOff);
hDTxFilt = design(hTxFilt, 'SystemObject', true);
% Division by two to match coefficients generated by RRC block in
% zynqRadioQPSKTransmitterAD9361AD9364ML example
SimParams.TransmitterFilterCoefficients = hDTxFilt.Numerator/2; 

% Simulation Parameters
SimParams.RadioFrameLength = SimParams.Upsampling*SimParams.FrameSize*SimParams.TxBufferedFrames;
SimParams.RadioFrameTime = SimParams.RadioFrameLength/SimParams.Fs;
SimParams.StopTime = 10;
