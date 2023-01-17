function [rxSymbols,rxEncodedBits,outLen]=subframeProc(enb,sf,rxGrid,frame,LFrame,Lsf,cec, rxSymbols)
rxSymbols = []; txSymbols = [];
hcd = comm.ConstellationDiagram('Title','Equalized PDSCH Symbols',...
                                'ShowReferenceConstellation',false);
enb.NSubframe = sf;
                rxsf = rxGrid(:,frame*LFrame+sf*Lsf+(1:Lsf),:);

                [hestsf,nestsf] = lteDLChannelEstimate(enb,cec,rxsf); % -------------------------> 信道估计

                %--------------------------------------------------------------------------------> PCFICH解调
                pcfichIndices = ltePCFICHIndices(enb);
                [pcfichRx,pcfichHest] = lteExtractResources(pcfichIndices,rxsf,hestsf);
                [cfiBits,recsym] = ltePCFICHDecode(enb,pcfichRx,pcfichHest,nestsf);

                %--------------------------------------------------------------------------------> CFI 解码
                enb.CFI = lteCFIDecode(cfiBits);
                
                %--------------------------------------------------------------------------------> 获得PDSCH索引
                [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, enb.PDSCH, enb.PDSCH.PRBSet); 
                [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsf, hestsf);

                %--------------------------------------------------------------------------------> PDSCH解码
                [rxEncodedBits, rxEncodedSymb] = ltePDSCHDecode(enb,enb.PDSCH,pdschRx,...
                                               pdschHest,nestsf);

                %--------------------------------------------------------------------------------> 重构符号流
                rxSymbols = [rxSymbols; rxEncodedSymb{:}]; %#ok<AGROW>
                
                %--------------------------------------------------------------------------------> DL-SCH解码
                outLen = enb.PDSCH.TrBlkSizes(enb.NSubframe+1);  
                
                [decbits{sf+1}, blkcrc(sf+1)] = lteDLSCHDecode(enb,enb.PDSCH,...  
                                                outLen, rxEncodedBits); 
                       
                txRecode = lteDLSCH(enb,enb.PDSCH,pdschIndicesInfo.G,decbits{sf+1});

                txRemod = ltePDSCH(enb, enb.PDSCH, txRecode);    %-------------------------------> PD-SCH解码
                [~,refSymbols] = ltePDSCHDecode(enb, enb.PDSCH, txRemod);

                txSymbols = [txSymbols; refSymbols{:}]; %#ok<AGROW>

                release(hcd); % 
                step(hcd,rxEncodedSymb{:}); % %---------------------------------------------------> 绘制星座点
end