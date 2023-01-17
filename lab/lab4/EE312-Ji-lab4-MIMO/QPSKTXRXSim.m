
% function [BER_1]=QPSKTXRXSim(EbNo)
clc; clear;
load commqpsktxrx_sbits_100.mat; % length 174
% General simulation parameters
SimParams.M = 4; % M-PSK alphabet size
SimParams.Upsampling = 4; % Upsampling factor
SimParams.Downsampling = 2; % Downsampling factor
SimParams.Fs = 2e5; % Sample rate in Hertz
SimParams.Ts = 1/SimParams.Fs; % Sample time in sec
SimParams.FrameSize = 100; % Number of modulated symbols per frame
% hAlamoutiEnc = comm.OSTBCEncoder;
% hAlamoutiDec = comm.OSTBCCombiner;
Hray = zeros(100, 2, 2);
% Create the Rayleigh distributed channel response 
% for two transmit and two receive antennas
Hray(1:2:end, :, :) = (randn(50, 2, 2) + 1i*randn(50, 2, 2))/sqrt(2);
% assume held constant for 2 symbol periods
Hray(2:2:end, :, :) = Hray(1:2:end, :, :);
SimParams.H21 = Hray(:,:,1)/sqrt(2); %
% Tx parameters
SimParams.BarkerLength = 26; % Number of Barker code symbols
SimParams.DataLength = (SimParams.FrameSize - SimParams.BarkerLength)*2; % Number of data payload bits per frame
SimParams.ScramblerBase = 2;
SimParams.ScramblerPolynomial = [1 1 1 0 1];
SimParams.ScramblerInitialConditions = [0 0 0 0];

SimParams.sBit = sBit; % Payload bits
SimParams.RxBufferedFrames = 10; % Received buffer length (in frames)

SimParams.RaisedCosineFilterSpan = 10; % Filter span of Raised Cosine Tx Rx filters (in symbols)
SimParams.MessageLength = 112;
SimParams.FrameCount = 100; % Number of frames transmitted

% Channel parameters
SimParams.PhaseOffset = 0; % in degrees
% MIMO = zeros(1,41);
% for i=-20:20
SimParams.EbNo = 5; % in dB
SimParams.FrequencyOffset = 0; % Frequency offset introduced by channel impairments in Hertz
SimParams.DelayType = 'Triangle'; % select the type of delay for channel distortion

% Rx parameters
SimParams.CoarseCompFrequencyResolution = 25; % Frequency resolution for coarse frequency compensation

% Look into model for details for details of PLL parameter choice. Refer equation 7.30 of "Digital Communications - A Discrete-Time Approach" by Michael Rice. 
K = 1;
A = 1/sqrt(2);
SimParams.PhaseRecoveryLoopBandwidth = 0.01; % Normalized loop bandwidth for fine frequency compensation
SimParams.PhaseRecoveryDampingFactor = 1; % Damping Factor for fine frequency compensation
SimParams.TimingRecoveryLoopBandwidth = 0.01; % Normalized loop bandwidth for timing recovery
SimParams.TimingRecoveryDampingFactor = 1; % Damping Factor for timing recovery
SimParams.TimingErrorDetectorGain = 2.7*2*K*A^2+2.7*2*K*A^2; % K_p for Timing Recovery PLL, determined by 2KA^2*2.7 (for binary PAM), QPSK could be treated as two individual binary PAM, 2.7 is for raised cosine filter with roll-off factor 0.5

%QPSK modulated Barker code header
BarkerCode = [+1; +1; +1; +1; +1; -1; -1; +1; +1; -1; +1; -1; +1; +1; +1; +1; +1; +1; -1; -1; +1; +1; -1; +1; -1; +1]; % Bipolar Barker Code        
SimParams.ModulatedHeader = sqrt(2)/2 * (-1-1i) * BarkerCode;
  
% Generate square root raised cosine filter coefficients (required only for MATLAB example)
SimParams.Rolloff = 0.5;

% Square root raised cosine transmit filter
SimParams.TransmitterFilterCoefficients = ...
  rcosdesign(SimParams.Rolloff, SimParams.RaisedCosineFilterSpan, ...
  SimParams.Upsampling);

% Square root raised cosine receive filter
SimParams.ReceiverFilterCoefficients = ...
  rcosdesign(SimParams.Rolloff, SimParams.RaisedCosineFilterSpan, ...
  SimParams.Upsampling);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
