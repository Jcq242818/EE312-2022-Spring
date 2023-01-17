%% clear all
clear; clc;
%% Waveform Configuration
mcs = 4;                % QPSK rate 1/2
psduLen = 32672/8;         % PSDU length in bytes

% Create a format configuration object for a 802.11p transmission
cfgNHT10 = wlanNonHTConfig;
cfgNHT10.ChannelBandwidth = 'CBW20';    % 10 MHz channel bandwidth
cfgNHT10.PSDULength = psduLen;          
cfgNHT10.MCS = mcs;                     

%% Channel Configuration
% Create and configure the channel
chanMdl = ['A','B','C','D','E'];
fd = 0;                            % Maximum Doppler shift, Hz
c = 3e8*3.6;                        % Speed of light, Km/hr
fc = 5.9e9;                         % Carrier frequency, Hz

fs10 = helperSampleRate(cfgNHT10);     % MSC=4
chanA = stdchan(1/fs10, fd, ['hiperlan2' chanMdl(1)]);
chanB = stdchan(1/fs10, fd, ['hiperlan2' chanMdl(2)]);
chanC = stdchan(1/fs10, fd, ['hiperlan2' chanMdl(3)]);
chanD = stdchan(1/fs10, fd, ['hiperlan2' chanMdl(4)]);
chanE = stdchan(1/fs10, fd, ['hiperlan2' chanMdl(5)]);

%% Simulation Parameters
snr10=[17.5 18.5 19.5 20.5];
enableFE = false;    % Disable front-end receiver components

%% Simulation Setup
maxNumErrors = 20;   % The maximum number of packet errors at an SNR point
maxNumPackets = 200; % Maximum number of packets at an SNR point

% Set random stream for repeatability of results
s = rng(98765);

%% Processing SNR Points
% Set up a figure for visualizing PER results
h = figure;
grid on;
hold on;
ax = gca;
ax.YScale = 'log';
xlim([17.5 20.5]);
ylim([1e-3 1]);
xlabel('SNR (dB)');
ylabel('PER');
h.NumberTitle = 'off';
title('MCS 4,Doppler 0 Hz');

% Simulation loop for both links 
perA = zeros(4,1); 
perB = zeros(4,1);
perC = zeros(4,1);
perD = zeros(4,1);
perE = zeros(4,1);
for i = 1:4    
    % MSC=4
       perA(i) = nonHTPERSimulator(cfgNHT10, chanA, snr10(i), ...
        maxNumErrors, maxNumPackets, enableFE);
       perB(i) = nonHTPERSimulator(cfgNHT10, chanB, snr10(i), ...
        maxNumErrors, maxNumPackets, enableFE);
       perC(i) = nonHTPERSimulator(cfgNHT10, chanC, snr10(i), ...
        maxNumErrors, maxNumPackets, enableFE);
       perD(i) = nonHTPERSimulator(cfgNHT10, chanD, snr10(i), ...
        maxNumErrors, maxNumPackets, enableFE);
       perE(i) = nonHTPERSimulator(cfgNHT10, chanE, snr10(i), ...
        maxNumErrors, maxNumPackets, enableFE);
   
    
    % Compare
    semilogy(snr10, perA, 'ro-');
    semilogy(snr10, perB, 'go-');
    semilogy(snr10, perC, 'bo-');
    semilogy(snr10, perD, 'co-');
    semilogy(snr10, perE, 'mo-');
    legend('A', 'B','C','D','E');
    drawnow;
end
hold off;

% Restore default stream
rng(s);

%displayEndOfDemoMessage(mfilename)