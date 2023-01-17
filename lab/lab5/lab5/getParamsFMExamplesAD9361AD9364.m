function fmRxParams = getParamsFMExamplesAD9361AD9364
% getParamsFMExamplesAD9361AD9364 Get parameters of Zynq-based Radio
% AD9361/AD9364 Monophonic FM receiver example and Zynq-based Radio
% AD9361/AD9364 Stereo FM receiver example thereof

% Copyright 2015 The MathWorks, Inc.

% radio
fmRxParams.CenterFrequency = 102.5e6;
fmRxParams.RadioGainControlMode = 'AGC Slow Attack';
fmRxParams.RadioOutputDataType  = 'single';
fmRxParams.RadioSampleRate = 960e3; % Hz
intermediateSampleRate = 152e3; % Hz (The FM Broadcast Demodulator first 
                                % resamples the signal to 152 kHz)

fmRxParams.AudioSampleRate = 48e3; % Hz
% FM Demodulator
fmRxParams.FrequencyDeviation = 75e3; % Hz
fmRxParams.FilterTimeConstant = 75e-6; % Seconds

% To get to 152 kHz from 960 kHz
[num, den] = rat(fmRxParams.RadioSampleRate / intermediateSampleRate);
IFInterpolationFactor = den;
IFDecimationFactor = num;
% To get to 48 kHz from 152 kHz
[num, den] = rat(intermediateSampleRate / fmRxParams.AudioSampleRate);
audioInterpolationFactor = den;
audioDecimationFactor = num;
% To get to 48 kHz from 240 kHz
interpolationFactor = IFInterpolationFactor * audioInterpolationFactor;
decimationFactor = IFDecimationFactor * audioDecimationFactor;

% Frame length of radio and buffer size of FM Broadcast Demodulator
fmRxParams.RadioFrameLength = 4800;
fmRxParams.BufferSize = fmRxParams.RadioFrameLength;

% Audio frame time in seconds
fmRxParams.AudioFrameTime  = (fmRxParams.RadioFrameLength ...
    * interpolationFactor / decimationFactor) ...
    / fmRxParams.AudioSampleRate; % Seconds

% Simulation stop time in seconds
fmRxParams.StopTime = 10;

% [EOF]
