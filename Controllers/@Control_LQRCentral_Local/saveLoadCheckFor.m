function [returnSuccess , returnResult] = saveLoadCheckFor( inputInstruction , inputSpecs )
% Defined for the "LQRCentral" controller class, this function will be used
% to save, load, or check for the existence of, a "P" or "K" matrix that
% were computed for a specific set of input arguments
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
% ----------------------------------------------------------------------- %
% This file is part of the Stochastic Optimisation Test Bed.
%
% The Stochastic Optimisation Test Bed - Copyright (C) 2015 Paul Beuchat
%
% The Stochastic Optimisation Test Bed is free software: you can
% redistribute it and/or modify it under the terms of the GNU General
% Public License as published by the Free Software Foundation, either
% version 3 of the License, or (at your option) any later version.
% 
% The Stochastic Optimisation Test Bed is distributed in the hope that it
% will be useful, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with the Stochastic Optimisation Test Bed.  If not, see
% <http://www.gnu.org/licenses/>.
%  ---------------------------------------------------------------------  %




    
    %% ----------------------------------------------------------------- %%
    %% DEFINE THE SET OF POSSIBLE "inputInstruction"
    inputInstruction_options = ...
        {   'load' ;...
            'save' ;...
            'check' ;...
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
    varargin_fields_forComputing_K = ...
        {   'modelID' ;...
            'disturbanceID' ;...
            'predHorizon' ;...
            'computeKEveryNumSteps' ;...
            'systemDynamics' ;...
            'energyToComfortScaling' ;...
        };
    
    
    

    %% ----------------------------------------------------------------- %%
    %% SWITCH BETWEEN THE DIFFERENT POSSIBLE "inputInstructions"
    
    switch inputInstruction
        
        %% ------------------------------------------------------------- %%
        %% CHECK FOR EXISTENCE OF A MATCHING ENTRY
        case {'check'}
            
            % CHECK THAT WE HAVE A MATCHING SET OF "K" MATRICES
            flag_matchFound = false;

            mySaveDataPath = constants_MachineSpecific.saveDataPath;
            lqrFolderName = 'LQR_SavedControllers';
            lqrFolderPath_full = [ mySaveDataPath , lqrFolderName , filesep ];
            % Check that there is already a folder of the LQR matrices
            if (exist(lqrFolderPath_full,'dir') == 7)

                % Now check if there is already a index file for what controllers
                % are saved
                lqrIndexFileName = 'lqr_SavedControllersIndex';
                lqrIndexFileName_full = [ lqrFolderPath_full , lqrIndexFileName , '.mat' ];

                % If it exists then load it 
                if (exist(lqrIndexFileName_full,'file') == 2)
                    tempload = load( lqrIndexFileName_full );
                    lqrIndex = tempload.lqrIndex;
                    
                    % Get the index and the properties that determine if
                    % there is a match
                    % First check that the field "K" even exists
                    if isfield( lqrIndex , 'K' );
                        this_lqrIndex = lqrIndex.K;
                        varargin_fields_forComputing = varargin_fields_forComputing_K;
                    else
                        returnSuccess = false; returnResult = [];
                        return;
                    end
                    
                    % Get the length of the LQR index
                    lqrIndexLength = size(this_lqrIndex,1);

                    % Get the info about "vararginLocal" (equivalently
                    % "inputSpecs" because it won't change at each
                    % iteration of the following for loop
                    inputSpecs_fields  = fields(inputSpecs );
                    tempThrowError = false;
                    check_inputSpecsHasRequiredFields = bbConstants.checkForFields( inputSpecs_fields , varargin_fields_forComputing , tempThrowError );
                    numFieldsToCheck_forComputing = length( varargin_fields_forComputing );

                    % Now look for a match via the index
                    for iIndex = 1:lqrIndexLength
                        thisEntry = this_lqrIndex{iIndex,1}.vararginLocal;
                        thisEntry_fields = fields(thisEntry);

                        % Check that this entry also has has the required fields
                        tempThrowError = false;
                        check_thisEntryHasRequiredFields = bbConstants.checkForFields( thisEntry_fields , varargin_fields_forComputing , tempThrowError );

                        % If both have the required fields...
                        if check_thisEntryHasRequiredFields && check_inputSpecsHasRequiredFields
                            % Then check if they match, initialising the
                            % match flag to "true", and setting it to
                            % "false" if a mis-match is found
                            flag_mathcingFieldData = true;
                            % Now check that the data in each field is the
                            % same
                            for iField = 1:numFieldsToCheck_forComputing
                                thisFieldName = varargin_fields_forComputing{iField,1};
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
                            % If a match was found, then store the index of
                            % the match (by not breaking the "for" loop,
                            % this means that if there are multiple
                            % matches, the one with the highest index will
                            % be returned
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
                matricesFolderPath_full = [ lqrFolderPath_full , matricesFolderName , filesep ];
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
            lqrFolderName = 'LQR_SavedControllers';
            % Concatenate the full path
            lqrFolderPath_full = [ mySaveDataPath , lqrFolderName , filesep ];
            % Check that there is already a folder of the LQR matrices
            if (exist(lqrFolderPath_full,'dir') == 7)

                % Now check if there is already a index file for what controllers
                % are saved
                lqrIndexFileName = 'lqr_SavedControllersIndex';
                lqrIndexFileName_full = [ lqrFolderPath_full , lqrIndexFileName , '.mat' ];

                % If it exists then load it (and get the length)
                if (exist(lqrIndexFileName_full,'file') == 2)
                    tempload = load( lqrIndexFileName_full );
                    lqrIndex = tempload.lqrIndex;
                    if strcmp( inputSpecs.type , 'K' )
                        this_lqrIndex = lqrIndex.K;
                        lqrIndexLength = size(this_lqrIndex,1);
                    else
                        % THIS SHOULDN'T HAPPEN
                        lqrIndexLength = inf;
                    end
            
                    % Check that the specified index is not beyond the 
                    % length
                    if inputIndex <= lqrIndexLength
                        % Get the path the folder where are the data is
                        matricesFolderName = 'Matrices';
                        matricesFolderPath_full = [ lqrFolderPath_full , matricesFolderName , filesep ];
                        if (exist(matricesFolderPath_full,'dir') == 7)
                            clear returnResult;
                            if strcmp( inputSpecs.type , 'K' )
                                % Load the matrices for the previously computed value functions
                                tempload = load( [matricesFolderPath_full, filesep, this_lqrIndex{inputIndex,1}.P_fileName, '.mat'] );
                                returnResult.P = tempload.P;
                                tempload = load( [matricesFolderPath_full, filesep, this_lqrIndex{inputIndex,1}.p_fileName, '.mat'] );
                                returnResult.p = tempload.p;
                                tempload = load( [matricesFolderPath_full, filesep, this_lqrIndex{inputIndex,1}.s_fileName, '.mat'] );
                                returnResult.s = tempload.s;
                                % Load the matrices for the previously computed "K" feedback matrix
                                tempload = load( [matricesFolderPath_full, filesep, this_lqrIndex{inputIndex,1}.K_fileName, '.mat'] );
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
            % Get the fodler where LQR controller are stored
            lqrFolderName = 'LQR_SavedControllers';
            % Construct the full path to the data folder
            lqrFolderPath_full = [ mySaveDataPath , lqrFolderName , filesep ];
            % Check that there is already a folder of the LQR matrices
            % ... creating one if required
            if ~(exist(lqrFolderPath_full,'dir') == 7)
                mkdir(lqrFolderPath_full);
            end
            % Get the folder where the actual matrices are stored
            matricesFolderName = 'Matrices';
            % Construct the full path to the data folder
            matricesFolderPath_full = [ lqrFolderPath_full , matricesFolderName , filesep ];
            % Check that there is already such a folder
            % ... creating one if required
            if ~(exist(matricesFolderPath_full,'dir') == 7)
                mkdir(matricesFolderPath_full);
            end

            % Now check if there is already a index file for what controllers
            % are saved
            % Get the name of the index file
            lqrIndexFileName = 'lqr_SavedControllersIndex';
            % Construct teh full path to the index file
            lqrIndexFileName_full = [ lqrFolderPath_full , lqrIndexFileName , '.mat' ];
            % If it exists then load it, otherwise 
            if (exist(lqrIndexFileName_full,'file') == 2)
                tempload = load( lqrIndexFileName_full );
                lqrIndex = tempload.lqrIndex;                
            else
                % Otherwise, initialise an empty index
                clear lqrIndex;
                lqrIndex = [];
            end

            % Generate a file name for this controller using the clock
            [~, ~, currDateStr, currTimeStr] = getCurrentTimeStrings();
            temp_fileNamePrefix = [currDateStr, '_', currTimeStr];
            % If the file name exists, then the previous save was done less
            % than a second ago, therefore pause for 2 seconds and
            % re-generate the file name prefix
            if (exist( [ matricesFolderPath_full , temp_fileNamePrefix , '_K.mat'] , 'file') == 2)
                pause(2);
                [~, ~, currDateStr, currTimeStr] = getCurrentTimeStrings();
                temp_fileNamePrefix = [currDateStr, '_', currTimeStr];
            end
            

            % Adding the details and saving the data
            % (This splits depending on the "type" of data to be saved)
            if strcmp( inputSpecs.type , 'K' )
                
                % Get the LQR Index for "K" matrices
                if isfield( lqrIndex , 'K' )
                    lqrIndexLength_K = size(lqrIndex.K,1);
                else
                    lqrIndex.K = cell(0,1);
                    lqrIndexLength_K = 0;
                end
                % Now add the details to the index
                lqrIndex.K{lqrIndexLength_K+1,1}.vararginLocal = inputSpecs.vararginLocal;
                lqrIndex.K{lqrIndexLength_K+1,1}.P_fileName = [temp_fileNamePrefix , '_P_quad'];
                lqrIndex.K{lqrIndexLength_K+1,1}.p_fileName = [temp_fileNamePrefix , '_p_lin'];
                lqrIndex.K{lqrIndexLength_K+1,1}.s_fileName = [temp_fileNamePrefix , '_s_const'];
                lqrIndex.K{lqrIndexLength_K+1,1}.K_fileName = [temp_fileNamePrefix , '_K'];
                
                % Extract the data so that it can be saved
                P = inputSpecs.P;
                p = inputSpecs.p;
                s = inputSpecs.s;
                K = inputSpecs.K;

                % Now save the matrices
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_P_quad', '.mat'], 'P', '-v7.3');
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_p_lin', '.mat'], 'p', '-v7.3');
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_s_const', '.mat'], 's', '-v7.3');
                save([matricesFolderPath_full, filesep, temp_fileNamePrefix, '_K', '.mat'], 'K', '-v7.3');
                
                % Set a flag that data was successfully saved
                returnSuccess = true;
                
            else
                % Set a flag that data was NOT  saved
                returnSuccess = false;
            end
            
            % And save the index back (if something was successfully saved
            if returnSuccess
                save(lqrIndexFileName_full, 'lqrIndex', '-v7.3');
            end
         
        %% ------------------------------------------------------------- %%
        %% OTHERWISE ... Handle an unrocognised case
        otherwise
            disp( ' ERROR: the "inputInstruction" was not recognised, it was:' );
            diplay inputInstruction;
            returnSuccess = false;
            returnResult = [];
            return;
    end   % END OF: "switch inputInstruction"
        
        
        
    
            
end
% END OF FUNCTION