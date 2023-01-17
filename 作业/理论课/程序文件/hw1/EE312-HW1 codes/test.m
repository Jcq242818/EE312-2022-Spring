STA = 10;  tx_same = 1000;
SIFS = 10; DIFS = 50; ACK = 44; aSlotTime = 20;  %定义与传输相关的时间量
DATA_length = 1000; %定义一个数据的传输持续时间
n = 2; % 定义CW与STA之间的比例关系，初始值为2
efficiency = zeros(1,STA); %定义平均传输效率，初始化为0    
count = zeros(50,STA);
for step_count = 1:50  %定义进行并行实验的次数
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
xlabel('STAs');   ylabel('Transmission efficiency'); title('传输效率与STA数目的关系图');
hold on
end








% %以下是代码的测试和绘图部分
% result = mean(count,1);
% figure(1)
% x = 1:STAs;
% plot(x,result,'linewidth',2)
% xlabel('STAs')
% ylabel('Transmission efficiency')
% title('平均传输效率与STA数目的关系图')

% %以下是代码的测试和绘图部分
% figure(2)
% x = 1:STAs;
% plot(x,efficiency,'linewidth',2)
% xlabel('STAs')
% ylabel('Transmission efficiency')
% title('传输效率与STA数目的关系图')
% grid on
figure(1)
x = 1:tx_same*STA+1;
plot(x,counter)
title('每次传输的时候STA之间发生冲突的次数')
xlabel('传输次数')
ylabel('发生冲突数目')
grid on