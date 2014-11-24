function returnData = getStatistic_fromData_withFormat_XiByXiByTime( inputData , startTime , duration , i_fullInput , j_fullInput )
% Defined for the "Disturbance-ology" class, this function loads the
% ".data" property from a specified file
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > ...
%               
% ----------------------------------------------------------------------- %

%% SETTING THE DURATION CONVENTION
% Does the "duration" include the "start time" step or not!?
%duration = duration - 1;

%% NOTE: ON SPEED OF "*.mat"  -versus-  FILES  -versus-  "obj.property"
%
% Matfiles are nice because you only "load" the data required, but that is
% a load from disk into ram, so multiple call to this are slow
% 
% obj.property referencing is nice because it is object orientated, but
% looking up the .property multiple times adds a bit of over-head
%
% Passing the obj.property data once seems to be the most efficient because
% it passes the handle to the data avoiding the need to look up the handle
% multiple times

%% DEPRECATED CODE: FOR GETTING A "matfile" OBJECT
% Get a "matfile" object for the data
%matfileWithData = matfile( loadFileFullPath , 'Writable',false );


%% GETTING THE SIZE AND DATUMS OF THE PROBLEM
% Get the size of the matrix stored
[numRows , ~ , numSlices] = size( inputData );
% Interpret the size
n_xi = numRows;
Tmax = numSlices;
% "mod" the start time to be within Tmax
startTime_mod = mod(startTime-1 , Tmax) + 1;
% Compute the end time and its mod
endTime = startTime_mod + duration - 1;
endTime_mod = mod(endTime-1 , Tmax) + 1;
% Check how many times we need to wrap through the disturbance cycle
numWraps = floor( double(endTime-1) / Tmax );

%% PREPARING THE INDEXING FOR A BLOCK DIAGONAL MATRIX
% For a Non-Time-Correlated disturbance model, the covariance matrix will
% be block diagonal and hence highly sparse
n_xi2 = n_xi*n_xi;
num_nonZeroFull = n_xi2 * duration;

if isempty(i_fullInput)
    i_full = zeros( num_nonZeroFull , 1 );
    for iStep = 1 : duration
       i_full( ((iStep-1)*n_xi2+1) : (iStep*n_xi2) , 1 ) = repmat( ( ((iStep-1)*n_xi+1) : (iStep*n_xi) )' , n_xi , 1 );
    end
else
    i_full = i_fullInput(1:num_nonZeroFull);
end
    
if isempty(j_fullInput)
    j_full = zeros( num_nonZeroFull , 1 );
    for iStep = 1 : (n_xi*duration)
       j_full( ((iStep-1)*n_xi+1) : (iStep*n_xi) , 1 ) = iStep;
    end
else
    j_full = j_fullInput(1:num_nonZeroFull);
end



%% PUTTING THE REQUIRED DATA INTO THE RETURN VARIABLE
% If there is no wrapping, then handle it directly
if numWraps == 0
    %numTimeStep = endTime_mod - startTime_mod + 1;
    getRangeSlices = startTime_mod:endTime_mod;
    s_full = reshape( inputData(:,:,getRangeSlices) , num_nonZeroFull , 1 );
% Else account for the wrapping
else
    % Initialise the variable for putting the data into
    s_full = zeros(num_nonZeroFull,1);
    % Fill in the part before the first wrap
    numTimeStep = Tmax - startTime_mod + 1;
    getRangeSlices = startTime_mod:Tmax;
    thisNum_nonZero = (n_xi * n_xi * numTimeStep);
    sRange = 1 : thisNum_nonZero;
    s_full(sRange,1) = reshape( inputData(:,:,getRangeSlices) , thisNum_nonZero , 1 );
    currReturnRow = thisNum_nonZero;
    % Iterate through the number of Wraps, filling in the return variable
    for iWrap = 1:numWraps-1
        numTimeStep = Tmax;
        getRangeSlices = 1:Tmax;
        thisNum_nonZero = (n_xi * n_xi * numTimeStep);
        sRange = (currReturnRow+1) : (currReturnRow+thisNum_nonZero);
        s_full(sRange,1) = reshape( inputData(:,:,getRangeSlices) , thisNum_nonZero , 1 );
        currReturnRow = (currReturnRow+thisNum_nonZero);
    end
    % Fill in the part after the last wrap
    numTimeStep = endTime_mod;
    getRangeSlices = 1:endTime_mod;
    thisNum_nonZero = (n_xi * n_xi * numTimeStep);
    sRange = (currReturnRow+1) : (currReturnRow+thisNum_nonZero);
    s_full(sRange,1) = reshape( inputData(:,:,getRangeSlices) , thisNum_nonZero , 1 );
    currReturnRow = (currReturnRow+thisNum_nonZero);

    % Check that the full "returnData" vector was filled in
    if ~( currReturnRow == num_nonZeroFull )
        disp(' ... ERROR: when extracting the data from file, less data than expected was extracted');
        error(bbConstants.errorMsg);
    end
end

% Build the sparse matrix as the return data
returnData = sparse( i_full , j_full , s_full , n_xi * duration , n_xi * duration , num_nonZeroFull );

end
% END OF FUNCTION
