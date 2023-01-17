%% Hiperlan2 Channel

function [txWaveformhiperlan2]=createhiperlan2Channel(nonHTcfg,txWaveform,SNR_i)

[datax,pilotsx] = helperSubcarrierIndices(nonHTcfg, 'Legacy');
Nst = numel(datax)+numel(pilotsx); % Number of occupied subcarriers
Nfft = helperFFTLength(nonHTcfg);     % FFT length

SNR = SNR_i-10*log10(Nfft/Nst); % Account for energy in nulls
fs = 2e7;
fd = 0;
trms=1e-7;
chan = stdchan(1/fs,fd,'hiperlan2A',trms);
nonHTPERSimulator(nonHTcfg, chan20, snr(i), ...
        maxNumErrors, maxNumPackets, enableFE);

txWaveformhiperlan2=step(AWGN,txWaveform);