classdef bbConstants
% 
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This class stores all the constants required by the
%               Black-Box such as:
%                   - identifier string
%                   - other strings
%                   - physical constants
%                   - tolerances
%                   - conventions.
% ----------------------------------------------------------------------- %
   
   
   
   
    properties(Constant)
        % PHYSICAL CONSTANTS
        gravityAcceleration@double = 9.80665; % heat capacity of air @25degC, [J/kgK]
        
        
        % Masking for statisitc to speed up code
        stats_numPossibleStats = 3;
        stats_labels_ordered = { 'mean' , 'cov' , 'bounds_boxtype' };
        stats_index_ordered = [ 1 ; 2 ; 3 ];
        
      
        % CONVENTIONS
        NULL_str@string = 'NULL';
        NaN_str@string = 'NaN';
        ZERO_str@string = '0';
        EMPTY_str@string = '';
        num2str_precision@string = '%.10g';
        release_Matlab_OO@string = 'R2008a';
        release_Matlab_METACLASS@string = 'R2012a';
        matlab_matFileVersion_forSave = '-v7.3';
        
        % CLASS NAME
        something_classname_str@string = 'something';
        
        % TOLERANCES
        tol_ofSomething@double = 0.05; % tolerance for non-planarity of vertices in a building element [m]
        
        % VARIABLE NAMES
        state_varName@string = 'x';
        input_varName@string = 'u';
        uncertainty_varName@string = 'v';
        output_varName@string = 'y';
        
        
        % COLORS FOR PLOTS
        state_color@double                        = [0 0 1]; % blue
        building_element_color@double             = [1 1 0]; % yellow
        building_element_nomass_color@double      = [0.4 0 0]; % brown
        building_element_edge_color@double        = [1 0.6 0]; % orange
        window_color@double                       = [0.2 1 1]; % turquise
        window_edge_color@double                  = [0 0 1]; % blue
        alpha_transparency@double                 = 0.05;
        vertex_color@double                       = [1 0 0]; % red
        vertex_size@double                        = 50;
      
        % PLOT LABELS
        time@string = 'Time [hrs]';
        temperature@string = 'Temp [?C]';
        heatflux@string = 'Heat Flux [W]';
        input_u@string = 'Control input u';
        input_v@string = 'Disturbance v';
        output_y@string = 'Output y';
        tool_box_name@string = 'Building RC-Modelling Toolbox';
        figure_name_simulation@string = 'Simulation of Building';
        fig_scale_left@double = 1/16;
        fig_scale_bottom@double = 1/14;
        fig_scale_width@double = 6/7;
        fig_scale_height@double = 6/7;
      
        % STRINGS FOR MESSAGES
        errorMsg@string = 'Terminating now :-( See previous messages and ammend.';
      
        % STRING FOR FILE AND FOLDER NAMES
        saveDefPrefix@string               = 'savedModel_ForBuildingID_';
        saveDefExtension@string            = '.mat';

        loadDefFolderPrefix@string         = 'Def_';
        loadDefFolderSuffixTrue@string     = '_True';
        loadDefFolderSuffixError@string    = '_withModelError';
        
        loadDefFunctionPrefix@string                = 'Load_';
        loadDefFunctionPrefix_forBuilding@string    = 'load_BuildingDef_';
        
        
        
        % Fundamental Data-Type memory size
        double_sizeIn_bits                 = 64;
        double_sizeIn_bytes                = 8;
        
        
    end %properties(Constant)
   
    % We do not allow an instantion of this object
    methods(Access=private)
        % constructor
        function obj = bbConstants()
            % Nothing to do here
        end % Constants
    end %methods(Access=private)
   
    methods(Static)
        
        
        % -----------------------------------
        % FUNCTION: Check that an object is a subclass of another class
        function returnCheck = checkObjIsSubclassOf( inputObj , inputSuperclass , flag_throwError)
            % Check that the class of "inputObj" is a subclass of
            % "inputSuperclass":
            if ~sum(ismember(superclasses(inputObj),inputSuperclass))
                disp([' ... ERROR: The "',class(inputObj),'" class is NOT a subclass of the "',inputSuperclass,'" class']);
                % Only terminate if "errorFlag" requests it
                if (flag_throwError)
                    error(bbConstants.errorMsg);
                end
                returnCheck = 0;
            else
                returnCheck = 1;
            end
        end
        % END OF: "checkObjIsSubclassOf"
        
        % -----------------------------------
        % FUNCTION: Check that an object is a "concrete" class
        %      > This means the class has no Abstract properties or methods
        %      > (i.e. it implements all the Abstract properties and
        %           methods from its  Superclass)
        function returnCheck = checkObjConcrete( inputObj , flag_throwError)
            % Check that the class of "inputObj" is "concrete" 
            objMetaData = metaclass(inputObj);
            if objMetaData.Abstract
                disp([' ... ERROR: The class "',class(inputObj),'" is NOT a concrete class']);
                if flag_throwError
                    error(bbConstants.errorMsg);
                end
                returnCheck = 0;
            else
                returnCheck = 1;
            end
        end
        % END OF: "checkObjConcrete"
        
        
        
        % -----------------------------------
        % FUNCTION: 
        function returnPath = createOrEmptyFolderWithCopyOption( inputRootPath , inputFolderName , inputCopy )
            % Make the full path
            path_full = [ inputRootPath , inputFolderName , filesep ];
            % First check if the path exists
            % If it doesn't exist then make the folder
            if ~(exist(path_full,'dir') == 7)
                mkdir(path_full);
                
            % Else, if it does exist, then...
            else
                % If requested to copy the folder, then:
                if inputCopy
                    % Check if it is empty or not
                    tempContents_struct = dir(path_full);
                    tempContents_cell = struct2cell(tempContents_struct);
                    tempSize = sum(cell2mat(tempContents_cell(3,:)));
                    % If the total size of the content is greter than 1
                    % byte then copy it
                    if tempSize > 1
                         [~, ~, currDateStr, currTimeStr] = getCurrentTimeStrings();
                        copyPath = [ inputRootPath , 'zzz_' , currDateStr , '_' , currTimeStr , '_' , inputFolderName , filesep ];
                        copyfile( path_full , copyPath );
                    end
                end
                % Delete all contents of this folder
                delete( [path_full , '*'] )
            end
            % Finally set the return variable
            returnPath = path_full;
            
        end
        
        
        % -----------------------------------
        % FUNCTION: 
        function [returnPath , returnSuccess] = checkExistenceOfFolderAndFiles(rootPath , inputFolders, inputFiles , inputErrorMsg , flag_throwError)
            % Assume success, and set to false anytime an error is
            % encountered
            % NOTE: This is just one success flag for all folders and files
            % to be checked
            returnSuccess = true;
            
            % String for displaying "ERROR" or "NOTE"
            if flag_throwError
                alertText = 'ERROR';
            else
                alertText = 'NOTE';
            end
            
            % Check that the input are as expected
            if ~isempty(inputFolders)
                if iscell(inputFolders) || ischar(inputFolders)
                    if iscell(inputFolders)
                        numFolders = length(inputFolders);
                    else
                        numFolders = 1;
                        inputFolders = {inputFolders};
                    end
                else
                    returnSuccess = false;
                    disp([' ... ',alertText,': "inputFolders" was not input as a cell array']);
                    if flag_throwError
                        error(bbConstants.errorMsg);
                    end
                end
            else
                numFolders = 0;
            end
            if ~isempty(inputFiles)
                if iscell(inputFiles) || ischar(inputFiles)
                    if iscell(inputFiles)
                        numFiles = length(inputFiles);
                        if numFiles == 1
                            inputFiles = inputFiles{1,1};
                        end
                    else
                        numFiles = 1;
                    end
                else
                    returnSuccess = false;
                    disp([' ... ',alertText,': "inputFiles" was not input as a string or a cell array']);
                    if flag_throwError
                        error(bbConstants.errorMsg);
                    end
                end
            else
                numFiles = 0;
            end
            
            % This function starts from the input "root path", so set that
            % as the current path
            currPath = rootPath;
            
            % Iterate through the folders
            % Note that this function only checks for the list of folder to
            % be consecutively sub-folders of each-other
            for iFolder = 1 : numFolders
                % Get this folder
                thisFolder = inputFolders{iFolder};
                % Check for its existence
                if ~( exist([currPath , thisFolder],'dir') == 7 )
                    returnSuccess = false;
                    disp([' ... ',alertText,': the "',thisFolder,'" directorty could not be found']);
                    disp(['            while looking in path:   ',currPath]);
                    disp(inputErrorMsg);
                    if flag_throwError
                        error(bbConstants.errorMsg);
                    end
                end
                % Update the current path
                currPath = strcat(currPath , thisFolder , filesep);
            end
            
            % If no files, then return the current path
            if numFiles == 0
                returnPath = currPath;
            % If only 1 file, then handle this separately and return the
            % path directly as a string
            elseif numFiles == 1
                if ~( exist([currPath , inputFiles],'file') == 2 )
                    returnSuccess = false;
                    disp([' ... ',alertText,': the "',inputFiles,'" file could not be found']);
                    disp(['            while looking in path:   ',currPath]);
                    disp(inputErrorMsg);
                    if flag_throwError
                        error(bbConstants.errorMsg);
                    end
                end
                returnPath = strcat(currPath , inputFiles);
            else
                returnPath = cell(numFiles,1);
                % Now iterate through the 
                for iFile = 1 : numFiles
                    % Get this File Name
                    thisFile = inputFiles{iFile};
                    % Check for its existence
                    if ~( exist([currPath , thisFile],'file') == 2 )
                        returnSuccess = false;
                        disp([' ... ',alertText,': the "',thisFile,'" file could not be found']);
                        disp(['            while looking in path:   ',currPath]);
                        disp(inputErrorMsg);
                        if flag_throwError
                            error(bbConstants.errorMsg);
                        end
                    end
                    % Put the path to this file in the return variable
                    returnPath{iFile,1} = strcat(currPath , thisFile);
                end
            end
            
        end
        % END OF: "function ... = checkExistenceOfFolderAndFiles()
        
        
        % -----------------------------------
        % FUNCTION:
        function returnMask = stats_createMaskFromCellArray( inputStats )
            % Initialise the return variable to be all "false"
            returnMask = false(bbConstants.stats_numPossibleStats,1);
            
            for iStat = 1 : bbConstants.stats_numPossibleStats
                thisStat = bbConstants.stats_labels_ordered(iStat);
                if ismember(thisStat,inputStats)
                    returnMask(iStat,1) = true;
                end
            end
        end
        
        
        % -----------------------------------
        % FUNCTION:
        % Just use the built-in Matlab "etime" function
        function clockDiff = clockDifference( clockEnd , clockStart )
            hhmmss_diff = clockEnd(4:6) - clockStart(4:6);
            
            clockDiff = hhmmss_diff(1)*60*60 + hhmmss_diff(2)*60 * hhmmss_diff(1);
        end
        
        
    end
    % END OF: methods(Static)
    
end
% END OF: "classdef bbConstants"
