%QPSK Transmitter
clc;
clear;

% General simulation parameters
TSimParams.Upsampling = 4; % Upsampling factor
TSimParams.Fs = 2e5; % Sample rate
TSimParams.Ts = 1/TSimParams.Fs; % Sample time
TSimParams.FrameSize = 100; % Number of modulated symbols per frame

% Tx parameters
TSimParams.BarkerLength = 13; % Number of Barker code symbols
TSimParams.DataLength = (TSimParams.FrameSize - TSimParams.BarkerLength)*2; % Number of data payload bits per frame
TSimParams.MessageLength = 105; % Number of message bits per frame, 7 ASCII characters
TSimParams.FrameCount = 100;

TSimParams.RxBufferedFrames = 10; % Received buffer length (in frames)
TSimParams.RaisedCosineGroupDelay = 5; % Group delay of Raised Cosine Tx Rx filters (in symbols)
TSimParams.ScramblerBase = 2;
TSimParams.ScramblerPolynomial = [1 1 1 0 1];
TSimParams.ScramblerInitialConditions = [0 0 0 0];

% Generate square root raised cosine filter coefficients (required only for MATLAB example)
TSimParams.SquareRootRaisedCosineFilterOrder = 2*TSimParams.Upsampling*TSimParams.RaisedCosineGroupDelay;
TSimParams.RollOff = 0.5;

% Square root raised cosine transmit filter
ThTxFilt = fdesign.interpolator(TSimParams.Upsampling, ...
                'Square Root Raised Cosine', TSimParams.Upsampling, ...
                'N,Beta', TSimParams.SquareRootRaisedCosineFilterOrder, TSimParams.RollOff);
ThDTxFilt = design(ThTxFilt);
TSimParams.TransmitterFilterCoefficients = ThDTxFilt.Numerator/2; 


%SDRu transmitter parameters
TSimParams.USRPCenterFrequency = 900e6;
TSimParams.USRPGain = 25;
TSimParams.USRPInterpolation = 1e8/TSimParams.Fs;
TSimParams.USRPFrameLength = TSimParams.Upsampling*TSimParams.FrameSize*TSimParams.RxBufferedFrames;

%Simulation Parameters
TSimParams.FrameTime = TSimParams.USRPFrameLength/TSimParams.Fs;
TSimParams.StopTime = 1000;

%%__________________________________________________________________________
prmQPSKTransmitter = TSimParams ;
%%__________________________________________________________________________

    % Initialize the components
    % Create and configure the transmitter System object
    hTx = QPSKTransmitter(...
        'UpsamplingFactor', prmQPSKTransmitter.Upsampling, ...
        'MessageLength', prmQPSKTransmitter.MessageLength, ...
        'TransmitterFilterCoefficients',prmQPSKTransmitter.TransmitterFilterCoefficients, ...
        'DataLength', prmQPSKTransmitter.DataLength, ...
        'ScramblerBase', prmQPSKTransmitter.ScramblerBase, ...
        'ScramblerPolynomial', prmQPSKTransmitter.ScramblerPolynomial, ...
        'ScramblerInitialConditions', prmQPSKTransmitter.ScramblerInitialConditions);
    

    % Create and configure the SDRu System object
    ThSDRu = comm.SDRuTransmitter('192.168.10.2', ...
        'CenterFrequency',        prmQPSKTransmitter.USRPCenterFrequency, ...
        'Gain',                   prmQPSKTransmitter.USRPGain, ...
        'InterpolationFactor',    prmQPSKTransmitter.USRPInterpolation);

currentTime = 0;

%Transmission Process
while currentTime < prmQPSKTransmitter.StopTime
    % Bit generation, modulation and transmission filtering
    data = step(hTx);
    % Data transmission
    step(ThSDRu, data);
    % Update simulation time
    currentTime=currentTime+prmQPSKTransmitter.FrameTime;
end

release(hTx);
release(ThSDRu);
