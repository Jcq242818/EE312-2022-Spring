load('DopplerFre_100000_80_60_2_60_sin_n.mat');
load('RangeAll_100000_80_60_2_60_sin_n.mat');


f = 2.12e9;                                        % frequency
c = 2.997e8;                                       % speed 

deg = 27;       %���ݵĽǶ�ɨ����� -60��2��60��һ��61�����ݣ��������м���ӳ���ϵ�����磺31����Ŷ�Ӧ0�ȸ���

speed = DopplerFre(deg,:)*c/f/2;
range = RangeAll(deg,:);
t = 0:20;
t = t/21/2;

figure(1)

subplot(211)

plot(t,speed)
title("Speed Time")
xlabel('Time/s')
ylabel('Speed/mps')
grid on

subplot(212)

plot(t,range)
title("Range Time")
xlabel('Time/s')
ylabel('Range/m')
grid on