function [x_k] = OFDM_symbol(size,sequence)
    size_half = size/2;
    x_k= zeros(1,size);
    for n = 1:1:size
        for k = -(size_half-1) :1:size_half
            x_k(n) = x_k(n) + sequence(k+size_half)*exp(1j*2*pi*k*(n-1)/size);
        end
    end
end

    
    
 
