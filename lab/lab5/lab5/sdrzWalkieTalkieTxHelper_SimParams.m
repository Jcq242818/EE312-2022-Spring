function simParams = sdrzWalkieTalkieTxHelper_SimParams()
%SDRZWALKIETALKIETXHELPER_SIMPARAMS return a structure of parameters used
%to control the sdrzWalkieTalkieTx Simulink example
%
% X = sdrzWalkieTalkieTxHelper_SimParams() returns a structure, X, who's
% fields contain parameters for use in the sdrzWalkieTalkieTx Simulink
% example.

%  Copyright 2014-2015 The MathWorks, Inc.

%% Constant parameters used in the example

% These parameters control the sample rates in the example
simParams.audioFrameSize = 512;
simParams.audioSampleRate = 8e3; % in Hertz
simParams.radioDACRate = 32.768e6; % in Hertz
simParams.radioInterpolationFactor = 512;
simParams.radioIntermediateFrequency = 10e6; % in Hertz

%% Derived parameters used in the example

simParams.radioSampleRate = simParams.radioDACRate / ...
                                simParams.radioInterpolationFactor;
simParams.radioSamplePeriod = 1 / simParams.radioSampleRate;
simParams.audioSamplePeriod = 1 / simParams.audioSampleRate;

% The frequencySensitivityGain parameter is used in the FM Modulation. The
% equation is:
%     frequencySensitivityGain = frequencyDeviation * (2*pi*Ts) / A
% where frequencyDeviation is the peak frequency deviation of the modulated
% FM signal, Ts is the sample period and A is the peak amplitude of the
% modulating audio signal. In this example, the audio signal is assumed to
% be normalized i.e. have a peak amplitude of 1.
frequencyDeviation = 2.5e3; % in Hertz. Common for FRS and PMR446.
peakAudioAmplitude = 1;

simParams.frequencySensitivityGain = frequencyDeviation * 2 * pi * ...
                                     simParams.radioSamplePeriod / ...
                                     peakAudioAmplitude;

% These parameters define the software upsample filter, from the 8 kHz
% audio rate to the radio baseband rate of 64 kHz.
simParams.softwareInterpolationFactor = simParams.radioSampleRate / ...
                                        simParams.audioSampleRate;
% The model uses an FIR Interpolation block to perform the upsampling. The
% required parameters are the filter coefficients and the interpolation
% factor. 
simParams.interpolatorCoefficients = dspmltiFIRDefaultFilter(...
    simParams.softwareInterpolationFactor,1);

end