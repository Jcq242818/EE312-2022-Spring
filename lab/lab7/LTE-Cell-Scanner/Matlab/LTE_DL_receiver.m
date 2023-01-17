%% From IQ sample to PDSCH output and RRC SIB messages.
%  Run with pre-captured IQ file. Input argument: filename (Should follow style: f2585_s19.2_bw20_0.08s_hackrf.bin)


close all;
clear;
warning('off','all');

sampling_carrier_twist = 1; % ATTENTION! If this is 1, make sure fc is aligned with bin file!!!
num_radioframe = 8; % Each radio frame length 10ms. MIB period is 4 radio frame
num_second = num_radioframe*10e-3;
raw_sampling_rate = 19.2e6; % Constrained by hackrf board and LTE signal format (100RB). 
nRB = 100;
sampling_rate = 30.72e6;
sampling_rate_pbch = sampling_rate/16; % LTE spec. 30.72MHz/16.
bandwidth = 20e6;

pss_peak_max_reserve = 2;
num_pss_period_try = 1;
combined_pss_peak_range = -1;
par_th = 8.5;
num_peak_th = 1/2;

%% 1、读取I/Q数据
filename = '../regression_test_signal_file/f1815.3_s19.2_bw20_0.08s_hackrf-1.bin';
if ~isempty(filename) % If need to read from bin file
    [fc, sdr_board] = get_freq_hardware_from_filename(filename);  %------------------------------------> 获取载波信息1.815G
    if isempty(fc) || isempty(sdr_board)
        disp([filename ' does not include valid frequency or hardware info!']);
        return;
    end
    disp(filename);
    
    r_raw = get_signal_from_bin(filename, inf, sdr_board);  %-----------------------------------------> 读取IQ数据
    figure(1)
    subplot(211); plot([0:length(r_raw)-1]/raw_sampling_rate, real(r_raw)); xlabel('t(sec)'); ylabel('Real(Raw)');
    axis([0 0.008 -1.5 1.5])
    subplot(212); plot([0:length(r_raw)-1]/raw_sampling_rate, imag(r_raw)); xlabel('t(sec)'); ylabel('Imag(Raw)');    
    axis([0 0.008 -1.5 1.5])
end

disp(['fc ' num2str(fc) '; IQ from ' sdr_board ' ' filename]);   


%% 2、导入小区搜索结果
%   [cell_info, r_pbch, r_20M] = CellSearch(r_pbch, r_20M, f_search_set,  fc);  ----------------------> 小区搜索

if (~isempty(filename)) && exist([filename(1:end-4) '.mat'], 'file')  %-------------------------------> 小区搜索结果导入
    load([filename(1:end-4) '.mat']);

    for i=1:length(cell_info)
        peak = cell_info(i);
        if peak.duplex_mode == 1
            cell_mode_str = 'TDD';
        else
            cell_mode_str = 'FDD';
        end
        disp(['Cell ' num2str(i) ' information:--------------------------------------------------------']);
        disp(['            Cell mode: ' num2str(cell_mode_str)]);
        disp(['              Cell ID: ' num2str(peak.n_id_cell)]);
        disp(['   Num. eNB Ant ports: ' num2str(peak.n_ports)]);
        disp(['    Carrier frequency: ' num2str(fc/1e6) 'MHz']);
        disp(['Residual freq. offset: ' num2str(peak.freq_superfine/1e3) 'kHz']);
        disp(['       RX power level: ' num2str(10*log10(peak.pow))]);
        disp(['              CP type: ' peak.cp_type]);
        disp(['              Num. RB: ' num2str(peak.n_rb_dl)]);
        disp(['       PHICH duration: ' peak.phich_dur]);
        disp(['  PHICH resource type: ' num2str(peak.phich_res)]);
    end
end

%% 3、PDSCH 解码 PCFICH->PDCCH->PDSCH
uldl_str = [ ...   %--------------------------------------------------------------------------> 上行链路和下行链路结构
        '|D|S|U|U|U|D|S|U|U|U|'; ...
        '|D|S|U|U|D|D|S|U|U|D|'; ...
        '|D|S|U|D|D|D|S|U|D|D|'; ...
        '|D|S|U|U|U|D|D|D|D|D|'; ...
        '|D|S|U|U|D|D|D|D|D|D|';
        '|D|S|U|D|D|D|D|D|D|D|';
        '|D|S|U|U|U|D|S|U|U|D|'
        ];

