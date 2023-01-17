function simParams = zynqRadioWalkieTalkieReceiverHelperAD9361AD9364ML_init(protocol, channel)
%zynqRadioWalkieTalkieReceiverHelperAD9361AD9364ML_init returns parameters
%for the sdrzWalkieTalkieReceiver example

% Copyright 2014-2015 The MathWorks, Inc.

% Set the variables that control the system sample rates
simParams.radioFrameSize = 4000;
simParams.audioSampleRate = 8e3; % constant, in Hertz
simParams.radioSampleRate = 640e3;
simParams.softwareDecimationFactor = simParams.radioSampleRate / ...
    simParams.audioSampleRate;

% Design the 6 kHz lowpass filter for channel selectivity
fd = fdesign.lowpass;
fd.Specification = 'N,Fp,Ap,Ast';
fd.FilterOrder = 32;
fd.Fpass = 5e3 * 2/simParams.radioSampleRate; % normalized cutoff
fd.Apass = 1; % dB passband ripple
fd.Astop = 40; % dB stopband attenuation
simParams.channelFilter = design(fd,'equiripple', 'SystemObject', true);
simParams.channelFilterCoefficients = simParams.channelFilter.Numerator;

% Design the interpolation filter for 8 kHz to 64 kHz
simParams.decimationCoefficients = dspmltiFIRDefaultFilter(1, ...
    simParams.softwareDecimationFactor);
% Design the highpass filter for removing the CTCSS tone
fd = fdesign.highpass;
normalizefreq(fd, false, simParams.audioSampleRate);
fd.Fpass  = 350; % Passband frequency in Hz
fd.Fstop = 260; % Stopband frequency in HZ
fd.Apass = 1; % dB passband ripple
fd.Astop = 40; % dB stopband attenuation
simParams.CTCSSFilter = design(fd,'equiripple', 'SystemObject', true);
simParams.CTCSSFilterCoefficients = simParams.CTCSSFilter.Numerator;

% Determine the SDR hardware center frequency
simParams.radioCenterFrequency = sdrzWalkieTalkieHelper_Channel2Frequency( ...
    protocol, channel);

end

