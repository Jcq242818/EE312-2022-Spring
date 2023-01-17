STA = 10;  tx_same = 1000;
SIFS = 10; DIFS = 50; ACK = 44; aSlotTime = 20;  %�����봫����ص�ʱ����
DATA_length = 1000; %����һ�����ݵĴ������ʱ��
n = 2; % ����CW��STA֮��ı�����ϵ����ʼֵΪ2
efficiency = zeros(1,STA); %����ƽ������Ч�ʣ���ʼ��Ϊ0    
count = zeros(50,STA);
for step_count = 1:50  %������в���ʵ��Ĵ���
for i=1:STA       
[Process,counter] = get_trans(i,n,tx_same);
min_sum=Process';
total=sum(min(min_sum));  
efficiency(1,i) = (tx_same*STA*(DATA_length+ACK))/(STA*tx_same*(DATA_length+SIFS+DIFS)+total*aSlotTime);
end
count(step_count,:)= efficiency;
figure(1)
x = 1:STA;
plot(x,efficiency)
xlabel('STAs');   ylabel('Transmission efficiency'); title('����Ч����STA��Ŀ�Ĺ�ϵͼ');
hold on
end








% %�����Ǵ���Ĳ��Ժͻ�ͼ����
% result = mean(count,1);
% figure(1)
% x = 1:STAs;
% plot(x,result,'linewidth',2)
% xlabel('STAs')
% ylabel('Transmission efficiency')
% title('ƽ������Ч����STA��Ŀ�Ĺ�ϵͼ')

% %�����Ǵ���Ĳ��Ժͻ�ͼ����
% figure(2)
% x = 1:STAs;
% plot(x,efficiency,'linewidth',2)
% xlabel('STAs')
% ylabel('Transmission efficiency')
% title('����Ч����STA��Ŀ�Ĺ�ϵͼ')
% grid on
figure(1)
x = 1:tx_same*STA+1;
plot(x,counter)
title('ÿ�δ����ʱ��STA֮�䷢����ͻ�Ĵ���')
xlabel('�������')
ylabel('������ͻ��Ŀ')
grid on