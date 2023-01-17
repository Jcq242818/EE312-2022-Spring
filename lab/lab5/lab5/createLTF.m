function [Long_preamble] = createLTF(L_k)
N_FFT = 64;
virtual_subcarrier = zeros(1,N_FFT-length(L_k));
Long_preamble_slot_Frequency = [virtual_subcarrier(1:6),L_k,virtual_subcarrier(7:11)];
Long_preamble_slot_Time = ifft(ifftshift(Long_preamble_slot_Frequency));
Long_preamble = [Long_preamble_slot_Time(33:64),Long_preamble_slot_Time,Long_preamble_slot_Time];
Long_preamble = Long_preamble*10;