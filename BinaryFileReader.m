classdef BinaryFileReader < matlab.System 
% BinaryFileReader Read binary files
%   reader = dsp.BinaryFileReader returns a System object, reader, that
%   reads binary files. 
%
%   reader = dsp.BinaryFileReader('Name', Value, ...) returns a binary file
%   reader System object, reader, with each specified property name set to
%   the specified value. You can specify name-value pair arguments in any
%   order as (Name1,Value1,...,NameN, ValueN).
%
%   reader = dsp.BinaryFileReader(Name,'PropertyName', PropertyValue, ...)
%   returns a binary file reader object, reader, with the Filename property
%   set to Name, and other properties set to the specified values.
%
%   Step method syntax:
%
%   data = step(reader) reads data from the binary file. The dimensions,
%   complexity, and datatype of data are determined by the property
%   settings of the object.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj) and y = obj() are
%   equivalent.
%
%   BinaryFileReader methods:
%
%   step                     - See above description for use of this method
%   release                  - Allow property value and input 
%                              characteristics changes, and release binary 
%                              file reader resources
%   clone                    - Create file reader object with same property 
%                              values
%   isLocked                 - Display locked status (logical)
%   reset                    - Reset to the beginning of the file
%   isDone                   - Returns true if object has read beyond the 
%                              end-of-file
%   readHeader               - Read file header
%
%   BinaryFileReader properties:
%
%   Filename            - Name of the file from which to read data
%   HeaderStructure     - Structure of the header at the beginning of the
%                         file
%   SamplesPerFrame     - Number of rows in the output matrix
%   NumChannels         - Number of columns in the output matrix 
%   DataType            - Output datatype
%   IsDataComplex       - Specify data complexity
%
%   % EXAMPLE: Create a binary file with a custom header using a 
%   % dsp.BinaryFileWriter System object. Read the header and data from the
%   % file using a dsp.BinaryFileReader System object. 
%   % Specify the file header. 
%   header = struct('A',[1 2 3 4],'B','x7');
%   writer = dsp.BinaryFileWriter('ex_file.bin','HeaderStructure',header);
%  
%   % Write data to file. The header is automatically written before the
%   % data is written.
%   data = sin(2 * pi * (0:1000-1) / 500).' + 0.01 * randn(1000,1);
%   writer(data);
%   release(writer);
% 
%   % Knowledge of the header structure is assumed:
%   headerPrototype = struct('A',[0 0 0 0],'B','-0');
%   L = 150;
%   reader = dsp.BinaryFileReader(...
%                                'ex_file.bin',...
%                                'HeaderStructure',headerPrototype,...
%                                'NumChannels',1,'SamplesPerFrame',L);
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
%   plot(out(1:1000),'ro')
%   legend('Original data', 'Data read from file')
%   xlabel('Index')
%   ylabel('Data')
%
% See also: dsp.BinaryFileWriter, dsp.MatFileReader, dsp.MatFileWriter

