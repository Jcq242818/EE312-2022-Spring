total = 2000;
input = ones(total,1);
scr_initial = [1;1;1;1;1;1;1];
scrambled = wlanScramble(input,scr_initial);
descrambled = wlanScramble(scrambled,scr_initial);
count = 0;
for i =1:1:2000
    if scrambled(i) == 0
        count = count + 1;
    end
end
prob = count/total
%绘制数据部分
figure(1)
stem(1:2000,input);
title('inputdata');
xlabel('bit number');
grid on
figure(2)
stem(1:2000,scrambled);
title('After Scrambled');
xlabel('bit number');
grid on
figure(3)
stem(1:2000,descrambled);
title('After Decrambled');
xlabel('bit number');
grid on
