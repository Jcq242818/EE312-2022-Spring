classdef QPSKChannelR < matlab.System 
%#codegen
    
%   Copyright 2012-2013 The MathWorks, Inc.
   
    
    properties (Nontunable)
        DelayType = 'Triangle';
        RaisedCosineFilterSpan = 10;
        PhaseOffset = 47;
        SignalPower = 0.25;
        FrameSize = 100;
        UpsamplingFactor = 4;
        EbNo = 7;
        BitsPerSymbol = 2;
        FrequencyOffset = 5000;
        SampleRate = 200000;
    end
    
    properties (Access=private)
        pPhaseFreqOffset
        pVariableTimeDelay
        pAWGNChannel
    end
    
    properties (Constant, Access=private)
        pDelayStepSize = 0.05;
        pDelayMaximum = 8;
        pDelayMinimum = 0.1;
    end
    
    methods
        function obj = QPSKChannelR(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj, ~, ~)
            obj.pPhaseFreqOffset = comm.PhaseFrequencyOffset(...
                'PhaseOffset', obj.PhaseOffset, ...
                'FrequencyOffset', obj.FrequencyOffset, ...
                'SampleRate',obj.SampleRate);
            obj.pVariableTimeDelay = dsp.VariableFractionalDelay(...
                'MaximumDelay', obj.FrameSize*obj.UpsamplingFactor);
            obj.pAWGNChannel = comm.AWGNChannel('EbNo', obj.EbNo, ...
                'BitsPerSymbol', obj.BitsPerSymbol, ...
                'SignalPower', obj.SignalPower, ...
                'SamplesPerSymbol', obj.UpsamplingFactor);
         end
        
        
        function corruptSignal = stepImpl(obj, TxSignal, count)
            
            % Calculates the delay 
            if strcmp(obj.DelayType,'Ramp')
                delay = ...
                    min(((count - 1) * obj.pDelayStepSize + obj.pDelayMinimum), ...
                    (obj.FrameSize-obj.RaisedCosineFilterSpan) ...
                    *obj.UpsamplingFactor); % Variable delay taking the form of a ramp
            else
                % Variable delay taking the shape of a triangle
                index = mod(count-1,2*obj.pDelayMaximum/obj.pDelayStepSize);
                if index <= obj.pDelayMaximum/obj.pDelayStepSize
                    delay = index * obj.pDelayStepSize;
                else
                    delay = 2*obj.pDelayMaximum - index * obj.pDelayStepSize;
                end
            end
            
            % Signal undergoes phase/frequency offset
            rotatedSignal = step(obj.pPhaseFreqOffset,TxSignal);
            
            % Delayed signal
            delayedSignal = step(obj.pVariableTimeDelay, rotatedSignal, 0);
            
            % Signal passing through AWGN channel
            corruptSignal = step(obj.pAWGNChannel, delayedSignal);
            
        end
        
        function resetImpl(obj)
            reset(obj.pPhaseFreqOffset);
            reset(obj.pVariableTimeDelay);            
            reset(obj.pAWGNChannel);
        end
        
        function releaseImpl(obj)
            release(obj.pPhaseFreqOffset);
            release(obj.pVariableTimeDelay);            
            release(obj.pAWGNChannel);            
        end
        
        function N = getNumInputsImpl(~)
            N = 2; 
        end
    end
end

