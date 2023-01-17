function [Process,counter] = get_trans(STA,n,tx_same)
CW = zeros(1,STA);
CW(1,:) = n * STA +1; %注意我们这里n为2

% 新建一个传输矩阵，首行是每个STAs剩余传输次数，之后的每一行代表每一次传输过程中每个STA对应生成的随机数
Process = zeros(tx_same*STA+1,STA);
Process(1,:) = tx_same;
save = CW;
counter = zeros(tx_same*STA+1,1); %记录传输失败的次数
min_index = 1;   % min_index代表输入的最小随机数的索引，首次传输先默认为1
initial = 2;  % 第一次传输时Process矩阵是从第二行开始写入的，因此这里的row为2
st_finish = zeros(1,STA); %记录传输完成的STA索引
% double = zeros(tx_same*STAs+1,1);  %记录了每一次传输的时候有没有发生过冲突，以便下一次传输产生随机数的时候要考虑是否需要加倍
count = 1;
while(1)
    % min_index代表输入的最小随机数的索引，st_finish是传输完成的STA索引
    [save,fail_count] = Generate_random(save,min_index,st_finish,n);
    Process(initial,:) = save;
    counter(initial,:) = fail_count;
    %查找最小随机数的索引并减去对应的STA的剩余传输数量
    [~, min_index] = min(save);
    Process(1,min_index) = Process(1,min_index) -1;
    %遍历所有STA，检查全部传输完成的STA，并将其索引添加到st_finish中
    for i = 1:STA
        if Process(1,i)==0
            st_finish(i)=i;
        end
    end
    
    %直到所有数据传输完成，则该次实验完成，跳出整个循环
    if sum(Process(1,:))==0
        break
    end
    %输入行数加一
    initial = initial+1;
    count = count+1; %记录已经经过的循环次数
end
end

function [randomBackOff,fail_count] = Generate_random(memory,min_index,stop,n)
%memory表示上一次的随机结果，min_index是最小的随机数索引,stop 是传输完成的STA索引
randomBackOff = memory;
memory_min = min(memory);
First = memory - memory_min;
STAs = length(randomBackOff);
fail_count = 0;
%声明随机数向量
for i=1:length(randomBackOff) %这个循环不支持First全为0的情况，即第一次传输数据

    if sum(First)==0   %如果第一次传输则不要进这个循环，跳出
        break;
    end
    %遇到最小的随机数将其randomBackOff(1,i)在这一次传输的过程中我们随机生成随机数开始新的倒计时       
    if i == min_index                
        randomBackOff(1,i) = floor(unifrnd (0, n*STAs+1, 1, 1));              
    %否则使用上一次被冻结的randomBackOff(1,i)继续进行倒数
    else
        randomBackOff(1,i) = randomBackOff(1,i) - memory_min;
    end
    %寻找是否存在传输完成的STA，如果完成所有的传输(1000次)则立刻挂起，加i是为了避免由于STA的CW值相同而陷入死循环
    for j=1:length(stop)
        if i == stop(j)
            randomBackOff(1,i) = n*STAs +1 + i;
        end
    end
end

%第一次进入循环时，CW全为0，因此我们要立刻为其赋值以免后面进入死循环
if sum(First)==0
    randomBackOff = floor(unifrnd (0, n*STAs+1, 1, STAs));
end

%通过上面的步骤，我们虽然生成了随机数，但是还不能立刻跳出循环开始传输，还得检查是否存在至少2个STA的随机数的值相同。
%因此，在某一次传输产生随机数完成后，我们还需要进行循环检测，来保证我们这一次产生的随机数在所有的STA中均不冲突
while(1)
%如果所有STA在这一次中所有的倒计时的数字都不同,即表示此次随机赋值无冲突，可以顺利跳出break
if length(unique(randomBackOff))==length(randomBackOff)
    break;
%那么如果遇到至少有2个STA产生的随机数相同，则检测到了冲突，此次我们将为CW倒计时翻倍并重新给每个STA分配随机的倒计时    
else  
    n = 2*n;
    randomBackOff = floor(unifrnd (0, n*STAs+1, 1, STAs));
    fail_count = fail_count + 1; %则我们可以记录在这一次分配随机数的时候发生冲突的计数器加1
end
end
end

