function runSDRuQPSKTransmitterR(prmQPSKTransmitter)
% Initialize the components
 % Create and configure the transmitter System object
 hTx = QPSKTransmitterR(...
 'UpsamplingFactor', prmQPSKTransmitter.Upsampling, ...
 'MessageLength', prmQPSKTransmitter.MessageLength, ...
 'TransmitterFilterCoefficients',prmQPSKTransmitter.TransmitterFilterCoefficients, ...
 'DataLength', prmQPSKTransmitter.DataLength, ...
 'ScramblerBase', prmQPSKTransmitter.ScramblerBase, ...
 'ScramblerPolynomial', prmQPSKTransmitter.ScramblerPolynomial, ...
 'ScramblerInitialConditions', prmQPSKTransmitter.ScramblerInitialConditions);
 
 % Create and configure the SDRu
 
 
 ThSDRu = comm.SDRuTransmitter('192.168.10.2', ...
 'CenterFrequency', prmQPSKTransmitter.USRPCenterFrequency, ...
 'Gain', prmQPSKTransmitter.USRPGain, ...
 'InterpolationFactor', prmQPSKTransmitter.USRPInterpolation);
currentTime = 0;
%Transmission Process
while currentTime < prmQPSKTransmitter.StopTime
 % Bit generation, modulation and transmission filtering
 data = step(hTx);
 % Data transmission
 step(ThSDRu, data);
 % Update simulation time
 currentTime=currentTime+prmQPSKTransmitter.FrameTime;
end
release(hTx);
release(ThSDRu);