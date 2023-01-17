classdef QPSKCoarseFrequencyCompensatorR < matlab.System
    %#codegen
    % This object is used only in supporting packages.
    %
    % Copyright 2012-2014 The MathWorks, Inc.
    properties (Nontunable)
        ModulationOrder = 4;
        CoarseCompFrequencyResolution = 50;
        SampleRate = 200000;
        DownsamplingFactor = 2;
    end
    
    properties (Access=private)
        pPhaseFreqOffset
        pCoarseFreqEst
    end
    
    methods
        function obj = QPSKCoarseFrequencyCompensatorR(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj, ~)
            currentSampleRate = obj.SampleRate/obj.DownsamplingFactor;
            obj.pPhaseFreqOffset = comm.PhaseFrequencyOffset(...
                'PhaseOffset', 0, ...
                'FrequencyOffsetSource', 'Input port' , ...
                'SampleRate', currentSampleRate);
            obj.pCoarseFreqEst = comm.QAMCoarseFrequencyEstimator( ...
                'FrequencyResolution', obj.CoarseCompFrequencyResolution, ...
                'SampleRate', currentSampleRate);
        end
        
        function compensatedSignal = stepImpl(obj, filteredSignal)
            
            % Find the frequency used for correction (the negative of the
            % actual offset)
            FreqOffset = -step(obj.pCoarseFreqEst, filteredSignal);
            % Remove the frequency offset
            compensatedSignal = ...
                step(obj.pPhaseFreqOffset,filteredSignal,FreqOffset);
            
        end
        
        function resetImpl(obj)
            reset(obj.pPhaseFreqOffset);
            reset(obj.pCoarseFreqEst);
        end
        
        function releaseImpl(obj)
            release(obj.pPhaseFreqOffset);
            release(obj.pCoarseFreqEst);
        end
    end
end