tic;
pcfich_corr = -1;
pcfich_info = -1;
for cell_idx = 1 : length(cell_info)
    cell_tmp = cell_info(cell_idx);
    %tfg：time/frequency grid.---------------------------------------------------------------> 时频资源网格
    [tfg, tfg_timestamp, cell_tmp]=extract_tfg(cell_tmp,r_20M,fc,sampling_carrier_twist, cell_tmp.n_rb_dl);
    
    if isempty(tfg)  %-----------------------------------------------------------------------> 资源网格非空，继续进行处理
        continue;
    end
    
    % 3.1 参数初始化
    n_symb_per_subframe = 2*cell_tmp.n_symb_dl;   %-----------------------------------------> 普通循环前缀，一个子帧14个OFDM符号
    n_symb_per_radioframe = 10*n_symb_per_subframe;   %-------------------------------------> 一个系统帧，有140个OFDM符号
    num_radioframe = floor(size(tfg,1)/n_symb_per_radioframe);  %---------------------------> 共有6个系统帧
    num_subframe = num_radioframe*10;  %----------------------------------------------------> 共有60个子帧
    pdcch_info = cell(1, num_subframe);
    pcfich_info = zeros(1, num_subframe);
    pcfich_corr = zeros(1, num_subframe);
    uldl_cfg = zeros(1, num_radioframe);
    
    nSC = cell_tmp.n_rb_dl*12;  %----------------------------------------------------------> 100个RB，共有120个载波
    n_ports = cell_tmp.n_ports; %----------------------------------------------------------> 共有2个天线端口
    
    tfg_comp_radioframe = zeros(n_symb_per_subframe*10, nSC);
    ce_tfg = NaN(n_symb_per_subframe, nSC, n_ports, 10);
    np_ce = zeros(10, n_ports);
    
    
    % 3.2 系统帧处理：频偏校正 -> 信道估计 -> CFI解码 -> 识别ULDL -> PDCCH解码 -> PDSCH解码
    for radioframe_idx = 1 : num_radioframe
        
        subframe_base_idx = (radioframe_idx-1)*10;
        
        %3.2.1 信道估计和PCFI信道解码
        for subframe_idx = 1 : 10   %--------------------------------------------------------> 对10个子帧分别处理
            sp = (subframe_base_idx + subframe_idx-1)*n_symb_per_subframe + 1;
            ep = sp + n_symb_per_subframe - 1;

            %（1）频偏校正：Compensates for frequency offset 
            [tfg_comp, ~, ~] = tfoec_subframe(cell_tmp, subframe_idx-1, tfg(sp:ep, :),  ...
                                              tfg_timestamp(sp:ep), fc, sampling_carrier_twist); 
            tfg_comp_radioframe( (subframe_idx-1)*n_symb_per_subframe+1 : subframe_idx*n_symb_per_subframe, :) = tfg_comp;
            
            %（2）信道估计：Channel estimation
            for i=1:n_ports
                [ce_tfg(:,:,i, subframe_idx), np_ce(subframe_idx, i)] = ...
                                               chan_est_subframe(cell_tmp, subframe_idx-1, tfg_comp, i-1);
            end

            %（3）PCFICH信道解码：pcfich decoding
            [pcfich_info(subframe_base_idx+subframe_idx), pcfich_corr(subframe_base_idx+subframe_idx)] = ...
                                         decode_pcfich(cell_tmp, subframe_idx-1, tfg_comp, ce_tfg(:,:,:, subframe_idx));
        end
        
        %3.2.2 识别UL DL configuration
        cell_tmp = get_uldl_cfg(cell_tmp, pcfich_info( (subframe_base_idx+1) : (subframe_base_idx+10) ));
        uldl_cfg(radioframe_idx) = cell_tmp.uldl_cfg;
        sfn = mod(cell_tmp.sfn+radioframe_idx-1, 1023);
        cell_info_post_str = [ ' CID-' num2str(cell_tmp.n_id_cell) ...
                               ' nPort-' num2str(cell_tmp.n_ports) ...
                               ' CP-' cell_tmp.cp_type ...
                               ' PHICH-DUR-' cell_tmp.phich_dur ...
                               '-RES-' num2str(cell_tmp.phich_res)];
                        
        if cell_tmp.uldl_cfg >= 0 % TDD and valid pcfich/UL-DL-PATTERN detected
            disp(['TDD SFN-' num2str(sfn) ...
                  ' ULDL-' num2str(cell_tmp.uldl_cfg) ...
                  '-' uldl_str(cell_tmp.uldl_cfg+1,:) cell_info_post_str]);
              
            title_str = ['TDD SFN-' num2str(sfn) ' ULDL-' num2str(cell_tmp.uldl_cfg) cell_info_post_str];
        elseif cell_tmp.uldl_cfg == -2 % FDD and valid pcfich/UL-DL-PATTERN detected
            disp(['FDD SFN-' num2str(sfn) ' ULDL-0: D D D D D D D D D D' cell_info_post_str]);
            title_str = ['FDD SFN-' num2str(sfn) ' ULDL-0' cell_info_post_str];
        end
        
        figure(10);
        a = abs(tfg_comp_radioframe)';
        subplot(2,1,1); pcolor(a); shading flat; 
        title(['RE grid: ' title_str]); xlabel('OFDM symbol idx'); ylabel('subcarrier idx'); drawnow; %colorbar; 
        subplot(2,1,2); plot(a); xlabel('subcarrier idx'); ylabel('abs'); 
        legend('diff color diff OFDM symbol'); grid on; 
        title('Spectrum of each OFDM symbol'); drawnow; %title('color -- OFDM symbol');  
        %savefig([num2str(radioframe_idx) '.fig']);
        clear a;
        
        % 3.2.3 PDCCH信道解码
        for subframe_idx = 1 : 10
            tfg_comp = tfg_comp_radioframe( (subframe_idx-1)*n_symb_per_subframe+1 : subframe_idx*n_symb_per_subframe, :);
            
            [sc_map, reg_info] = get_sc_map(cell_tmp, pcfich_info(subframe_base_idx+subframe_idx), subframe_idx-1);
            
            pdcch_info{subframe_base_idx+subframe_idx} = ...
            decode_pdcch(cell_tmp, reg_info, subframe_idx-1, tfg_comp, ce_tfg(:,:,:, subframe_idx), np_ce(subframe_idx,:));
            disp(['SF' num2str(subframe_idx-1) ...
                  ' PHICH' num2str(reg_info.n_phich_symb)...
                  ' PDCCH' num2str(reg_info.n_pdcch_symb) ...
                  ' RNTI: ' pdcch_info{subframe_base_idx+subframe_idx}.rnti_str]);
           
         % 3.2.4 PDSCH信道解码
            if ~isempty(pdcch_info{subframe_base_idx+subframe_idx}.si_rnti_info)
                num_info = size(pdcch_info{subframe_base_idx+subframe_idx}.si_rnti_info,1);
                for info_idx = 1 : num_info
                    format1A_bits = pdcch_info{subframe_base_idx+subframe_idx}.si_rnti_info(info_idx,:);
                    format1A_location = pdcch_info{subframe_base_idx+subframe_idx}.si_rnti_location(info_idx,:);
                    [dci_str, dci_info] = parse_DCI_format1A(cell_tmp, 0, format1A_bits);
                    
                    disp(['PDCCH No.' num2str(format1A_location(1)) ...
                          '  ' num2str(format1A_location(2)) 'CCE: ' dci_str]);
                      
