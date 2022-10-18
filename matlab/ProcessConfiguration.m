classdef ProcessConfiguration
    % This class encapsulates the reading (and writing?) of the xml input
    % file, so that all the functions that process the data simply query
    % this object rather than parse the xml file. Encapsulating it makes it
    % easy to replace this for a specific project's processing framework,
    % or extend it for more configuration files.
    % 
    % All of the XML reading is in here - no one else should be parsing the
    % file.
    
    properties
        inputfilename; % The full path to the file
    end
    
    % Calculated properties
    properties (Dependent=true)
       fileRoot;
       outputRoot;
       
       % Output Path
       analysisPath;  
       generatedDicomPath;
       
       sourceScans;         % cell array of all the water references scans
       sourceFileFormat;    % The source file format
              
    end
    
    properties (Access='protected')
        xpath;  % The xpath object used for querying
        doc;    % The xml document used for parsing
    end
       
    methods
        function obj = ProcessConfiguration(fname)
            if nargin<1
                % Default constructor
            %elseif isa(obj, 'ChoQuantConfiguration');
                % TODO: copy all internal values
            elseif ischar(fname)
                % Parse the input file
                obj.inputfilename = fname;
                obj = parseInputFile(obj);
            else
                error('cannot create an object with a %s', class(s));
            end
        end
        
        function value = getOption(obj, name)
            val = obj.xpath.evaluate(...
                sprintf('/input/options/%s', name), obj.doc);
            if(val.isEmpty() )
                % None specified
                value = '';
            else
                value = char(val);
            end
        end       
               
        
        function cleanOutput(obj)
                  
            % Analyzed
            if exist(obj.analysisPath)
                cmd = sprintf('\\rm -r %s', obj.analysisPath);
                fprintf('removing analyzed dir: %s\n', cmd);
                system(cmd);
            end

            % generatedDicomPath
            if exist(obj.generatedDicomPath)
                cmd = sprintf('\\rm -r %s', obj.generatedDicomPath);
                fprintf('removing generated-dicom dir: %s\n', cmd);
                system(cmd);
            end
            
            % Copy of input file, in output root
            inputCopy = fullfile(obj.outputRoot, 'inputFileCopy.xml');
            if exist(inputCopy)
                cmd = sprintf('\\rm %s', inputCopy);
                fprintf('removing input file copy: %s\n', cmd);
                system(cmd);
            end
                        
            % Logs
            cmd = sprintf('\\rm %s%sanalysis*.log', obj.outputRoot, filesep);
            fprintf('removing log files: %s\n', cmd);
            system(cmd);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get methods for dependent properties
        function fileroot = get.fileRoot(obj)
            val = obj.xpath.evaluate('/input/fileroot', obj.doc);
            if(val.isEmpty() )
                fileroot = getInputFilePath();
            else
                fileroot = char(val);
            end
        end
        
        function outputRoot = get.outputRoot(obj)
            val = obj.xpath.evaluate('/input/output/output-root', obj.doc);
            if(val.isEmpty() )
                outputRoot = getInputFilePath();
            else
                outputRoot = fullfile(obj.fileRoot, char(val));
            end
        end
        
        function sourceScans = get.sourceScans(obj)
            % Returns a string array of the water reference scans, inorder
            numscans = str2num(...
                obj.xpath.evaluate('/input/source-data/count(name)', obj.doc));
            for idx=1:numscans
                val = obj.xpath.evaluate(...
                    sprintf('/input/source-data/name[%d]', idx), ...
                    obj.doc);
                sourceScans{idx} = ...
                    fullfile(obj.fileRoot, char(val));
            end
        end
        
        function sourceFileFormat = get.sourceFileFormat(obj)
            % This should be specified explicitly. Optionally, can figure
            % it out
            val = obj.xpath.evaluate('/input/source-data/format', obj.doc);
            if(val.isEmpty() )generateDatasetReport.m
                % None specified
                sourceFileFormat = 'UNKNOWN';
            else
                sourceFileFormat = char(val);
            end
        end        

        
        function analysisPath = get.analysisPath(obj)
            % Can be explicit; otherwise append "analysis" to the
            % outputRoot
            val = obj.xpath.evaluate('/input/output/analysis', obj.doc);
            if(val.isEmpty() )
                % None specified
                analysisPath = fullfile(obj.outputRoot, 'analysis');
            else
                analysisPath = fullfile(obj.fileRoot, char(val));
            end
        end

        function generatedDicomPath = get.generatedDicomPath(obj)
            % Can be explicit; otherwise append "generated-dicom" to the
            % outputRoot
            val = obj.xpath.evaluate('/input/output/generated-dicom', obj.doc);
            if(val.isEmpty() )
                % None specified
                generatedDicomPath = fullfile(obj.outputRoot, 'generated-dicom');
            else
                generatedDicomPath = fullfile(obj.fileRoot, char(val));
            end
        end
        
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Protected methods
    methods (Access='protected')
        
        function obj = parseInputFile(obj)
            % Read the input file
            obj.xpath = ProcessConfiguration.get_xpath();
            obj.doc = ProcessConfiguration.load_xml_doc(obj.inputfilename);
        end
                       
        function inputFilePath = getInputFilePath(obj)
            [inputFilePath, x, y, z] = fileparts(obj.inputfilename);
        end
           
    end
    
    methods (Static=true)
        %%%%%%%%%%%%%%%%%%%%%
        % XML Parsing helpers. These are normally on my path, but there
        % here to make sure they always work
        function xpath = get_xpath()
            import javax.xml.xpath.*
            
            xpf = XPathFactory.newInstance();
            xpath = xpf.newXPath();
        end
        
        
        % Filename must be full path!
        function doc = load_xml_doc(filename)
            import javax.xml.parsers.*
            
            % First load the doc and parse it
            factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            builder = factory.newDocumentBuilder();
            doc = builder.parse(filename);
        end
        
        
    end
    
end