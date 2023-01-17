clc
clear
%% Transmitter Design: System Architecture
%DL-SCH 下行链路仿真
txsim.RC = 'R.7';       % Base RMC configuration, 10 MHz bandwidth
txsim.NCellID = 88;     % Cell identity
txsim.NFrame = 700;     % Initial frame number
txsim.TotFrames = 1;    % Number of frames to generate
txsim.DesiredCenterFrequency = 2.2e9; % Center frequency in Hz
txsim.NTxAnts = 1;      % Number of transmit antennas

%%
% *Prepare Image File 图像->比特流

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
% image data，计算需要多少个LTE帧。
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

%2. 利用USRP将eNodeBOutput信号波形发射出去；3小步来实现：
%(1)设置USRP参数；
prmQPSKTransmitter.USRPCenterFrequency = 900e6;
prmQPSKTransmitter.USRPGain = 25;
prmQPSKTransmitter.RxBufferedFrames=1;
prmQPSKTransmitter.Fs = 5e6; % IQ 速率；
prmQPSKTransmitter.USRPInterpolation = 100e6/prmQPSKTransmitter.Fs; 
prmQPSKTransmitter.FrameSize=length(txWaveform);
prmQPSKTransmitter.USRPFrameLength = ...
    prmQPSKTransmitter.FrameSize*prmQPSKTransmitter.RxBufferedFrames;

%Simulation Parameters
prmQPSKTransmitter.FrameTime = ...
    prmQPSKTransmitter.USRPFrameLength/prmQPSKTransmitter.Fs;
prmQPSKTransmitter.StopTime = 1000;

%（2）构造USRP发射机对象
    ThSDRu = comm.SDRuTransmitter('192.168.10.2', ...
        'CenterFrequency',        prmQPSKTransmitter.USRPCenterFrequency, ...
        'Gain',                   prmQPSKTransmitter.USRPGain, ...
        'InterpolationFactor',    prmQPSKTransmitter.USRPInterpolation);

%（3）循环发送
currentTime=0;
while currentTime < prmQPSKTransmitter.StopTime
    % Data transmission
    step(ThSDRu, txWaveform);
        
    % Update simulation time
    currentTime=currentTime+prmQPSKTransmitter.FrameTime
    
end

release(ThSDRu);

