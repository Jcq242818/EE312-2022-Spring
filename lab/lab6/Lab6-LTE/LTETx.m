clc
clear
%% Transmitter Design: System Architecture
%DL-SCH ������·����
txsim.RC = 'R.7';       % Base RMC configuration, 10 MHz bandwidth
txsim.NCellID = 88;     % Cell identity
txsim.NFrame = 700;     % Initial frame number
txsim.TotFrames = 1;    % Number of frames to generate
txsim.DesiredCenterFrequency = 2.2e9; % Center frequency in Hz
txsim.NTxAnts = 1;      % Number of transmit antennas

%%
% *Prepare Image File ͼ��->������

fileTx = 'peppers.png';            % Image file name
fData = imread(fileTx);            % Read image data from file
scale = 0.3;                       % Image scaling factor
origSize = size(fData);            % Original input image size
scaledSize = max(floor(scale.*origSize(1:2)),1); % Calculate new image size
heightIx = min(round(((1:scaledSize(1))-0.5)./scale+0.5),origSize(1));
widthIx = min(round(((1:scaledSize(2))-0.5)./scale+0.5),origSize(2));
fData = fData(heightIx,widthIx,:); % Resize image
imsize = size(fData);              % Store new image size
binData = dec2bin(fData(:),8);     % Convert to 8 bit unsigned binary
trData = reshape((binData-'0').',1,[]).'; % Create binary stream

%%
% Plot transmit image
figure(1);
 imFig.Visible = 'on';
subplot(211); 
    imshow(fData);
    title('Transmitted Image');
subplot(212);
    title('Received image will appear here...');
    set(gca,'Visible','off'); % Hide axes
    set(findall(gca, 'type', 'text'), 'visible', 'on'); % Unhide title

pause(1); % Pause to plot Tx image
    
%%
% *Generate Baseband LTE Signal*

rmc = lteRMCDL(txsim.RC);

% Calculate the required number of LTE frames based on the size of the
% image data��������Ҫ���ٸ�LTE֡��
trBlkSize = rmc.PDSCH.TrBlkSizes;
txsim.TotFrames = ceil(numel(trData)/sum(trBlkSize(:)));

% Customize RMC parameters
rmc.NCellID = txsim.NCellID;
rmc.NFrame = txsim.NFrame;
rmc.TotSubframes = txsim.TotFrames*10; % 10 subframes per frame
rmc.CellRefP = txsim.NTxAnts; % Configure number of cell reference ports
rmc.PDSCH.RVSeq = 0;

% Fill subframe 5 with dummy data
rmc.OCNGPDSCHEnable = 'On';
rmc.OCNGPDCCHEnable = 'On';

fprintf('\nGenerating LTE transmit waveform:\n')
fprintf('  Packing image data into %d frame(s).\n\n', txsim.TotFrames);

% Pack the image data into a single LTE frame
[eNodeBOutput,txGrid,rmc] = lteRMCDLTool(rmc,trData);

txWaveform = eNodeBOutput;
powerScaleFactor = 0.8;
txWaveform = txWaveform.*(1/max(abs(txWaveform))*powerScaleFactor);

size(txWaveform)

%2. ����USRP��eNodeBOutput�źŲ��η����ȥ��3С����ʵ�֣�
%(1)����USRP������
prmQPSKTransmitter.USRPCenterFrequency = 900e6;
prmQPSKTransmitter.USRPGain = 25;
prmQPSKTransmitter.RxBufferedFrames=1;
prmQPSKTransmitter.Fs = 5e6; % IQ ���ʣ�
prmQPSKTransmitter.USRPInterpolation = 100e6/prmQPSKTransmitter.Fs; 
prmQPSKTransmitter.FrameSize=length(txWaveform);
prmQPSKTransmitter.USRPFrameLength = ...
    prmQPSKTransmitter.FrameSize*prmQPSKTransmitter.RxBufferedFrames;

%Simulation Parameters
prmQPSKTransmitter.FrameTime = ...
    prmQPSKTransmitter.USRPFrameLength/prmQPSKTransmitter.Fs;
prmQPSKTransmitter.StopTime = 1000;

%��2������USRP���������
    ThSDRu = comm.SDRuTransmitter('192.168.10.2', ...
        'CenterFrequency',        prmQPSKTransmitter.USRPCenterFrequency, ...
        'Gain',                   prmQPSKTransmitter.USRPGain, ...
        'InterpolationFactor',    prmQPSKTransmitter.USRPInterpolation);

%��3��ѭ������
currentTime=0;
while currentTime < prmQPSKTransmitter.StopTime
    % Data transmission
    step(ThSDRu, txWaveform);
        
    % Update simulation time
    currentTime=currentTime+prmQPSKTransmitter.FrameTime
    
end

release(ThSDRu);

