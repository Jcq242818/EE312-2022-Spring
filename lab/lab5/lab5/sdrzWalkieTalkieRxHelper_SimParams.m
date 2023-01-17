function simParams = sdrzWalkieTalkieRxHelper_SimParams()
%SDRZWALKIETALKIERXHELPER_SIMPARAMS return a structure of parameters used
%to control the sdrzWalkieTalkieRx Simulink example
%
% X = sdrzWalkieTalkieRxHelper_SimParams() returns a structure, X, who's
% fields contain parameters for use in the sdrzWalkieTalkieRx Simulink
% example.

%  Copyright 2014-2015 The MathWorks, Inc.

%% Set the variables that control the system sample rates
simParams.radioFrameSize = 4000;
simParams.audioSampleRate = 8e3; % constant, in Hertz
simParams.radioADCRate = 40.96e6; % in Hertz
simParams.radioDecimationFactor = 512;
simParams.radioIntermediateFrequency = 10e6;


%% Derived parameters used in the example
simParams.radioSampleRate = simParams.radioADCRate / ...
    simParams.radioDecimationFactor;
simParams.radioSamplePeriod = 1 / simParams.radioSampleRate;
simParams.audioSamplePeriod = 1 / simParams.audioSampleRate;


% These parameters define the software downsample filter, from the 80 kHz
% radio baseband rate to the audio rate of 8 kHz.
simParams.softwareDecimationFactor = simParams.radioSampleRate / ...
    simParams.audioSampleRate;
% The model uses an FIR Decimation block to perform the downsampling. The
% required parameters are the filter coefficients and the decimation
% factor.
simParams.decimationCoefficients = ...
    dspmltiFIRDefaultFilter(1,simParams.softwareDecimationFactor);

% There GoertzelCoefficients are used by the Goertzel algorithm, used in
% the CTCSS Decode MATLAB function block. They need to be in the base
% workspace using the variable name 'GoertzelCoeffs' to be used by the
% function block.
frs_toneFreqs = ...
    [67.0 71.9 74.4 77.0 79.7 82.5 85.4 88.5  91.5 94.8 97.4  ...
     100.0 103.5 107.2 110.9 114.8 118.8 123.0 127.3 131.8 136.5 141.3 ...
     146.2 151.4 156.7 162.2 167.9 173.8 179.9 186.2 192.8 ...
     203.5 210.7 218.1 225.7 233.6 241.8 250.3]';
GoertzelCoefficients   = ...
    2 * cos (2 * pi * frs_toneFreqs / simParams.audioSampleRate);
assignin('base', 'GoertzelCoeffs', GoertzelCoefficients);
end