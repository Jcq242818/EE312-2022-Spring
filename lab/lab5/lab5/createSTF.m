function [Short_preamble] = createSTF(S_k)
N_FFT = 64;
virtual_subcarrier = zeros(1,N_FFT-length(S_k));
Short_preamble_slot_Frequency = [virtual_subcarrier(1:6),S_k,virtual_subcarrier(7:11)];
Short_preamble_slot_Time = ifft(ifftshift(Short_preamble_slot_Frequency));
Short_preamble = repmat(Short_preamble_slot_Time(1:16),1,10);
Short_preamble = Short_preamble*20;