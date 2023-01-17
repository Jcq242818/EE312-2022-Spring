%% Waveform Configuration
mcs = [0 2 4 6];                % QPSK rate 1/2
psduLen = 32672/8;         % PSDU length in bytes

% Create a format configuration object for a 802.11p transmission
cfgNHT10 = wlanNonHTConfig;
cfgNHT10.ChannelBandwidth = 'CBW20';    % 10 MHz channel bandwidth
cfgNHT10.PSDULength = psduLen;          
cfgNHT10.MCS = mcs(1);                     

% Create a format configuration object for a 802.11a transmission
cfgNHT20 = wlanNonHTConfig;
cfgNHT20.ChannelBandwidth = 'CBW20';    % 10 MHz channel bandwidth
cfgNHT20.PSDULength = psduLen;          
cfgNHT20.MCS = mcs(2);                     

cfgNHT30 = wlanNonHTConfig;
cfgNHT30.ChannelBandwidth = 'CBW20';    % 10 MHz channel bandwidth
cfgNHT30.PSDULength = psduLen;          
cfgNHT30.MCS = mcs(3);   

cfgNHT40 = wlanNonHTConfig;
cfgNHT40.ChannelBandwidth = 'CBW20';    % 10 MHz channel bandwidth
cfgNHT40.PSDULength = psduLen;          
cfgNHT40.MCS = mcs(4);   

%% Channel Configuration
% Create and configure the channel
chanMdl = 'A';
fd = 0;                            % Maximum Doppler shift, Hz
c = 3e8*3.6;                        % Speed of light, Km/hr
fc = 5.9e9;                         % Carrier frequency, Hz

fs40 = helperSampleRate(cfgNHT40);     % MSC=6
chan40 = stdchan(1/fs40, fd, ['hiperlan2' chanMdl]);

fs30 = helperSampleRate(cfgNHT30);     % MSC=4
chan30 = stdchan(1/fs30, fd, ['hiperlan2' chanMdl]);

fs20 = helperSampleRate(cfgNHT20);     % MSC=2
chan20 = stdchan(1/fs20, fd, ['hiperlan2' chanMdl]);

fs10 = helperSampleRate(cfgNHT10);     % MSC=0
chan10 = stdchan(1/fs10, fd, ['hiperlan2' chanMdl]);


%% Simulation Parameters
snr10=[9 10 11 12];
snr20=[12 13 14 15];
snr30=[17.5 18.5 19.5 20.5];
snr40=[25 26 27 28];
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
xlim([5 30]);
ylim([1e-2 1]);
xlabel('SNR (dB)');
ylabel('PER');
h.NumberTitle = 'off';
title(['HIPERLAN/2 Model  ' chanMdl ', Doppler ' num2str(fd) ' Hz']);

% Simulation loop for both links
per40 = zeros(4,1); 
per30 = zeros(4,1); 
per20 = zeros(4,1); 
per10 = zeros(4,1); 

for i = 1:4     
    % MSC=0
    per10(i) = nonHTPERSimulator(cfgNHT10, chan10, snr10(i), ...
        maxNumErrors, maxNumPackets, enableFE);

    % MSC=2
    per20(i) = nonHTPERSimulator(cfgNHT20, chan20, snr20(i), ...
        maxNumErrors, maxNumPackets, enableFE);

    % MSC=4
    per30(i) = nonHTPERSimulator(cfgNHT30, chan30, snr30(i), ...
        maxNumErrors, maxNumPackets, enableFE);
    
    % MSC=6
    per40(i) = nonHTPERSimulator(cfgNHT40, chan40, snr40(i), ...
        maxNumErrors, maxNumPackets, enableFE);
    
    % Compare
    semilogy(snr10, per10, 'ro-');
    semilogy(snr20, per20, 'go-');
    semilogy(snr30, per30, 'bo-');
    semilogy(snr40, per40, 'co-');
    legend('MSC=0', 'MSC=2','MSC=4','MSC=6');
    drawnow;
end
hold off;

% Restore default stream
rng(s);

%displayEndOfDemoMessage(mfilename)