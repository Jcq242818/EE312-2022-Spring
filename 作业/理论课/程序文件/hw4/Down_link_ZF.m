total = 10000; % total是总的测试次数：randomly generate more than 1000 channel matrices 题目要求
SNR = zeros(total,4);   %因为发射机到接收机总共通过我们的预编码可以等效为4条平行信道，因此我们需要记录每一个信道的信噪比分布 
No=0.5;   %噪声的功率谱密度，我们在不知道P矩阵之前先姑且将其假设为0.5
constant = [1+1j -1+1j -1-1j 1-1j]; %定义QPSK常量数组，后面发生波束产生随机数就基于这个数组下标产生
for i = 1:1:total  %每进行外部循环相当于进行了一次传输
    s1= constant(randi(4));
    s2= constant(randi(4));
    s3= constant(randi(4));
    s4= constant(randi(4));  
    s = [s1;s2;s3;s4];  %待传输的四个随机数据
    %创建信道矩阵
    H1=  (randn(1,4)+1j*randn(1,4));
    H2=  (randn(1,4)+1j*randn(1,4));
    H3=  (randn(1,4)+1j*randn(1,4));
    H4=  (randn(1,4)+1j*randn(1,4));
    
    H_all = [H1; H2; H3; H4;];  %总传输矩阵
    
    Z = sqrt(No/2)*(randn(4,1)+1j*randn(4,1)); %噪声矩阵
    
    %现在开始由H矩阵反推P矩阵，得到预编码矩阵P1-P4
    %首先得到P1-P4解码的零空间基向量
    NULL_1 = null([H2;H3;H4]);
    NULL_2 = null([H1;H3;H4]);
    NULL_3 = null([H1;H2;H4]);
    NULL_4 = null([H1;H2;H3]);
    %之后得到投影后的P向量
    P1_re = ((H1*NULL_1)*NULL_1);
    P2_re = ((H2*NULL_2)*NULL_2);
    P3_re = ((H3*NULL_3)*NULL_3);
    P4_re = ((H4*NULL_4)*NULL_4);
    P = [P1_re P2_re P3_re P4_re];
    
    %计算信噪比
    % calculate SNR，因为信道是并行的，我们只需要把每一个信道的信息单独抽出来进行计算就行了
    Signal = H_all * P * s; %得到从信噪出来的信号的表达式
    SNR(i,1) = (abs(Signal(1,1)))^2 ./ (abs(Z(1,1)))^2;  %本次传输中信道1的信噪比
    SNR(i,2) = (abs(Signal(2,1)))^2 ./ (abs(Z(2,1)))^2;  %本次传输中信道2的信噪比
    SNR(i,3) = (abs(Signal(3,1)))^2 ./ (abs(Z(3,1)))^2;  %本次传输中信道3的信噪比
    SNR(i,4) = (abs(Signal(4,1)))^2 ./ (abs(Z(4,1)))^2;  %本次传输中信道4的信噪比
end

SNR_channel1 = SNR(:,1);  %第一列都是信道1的信噪比
SNR_channel2 = SNR(:,2); %第二列都是信道2的信噪比
SNR_channel3 = SNR(:,3); %第三列都是信道3的信噪比
SNR_channel4 = SNR(:,4); %第四列都是信道4的信噪比

%将真实的SNR值转化为dB值
SNR_channel1 =10*log10(SNR_channel1);
SNR_channel2 =10*log10(SNR_channel2);
SNR_channel3 =10*log10(SNR_channel3);
SNR_channel4 =10*log10(SNR_channel4);


