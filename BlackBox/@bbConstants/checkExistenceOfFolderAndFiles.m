%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
%  ---------     checkForFields.m
%  ---------------------------------------------------------------------  %
%  ---------------------------------------------------------------------  %
function [returnPath , returnSuccess] = checkExistenceOfFolderAndFiles(rootPath , inputFolders, inputFiles , inputErrorMsg , flag_throwError)

%  ---------------------------------------------------------------------  %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Common Function
%
%  DESCRIPTION: > Function to check the existence of 1 Folder and many
%                 Files contained within that 1 Folder
%               
%  ---------------------------------------------------------------------  %

    %% Assume success, and set to false anytime an error is encountered
    % NOTE: This is just one success flag for all folders and files
    % to be checked
    returnSuccess = true;

    %% String for displaying "ERROR" or "NOTE"
    if flag_throwError
        alertText = 'ERROR';
    else
        alertText = 'NOTE';
    end

    %% Check that the input are as expected
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

    %% This function starts from the input "root path", so set that
    % as the current path
    currPath = rootPath;

    %% Iterate through the folders
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

    %% If no files, then return the current path
    if numFiles == 0
        returnPath = currPath;
    %% If only 1 file, then handle this separately and return the
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
    %% Else if multiple files then check them all, returning the path to each in a cell array
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