prmQPSKTxRx = SimParams; % QPSK system parameters 
printData = true; %true if the received data is to be printed
useScopes = true; % true if scopes are to be used

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Initialize the components
    % Create and configure the transmitter System object
    hTx = QPSKTransmitterR(...
        'UpsamplingFactor', prmQPSKTxRx.Upsampling, ...
        'MessageLength', prmQPSKTxRx.MessageLength, ...
        'TransmitterFilterCoefficients',prmQPSKTxRx.TransmitterFilterCoefficients, ...
        'DataLength', prmQPSKTxRx.DataLength, ...
        'ScramblerBase', prmQPSKTxRx.ScramblerBase, ...
        'ScramblerPolynomial', prmQPSKTxRx.ScramblerPolynomial, ...
        'ScramblerInitialConditions', prmQPSKTxRx.ScramblerInitialConditions, ...
        'H21',prmQPSKTxRx.H21);
    % Create and configure the AWGN channel System object
    hChan = QPSKChannelR('DelayType', prmQPSKTxRx.DelayType, ...
        'RaisedCosineFilterSpan', prmQPSKTxRx.RaisedCosineFilterSpan, ...
        'PhaseOffset', prmQPSKTxRx.PhaseOffset, ...
        'SignalPower', 1/prmQPSKTxRx.Upsampling, ...
        'FrameSize', prmQPSKTxRx.FrameSize, ...
        'UpsamplingFactor', prmQPSKTxRx.Upsampling, ...
        'EbNo', prmQPSKTxRx.EbNo, ...
        'BitsPerSymbol', prmQPSKTxRx.Upsampling/prmQPSKTxRx.Downsampling, ...
        'FrequencyOffset', prmQPSKTxRx.FrequencyOffset, ...
        'SampleRate', prmQPSKTxRx.Fs);

    % Create and configure the receiver System object
    hRx = QPSKReceiverR('DesiredAmplitude', 1/sqrt(prmQPSKTxRx.Upsampling), ...
        'ModulationOrder', prmQPSKTxRx.M, ...
        'DownsamplingFactor', prmQPSKTxRx.Downsampling, ...
        'CoarseCompFrequencyResolution', prmQPSKTxRx.CoarseCompFrequencyResolution, ...
        'PhaseRecoveryDampingFactor', prmQPSKTxRx.PhaseRecoveryDampingFactor, ...
        'PhaseRecoveryLoopBandwidth', prmQPSKTxRx.PhaseRecoveryLoopBandwidth, ...
        'TimingRecoveryDampingFactor', prmQPSKTxRx.TimingRecoveryDampingFactor, ...
        'TimingRecoveryLoopBandwidth', prmQPSKTxRx.TimingRecoveryLoopBandwidth, ...
        'TimingErrorDetectorGain', prmQPSKTxRx.TimingErrorDetectorGain, ...
        'PostFilterOversampling', prmQPSKTxRx.Upsampling/prmQPSKTxRx.Downsampling, ...
        'FrameSize', prmQPSKTxRx.FrameSize, ...
        'BarkerLength', prmQPSKTxRx.BarkerLength, ...
        'MessageLength', prmQPSKTxRx.MessageLength, ...
        'SampleRate', prmQPSKTxRx.Fs, ...
        'DataLength', prmQPSKTxRx.DataLength, ...
        'ReceiverFilterCoefficients', prmQPSKTxRx.ReceiverFilterCoefficients, ...
        'DescramblerBase', prmQPSKTxRx.ScramblerBase, ...
        'DescramblerPolynomial', prmQPSKTxRx.ScramblerPolynomial, ...
        'DescramblerInitialConditions', prmQPSKTxRx.ScramblerInitialConditions,...
        'PrintOption', printData, ...    
        'H21',prmQPSKTxRx.H21);
    if useScopes
        % Create the System object for plotting all the scopes
        hScopes = QPSKScopes;
    end

hRx.PrintOption = printData;

for count = 1:prmQPSKTxRx.FrameCount
    [transmittedSignal] = step(hTx); % Transmitter
    corruptSignal = step(hChan, transmittedSignal, 0); % AWGN Channel
    [RCRxSignal,coarseCompBuffer, timingRecBuffer,BER] = step(hRx,corruptSignal); % Receiver
%     figure(1)
%     plot(real(transmittedSignal))
%     drawnow
    
%     figure(2)
%     plot(real(modulatedData))
%     drawnow
%     
%     figure(3)
%     plot(transmittedData)
%     drawnow
%     
%    pause(1)
%     if useScopes
%         stepQPSKScopes(hScopes,RCRxSignal,coarseCompBuffer, timingRecBuffer); % Plots all the scopes
%     end
end
% if isempty(coder.target)
%     release(hTx);
%     release(hChan);
%     release(hRx);
% end
% if useScopes
%      releaseQPSKScopes(hScopes);
% end
BER_1=BER(1);
fprintf('Error rate = %f.\n',BER(1));
fprintf('Number of detected errors = %d.\n',BER(2));
fprintf('Total number of compared samples = %d.\n',BER(3));
% MIMO(i+21) = BER(1);
% end
% save MIMO









