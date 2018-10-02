classdef BinaryFileReader < matlab.System
    % tx_waveform
    
    % Public, but non-tunable properties
    properties (Nontunable)
        Filename = '',
        SamplesPerFrame = 188
    end
    
    properties
        PlayCount = 1
    end
    
    % Pre-computed constants
    properties(Access = private)
        pFID = -1,
        pNumEofReached = 0
    end
    
    properties(Constant, Hidden)
        PadValue = 0
    end
    
    
    methods(Access = public)
        function obj = BinaryFileReader(varargin)
            setProperties(obj, nargin, varargin{:});
        end
        
        
    end
    
    methods(Access = protected)
        % initialize the object
        function setupImpl(obj)
            % Populate obj.pFID
            getWorkingFID(obj)
            
            % Go to start of data
            goToStartOfData(obj)
        end
        
        % execute the core functionality
        function y = stepImpl(obj)
            bs = obj.SamplesPerFrame;
            y = readBuffer(obj, bs);
        end
        function tf = isDoneImpl(obj)
            tf = logical(feof(obj.pFID));
        end
        function resetImpl(obj)
            goToStartOfData(obj);
            obj.pNumEofReached = 0;
        end
        
        % release the object and its resources
        function releaseImpl(obj)
            fclose(obj.pFID);
            obj.pFID = -1;
        end
        
        % indicate if we have reached the end of the file
        
        function loadObjectImpl(obj,s,wasLocked)
            % Call base class method
            loadObjectImpl@matlab.System(obj,s,wasLocked);
            
            % Re-load state if saved version was locked
            if wasLocked
                % All the following were set at setup
                
                % Set obj.pFID - needs obj.Filename (restored above)
                obj.pFID = -1; % Superfluous - already set to -1 by default
                getWorkingFID(obj);
                % Go to saved position
                fseek(obj.pFID, s.SavedPosition, 'bof');
                
                obj.pNumEofReached = s.pNumEofReached;
            end
            
        end
        
        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@matlab.System(obj);
            
            if isLocked(obj)
                % All the fields in s are properties set at setup
                s.SavedPosition = ftell(obj.pFID);
                s.pNumEofReached = obj.pNumEofReached;
            end
        end
    end
    
    methods(Access = private)
        
        function getWorkingFID(obj)
            if(obj.pFID < 0)
                [obj.pFID, err] = fopen(obj.Filename, 'r');
                if ~isempty(err)
                    error(message('FileReader:fileError', err));
                end
            end
            
        end
        
        function goToStartOfData(obj)
            fid = obj.pFID;
            frewind(fid);
        end
        
        
        function rawData = readBuffer(obj, numValues)
            bufferSize = obj.SamplesPerFrame;
            tmp = fread(obj.pFID, obj.SamplesPerFrame, 'uint8'); % Lire une trame
            
            numValuesRead = numel(tmp);
            
            if(numValuesRead == bufferSize)&&(~feof(obj.pFID))
                rawData = tmp;
            else
                % End of file - may also need to complete frame
                obj.pNumEofReached = obj.pNumEofReached + 1;
                if(obj.pNumEofReached < obj.PlayCount)
                    % Keep reading from start of file
                    goToStartOfData(obj)
                    moreData = readBuffer(obj, numValues-numValuesRead);
                    rawData = [tmp; moreData];
                else
                    % First pad with pad value, then reshape
                    padVector = repmat(obj.PadValue, ...
                        numValues - numValuesRead, 1);
                    rawData = [tmp; padVector];
                end
            end
            rawData = uint8(rawData);
        end
        
    end
end
