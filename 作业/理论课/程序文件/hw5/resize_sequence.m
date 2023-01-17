%该函数的作用是将一个序列拆成两半，并将拆成两半的序列依次输出
function [sequence_front,sequence_behind] = resize_sequence(sequence)
    Length = length(sequence); %获取序列的长度
    sequence_front = sequence(1:1:Length/2);
    sequence_behind = sequence(Length/2+1:1:Length);
    
    
    
    
    
    
