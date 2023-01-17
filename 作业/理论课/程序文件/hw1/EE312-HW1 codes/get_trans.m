function [Process,counter] = get_trans(STA,n,tx_same)
CW = zeros(1,STA);
CW(1,:) = n * STA +1; %ע����������nΪ2

% �½�һ���������������ÿ��STAsʣ�ഫ�������֮���ÿһ�д���ÿһ�δ��������ÿ��STA��Ӧ���ɵ������
Process = zeros(tx_same*STA+1,STA);
Process(1,:) = tx_same;
save = CW;
counter = zeros(tx_same*STA+1,1); %��¼����ʧ�ܵĴ���
min_index = 1;   % min_index�����������С��������������״δ�����Ĭ��Ϊ1
initial = 2;  % ��һ�δ���ʱProcess�����Ǵӵڶ��п�ʼд��ģ���������rowΪ2
st_finish = zeros(1,STA); %��¼������ɵ�STA����
% double = zeros(tx_same*STAs+1,1);  %��¼��ÿһ�δ����ʱ����û�з�������ͻ���Ա���һ�δ�������������ʱ��Ҫ�����Ƿ���Ҫ�ӱ�
count = 1;
while(1)
    % min_index�����������С�������������st_finish�Ǵ�����ɵ�STA����
    [save,fail_count] = Generate_random(save,min_index,st_finish,n);
    Process(initial,:) = save;
    counter(initial,:) = fail_count;
    %������С���������������ȥ��Ӧ��STA��ʣ�ഫ������
    [~, min_index] = min(save);
    Process(1,min_index) = Process(1,min_index) -1;
    %��������STA�����ȫ��������ɵ�STA��������������ӵ�st_finish��
    for i = 1:STA
        if Process(1,i)==0
            st_finish(i)=i;
        end
    end
    
    %ֱ���������ݴ�����ɣ���ô�ʵ����ɣ���������ѭ��
    if sum(Process(1,:))==0
        break
    end
    %����������һ
    initial = initial+1;
    count = count+1; %��¼�Ѿ�������ѭ������
end
end

function [randomBackOff,fail_count] = Generate_random(memory,min_index,stop,n)
%memory��ʾ��һ�ε���������min_index����С�����������,stop �Ǵ�����ɵ�STA����
randomBackOff = memory;
memory_min = min(memory);
First = memory - memory_min;
STAs = length(randomBackOff);
fail_count = 0;
%�������������
for i=1:length(randomBackOff) %���ѭ����֧��FirstȫΪ0�����������һ�δ�������

    if sum(First)==0   %�����һ�δ�����Ҫ�����ѭ��������
        break;
    end
    %������С�����������randomBackOff(1,i)����һ�δ���Ĺ�����������������������ʼ�µĵ���ʱ       
    if i == min_index                
        randomBackOff(1,i) = floor(unifrnd (0, n*STAs+1, 1, 1));              
    %����ʹ����һ�α������randomBackOff(1,i)�������е���
    else
        randomBackOff(1,i) = randomBackOff(1,i) - memory_min;
    end
    %Ѱ���Ƿ���ڴ�����ɵ�STA�����������еĴ���(1000��)�����̹��𣬼�i��Ϊ�˱�������STA��CWֵ��ͬ��������ѭ��
    for j=1:length(stop)
        if i == stop(j)
            randomBackOff(1,i) = n*STAs +1 + i;
        end
    end
end

%��һ�ν���ѭ��ʱ��CWȫΪ0���������Ҫ����Ϊ�丳ֵ������������ѭ��
if sum(First)==0
    randomBackOff = floor(unifrnd (0, n*STAs+1, 1, STAs));
end

%ͨ������Ĳ��裬������Ȼ����������������ǻ�������������ѭ����ʼ���䣬���ü���Ƿ��������2��STA���������ֵ��ͬ��
%��ˣ���ĳһ�δ�������������ɺ����ǻ���Ҫ����ѭ����⣬����֤������һ�β���������������е�STA�о�����ͻ
while(1)
%�������STA����һ�������еĵ���ʱ�����ֶ���ͬ,����ʾ�˴������ֵ�޳�ͻ������˳������break
if length(unique(randomBackOff))==length(randomBackOff)
    break;
%��ô�������������2��STA�������������ͬ�����⵽�˳�ͻ���˴����ǽ�ΪCW����ʱ���������¸�ÿ��STA��������ĵ���ʱ    
else  
    n = 2*n;
    randomBackOff = floor(unifrnd (0, n*STAs+1, 1, STAs));
    fail_count = fail_count + 1; %�����ǿ��Լ�¼����һ�η����������ʱ������ͻ�ļ�������1
end
end
end

