%% AWGN Channel

function [txWaveformAWGN]=createAWGNChannel(nonHTcfg,txWaveform,SNR_i)

[datax,pilotsx] = helperSubcarrierIndices(nonHTcfg, 'Legacy');
Nst = numel(datax)+numel(pilotsx); % Number of occupied subcarriers
Nfft = helperFFTLength(nonHTcfg);     % FFT length

AWGN = comm.AWGNChannel;
AWGN.NoiseMethod = 'Signal to noise ratio (SNR)';
AWGN.SignalPower = 1;              % Unit power
AWGN.SNR = SNR_i-10*log10(Nfft/Nst); % Account for energy in nulls

txWaveformAWGN=step(AWGN,txWaveform);
