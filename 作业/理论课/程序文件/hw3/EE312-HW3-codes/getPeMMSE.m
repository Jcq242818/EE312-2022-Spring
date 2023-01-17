function Pe=getPeMMSE(SNR_dB)
SNR=10^(SNR_dB/10);
Cons = [1+1j -1+1j -1-1j 1-1j];
No=1/(SNR);%高斯白噪声的功率谱密度，将接收段接收信号的功率设为1
sigmaz = No; 
sigma = 2;
Frame=100;
ErrorNum=0;

for i=1:1:Frame
    s1=Cons(randi(4));
    s2=Cons(randi(4));
    s3=Cons(randi(4));
    s4=Cons(randi(4));
    s = [s1;s2;s3;s4];
    %-----------------------------------------------进行空时编码
    S = [s1 conj(s2); -conj(s2) s1; s3 conj(s4); -conj(s4) s3];
    
    %-----------------------------------------------准备信道
    H = sqrt(1/4)*(randn(2,4)+1j*randn(2,4));
    
    N = sqrt(No/2)*(randn(2,2)+1j*randn(2,2)); %接收端的噪声
    
    R = H * S + N; %封装
    %-----------------------------------------------进行空时解码
    calcR = [R(1,1); R(2,1); R(1,2); R(2,2)];
    %解码所用的H矩阵
    calcH = [H(1,1) -H(1,2) H(1,3) -H(1,4);...
             H(2,1) -H(2,2) H(2,3) -H(2,4);...
             H(1,2) H(1,1) H(1,4) H(1,3);...
             H(2,2) H(2,1) H(2,4) H(2,3)];

    %创建convex model使用cvx求解Q
    
    cvx_begin quiet
        variable Q(4,4) complex
        %min(trace((Q*calcH - eye(4))*(Q*calcH - eye(4))'))
        minimize (sigma*square_pos(norm(Q*calcH - eye(4),'fro'))...
        + sigmaz*square_pos(norm(Q,'fro')))    
    cvx_end
    
    %解算S
    recS = Q*calcR;
    recS = [recS(1,1); conj(recS(2,1)); recS(3,1); conj(recS(4,1))];
    
    %-----------------------------------------------判决域
    Snorm = recS;
    for j = 1:4
        if real(recS(j))>0 && imag(recS(j))>0
            Snorm(j)=Cons(1);
        elseif real(recS(j))>0 && imag(recS(j))<0
            Snorm(j)=Cons(4);
        elseif real(recS(j))<0 && imag(recS(j))>0
            Snorm(j)=Cons(2);
        else
            Snorm(j)=Cons(3);
        end
    

        if s(j) ~= Snorm(j) %一组s只要有一个fail,记作一次error
            ErrorNum = ErrorNum + 1;
            break
        end
    end
end
Pe = ErrorNum/Frame;





