%sdrzIdentifyDLChannels returns a matrix of enumerated channel allocations
%given a cell-wide configuration and resource grid.

% Copyright 2014 The MathWorks, Inc.

function colors = sdrzIdentifyDLChannels(enb,grid)
    
    % Initialization of output
    colors = ones(size(grid));
    
    % Determine subframe length 'L' (in OFDM symbols) and the number of 
    % subframes 'nsf' in the input grid 
    dims = lteDLResourceGridSize(enb);
    L = dims(2);
    nsf = size(grid,2)/L;
    
    % Initialization of PDSCH physical resource block set
    enb.PDSCH.PRBSet = (0:enb.NDLRB-1).';
    
    % Loop for each subframe
    for i=0:nsf-1

        % Configure subframe number
        enb.NSubframe = mod(i,10);   
        
        % Create empty resource grid
        sfcolors = lteDLResourceGrid(enb);  
    
        % Colourize the Resource Elements for each channel and signal
        sfcolors(lteCellRSIndices(enb,0)) = 1;
        sfcolors(ltePSSIndices(enb,0)) = 2;
        sfcolors(lteSSSIndices(enb,0)) = 3;
        sfcolors(ltePBCHIndices(enb)) = 4;
        duplexingInfo = lteDuplexingInfo(enb);
         if (duplexingInfo.NSymbolsDL~=0)
             sfcolors(ltePCFICHIndices(enb)) = 5;
             sfcolors(ltePHICHIndices(enb)) = 6;
             sfcolors(ltePDCCHIndices(enb)) = 7;
             sfcolors(ltePDSCHIndices(enb,enb.PDSCH,enb.PDSCH.PRBSet)) = 8;
         end

        % Set current subframe into output
        colors(:,i*L+(1:L)) = colors(:,i*L+(1:L)) + sfcolors;

    end
    
end
