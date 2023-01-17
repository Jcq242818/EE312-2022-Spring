function [txData, psduData, numMSDUs, lengthMPDU]=createPSDU(txImage,MPDU_Param)
msduLength = 4048;% (1) 设置MSDU字节数（无需改动）
msduBits= msduLength*8;%（2）计算MSDU比特数（导出参数）
numMSDUs=ceil(length(txImage)/msduBits);%（3）计算所需的MSDU数目（导出参数）
padZeros = msduBits - mod(length(txImage),msduBits);%（4）最后不够一个MSDU的比特流，补0凑成一个MSDU（导出参数）
txData = [txImage; zeros(padZeros,1)];%（5）需要发射数据
%（6）设置校验参数FCS （Frame Check Sequence，帧检验序列）
generatorPolynomial = MPDU_Param.generatorPolynomial;
fcsGen = comm.CRCGenerator(generatorPolynomial); %除数
fcsGen.InitialConditions = 1;
fcsGen.DirectMethod = true;
fcsGen.FinalXOR = 1;
%（7）将数据分块
numFragment = 0;
%（8）MPDU头部所需的比特数
lengthMACheader = MPDU_Param.lengthMACheader; % MPDU header length in bits
%（9）FCS所需的比特数
lengthFCS = MPDU_Param.lengthFCS;% FCS length in bits
%（10）MPDU长度等于MAC头长度+MSDU比特+帧校验位 一个MPDU的长度，增加了头部和帧校验位
lengthMPDU = lengthMACheader+msduBits+lengthFCS; % MPDU length in bits
%（11）数据初始化
psduData = zeros(lengthMPDU*numMSDUs,1);
%用循环将图像按照MPDU的格式构建
%（12）形成MSDU数据包
for ind=0:numMSDUs-1

%获取MSDU比特，创建一个MPDU帧的数据区
frameBody = txData(ind*msduBits+1:msduBits*(ind+1),:);
%创建MPDU头部 WLAN
mpduHeader = helperNonHTMACHeader(mod(numFragment, 16),mod(ind,4096));

%创建携带MAC头，帧体和FCS的MPDU数据
psdu = step(fcsGen,[mpduHeader;frameBody]);
%创建PSDU数据包
psduData(lengthMPDU*ind+1:lengthMPDU*(ind+1)) = psdu;

end