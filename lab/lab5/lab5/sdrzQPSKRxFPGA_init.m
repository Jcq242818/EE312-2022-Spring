function SimParams = sdrzQPSKRxFPGA_init
% Set simulation parameters
% SimParams = sdrzQPSKRxFPGA_init

%   Copyright 2014-2015 The MathWorks, Inc.

%SDR receiver parameters
SimParams.DesiredRFCenterFrequency =  2.415e9;
SimParams.RadioIntermediateFrequency = 3e6;
SimParams.RadioCenterFrequency = SimParams.DesiredRFCenterFrequency - SimParams.RadioIntermediateFrequency;
SimParams.RadioGain = 4.5;
SimParams.RadioADCRate = 98.304e6;
SimParams.RadioDecimationFactor = 492; %SimParams.RadioADCRate/SimParams.Fs;
SimParams.RadioFrontEndSampleRate = SimParams.RadioADCRate / SimParams.RadioDecimationFactor;

% General simulation parameters
SimParams.M = 4; % M-PSK alphabet size
SimParams.Upsampling = 4; % Upsampling factor
SimParams.Downsampling = 2; % Downsampling factor

SimParams.Fs = SimParams.RadioFrontEndSampleRate; % Sample rate in FPGA
SimParams.Ts = 1/SimParams.Fs; % Sample time
SimParams.FrameSize = 100; % Number of modulated symbols per frame
SimParams.RxBufferedFrames = 10; % Received buffer length (in frames)

% Tx parameters
SimParams.BarkerLength = 13; % Number of Barker code symbols
SimParams.DataLength = (SimParams.FrameSize - SimParams.BarkerLength)*log2(SimParams.M); % Number of data payload bits per frame
SimParams.MsgLength = 105;

% Rx parameters
K = 1;
A = 1/sqrt(2);
% Look into model for details for details of PLL parameter choice.
SimParams.FineFreqPEDGain = 2*K*A^2+2*K*A^2; % K_p for Fine Frequency Compensation PLL, determined by 2KA^2 (for binary PAM), QPSK could be treated as two individual binary PAM
SimParams.FineFreqCompensateGain = 1; % K_0 for Fine Frequency Compensation PLL
SimParams.TimingRecTEDGain = 2.7*2*K*A^2+2.7*2*K*A^2; % K_p for Timing Recovery PLL, determined by 2KA^2*2.7 (for binary PAM), QPSK could be treated as two individual binary PAM, 2.7 is for raised cosine filter with roll-off factor 0.5
SimParams.TimingRecCompensateGain = -1; % K_0 for Timing Recovery PLL, fixed due to modulo-1 counter structure

% Generate square root raised cosine filter coefficients (required only for MATLAB example)
SimParams.RaisedCosineGroupDelay = 5; % Group delay of Raised Cosine Tx Rx filters (in symbols)
SimParams.SquareRootRaisedCosineFilterOrder = 2*SimParams.Upsampling*SimParams.RaisedCosineGroupDelay;
SimParams.RollOff = 0.5;

% Square root raised cosine receive filter
hRxFilt = fdesign.decimator(SimParams.Upsampling/SimParams.Downsampling, ...
                'Square Root Raised Cosine', SimParams.Upsampling, ...
                'N,Beta', SimParams.SquareRootRaisedCosineFilterOrder, SimParams.RollOff);
hDRxFilt = design(hRxFilt, 'SystemObject', true);
% The RRC filter block in sdrzqpskrx has a linear gain of 1. To match this,
% we have to multiply the coefficients produced by the filter designer by 2
SimParams.ReceiverFilterCoefficients = hDRxFilt.Numerator * 2; 

% For CORDIC
SimParams.rad_WL = 16;
SimParams.rad_FL = 13;
SimParams.car_WL = 32;
SimParams.car_FL = 26;
SimParams.tb = [0.4636    0.2450    0.1244    0.0624    0.0312];

% The CORDIC output represents an angle, say alpha. Given M=3 and the fact 
% that CFC raises the input signal to the power of SimParams.M (4 in the 
% case of QPSK modulation), the actual frequency is estimated as
%
%    f_hat = alpha/[pi*SimParams.Ts*(3+1)]/SimParams.M;
%
% which, in one sample period, translates into a phase shift of
%
%    phase_hat = 2pi*f_hat*SimParams.Ts 
%              = alpha/(2*SimParams.M)
%
% This phase needs to multiply 2^17/(2pi) before feeding into NCO,
% therefore, the net constant should be (-1 is for compensation)
%
%    SimParams.CFC_Const = (-1)*[1/(2*SimParams.M)]*[2^17/(2pi)];
%                        = -(2^15)/(pi*SimParams.M)
% However, the (1/pi) term is already taken care of by Normalized Radians
% representation in Complex To Magnitude Angle HDL Optimized, so:

SimParams.CFC_Const = -(2^15)/(SimParams.M);

% Phase value needs to multiply 2^17/(2pi) before feeding into NCO,
SimParams.FFC_Const = -(2^16)/pi;


