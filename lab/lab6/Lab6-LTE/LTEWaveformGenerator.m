function [eNodeBOutput,txGrid,rmc] = LTEWaveformGenerator(rmc,txsim,trData)
rmc.NCellID = txsim.NCellID;
rmc.NFrame = txsim.NFrame;
rmc.TotSubframes = txsim.TotFrames*10;
rmc.CellRefP = txsim.NTxAnts;
rmc.PDSCH.RVSeq = 0;

rmc.OCNGPDSCHEnable = 'On';
rmc.OCNGPDCCHEnable = 'On';

fprintf('\nGenerating LTE transmit waveform:\n')
fprintf('Packing image data into %d frame(s). \n\n',txsim.TotFrames);

[eNodeBOutput,txGrid,rmc] = lteRMCDLTool(rmc,trData);
end
    