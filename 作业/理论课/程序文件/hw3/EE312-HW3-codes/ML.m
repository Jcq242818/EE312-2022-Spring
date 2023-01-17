function ERROR=ML(SNR_dB)
SNR=10^(SNR_dB/10);
constant = [1+1j -1+1j -1-1j 1-1j]; %定义QPSK常量数组，后面发生波束产生随机数就基于这个数组下标产生
No=1/(SNR);%噪声的功率谱密度，将接收段接收信号的功率设为1
total=10000;  % randomly generate channel for at least 10000 times 题目要求
error_count=0;

for i=1:1:total
    s1=constant(randi(4));
    s2=constant(randi(4));
    s3=constant(randi(4));
    s4=constant(randi(4));
    s = [s1;s2;s3;s4];  %待传输的数据
    %此处将仿照课件进行编写程序--4*2STBC编码，X,H,N,W与课件相对应
    X = [s1 conj(s2); -conj(s2) s1; s3 conj(s4); -conj(s4) s3];  
    H = (randn(2,4)+1j*randn(2,4)); %随机产生高斯信道
    W = sqrt(No/2)*(randn(2,2)+1j*randn(2,2));   %产生的噪声(能量开方)
    Y = H * X + W;
    %开始空时解码
    %此处编写也与课件一致，反应了构建传输方程后对方程中矩阵的进一步处理
    Y_trans = [Y(1,1); Y(2,1); Y(1,2); Y(2,2)];
    %解码所用的H矩阵
    H_trans = [H(1,1) -H(1,2) H(1,3) -H(1,4);...
             H(2,1) -H(2,2) H(2,3) -H(2,4);...
             H(1,2) H(1,1) H(1,4) H(1,3);...
             H(2,2) H(2,1) H(2,4) H(2,3)];
         
   %因为要一个个的试，总共256种情况，因此采用多重嵌套for循环最为简单
    error_min = inf; %定义交换变量，因为要取的是最小值，因此一开始把交换变量设置成无穷大
    for i = 1:4
       for j = 1:4
          for k = 1:4
             for l = 1:4
             ERROR = sqrt(norm(Y_trans - H_trans * [constant(i); conj(constant(j));constant(k); conj(constant(l))]));
             if ERROR < error_min
                error_min = ERROR;
                %最小值出来之后赶紧保存当前循环出现的最小值对应的四根天线对应的QPSK映射值
                match = [constant(i); constant(j); constant(k); constant(l)];
             end
             end
          end
       end
    end
   %最后进入统计环节，统计在当前循环中是否出错，如出错则计数变量加1 
   %找出最小值对应的s后，对得到的s与原先实际传输的数据进行比较，进而统计出检测出错的概率
    for j = 1:4
        if match(j) ~= s(j) %只要有一个天线估计的不对，就出错了
            error_count = error_count + 1;
            break
        end
    end
end
ERROR = error_count/total;





