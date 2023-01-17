total = 2000;
input_Data = ones(1,total); %定义输出数据，我们假设其很长且所有元素都是1
%产生扰码初始的状态，全是1
scrambler = ones(1,2000);
save_scrambler_shift = zeros(1,127);
%扰码器产生与输入信号进行逻辑异或的扰码序列
for i = 1:1:127%对扰码按文档进行向左循环移位操作
    save_scrambler_shift(i) = mod((scrambler(7) + scrambler(4)),2);  %因为要取上一次的4和7，故应该在4和7赋值前完成此操作
	scrambler(7) = scrambler(6);  %开始循环移位，也就是这次的值等于上次前一位的值
	scrambler(6) = scrambler(5);
	scrambler(5) = scrambler(4);
	scrambler(4) = scrambler(3);
	scrambler(3) = scrambler(2);
	scrambler(2) = scrambler(1);
	scrambler(1) = save_scrambler_shift(i);
end
scrambled_finish= zeros(1,total);
descrambled_finish = zeros(1,total);
%接下来对我们的输出进行加扰
count_scr = 1; %定义记录加扰位置的变量
count_sc =1; %定义记录扰码位置的变量
count_descr = 1; %定义记录解扰位置的变量
count_desc = 1; %定义记录扰码位置的变量
count_zero = 0; %定义计数变量，记录加扰中全变为0的次数
for i= 1:1:2000 %我们在一个循环中进行加扰操作
    if count_sc == 128
        count_sc = 1;
    end
    scrambled_finish(1,count_scr) = mod((input_Data(1,count_scr) + save_scrambler_shift(1,count_sc)),2); %加扰，本质还是逻辑异或操作
    if scrambled_finish(1,count_scr) == 0 %统计下加扰的时候1变成0的次数，这个能反应我们加扰后数据的随机程度
        count_zero = count_zero+1;
    end
    count_scr = count_scr + 1;
    count_sc =  count_sc + 1;
end
prob = count_zero/total %计算了加扰过程中1变为0的总次数

%进行解扰操作
for j= 1:1:2000
    if count_desc == 128
        count_desc = 1;
    end
    descrambled_finish(1,count_descr) = mod((scrambled_finish(1,count_descr) + save_scrambler_shift(1,count_desc)),2);
    count_descr = count_descr + 1;
    count_desc =  count_desc + 1;
    
end

%绘制输入数据以及在扰码前后的数据对比
figure(1)
stem(input_Data)
title('Input Data')
xlabel('bit number')
grid on

figure(2)
stem(scrambled_finish)
xlabel('bit number')
title('After Scrambled')
grid on

figure(3)
stem(descrambled_finish)
xlabel('bit number')
title('After Decrambled')
grid on

