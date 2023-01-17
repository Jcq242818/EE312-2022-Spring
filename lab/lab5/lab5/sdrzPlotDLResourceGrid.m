%sdrzPlotDLResourceGrid plots the downlink resource grid with colored
%physical channel allocations.

% Copyright 2014 The MathWorks, Inc.

function hPlot = sdrzPlotDLResourceGrid(enb,grid)
                
    % Create patches (outside of final view) to facilitate the creation 
    % of the legend
    hPlot = figure;
    hold on;
    for i=1:9
        patch([-2 -3 -3 -2],[-2 -2 -3 -3],i);
    end            
    
    % Obtain resource grid colorization
    colors = sdrzIdentifyDLChannels(enb,grid);
    
    % Plot resource grid
    sdrzPlotResourceGrid(abs(grid),colors);
    
    % Set view    
    view([0 90]);
    
    % Add legend
    legend('unused','Cell RS','PSS','SSS','PBCH','PCFICH','PHICH', ...
            'PDCCH','PDSCH','Location','NorthEastOutside');

end