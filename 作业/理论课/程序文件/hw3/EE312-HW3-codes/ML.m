function ERROR=ML(SNR_dB)
SNR=10^(SNR_dB/10);
constant = [1+1j -1+1j -1-1j 1-1j]; %����QPSK�������飬���淢����������������ͻ�����������±����
No=1/(SNR);%�����Ĺ������ܶȣ������նν����źŵĹ�����Ϊ1
total=10000;  % randomly generate channel for at least 10000 times ��ĿҪ��
error_count=0;

for i=1:1:total
    s1=constant(randi(4));
    s2=constant(randi(4));
    s3=constant(randi(4));
    s4=constant(randi(4));
    s = [s1;s2;s3;s4];  %�����������
    %�˴������տμ����б�д����--4*2STBC���룬X,H,N,W��μ����Ӧ
    X = [s1 conj(s2); -conj(s2) s1; s3 conj(s4); -conj(s4) s3];  
    H = (randn(2,4)+1j*randn(2,4)); %���������˹�ŵ�
    W = sqrt(No/2)*(randn(2,2)+1j*randn(2,2));   %����������(��������)
    Y = H * X + W;
    %��ʼ��ʱ����
    %�˴���дҲ��μ�һ�£���Ӧ�˹������䷽�̺�Է����о���Ľ�һ������
    Y_trans = [Y(1,1); Y(2,1); Y(1,2); Y(2,2)];
    %�������õ�H����
    H_trans = [H(1,1) -H(1,2) H(1,3) -H(1,4);...
             H(2,1) -H(2,2) H(2,3) -H(2,4);...
             H(1,2) H(1,1) H(1,4) H(1,3);...
             H(2,2) H(2,1) H(2,4) H(2,3)];
         
   %��ΪҪһ�������ԣ��ܹ�256���������˲��ö���Ƕ��forѭ����Ϊ��
    error_min = inf; %���彻����������ΪҪȡ������Сֵ�����һ��ʼ�ѽ����������ó������
    for i = 1:4
       for j = 1:4
          for k = 1:4
             for l = 1:4
             ERROR = sqrt(norm(Y_trans - H_trans * [constant(i); conj(constant(j));constant(k); conj(constant(l))]));
             if ERROR < error_min
                error_min = ERROR;
                %��Сֵ����֮��Ͻ����浱ǰѭ�����ֵ���Сֵ��Ӧ���ĸ����߶�Ӧ��QPSKӳ��ֵ
                match = [constant(i); constant(j); constant(k); constant(l)];
             end
             end
          end
       end
    end
   %������ͳ�ƻ��ڣ�ͳ���ڵ�ǰѭ�����Ƿ��������������������1 
   %�ҳ���Сֵ��Ӧ��s�󣬶Եõ���s��ԭ��ʵ�ʴ�������ݽ��бȽϣ�����ͳ�Ƴ�������ĸ���
    for j = 1:4
        if match(j) ~= s(j) %ֻҪ��һ�����߹��ƵĲ��ԣ��ͳ�����
            error_count = error_count + 1;
            break
        end
    end
end
ERROR = error_count/total;