% Copyright 2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
    
     properties (Nontunable, Dependent)
       %Filename File name
       %   Specify the name of the binary file as a character vector. 
       %   The full path for the file needs to be specified only if the 
       %   file is not on the MATLAB path. The default value of this 
       %   property is 'Untitled.bin'.
        Filename
     end
    
    properties (Logical, Nontunable)
        % IsDataComplex Data is complex
        % If the data stored in the file is complex, set this property to
        % true. Otherwise, set it to false. The default is false. 
        IsDataComplex = false;
    end
    
    properties (Nontunable, PositiveInteger)
        %NumChannels Number of channels
        % Specify the number of columns of the output matrix returned by
        % step. This property defines the number of consecutive interleaved
        % data samples stored in the file for each time instant. The
        % default is 1.
        NumChannels = 1
        %SamplesPerFrame Samples per frame
        % Specify the number of rows of the output matrix, data, returned
        % by step. The size of data is SamplesPerFrame-by-NumChannels. Once
        % the file reaches the end, if data is not full, the object fills
        % data with zeros to make it a fully-sized matrix.
        SamplesPerFrame = 1024 
    end
    
    properties (Dependent, Nontunable)
        %DataType Storage data type
        % Specify the storage class of the data in the file as
        % 'double','single','int8','int16','int32','int64', 'uint8',
        % 'uint16','uint32' or 'uint64'. This property defines the datatype
        % of the matrix returned by the step method. The default is
        % 'double'.
        DataType
    end
    
    properties (Nontunable, Dependent)
        % HeaderStructure Header structure 
        % Set this property if the data in the binary file is preceded by a 
        % header. Specify the header as a scalar structure. Each field of 
        % the structure must be a real matrix of a built-in type. For 
        % example, if HeaderStructure is set to 
        % struct('field1',1:10,'field2',single(1)), the object assumes
        % that the header is formed by 10 real double-precision values
        % followed by one single-precision value. You can retrieve the 
        % header from the file by calling the readHeader method. The 
        % default is struct('Field1',[]).
        HeaderStructure;
    end
    
    properties (Access = private)
        % Private properties used to handle the header structure
        pStruct          = struct('Field1',[]);
        pStructPrototype = struct('Field1',[]);
        % Holds most recently read samples
        pBuffer
    end
    
    properties(Access=protected, Constant)
       pNumFrames = 50; 
    end
    
     properties (Access = protected)
       pIndex = 1; 
     end
    
    properties (Access = protected)
       % pIsDone True if there are no more samples in the file 
       pIsDone
    end

    properties ( Nontunable , Access = private)
        % pHeaderBytes Number of bytes in the header
        pHeaderBytes
        % pspf Number of samples (per channel) to read every step
        pspf
    end
    
    properties ( Nontunable , Access = protected)
       % pFilename Cache file name
        pFilename = 'Untitled.bin'; 
    end
    
    properties(Access=protected)
        % Saved value of the file identifier
        pFID = -1
    end
    
    properties (Access=private,Nontunable)
        % Data type specification string consumed by fread within step
        pDataTypeSpec = '*double'
    end
    
    properties(Constant, Hidden)
        DataTypeSet = matlab.system.StringSet(...
            {'double','single','int8','int16','int32','int64',...
            'uint8','uint16','uint32','uint64'})
        pDataTypeSpecSet = matlab.system.StringSet(...
            {'*double','*single','*int8','*int16','*int32','*int64',...
            '*uint8','*uint16','*uint32','*uint64'})
    end
    
    methods
        % Constructor
        function obj = BinaryFileReader(varargin)
            setProperties(obj, nargin, varargin{:},'Filename');
            obj.pIsDone = false(1,obj.pNumFrames);
        end
        
        function set.Filename(obj,name)
            validateattributes( name, { 'char' }, { 'nonempty' }, '', 'Filename');
            coder.extrinsic('dsp.BinaryFileReader.getFilename');
            obj.pFilename = coder.const(@obj.getFilename,name);
        end
        
        function name = get.Filename(obj)
            name = obj.pFilename;
        end
        
        function set.HeaderStructure(obj,val)
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
            obj.pStruct = val;
            obj.pStructPrototype = val;
        end
        
        function val = get.HeaderStructure(obj)
            val = obj.pStructPrototype;
        end

        function set.DataType(obj,val)
            switch val
                case 'double'
                    obj.pDataTypeSpec = '*double';
                case 'single'
                    obj.pDataTypeSpec = '*single';
                case 'int8'
                    obj.pDataTypeSpec = '*int8';
                case 'int16'
                    obj.pDataTypeSpec = '*int16';
                case 'int32'
                    obj.pDataTypeSpec = '*int32';
                case 'int64'
                    obj.pDataTypeSpec = '*int64';
                case 'uint8'
                    obj.pDataTypeSpec = '*uint8';
                case 'uint16'
                    obj.pDataTypeSpec = '*uint16';
                case 'uint32'
                    obj.pDataTypeSpec = '*uint32';
                case 'uint64'
                    obj.pDataTypeSpec = '*uint64';
                otherwise
                    obj.pDataTypeSpec = '*double';
            end
        end
        
        function val = get.DataType(obj)
            switch obj.pDataTypeSpec
                case '*double'
                    val = 'double';
                case '*single'
                    val = 'single';
                case '*int8'
                    val = 'int8';
                case '*int16'
                    val = 'int16';
                case '*int32'
                    val = 'int32';
                case '*int64'
                    val = 'int64';
                case '*uint8'
                    val = 'uint8';
                case '*uint16'
                    val= 'uint16';
                case '*uint32'
                    val = 'uint32';
                case '*uint64'
                    val = 'uint64';
                otherwise
                    val = 'double';
            end
        end
             
        function S = readHeader(obj)
        % readHeader Read the file header
        %
        % S = readHeader(reader) returns the header structure, S, from the
        % file specified by the binary file reader, reader.  
        %
        % % Example
        % % Write a binary file
        % fid = fopen('myfile.dat','w');
        % % First, write a header. In this example, the header is a 1-by-4
        % % matrix  of double precision values, followed by a 5-by-1 
        % % vector of single-precision values: 
        % fwrite(fid,[1 2 3 4],'double');
        % fwrite(fid,single((1:5).'),'single');
        % % Write data
        % fwrite(fid,(1:1000).','double');
        % fclose(fid);
        % % Read the header using a dsp.BinaryFileReader object
        % reader = dsp.BinaryFileReader('myfile.dat');
        % % Specify the expected header structure:
        % s = struct('A',[0 0 0 0],'B',ones(5,1,'single'));
        % reader.HeaderStructure = s;
        % H = readHeader(reader);
        % fprintf('H.A: ')
        % fprintf('%d ',H.A);
        % fprintf('\nH.A datatype: %s\n',class(H.A))
        % fprintf('H.B: ')
        % fprintf('%d ',H.B);
        % fprintf('\nH.B datatype: %s\n',class(H.B))
        
        if obj.pFID == -1
            % Read header from the file if the object is not locked
            setupHeaderStruct(obj);
        end
        S = obj.pStruct;
        end
        
         % indicate if we have reached the end of the file
        function tf = isDone(obj)
%       isDone  True if reader has reached end-of-file
%       isDone(READER) returns true if the binary file reader, READER, has
%       reached the end of the file
            tf = obj.pIsDone(obj.pIndex);
        end

    end
    
    % Overridden implementation methods
    methods(Access = protected)
        % initialize the object
        function setupImpl(obj)
            
            reoslvedName = setupHeaderStruct(obj);
            
            % Populate obj.pFID
            getWorkingFID(obj,reoslvedName)
            obj.pHeaderBytes =  getStructSize(obj);
            if ~obj.IsDataComplex
                obj.pspf =  obj.SamplesPerFrame;
            else
                obj.pspf = 2  * obj.SamplesPerFrame;
            end
            obj.pBuffer = zeros(obj.pspf * obj.NumChannels,obj.pNumFrames,obj.DataType);
        end
        
        function sz = getStructSize(obj)
            sz = 0;
            fnames = fieldnames(obj.HeaderStructure);
            for index = 1:length(fnames)
                val =  obj.HeaderStructure.(fnames{index});
                sz = sz + numel(val) * getDTSize(val);
            end
        end
        
        % reset the state of the object
        function resetImpl(obj)
            % Go to the beginning of the file and skip header bytes
            goToStartOfData(obj)
            obj.pIsDone = false(1,obj.pNumFrames);
            obj.pBuffer = reshape(readData(obj) , obj.pspf * obj.NumChannels,obj.pNumFrames );
            obj.pIndex      = 1;
        end
        
        % execute the algorithm
        function y = stepImpl(obj)
            
            % Form output
            ind = obj.pIndex;
            rawData = obj.pBuffer(:,ind);
            if ~obj.IsDataComplex
                y = reshape(rawData,obj.NumChannels,[]).';
            else
                z = reshape(rawData,2 * obj.NumChannels,[]).';
                y = complex(zeros(obj.SamplesPerFrame,obj.NumChannels,obj.DataType)  , zeros(obj.SamplesPerFrame,obj.NumChannels,obj.DataType)) ;
                for index = 1:obj.NumChannels
                    y(:,index) = complex(z(:,(index-1)*2+1),z(:,(index-1)*2+2));
                end
            end
            ind = ind + 1;
            
            % Refresh buffer
            if ind == obj.pNumFrames + 1
                obj.pBuffer = reshape(readData(obj) , obj.pspf * obj.NumChannels,obj.pNumFrames );
                ind = 1;
            end
            
            obj.pIndex = ind;
            
        end
        
        % release the object and its resources
        function releaseImpl(obj)
            fclose(obj.pFID);
            obj.pFID = -1;
           obj.pIsDone = false(1,obj.pNumFrames);
        end
        
        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@matlab.System(obj); 
            s.pFilename        = obj.pFilename;
            s.pDataTypeSpec    = obj.pDataTypeSpec;
            s.pStructPrototype = obj.pStructPrototype;
            s.SaveLockedData = false;
        end
        
        function obj = loadObjectImpl(obj,s,wasLocked)
             % Call base class method
             obj.pFilename        = s.pFilename;
             obj.pDataTypeSpec    = s.pDataTypeSpec;
             obj.pStructPrototype = s.pStructPrototype;
             loadObjectImpl@matlab.System(obj,s,wasLocked);
        end
        
       function resolvedName = setupHeaderStruct(obj)
            
            resolvedName = resolveFileName(obj);
            fnames = fieldnames(obj.HeaderStructure);
            fid = fopen(resolvedName, 'r');
            for index = 1:length(fnames)
                val = obj.HeaderStructure.(fnames{index});
                dt = class(val);
                L  = numel(val);
                if islogical(val)
                    tmp0 = fread(fid, L, '*uint8');
                    tmp_ = cast(tmp0,'logical');
                else
                    dt_read = ['*' dt]; 
                    tmp_ = fread(fid, L, dt_read);
                end
                sz = size(val);
                tmp  = reshape(tmp_.',[sz(2) sz(1)]).';
                obj.pStruct.(fnames{index}) = tmp;
            end
            fclose(fid);
       end
       
       function resolvedName = resolveFileName(obj)
            coder.extrinsic('dsp.BinaryFileReader.checkFileName');
            resolvedName = coder.const(@dsp.BinaryFileReader.checkFileName,obj.pFilename);
       end
        
    end
    
    methods(Access = private)
        
        function getWorkingFID(obj,resolvedName)
            if(obj.pFID < 0)
                obj.pFID = fopen(resolvedName, 'r');
                coder.internal.errorIf(obj.pFID<0,...
                    'dsp:binaryfileio:FileError');
            end
        end
        
        function goToStartOfData(obj)
            fid = obj.pFID;
            frewind(fid)
            fread(fid, obj.pHeaderBytes);
        end
        
        function rawData = readData(obj)
            
            numChannels = obj.NumChannels;
            numRows     = obj.pNumFrames * obj.pspf;

            dt = obj.pDataTypeSpec;
            
            [tmp, numValuesRead] = fread(obj.pFID, numChannels*numRows, dt);
            
            numRowsRead = floor(numValuesRead/numChannels);
            if(numRowsRead == numRows)&&(~feof(obj.pFID))
                rawData = tmp(1:numChannels*numRows,:);
            else
                rawData = zeros(numRows*numChannels,1,obj.DataType);
                rawData( 1:numValuesRead) = tmp(1:numValuesRead);
            end
            
            nframes = obj.pNumFrames;
            MinSamples  = 1:numChannels*numRows/nframes:numChannels*numRows/nframes * (nframes-1) + 1;
            obj.pIsDone(:) = numValuesRead < MinSamples;
             
        end
    end
    
    %%  header - widget grouping
    methods(Static, Access=protected)
        function group = getPropertyGroupsImpl
            % Modify order of display
            group =  matlab.system.display.Section(...
                'Title', getString(message('dsp:system:Shared:Parameters')), ...
                'PropertyList', {'Filename',...
                'HeaderStructure','SamplesPerFrame',...
                'NumChannels','DataType','IsDataComplex'},...
                'DependOnPrivatePropertyList',{'Filename','HeaderStructure','DataType'});
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
        
        function name = checkFileName(name)
            exists = fileattrib(name);
            coder.internal.errorIf(~exists, ['dsp:binaryfileio',...
                    ':FileDoesNotExist']); 
        end
        

    end
    
end

function sz = getDTSize(val)

switch class(val)
    case 'logical'
        sz = 1;
    case 'double'
        sz = 8;
    case 'single'
        sz = 4;
    case 'int8'
        sz = 1;
    case 'int16'
        sz = 2;
    case 'int32'
        sz = 4;
   case 'int64'
        sz = 8;
    case 'uint8'
        sz = 1;
    case 'uint16'
        sz = 2;
    case 'uint32'
        sz = 4;
    case 'uint64'
        sz = 8;
    case 'char'
        sz = 1;
end


end

function flag = checkDatatype(val)

flag = isa(val,'double') || isa(val,'single') || isa(val,'int8') || ...
       isa(val,'uint8')  || isa(val,'int16') || isa(val,'uint16') || ...
       isa(val,'int32')  || isa(val,'uint32') || isa(val,'int64') || ...
       isa(val,'uint64')  || isa(val,'logical') || isa(val,'char');

end