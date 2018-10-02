classdef AppendBinaryFileWriter < matlab.System &  matlab.system.mixin.CustomIcon
% BinaryFileWriter Write binary files
%   writer = dsp.BinaryFileWriter returns a System object, writer, that
%   writes data to binary files. 
%
%   writer = dsp.BinaryFileWriter('Name', Value, ...) returns a binary file
%   writer System object, writer, with each specified property name set to
%   the specified value. You can specify name-value pair arguments in any
%   order.
%
%   writer = dsp.BinaryFileWriter(Name,'PropertyName', PropertyValue, ...)
%   returns a binary file writer object, writer, with the Filename property
%   set to Name, and other properties set to the specified values.
%
%   Step method syntax:
%
%   step(writer,data) writes data to the binary file. 
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, step(obj, x) and obj(x) are equivalent.
%
%   BinaryFileWriter methods:
%
%   step                     - See above description for use of this method
%   release                  - Allow property value and input 
%                              characteristics changes, and release binary  
%                              file writer resources
%   clone                    - Create file writer object with same property 
%                              values
%   isLocked                 - Display locked status (logical)
%   reset                    - Reset to the beginning of the file
%
%   BinaryFileWriter properties:
%
%   Filename            - Name of the file to which to write data
%   HeaderStructure     - Header to write at the beginning of the file
%
%   % EXAMPLE: Create a binary file with a custom header using a 
%   % dsp.BinaryFileWriter System object. Read the header and data from the
%   % file using a dsp.BinaryFileReader System object. 
%   % Specify the file header. 
%   header = struct('A',[1 2 3 4],'B','x7');
%   writer = dsp.BinaryFileWriter('ex_file.bin','HeaderStructure',header);
%  
%   % Write data to file. The header is automatically written before data 
%   % is written.
%   data = sin(2 * pi * (0:1000-1) / 500).' + 0.01 * randn(1000,1);
%   writer(data);
%   release(writer);
% 
%   headerPrototype = struct('A',[0 0 0 0],'B','-0');
%   L = 150;
%   reader = dsp.BinaryFileReader(...
%                   'ex_file.bin','HeaderStructure',headerPrototype,...
%                   'NumChannels',1,'SamplesPerFrame',L);
%   out = zeros(ceil(1000/L) * L,1);
%   % Read header data from the file:
%   header = readHeader(reader);
%   fprintf('header.A: ')
%   fprintf('%d ',header.A)
%   fprintf('\nheader.B: ')
%   fprintf('%s ',header.B)
%   fprintf('\n');
%   index = 1;
%   % Read data until EOF is reached:
%   while ~isDone(reader)
%      out((index-1)*L + 1:index*L,:) = reader();
%      index = index + 1;
%   end
%   release(reader)
%   plot(data,'b-','LineWidth',4)
%   hold on;
%   grid on;
%   plot(out(1:1000),'ro-')
%   legend('Original data', 'Data read from file')
%   xlabel('Index')
%   ylabel('Data')
%
% See also: dsp.BinaryFileReader, dsp.MatFileReader, dsp.MatFileWriter

