function [enbMax,offsetMax,enb]=NCellDetection(enb,downsampled)
%PSS��SSSä����Եó�С��PCI(enb.NCellID)
fprintf('\nPerforming cell search...\n');
duplexModes = {'TDD' 'FDD'};
cyclicPrefixes = {'Normal' 'Extended'};

searchalg.MaxCellCount = 1;
searchalg.SSSDetection = 'PostFFT';
peakMax = -Inf;

for duplexMode = duplexModes %ä��TDD��FDD
    for cyclicPrefix = cyclicPrefixes  %ä����ͨ����չCP
        enb.DuplexMode = duplexMode{1};
        enb.CyclicPrefix = cyclicPrefix{1};
        [enb.NCellID, offset, peak] = lteCellSearch(enb, downsampled, searchalg);%С����������ȡPCI
        enb.NCellID = enb.NCellID(1);
        offset = offset(1);
        peak = peak(1);
        if (peak>peakMax)%���ֵ��ӦTDD/FDD
            enbMax = enb;
            offsetMax= offset;
            peakMax = peak;
        end
    end
end
end
    