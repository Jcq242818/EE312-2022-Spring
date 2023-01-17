function runZynqRadioQPSKTransmitterAD9361AD9364ML(prmQPSKTransmitter)

%   Copyright 2014-2015 The MathWorks, Inc.

%#codegen
coder.extrinsic('fprintf');

persistent hTx hSDR
if isempty(hTx)
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
    
    % Create and configure the SDR System object
  
    hSDR = sdrtx( prmQPSKTransmitter.SDRDeviceName,...
    'IPAddress',             prmQPSKTransmitter.RadioIP, ...
    'BasebandSampleRate',    prmQPSKTransmitter.RadioFrontEndSampleRate, ...
    'CenterFrequency',       prmQPSKTransmitter.RadioCenterFrequency,...
    'ChannelMapping',        prmQPSKTransmitter.RadioChannelMapping);
   
end

approxInitTime = 4; % A rough estimate of the time taken to start transmitting
fprintf('\n==== Starting Transmission ====\n');
fprintf(['If the execution time is significantly longer than %gs'...
                ' you are probably not running in real time.\n'],...
                prmQPSKTransmitter.StopTime + approxInitTime);
fprintf('Transmitting...\n');

 %Transmission Process
 currentTime = 0;
while currentTime < prmQPSKTransmitter.StopTime
    % Bit generation, modulation and transmission filtering
    data = step(hTx);
    % Data transmission
    step(hSDR, data);
    % Update simulation time
    currentTime=currentTime+prmQPSKTransmitter.RadioFrameTime;
end

release(hTx);
release(hSDR);
end
