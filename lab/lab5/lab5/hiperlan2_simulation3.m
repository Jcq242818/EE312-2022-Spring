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
chanMdl = 'A';
fd = [0 50 100 150 200 250 300 350 400 450 500];                            % Maximum Doppler shift, Hz
c = 3e8*3.6;                        % Speed of light, Km/hr
fc = 5.9e9;                         % Carrier frequency, Hz

fs10 = helperSampleRate(cfgNHT10);     % MSC=4
% chan = stdchan(1/fs10, fd(i), ['hiperlan2' chanMdl]);


%% Simulation Parameters
snr=20;
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
xlim([0 500]);
ylim([1e-3 1]);
xlabel('fd(Hz)');
ylabel('PER');
h.NumberTitle = 'off';
title('MCS=4,Model A,SNR=20');

% Simulation loop for both links 
per = zeros(11,1); 

for i = 1:11    
    % MSC=4
       chan = stdchan(1/fs10, fd(i), ['hiperlan2' chanMdl]);
       per(i) = nonHTPERSimulator(cfgNHT10, chan, snr, ...
        maxNumErrors, maxNumPackets, enableFE);
    % Compare
    semilogy(fd, per, 'ro-');
    drawnow;
end
hold off;

% Restore default stream
rng(s);

%displayEndOfDemoMessage(mfilename)