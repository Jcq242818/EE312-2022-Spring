%该函数的意义是通过类DFT抽取之前加载到ODFM符号的一个sample内的62个PSS初始序列
function [x_k] = OFDM_reverse_symbol(tx)
    N = length(tx);
    input_process = zeros(1,N);
    for k = -63:1:64
        for n = 1:1:N
        input_process(k+64) = input_process(k+64)+tx(n)*exp(-1j*2*pi*k*(n-1)/N);
        end
    end
      input_process = input_process ./ N;  %因为128个都算了一遍，现在要除以128才行
      x_k = input_process;
    end

