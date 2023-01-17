%sdrzPlotResourceGrid plots the physical channel allocations given a grid
%and matrix of enumerated channel locations.

% Copyright 2014 The MathWorks, Inc.

function sdrzPlotResourceGrid(grid,colors)      
     
    % Determine number of subcarriers 'K' and number of OFDM symbols 'L'
    % in input resource grid
    K = size(grid,1);
    L = size(grid,2);
    
    % Pad edges of resource grid and colors
    grid = [zeros(K,1) grid zeros(K,2)];
    grid = [zeros(1,L+3); grid; zeros(2,L+3)];    
    colors = [zeros(K,1) colors zeros(K,2)];
    colors = [zeros(1,L+3); colors; zeros(1,L+3)];    
    for k = 1:K+3
        for l = L+3:-1:2
            if (grid(k,l)==0 && grid(k,l-1)~=0)
                grid(k,l) = grid(k,l-1);                
            end
        end
    end    
    for l = 1:L+3
        for k = K+3:-1:2
            if (grid(k,l)==0 && grid(k-1,l)~=0)
                grid(k,l) = grid(k-1,l);  
            end
        end
    end     
    
    % Create resource grid power matrix, with a floor of -40dB
    powers = 20*log10(grid+1e-2);
    
    % Create surface plot of powers
    h = surf((-1:L+1)-0.5,(-1:K+1)-0.5,powers,colors);                    
     
    % Create and apply color map
    map=[0.50 0.50 0.50; ...
         0.75 0.75 0.75; ...
         1.00 1.00 1.00; ...
         0.25 0.25 1.00; ...
         0.50 0.50 1.00; ...
         0.75 0.75 1.00; ...
         1.00 0.00 0.00; ...
         1.00 0.75 0.00; ...
         1.00 1.00 0.25; ...
         0.25 1.00 0.25; ...
         0.50 1.00 0.50; ...
         0.75 1.00 0.75];     
    caxis([0 12])
    colormap(map);
    set(h,'EdgeColor',[0.25 0.25 0.25]);
    
    % Set view and axis ranges
    az = -12.5;
    el = 66;
    view(az,el);
    axis([-1.5 L+0.5 -1.5 K+0.5 min(powers(:))-5 max(powers(:))+5]);

    % Set plot axis labels
    zlabel('Power (dB)');
    ylabel('Subcarrier index');
    xlabel('OFDM symbol index');        
    
end