% Copyright 2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>

    properties (Nontunable, Dependent)
       %Filename File name
        %   Specify the name of the binary file as a character vector. The
        %   full path for the file needs to be specified only if the file
        %   is not on the MATLAB path. The default value of this property
        %   is 'Untitled.bin'.
        Filename
    end
    
    properties (Nontunable)
        %HeaderStructure File header
        % Set this property if you want to write a header to the file prior
        % to the data.  Specify the header as a scalar structure. Each
        % field of the structure must be a real matrix of a built-in type.
        % For example, if HeaderStructure is set to
        % struct('field1',1:10,'field2',single(1)), the object will write
        % a header formed of 10 double-precision values, (1:10), followed
        % by one single-precision value, single(1). The default is
        % struct([]).
        HeaderStructure = struct([])
        FilePermission = 'a'
    end
    
    properties(Access=private)
        % Saved value of the file identifier
        pFID = -1
        pWroteHeader
        pCount
        pBuffer
    end
    
    properties(Access=private, Logical, Nontunable)
        % pIsReal Cache complexity of input
       pIsReal 
    end
    
    properties(Access=private, Nontunable)
        % C-style data type used by write data to file. Useful in
        % particular when the input to step uses a MATLAB generic
        % fixed-point data type
        pDataType
        pLimit
        pFrameSize
        pNumChans
        pFilename = 'Untitled.bin'
    end
    
    methods
        % Constructor
        function obj = AppendBinaryFileWriter(varargin)
            setProperties(obj, nargin, varargin{:},'Filename');
        end
        
        function set.Filename(obj,name)
            validateattributes( name, { 'char' }, { 'nonempty' }, '', 'Filename');
            coder.extrinsic('dsp.BinaryFileWriter.getFilename');
            obj.pFilename = coder.const(@obj.getFilename,name);
        end
        
        function val = get.Filename(obj)
          val =  obj.pFilename;
        end
        
        function set.HeaderStructure(obj,val)
            % Validate structure
            validateattributes(val, {'struct'}, {},'','HeaderStructure')
            coder.internal.errorIf(~isscalar(val) && ~isempty(val)  , 'dsp:binaryfileio:HeaderNotScalar');
            if ~isempty(val)
                coder.internal.errorIf(~all(structfun(@ismatrix,val)),...
                    'dsp:binaryfileio:HeaderNotMatrix');
                coder.internal.errorIf(~all(structfun(@checkDatatype,val)),...
                    'dsp:binaryfileio:HeaderDatatype');
                coder.internal.errorIf(~all(structfun(@isreal,val)),...
                    'dsp:binaryfileio:HeaderNotReal');
            end
            obj.HeaderStructure = val;
        end
        
    end
    
    % Overridden implementation methods
    methods(Access = protected)
        
        % initialize the object
        function setupImpl(obj,u)
            
            coder.extrinsic('dsp.BinaryFileWriter.checkFilename');
            obj.checkFilename(obj.pFilename);
            
            % Populate obj.pFID
            getWorkingFID(obj, obj.FilePermission)

            % Store data precision
            obj.pDataType = getPrecision(obj, u);

            obj.pFrameSize = size(u,1);
            obj.pNumChans  = size(u,2);
            obj.pLimit     = max(floor(1000*1e3/obj.pFrameSize),1);
            obj.pIsReal    = isreal(u);
            
            if obj.pIsReal
                obj.pBuffer = zeros(obj.pFrameSize*obj.pLimit,obj.pNumChans, obj.pDataType);
            else
                obj.pBuffer = zeros(obj.pFrameSize*obj.pLimit,2 * obj.pNumChans, obj.pDataType);
            end
        end
      
        
        % reset the state of the object
        function resetImpl(obj)
            
            frewind(obj.pFID)
            
            % Write header
            writeHeader(obj)
            
            obj.pBuffer = zeros(size(obj.pBuffer),'like',obj.pBuffer);
            obj.pCount = 0;
        end
        
        function stepImpl(obj,u)

            if(obj.pIsReal)
                ri = u;
            else
                % If input is complex, interleave real and imag parts as
                % separate adjacent channels
                ri = zeros(size(u,1),2*size(u,2),'like',u);
                ri(:,1:2:end) = real(u);
                ri(:,2:2:end) = imag(u);
            end

            p = obj.pCount;
            p = p + 1;

            spf = obj.pFrameSize;
            obj.pBuffer((p-1)*spf+1:p*spf,:) = real(ri);

            if p == obj.pLimit
              p = 0;
              fwrite(obj.pFID, obj.pBuffer.', obj.pDataType);
            end

            obj.pCount = p;
        end
        
        % release the object and its resources
        function releaseImpl(obj)
            % Write data in buffer
            fwrite(obj.pFID, obj.pBuffer(1:obj.pCount*obj.pFrameSize,:).', obj.pDataType);
            fclose(obj.pFID);
            obj.pFID = -1;
        end
 
        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@matlab.System(obj); 
            s.pFilename        = obj.pFilename;
            s.SaveLockedData = false;
        end
        
        function obj = loadObjectImpl(obj,s,wasLocked)
             % Call base class method
             obj.pFilename        = s.pFilename;
            loadObjectImpl@matlab.System(obj,s,wasLocked);
        end
              
       function icon = getIconImpl(~)
          icon = getString(message('dsp:binaryfileio:BinaryFileWriterIcon'));
       end

       function s = getInputNamesImpl(~)
           s = '';
       end
       
       function flag = isInputComplexityLockedImpl(~,~)
          flag = true;
       end
       
       function flag = isInputSizeLockedImpl(~,~)
          flag = true; 
       end
       
       function validateInputsImpl(~,u)
           validateattributes(u, {'double','single','int64','uint64',...
                                 'int32','uint32','int16','uint16',...
                                 'int8','uint8'}, {'2d'},'','')
       end
        
    end
    
    methods(Access = private)

        function getWorkingFID(obj, permission)
            if(obj.pFID < 0)
                obj.pFID = fopen(obj.Filename, permission);
                coder.internal.errorIf(obj.pFID<0,...
                    'dsp:binaryfileio:FileError');
            end
        end
        
        function fmt = getPrecision(~, x)
            switch(class(x))
                case {'double','single',...
                        'int64','uint64','int32','uint32',...
                        'int16','uint16','int8','uint8','char'}
                    fmt = class(x);
                case {'logical'}
                    fmt = 'uint8';
                otherwise

            end
        end
        
        function writeHeader(obj)
            % Get header data type
            f = fieldnames(obj.HeaderStructure);
            for index = 1:length(f)
                h = obj.HeaderStructure.(f{index});
                headerDataType = getPrecision(obj, h);
                fwrite(obj.pFID, h.', headerDataType);
            end
        end
        
    end
    
     methods (Static, Hidden)
         
         function name = getFilename(fname)
            name = which(fname);
            if isempty(name)
                name = fname;
            end
            name = strrep(name,'\','/');
         end
        
        function checkFilename(FILE)
            [PATHSTR,NAME,EXT] = fileparts(FILE);
            if ~isempty(PATHSTR)
                
                % check path
                coder.internal.errorIf(~isdir(PATHSTR), ['dsp:binaryfileio',...
                    ':FilePathDoesNotExist']); 
            end
            
            % check name
            coder.internal.errorIf(~isempty(regexp(NAME, '[/\*:?"<>|]', 'once')) && ~isempty(NAME), ['dsp:binaryfileio',...
                    ':InvalidFilename']); 
                
            % check extension
            coder.internal.errorIf(~isempty(regexp(EXT, '[/\*:?"<>|]', 'once')), ['dsp:binaryfileio',...
                    ':InvalidFileExtension']); 
        end
     end
     
    %% Block header - widget grouping
    methods(Static, Access=protected)
        function group = getPropertyGroupsImpl
            % Modify order of display
            group =  matlab.system.display.Section(...
                'Title', getString(message('dsp:system:Shared:Parameters')), ...
                'PropertyList', {'Filename','HeaderStructure'},...
                                 'DependOnPrivatePropertyList',{'Filename'});
                             
        end
        %------------------------------------------------------------------
        function header = getHeaderImpl
            % MATLAB System block header
            header = matlab.system.display.Header(...
                'dsp.BinaryFileWriter', ...
                'ShowSourceLink', true, ...
                'Title', getString(message('dsp:binaryfileio:BinaryFileWriterTitle')),...
                'Text',  getString(message('dsp:binaryfileio:BinaryFileWriterHeader')));
        end
    end
end

function flag = checkDatatype(val)

flag = isa(val,'double') || isa(val,'single') || isa(val,'int8') || ...
       isa(val,'uint8')  || isa(val,'int16') || isa(val,'uint16') || ...
       isa(val,'int32')  || isa(val,'uint32') || isa(val,'int64') || ...
       isa(val,'uint64')  || isa(val,'logical') || isa(val,'char');
end