%                   syms = decode_pdsch(cell_tmp, reg_info, dci_info, subframe_idx-1, tfg_comp, ...
                                                            % ce_tfg(:,:,:, subframe_idx), np_ce(subframe_idx,:));
%                   figure(3); plot(real(syms), imag(syms), 'r.');

                    [sib_info, syms] = decode_pdsch(cell_tmp, reg_info, dci_info, ...
                                    subframe_idx-1, tfg_comp, ce_tfg(:,:,:, subframe_idx), np_ce(subframe_idx,:));
                    parse_SIB(sib_info);
                    disp(['SIB crc' num2str(sib_info.blkcrc) ': ' num2str(sib_info.bits)]);
                    
                  figure(4); plot(real(syms), imag(syms), 'b.');
                  if mod(sfn, 2) == 0 && subframe_idx==6
                        title('raw SIB1 PDSCH');  xlabel('real'); ylabel('imag'); drawnow;
                  else
                        title('raw SIBx PDSCH');  xlabel('real'); ylabel('imag'); drawnow;
                  end
                end
            end
            figure(5); plot_sc_map(sc_map, tfg_comp);
        end        
    end
    
    disp(num2str(pcfich_corr));
    sf_set = find(pcfich_info>0);
    val_set = pcfich_info(pcfich_info>0);
    disp(['subframe  ' num2str(sf_set)]);
    disp(['num pdcch ' num2str(val_set)]);

end

toc
figure(9)
subplot(4,1,1); plot(pcfich_corr); axis tight;
subplot(4,1,2); plot(sf_set, val_set, 'b.-'); axis tight;
subplot(4,1,3);
a = zeros(1, max(sf_set)); a(sf_set) = 1;
pcolor([a;a]); shading faceted;  axis tight;
subplot(4,1,4); plot(uldl_cfg);
