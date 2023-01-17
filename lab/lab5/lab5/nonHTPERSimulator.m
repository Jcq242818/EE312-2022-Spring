function packetErrorRate = nonHTPERSimulator(cfgNHT, chan, snr, ...
    maxNumErrors, maxNumPackets, enableFE)
%nonHTPERSimulator Featured example helper function
%
%   Simulates the Non-HT transmit-receive link over a fading channel.

%   Copyright 2015 The MathWorks, Inc.

% Waveform generation parameters
idleTime = 0;
numPkts = 1;
winTransTime = 0; % No windowing

fs = helperSampleRate(cfgNHT);     % Baseband sampling rate

% Indices for accessing each field within the time-domain packet
ind = wlanFieldIndices(cfgNHT);

% Get the number of occupied subcarriers and FFT length
[data,pilots] = helperSubcarrierIndices(cfgNHT, 'Legacy');
Nst = numel(data)+numel(pilots); % Number of occupied subcarriers
Nfft = helperFFTLength(cfgNHT);     % FFT length

% Create an instance of the AWGN channel per SNR point simulated
AWGN = comm.AWGNChannel;
AWGN.NoiseMethod = 'Signal to noise ratio (SNR)';
AWGN.SignalPower = 1;              % Unit power
AWGN.SNR = snr-10*log10(Nfft/Nst); % Account for energy in nulls

chDelay = 100; % arbitrary delay to account for all channel profiles

% Loop to simulate multiple packets
numPacketErrors = 0;
numPkt = 0; % Index of packet transmitted
while numPacketErrors<=maxNumErrors && numPkt<=maxNumPackets
    % Generate a packet waveform
    inpPSDU = randi([0 1], cfgNHT.PSDULength*8, 1); % PSDULength in bytes
    
    tx = wlanWaveformGenerator(inpPSDU,cfgNHT, 'IdleTime', idleTime,...
        'NumPackets', numPkts, 'WindowTransitionTime', winTransTime);
    
    % Add trailing zeros to allow for channel delay
    padTx = [tx; zeros(chDelay, 1)];
    
    % Pass through HiperLAN/2 fading channel model
    rx = filter(chan, padTx);
    reset(chan);    % Reset channel to create different realizations
    
    % Add noise
    rx = step(AWGN, rx);
    
    if enableFE
        % Packet detect
        pktStartIdx = helperPacketDetect(rx, cfgNHT.ChannelBandwidth);
        if isempty(pktStartIdx) % If empty no L-STF detected; packet error
            numPacketErrors = numPacketErrors+1;
            numPkt = numPkt+1;
            continue; % Go to next loop iteration
        end
        pktOffset = pktStartIdx-1; % Packet offset from start of waveform

        % Extract L-STF and perform coarse frequency offset correction
        lstf = rx(pktOffset+(ind.LSTF(1):ind.LSTF(2)),:);
        coarseFreqOff = wlanCoarseCFOEstimate(lstf, cfgNHT.ChannelBandwidth);
        rx = helperFrequencyOffset(rx, fs, -coarseFreqOff);

        % Extract the Non-HT fields and determine start of L-LTF
        nonhtfields = rx(pktOffset+(ind.LSTF(1):ind.LSIG(2)),:);
        lltfIdx = helperSymbolTiming(nonhtfields, cfgNHT.ChannelBandwidth);

        % Synchronize the received waveform given the offset between the
        % expected start of the L-LTF and actual start of L-LTF
        pktOffset = pktOffset+lltfIdx-double(ind.LLTF(1));
        % If no L-LTF detected or if packet detected outside the range of
        % expected delays from the channel modeling; packet error
        if isempty(lltfIdx) || pktOffset<0 || pktOffset>chDelay
            numPacketErrors = numPacketErrors+1;
            numPkt = numPkt+1;
            continue; % Go to next loop iteration
        end
        rx = rx(1+pktOffset:end,:);

        % Extract L-LTF and perform fine frequency offset correction
        lltf = rx(ind.LLTF(1):ind.LLTF(2),:);
        fineFreqOff = wlanFineCFOEstimate(lltf, cfgNHT.ChannelBandwidth);
        rx = helperFrequencyOffset(rx, fs, -fineFreqOff);
    else
        % Directly offset the simulated channel filter delay
        chDelay = chan.ChannelFilterDelay;
        rx = rx(chDelay+1:end,:);
    end
    
    % Extract L-LTF samples from the waveform, demodulate and perform
    % channel estimation
    lltf = rx(ind.LLTF(1):ind.LLTF(2),:);
    lltfDemod = wlanLLTFDemodulate(lltf, cfgNHT, 1);
    chanEst = wlanLLTFChannelEstimate(lltfDemod, cfgNHT);

    % Get estimate of the noise power from L-LTF
    nVar = helperNoiseEstimate(lltfDemod);
    
    % Extract Non-HT Data samples from the waveform and recover the PSDU
    nhtdata = rx(ind.NonHTData(1):ind.NonHTData(2),:);
    rxPSDU = wlanNonHTDataRecover(nhtdata, chanEst, nVar, cfgNHT);
    
    % Determine if any bits are in error, i.e. a packet error
    packetError = any(biterr(inpPSDU, rxPSDU));
    numPacketErrors = numPacketErrors+packetError;
    numPkt = numPkt+1;
end

% Calculate packet error rate (PER) at SNR point
packetErrorRate = numPacketErrors/numPkt;
disp(['CBW' cfgNHT.ChannelBandwidth(4:end) ', SNR ' num2str(snr) ...
    ' completed after ' num2str(numPkt) ' packets, PER: ' ...
    num2str(packetErrorRate)]);

end