%%
function reBuildImage(rxBit,offsetLLTF,pktOffset,packetSeq,numMSDUs,MPDU_Param,txData,lengthTxImage,imsize)
%%

if ~(isempty(offsetLLTF)||isempty(pktOffset))&&(numMSDUs==(numel(packetSeq)-1));
    rxBitMatrix = cell2mat(rxBit); 
    rxData = rxBitMatrix(MPDU_Param.lengthMACheader+1:end,1:numel(packetSeq)-1);
 
    startSeq = find(packetSeq==0);
    rxData = circshift(rxData,[0 -(startSeq(1)-1)]);% Order MAC fragments

%（1）计算误码率
    % Perform bit error rate (BER) calculation
    hBER = comm.ErrorRate;
    err = step(hBER,double(rxData(:)),txData(1:length(reshape(rxData,[],1))));
    fprintf('  \nBit Error Rate (BER):\n');
    fprintf('          Bit Error Rate (BER) = %0.5f.\n',err(1));
    fprintf('          Number of bit errors = %d.\n', err(2));
    fprintf('    Number of transmitted bits = %d.\n\n',lengthTxImage);

%（2）重构图像
    fprintf('\nConstructing image from received data.\n');
    
    str = reshape(sprintf('%d',rxData(1:lengthTxImage)),8,[]).';
    decdata = uint8(bin2dec(str));
    receivedImage = reshape(decdata,imsize);

%（3）图像显示
    figure(1); subplot(212); 
    imshow(receivedImage);
    title(sprintf('Received Image'));
end