function [enbMax,offsetMax,enb]=NCellDetection(enb,downsampled)
%PSS和SSS盲检可以得出小区PCI(enb.NCellID)
fprintf('\nPerforming cell search...\n');
duplexModes = {'TDD' 'FDD'};
cyclicPrefixes = {'Normal' 'Extended'};

searchalg.MaxCellCount = 1;
searchalg.SSSDetection = 'PostFFT';
peakMax = -Inf;

for duplexMode = duplexModes %盲检TDD、FDD
    for cyclicPrefix = cyclicPrefixes  %盲检普通、拓展CP
        enb.DuplexMode = duplexMode{1};
        enb.CyclicPrefix = cyclicPrefix{1};
        [enb.NCellID, offset, peak] = lteCellSearch(enb, downsampled, searchalg);%小区搜索、获取PCI
        enb.NCellID = enb.NCellID(1);
        offset = offset(1);
        peak = peak(1);
        if (peak>peakMax)%最大值对应TDD/FDD
            enbMax = enb;
            offsetMax= offset;
            peakMax = peak;
        end
    end
end
end
    