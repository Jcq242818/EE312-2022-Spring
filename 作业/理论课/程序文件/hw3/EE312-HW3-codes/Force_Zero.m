function ERROR=Force_Zero(SNR_dB)
SNR=10^(SNR_dB/10);
constant = [1+1j -1+1j -1-1j 1-1j]; %����QPSK�������飬���淢����������������ͻ�����������±����
No=1/(SNR);%�����Ĺ������ܶȣ������նν����źŵĹ�����Ϊ1
total=10000;   % randomly generate channel for at least 10000 times ��ĿҪ��
error_count=0;

for i=1:1:total
    s1=constant(randi(4));
    s2=constant(randi(4));
    s3=constant(randi(4));
    s4=constant(randi(4));
    s = [s1;s2;s3;s4];  %�����������
    %�˴������տμ����б�д����--4*2STBC���룬X,H,N,W��μ����Ӧ
    X = [s1 conj(s2); -conj(s2) s1; s3 conj(s4); -conj(s4) s3];
    H = (randn(2,4)+1j*randn(2,4));%���������˹�ŵ�
    W = sqrt(No/2)*(randn(2,2)+1j*randn(2,2)); %����������(��������)
    Y = H * X + W;
    %��ʼ��ʱ����
    %�˴���дҲ��μ�һ�£���Ӧ�˹������䷽�̺�Է����о���Ľ�һ������
    Y_trans = [Y(1,1); Y(2,1); Y(1,2); Y(2,2)];
    %�������õ�H����
    H_trans = [H(1,1) -H(1,2) H(1,3) -H(1,4);...
             H(2,1) -H(2,2) H(2,3) -H(2,4);...
             H(1,2) H(1,1) H(1,4) H(1,3);...
             H(2,2) H(2,1) H(2,4) H(2,3)];
    %process = inv(calcH) * calcR;
    process = H_trans \ Y_trans; %������ʵ�������ȡ�������ı�ֻ������д������Ĵ���MATLAB��ʾ������д���ܸ���
    process = [process(1,1); conj(process(2,1)); process(3,1); conj(process(4,1))];
    %�����������󼴿ɽ���������о����ڣ�QPSK�ĸ����޵��о��������Ǻ������ܵó�����
    for j = 1:4
        if real(process(j))>0 && imag(process(j))>0
            process(j)=constant(1);
        elseif real(process(j))<0 && imag(process(j))>0
            process(j)=constant(2);
        elseif real(process(j))<0 && imag(process(j))<0
            process(j)=constant(3);
        elseif real(process(j))>0 && imag(process(j))<0
            process(j)=constant(4);
        end
       %������ͳ�ƻ��ڣ�ͳ���ڵ�ǰѭ�����Ƿ��������������������1
        if process(j) ~= s(j) %ֻҪ��һ�����߹��ƵĲ��ԣ��ͳ�����
            error_count = error_count + 1;
            break
        end
    end
end
ERROR = error_count/total;





