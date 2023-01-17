%% CellSearch.m
% Improved LTE-Cell-Scanner (written by James Peroulas: https://github.com/Evrytania/LTE-Cell-Scanner).

% Some scripts are borrowed from:
% https://github.com/JiaoXianjun/rtl-sdr-LTE
% https://github.com/Evrytania/LTE-Cell-Scanner
% https://github.com/Evrytania/Matlab-Library
% https://github.com/JiaoXianjun/multi-rtl-sdr-calibration

%% 小区搜索：根据预先录制的实际数据，恢复小区的SIB信息。  
clear;
close all;
warning('off','all');

%% 1、读取文件信息
test_source_info = regression_test_source('../regression_test_signal_file');
test_sp = 1;
test_ep = length(test_source_info);
sampling_carrier_twist = 0;
f_search_set = -140e3:5e3:140e3; 
pss_peak_max_reserve = 2;
num_pss_period_try = 1;
combined_pss_peak_range = -1; % set it to -1 to use complementary range of peak.
par_th = 8.5;
num_peak_th = 1/2; % originally is 2/3;

filename = ['CellSearch_test' num2str(test_sp) 'to' num2str(test_ep) '_twist' num2str(sampling_carrier_twist)...
         '_fo' num2str(min(f_search_set)/1e3) 'to' num2str(max(f_search_set)/1e3) '_resv' num2str(pss_peak_max_reserve)...
         '_numPtry' num2str(num_pss_period_try) '_Prange' num2str(combined_pss_peak_range) '_parTh' num2str(par_th)...
         '_numPth' num2str(num_peak_th) '.mat'];

disp(test_source_info.filename);
coef_pbch = pbch_filter_coef_gen(test_source_info.fs);
    
r_raw = get_signal_from_bin(test_source_info.filename, inf, test_source_info.dev);
r_raw = r_raw - mean(r_raw); % remove DC

figure(1)  %----------------------------------------------------------------------------> 显示原始波形采样
raw_sampling_rate = 19200000;
subplot(211); plot([0:length(r_raw)-1]/raw_sampling_rate, real(r_raw)); xlabel('t(sec)'); ylabel('Real(Raw)');
axis([0 0.008 -1.5 1.5])
subplot(212); plot([0:length(r_raw)-1]/raw_sampling_rate, imag(r_raw)); xlabel('t(sec)'); ylabel('Imag(Raw)');   
axis([0 0.008 -1.5 1.5])

figure(2) %----------------------------------------------------------------------------> 显示原始波形采样
r_pbch = filter_wo_tail(r_raw, coef_pbch, (30.72e6/16)/test_source_info.fs);
subplot(211); plot([0:length(r_pbch)-1]/raw_sampling_rate, real(r_pbch)); xlabel('t(sec)'); ylabel('Real(r_pbch)');
axis([0 0.008 -0.5 0.5])
subplot(212); plot([0:length(r_pbch)-1]/raw_sampling_rate, imag(r_pbch)); xlabel('t(sec)'); ylabel('Imag(r_pbch)');
axis([0 0.008 -0.5 0.5])

%% 2、小区搜索，返回cell_info信息
[~, ~, ~, cell_info] = CellSearch(r_pbch, [], f_search_set, test_source_info.fc, sampling_carrier_twist, ...
                                  pss_peak_max_reserve, num_pss_period_try, combined_pss_peak_range, par_th, num_peak_th);

%save(filename, 'test_source_info', 'cell_info', 'test_sp', 'test_ep', 'sampling_carrier_twist', ...
%'f_search_set', 'pss_peak_max_reserve', 'num_pss_period_try', 'combined_pss_peak_range');
