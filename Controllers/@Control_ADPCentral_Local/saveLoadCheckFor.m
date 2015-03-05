function [returnSuccess , returnResult] = saveLoadCheckFor( inputInstruction , inputSpecs )
% Defined for the "ADPCentral" controller class, this function will be used
% to save, load, or check for the existence of, a "P" or "K" matrix that
% were computed for a specific set of input arguments
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %    

    % 

    
    %% ----------------------------------------------------------------- %%
    %% DEFINE THE SET OF POSSIBLE "inputInstruction"
    inputInstruction_options = ...
        {   'load' ;...
            'save' ;...
            'check_P' ;...
            'check_K_PWA' ;...
        };
    
    if ~ismember(inputInstruction , inputInstruction_options)
        disp( ' ERROR: the "inputInstruction" was not recognised, it was:' );
        display(inputInstruction);
        returnSuccess = false;
        returnResult = [];
        return;
    end
    
    
    %% ----------------------------------------------------------------- %%
    %% DEFINE THE FIELDS THAT NEED TO BE CHECKED/SAVED FOR IDENTIFYINF A RESULT
    varargin_fields_forComputing_P = ...
        {   'modelID' ;...
            'disturbanceID' ;...
            'predHorizon' ;...
            'computeVEveryNumSteps' ;...
            'ADPMethod' ;...
            'systemDynamics' ;...
            'bellmanIneqType' ;...
            'PMatrixStructure' ;...
            'computeAllVsAtInitialisation' ;...
            'usePreviouslySavedVs' ;...
            'VFitting_xInternal_lower' ;...
            'VFitting_xInternal_upper' ;...
            'VFitting_xExternal_lower' ;...
            'VFitting_xExternal_upper' ;...
        };
        
    varargin_fields_forComputing_K_PWA = ...
    {   'usePWAPolicyApprox' ;...
        'liftingNumSidesPerDim' ;...
    };
    
    
    

    %% ----------------------------------------------------------------- %%
    %% SWITCH BETWEEN THE DIFFERENT POSSIBLE "inputInstructions"
    
    switch inputInstruction
        
        %% ------------------------------------------------------------- %%
        %% CHECK FOR EXISTENCE OF A MATCHING ENTRY
        case {'check_P' , 'check_K_PWA'}
            
            % FIRST CHECK THAT WE HAVE A MATCHING SET OF "P" MATRICES
            flag_matchFound = false;

            mySaveDataPath = constants_MachineSpecific.saveDataPath;
            adpFolderName = 'ADP_SavedControllers';
            adpFolderPath_full = [ mySaveDataPath , adpFolderName , filesep ];
            % Check that there is already a folder of the ADP matrices
            if (exist(adpFolderPath_full,'dir') == 7)

                % Now check if there is already a index file for what controllers
                % are saved
                adpIndexFileName = 'adp_SavedControllersIndex';
                adpIndexFileName_full = [ adpFolderPath_full , adpIndexFileName , '.mat' ];

                % If it exists then load it 
                if (exist(adpIndexFileName_full,'file') == 2)
                    tempload = load( adpIndexFileName_full );
                    adpIndex = tempload.adpIndex;
                    
                    % At this point, the rest of the check depends of
                    % whether we are checking for "P" or "K"
                    if strcmp( inputInstruction , 'check_P' )
                        % First check that the field "P" even exists
                        if isfield( adpIndex , 'P' );
                            this_adpIndex = adpIndex.P;
                            varargin_fields_forComputing = varargin_fields_forComputing_P;
                        else
                            returnSuccess = false; returnResult = [];
                            return;
                        end
                    elseif strcmp( inputInstruction , 'check_K_PWA' )
                        % First check that the field "K" even exists
                        if isfield( adpIndex , 'K' );
                            this_adpIndex = adpIndex.K;
                            varargin_fields_forComputing = varargin_fields_forComputing_K;
                        else
                            returnSuccess = false; returnResult = [];
                            return;
                        end
                    else
                        % THIS SHOULDN'T HAVE BECAUSE THIS CASE ONLY ALLOWS
                        % "check_P" and "check_K_PWA"
                        returnSuccess = false; returnResult = [];
                        return;
                    end
                    
                    % Get the length of the ADP index
                    apdIndexLength = size(this_adpIndex,1);

                    % Get the info about "vararginLocal" (equivalently
                    % "inputSpecs" because it won't change at each
                    % iteration of the following for loop
                    inputSpecs_fields  = fields(inputSpecs );
                    tempThrowError = false;
                    check_inputSpecsHasRequiredFields = bbConstants.checkForFields( inputSpecs_fields , varargin_fields_forComputing , tempThrowError );
                    numFieldsToCheck_forComputing = length( varargin_fields_forComputing );

                    % Now look for a match for the "P" part of the save files
                    for iIndex = 1:apdIndexLength
                        thisEntry = this_adpIndex{iIndex,1}.vararginLocal;
                        thisEntry_fields = fields(thisEntry);

                        % Check that this entry also has has the required fields
                        tempThrowError = false;
                        check_thisEntryHasRequiredFields = bbConstants.checkForFields( thisEntry_fields , varargin_fields_forComputing , tempThrowError );

                        if check_thisEntryHasRequiredFields && check_inputSpecsHasRequiredFields
                            flag_mathcingFieldData = true;
                            % Now check that the data in each field is the
                            % same
                            for iField = 1:numFieldsToCheck_forComputing
                                thisFieldName = varargin_fields_forComputing_P{iField,1};
                                thisFieldData = thisEntry.(thisFieldName);
                                if isa( thisFieldData , 'double' ) || isa( thisFieldData , 'logical' )
                                    if thisFieldData ~= inputSpecs.(thisFieldName)
                                        flag_mathcingFieldData = false;
                                    end
                                elseif isa( thisFieldData , 'char' )
                                    if ~strcmp( thisFieldData , inputSpecs.(thisFieldName) )
                                        flag_mathcingFieldData = false;
                                    end
                                else
                                    flag_mathcingFieldData = false;
                                end
                            end
                            if flag_mathcingFieldData
                                flag_matchFound = true;
                                index_ofMatchFound = iIndex;
                            end
                        end
                    end
                end
            end

            % IF WE FOUND A MATCH, THEN PERFORM A SANITY CHECK THAT THE
            % FOLDER "Matrices"  (where the data is expected to be)
            % ACTUALLY EXISTS
            if flag_matchFound
                matricesFolderName = 'Matrices';
                matricesFolderPath_full = [ adpFolderPath_full , matricesFolderName , filesep ];
                if ~(exist(matricesFolderPath_full,'dir') == 7)
                    flag_matchFound = false;
                end
            end
            
            % FILL IN THE RETURN VARIABLES
            returnSuccess = flag_matchFound;
            if flag_matchFound
                returnResult = index_ofMatchFound;
            else
                returnResult = [];
            end
            
            
        
            
        %% ------------------------------------------------------------- %%
        %% LOAD FROM A GIVEN INDEX
        case 'load'            
            
            % Get the index form the "inputSpecs"
            inputIndex = inputSpecs.index;
            
            % Get the folder where data is saved
            mySaveDataPath = constants_MachineSpecific.saveDataPath;
            % Get the folder path where controllers are saved
            adpFolderName = 'ADP_SavedControllers';
            % Concatenate the full path
            adpFolderPath_full = [ mySaveDataPath , adpFolderName , filesep ];
            % Check that there is already a folder of the ADP matrices
            if (exist(adpFolderPath_full,'dir') == 7)

                % Now check if there is already a index file for what controllers
                % are saved
                adpIndexFileName = 'adp_SavedControllersIndex';
                adpIndexFileName_full = [ adpFolderPath_full , adpIndexFileName , '.mat' ];

                % If it exists then load it (and get the length)
                if (exist(adpIndexFileName_full,'file') == 2)
                    tempload = load( adpIndexFileName_full );
                    adpIndex = tempload.adpIndex;
                    if strcmp( inputSpecs.type , 'P' )
                        this_adpIndex = adpIndex.P;
                        apdIndexLength = size(this_adpIndex,1);
                    elseif strcmp( inputSpecs.type , 'K' )
                        this_adpIndex = adpIndex.K;
                        apdIndexLength = size(this_adpIndex,1);
                    else
                        % THIS SHOULDN'T HAPPEN
                        apdIndexLength = inf;
                    end
            
                    % Check that the specifies index is not beyond the 
                    % length
                    if inputIndex <= apdIndexLength
                        % Get the path the folder where are the data is
                        matricesFolderName = 'Matrices';
                        matricesFolderPath_full = [ adpFolderPath_full , matricesFolderName , filesep ];
                        if (exist(matricesFolderPath_full,'dir') == 7)
                            clear returnResult;
                            if strcmp( inputSpecs.type , 'P' )
                                % Load the matrices for the previously computed value functions
                                tempload = load( [matricesFolderPath_full, filesep, this_adpIndex{inputIndex,1}.P_fileName, '.mat'] );
                                returnResult.P = tempload.P;
                                tempload = load( [matricesFolderPath_full, filesep, this_adpIndex{inputIndex,1}.p_fileName, '.mat'] );
                                returnResult.p = tempload.p;
                                tempload = load( [matricesFolderPath_full, filesep, this_adpIndex{inputIndex,1}.s_fileName, '.mat'] );
                                returnResult.s = tempload.s;
                                % Set the return flag
                                returnSuccess = true;
                            elseif strcmp( inputSpecs.type , 'K' )
                                % Load the matrices for the previously computed value functions
                                tempload = load( [matricesFolderPath_full, filesep, this_adpIndex{inputIndex,1}.K_fileName, '.mat'] );
                                returnResult.K = tempload.K;
                                % Set the return flag
                                returnSuccess = true;
                            else
                                % THIS SHOULDN'T HAPPEN
                                returnSuccess = false; returnResult = [];
                            end
                            
                        else
                            returnSuccess = false; returnResult = [];
                        end
                    else
                        returnSuccess = false; returnResult = [];
                    end
                else
                    returnSuccess = false; returnResult = [];
                end
            else
                returnSuccess = false; returnResult = [];
            end
        
        %% ------------------------------------------------------------- %%
        %% LOAD FROM A GIVEN INDEX  
        case 'save'

            % No result is return for the 'save' case, so set to blank
            returnResult = [];
            
            % SAVE THE COMPUTED V's SO THEY CAN BE USED AGAIN TO SAVE TIME
            
            % Get the path to save data
            mySaveDataPath = constants_MachineSpecific.saveDataPath;
            % Get the fodler where ADP controller are stored
            adpFolderName = 'ADP_SavedControllers';
            % Construct the full path to the data folder
            adpFolderPath_full = [ mySaveDataPath , adpFolderName , filesep ];
            % Check that there is already a folder of the ADP matrices
            % ... creating one if required
            if ~(exist(adpFolderPath_full,'dir') == 7)
                mkdir(adpFolderPath_full);
            end
            % Get the folder where the actual matrices are stored
            matricesFolderName = 'Matrices';
            % Construct the full path to the data folder
            matricesFolderPath_full = [ adpFolderPath_full , matricesFolderName , filesep ];
            % Check that there is already such a folder
            % ... creating one if required
            if ~(exist(matricesFolderPath_full,'dir') == 7)
                mkdir(matricesFolderPath_full);
            end

            % Now check if there is already a index file for what controllers
            % are saved
            % Get the name of the index file
            adpIndexFileName = 'adp_SavedControllersIndex';
            % Construct teh full path to the index file
            adpIndexFileName_full = [ adpFolderPath_full , adpIndexFileName , '.mat' ];
            % If it exists then load it, otherwise 
            if (exist(adpIndexFileName_full,'file') == 2)
                tempload = load( adpIndexFileName_full );
                adpIndex = tempload.adpIndex;                
            else
                % Otherwise, initialise an empty index
                clear adpIndex;
                adpIndex = [];
            end

            % Generate a file name for this controller using the clock
            [~, ~, currDateStr, currTimeStr] = getCurrentTimeStrings();
            temp_fileNamePrefix = [currDateStr, '_', currTimeStr];

            % Adding the details and saving the data now splits depending
            % on the "type" of data to be saved
            if strcmp( inputSpecs.type , 'P' )
            
                % Get the ADP Index for "P" matrices
                if isfield( adpIndex , 'P' )
                    apdIndexLength_P = size(adpIndex.P,1);
                else
                    adpIndex.P = cell(0,1);
                    apdIndexLength_P = 0;
                end
                % Now add the details to the index
                adpIndex.P{apdIndexLength_P+1,1}.vararginLocal = inputSpecs.vararginLocal;
                adpIndex.P{apdIndexLength_P+1,1}.P_fileName = [temp_fileNamePrefix , '_P_quad'];
                adpIndex.P{apdIndexLength_P+1,1}.p_fileName = [temp_fileNamePrefix , '_p_lin'];
                adpIndex.P{apdIndexLength_P+1,1}.s_fileName = [temp_fileNamePrefix , '_s_const'];
                
                % Extract the data so that it can be saved
                P = inputSpecs.P;
                p = inputSpecs.p;
                s = inputSpecs.s;

                % Now save the matrices
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_P_quad', '.mat'], 'P', '-v7.3');
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_p_lin', '.mat'], 'p', '-v7.3');
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_s_const', '.mat'], 's', '-v7.3');
                
                % Set a flag that data was successfully saved
                returnSuccess = true;
                
            elseif strcmp( inputSpecs.type , 'K' )
                
                % Get the ADP Index for "K" matrices
                if isfield( adpIndex , 'K' )
                    apdIndexLength_K = size(adpIndex.K,1);
                else
                    adpIndex.K = cell(0,1);
                    apdIndexLength_K = 0;
                end
                % Now add the details to the index
                adpIndex.K{apdIndexLength_K+1,1}.vararginLocal = inputSpecs.vararginLocal;
                adpIndex.K{apdIndexLength_K+1,1}.K = [temp_fileNamePrefix , '_K_pwa'];
                
                % Extract the data so that it can be saved
                K = inputSpecs.K;

                % Now save the matrices
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_K_pwa', '.mat'], 'K', '-v7.3');
                
                % Set a flag that data was successfully saved
                returnSuccess = true;
                
            else
                % Set a flag that data was NOT  saved
                returnSuccess = false;
            end
            
            % And save the index back (if something was successfully saved
            if returnSuccess
                save(adpIndexFileName_full, 'adpIndex', '-v7.3');
            end
         
        %% ------------------------------------------------------------- %%
        %% OTHERWISE ... Handle an unrocognised case
        otherwise
            disp( ' ERROR: the "inputInstruction" was not recognised, it was:' );
            diplay inputInstruction;
            flag_sucess = false;
            loadedObject = [];
            return;
    end   % END OF: "switch inputInstruction"
        
        
        
    
            
end
% END OF FUNCTION