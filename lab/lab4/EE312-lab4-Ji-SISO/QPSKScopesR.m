

%   Copyright 2012 The MathWorks, Inc.

classdef QPSKScopes < matlab.System
    
    properties (Access=private)
        pRxScope % Spectrum analyzer System object to plot received signal after filtering
        pRxConstellation % Constellation scope System object to plot received signal after filtering
        pFreqRecConstellation % Constellation scope System object to plot received signal after filtering
        pTimingError % Time scope System object to plot normalized timing error
    end
    
    methods
        function obj = QPSKScopes(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj, ~, ~, ~)
            obj.pRxScope = dsp.SpectrumAnalyzer('SpectralAverages', 2, ...
                    'PowerUnits', 'dBW', 'YLimits', [-130 -15], ...
                    'Title', 'After Raised Cosine Rx Filter', ...
                    'SpectralAverages', 1, ...
                    'YLabel', 'PSD', ...
                    'SpectrumType', 'Power density', ...
                    'Position', figposition([1.5 37.2 24 26]));
            obj.pRxConstellation = comm.ConstellationDiagram( ...
                    'ShowGrid', true, ...
                    'Position', figposition([1.5 72 17 20]), ...                    
                    'SamplesPerSymbol', 2, ...                    
                    'YLimits', [-1 1], ...
                    'XLimits', [-1 1], ...
                    'Title', 'After Raised Cosine Rx Filter');
            obj.pFreqRecConstellation = comm.ConstellationDiagram( ...
                    'ShowGrid', true, ...
                    'Position', figposition([19 72 17 20]), ...
                    'YLimits', [-1 1], ...
                    'XLimits', [-1 1], ...                    
                    'SamplesPerSymbol', 2, ...                    
                    'Title', 'After Fine Frequency Compensation');
            obj.pTimingError = dsp.TimeScope( ...
                    'Title', 'Normalized Timing Error', ...
                    'YLabel', 'mu (half symbols)', 'TimeSpan', 1000, ...
                    'YLimits', [-0.1 1.1], 'ShowGrid', true, ...
                    'Position', figposition([26 45 11.8 17.8]));    
        end
        
        
        function stepImpl(obj, RCRxSignal, coarseCompBuffer, timingRecBuffer)
            
               % Plots the constellation of the filtered signal
               step(obj.pRxConstellation,RCRxSignal);
               
               % Plots the spectrum scope of the filtered signal
               step(obj.pRxScope,RCRxSignal);
      
               % Plots the constellation of the phase recovered signal
               step(obj.pFreqRecConstellation,coarseCompBuffer);
               
               % Plots the time scope of normalized timing error
               step(obj.pTimingError, timingRecBuffer(1:10:end));
        end
        
        function resetImpl(obj)
            reset(obj.pRxConstellation);
            reset(obj.pFreqRecConstellation);
            reset(obj.pRxScope);
            reset(obj.pTimingError);
        end
        
        function releaseImpl(obj)
            release(obj.pRxConstellation);
            release(obj.pFreqRecConstellation);
            release(obj.pRxScope);
            release(obj.pTimingError);
        end
        
        function N = getNumInputsImpl(~)
            N = 3; 
        end
        
        function N = getNumOutputsImpl(~)
            N = 0; 
        end
    end
end

