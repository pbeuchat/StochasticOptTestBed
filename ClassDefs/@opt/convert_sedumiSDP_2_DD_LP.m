function [flag_success, cnew, A_ineq, b_ineq, A_eq, b_eq, lb, ub, dd_2_psd, f_per_psd_start, f_per_psd_end, time_conversion_elaspsed] = convert_sedumiSDP_2_DD_LP(A_in,b_in,c_in,K_in)
% Defined for the "opt" class, this function takes a Semi-definite program
% given in the standard SeDuMi format and converts it to a SeDuMi format
% where the positive semi-definite (psd) variables have been 
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


%% --------------------------------------------------------------------- %%
%% 00) INFO ABOUT THE GUROBI INTERFACE VIA MATLAB
% http://www.gurobi.com/documentation/6.0/refman/matlab_solving_models_with.html
% http://www.gurobi.com/documentation/6.0/refman/matlab_gurobi.html



%% --------------------------------------------------------------------- %%
%% 0) GET THE TIME AT THE START OF PERFORMING THE CONVERSION
time_conversion_start = clock;


%% --------------------------------------------------------------------- %%
%% 0) INITIALISE THE SUCCESS FLAG TO BE "true"
% It will be set to "false" if a problem is found
flag_success = true;


%% --------------------------------------------------------------------- %%
%% 1) CHECK THAT THERE ARE ACTUALLY ANY POSITIVE SEMI-DEFINITE VARIABLES

% Check that a field sepcifying "psd" variables even exists
if ~isfield(K_in,'s')
    % If not, then return a blank formulation
    A_ineq = []; b_ineq = []; A_eq = []; b_eq = []; lb = []; ub = [];
    cnew = []; dd_2_psd = []; f_per_psd_start = []; f_per_psd_end = [];
    time_conversion_elaspsed = [];
    % Display a message letting the user know
    disp( ' ... NOTE: The SeDuMi problem input does NOT have any positive semi definite field defined' );
    disp( '           (ie. the field "K.s" does NOT exist, "~isfield(K,''s'') == false" )' );
    disp( '           Hence returning the exact same formulation because there is nothing for this function to do' );
    % And now return, setting the return flag to indicate FAILURE
    flag_success = false;
    return;
end


% Even if the field exists, it could have been mistakely set as empty
% (which will make SeDuMi fail, but we will let the user find that out via
% SeDuMi and not via this conversion function
if isempty( K_in.s )
    % If not, then return a blank formulation
    A_ineq = []; b_ineq = []; A_eq = []; b_eq = []; lb = []; ub = [];
    cnew = []; dd_2_psd = []; f_per_psd_start = []; f_per_psd_end = [];
    time_conversion_elaspsed = [];
    % Display a message letting the user know
    disp( ' ... NOTE: The SeDuMi problem input an EMPTY specification for the positive semi definite field' );
    disp( '           (ie. the field "K.s" exists but it is EMPTY, "isempty( K.s ) = true" )' );
    disp( '           Hence returning the exact same formulation because there is nothing for this function to do' );
    disp( ' ... NOTE: further that this formulation will likely cause SeDuMi to throw an error because the field "s"' );
    disp( '           but is empty' );
    % And now return, setting the return flag to indicate FAILURE
    flag_success = false;
    return;
end


%% --------------------------------------------------------------------- %%
%% 2) CHECK THAT THERE ARE NOT ANY CONE VARIABLES
% Check that no "Lorentz Cone" variables are specified
if isfield(K_in,'q')
    if ~isempty(K_in.q)
        % If NOT empty, then return a blank formulation
        A_ineq = []; b_ineq = []; A_eq = []; b_eq = []; lb = []; ub = [];
        cnew = []; dd_2_psd = []; f_per_psd_start = []; f_per_psd_end = [];
        time_conversion_elaspsed = [];
        % Display a message letting the user know
        disp( ' ... NOTE: The SeDuMi problem input includes Lorentz Cone variables' );
        disp( '           (ie. the field "K.q" does exist and is not empty, "isempty(K.q) == false" )' );
        disp( '           This function does not handle an LP reformulation of SOCPs' );
        disp( '           Hence returning an empty LP formulation and flag indicating failure' );
        % And now return, setting the return flag to indicate FAILURE
        flag_success = false;
        return;
    end
end

% Check that no "Rotated Lorentz Cone" variables are specified
if isfield(K_in,'r')
    if ~isempty(K_in.r)
        % If NOT empty, then return a blank formulation like-for-like
        A_ineq = []; b_ineq = []; A_eq = []; b_eq = []; lb = []; ub = [];
        cnew = []; dd_2_psd = []; f_per_psd_start = []; f_per_psd_end = [];
        time_conversion_elaspsed = [];
        % Display a message letting the user know
        disp( ' ... NOTE: The SeDuMi problem input includes Rotated Lorentz Cone variables' );
        disp( '           (ie. the field "K.r" does exist and is not empty, "isempty(K.r) == false" )' );
        disp( '           This function does not handle an LP reformulation of SOCPs' );
        disp( '           Hence returning an empty LP formulation and flag indicating failure' );
        % And now return, setting the return flag to indicate FAILURE
        flag_success = false;
        return;
    end
end



%% --------------------------------------------------------------------- %%
%% 2) GET THE POSITIVE DEFINITE VARAIBLES DEFINITION ...

% Get the "s" field from the input that defines the "psd" variables
s_in = K_in.s;

% Check that "s input" is a vector
if ~isvector( s_in )
    % If NOT a vector, then return a blank formulation
    A_ineq = []; b_ineq = []; A_eq = []; b_eq = []; lb = []; ub = [];
    cnew = []; dd_2_psd = []; f_per_psd_start = []; f_per_psd_end = [];
    time_conversion_elaspsed = [];
    % Display a message letting the user know
    disp( ' ... NOTE: For SeDuMi problem input the field "K.s" is NOT a vector' );
    disp( '           (ie. "isvector( K.s ) = false" )' );
    disp( '           A non-vector format cannot be interpretted by this function' );
    disp( ' ... NOTE: further that the exact same formulation is being returned and that this formulation will likely' );
    disp( '           cause SeDuMi to throw an error because the field "K.s" but is not a vector' );
    % And now return
    flag_success = false;
    return;
end

% Get the number of "psd" variables
num_psd_variable = length( s_in );


%% ... AND DEFINE THE ROTATED LORENTZ VARIABLES TO REPLACE THEM

% For each "psd" matrix, let "n" denote the size, then (1/2)*n*(n+1) free
% variables are needed to define the equivalent SSD matrix, and 
% (1/2)*n*(n-1) free variables are required to for the off-diagonal
% element-wise absolute values

f_per_psd    = 0.5 .* s_in .* (s_in + 1);
abs_per_psd  = 0.5 .* s_in .* (s_in - 1);

f_for_psd = sum(f_per_psd);
abs_for_psd = sum(abs_per_psd);



%% --------------------------------------------------------------------- %%
%% 3) GET THE OTHER TYPES OF VARIABLES SEPCIFIED IN THE INPUT PROBLEM

% Initialise flags sepcifying which ones are present
flag_include_f = false;         % Free variables
flag_include_l = false;         % Non-negative variables

if isfield(K_in,'f')
    flag_include_f = true;
end
if isfield(K_in,'l')
    flag_include_l = true;
end



%% --------------------------------------------------------------------- %%
%% 4) CREATE AN INDEX FOR THE START AND END OF EACH VARIABLE TYPE

if flag_include_f
    f_start = 1;
    f_end = f_start + K_in.f - 1;
else
    %f_start = 0;       % NOTE: f_start if not used anywhere in this case
    f_end = 0;
end
if flag_include_l
    l_start = f_end + 1;
    l_end = l_start + K_in.l - 1;
else
    l_start = f_end;
    l_end = l_start;
end

f_for_psd_start = l_end + 1;
f_for_psd_end   = f_for_psd_start + f_for_psd - 1;

abs_for_psd_start = f_for_psd_end + 1;
abs_for_psd_end   = abs_for_psd_start + abs_for_psd - 1;


% Index also the set of "f" and "abs" variables introduced per "psd"
% variable
% Initialise the index first
f_per_psd_start = zeros(num_psd_variable,1);
f_per_psd_end = zeros(num_psd_variable,1);
abs_per_psd_start = zeros(num_psd_variable,1);
abs_per_psd_end = zeros(num_psd_variable,1);
temp_previous_f_end = l_end;
temp_previous_abs_end = f_for_psd_end;
% Then step through the "psd" variables
for i_psd = 1:num_psd_variable
    % Get the number of "f" and "abs" variable elements for this "i_psd"
    this_f_length    = f_per_psd(i_psd);
    this_abs_length  = abs_per_psd(i_psd);
    % Compute the start
    f_per_psd_start(i_psd,1)    = temp_previous_f_end + 1;
    abs_per_psd_start(i_psd,1)  = temp_previous_abs_end + 1;
    % Compute the end
    f_per_psd_end(i_psd,1)    = f_per_psd_start(i_psd,1)   + this_f_length - 1;
    abs_per_psd_end(i_psd,1)  = abs_per_psd_start(i_psd,1) + this_abs_length - 1;
    % Update the temporary variable for passing around the previous end
    temp_previous_f_end    = f_per_psd_end(i_psd,1);
    temp_previous_abs_end  = abs_per_psd_end(i_psd,1);
end


%% 4a) COMPUTE THE TOTAL LENGTH OF THE NEW DECISION VECTOR
x_length = abs_for_psd_end;

% And compute the length of the "abs" variables introduced
abs_for_psd_length = abs_for_psd_end - abs_for_psd_start + 1;


%% --------------------------------------------------------------------- %%
%% 5) NOW BUILD A "per psd" MATRIX TO CONVERT THE "f" VARIABLES TO THE "s"
%%    (Building the Diagonal Dominance inequality constraints at the same time)

% Initialise a container for the mapping
map_f_to_psd = cell( num_psd_variable , 1 );

% Initialise a container for the inequality constraint matrices
A_ineq_f_for_dd   = cell( num_psd_variable , 1 );
A_ineq_abs_for_dd = cell( num_psd_variable , 1 );
A_ineq_numRows_for_dd = zeros( num_psd_variable , 1 );

% Step through the "psd" variables
for i_psd = 1:num_psd_variable

    % Start by building an index of which element in the "psd" each "r"
    % variable corresponds to
    
    % Get the number of "r" variable elements for this "i_psd"
    this_psd_size    = s_in(i_psd);
    this_f_length    = f_per_psd(i_psd);
    this_abs_length  = abs_per_psd(i_psd);
    
    % Initialise the index container
    f_index_i = zeros(1,this_f_length);
    f_index_j = zeros(1,this_f_length);
    abs_index_i = zeros(1,this_abs_length);
    abs_index_j = zeros(1,this_abs_length);
    % We will do this with for loops, which should be fast enough for such
    % simple operations
    this_f_index = 0;
    this_abs_index = 0;
    
    % Put the diagonal first elements first to make the Diagonal Dominance
    % inequality constraints easier to formulate
    for iIndex = 1:this_psd_size
        % Put in the index of this element
        f_index_i(1,this_f_index+1) = iIndex;
        f_index_j(1,this_f_index+1) = iIndex;
        % Increment the index counter
        this_f_index = this_f_index + 1;
    end
    
    for iIndex = 1:this_psd_size-1
        for jIndex = iIndex+1:1:this_psd_size
            % Put in the index of this element
            f_index_i(1,this_f_index+1) = iIndex;
            f_index_j(1,this_f_index+1) = jIndex;
            % Increment the index counter
            this_f_index = this_f_index + 1;
            
            % The "abs" variables only exist for the off diagonals
            if iIndex ~= jIndex
                % Put in the index of this element
                abs_index_i(1,this_abs_index+1) = iIndex;
                abs_index_j(1,this_abs_index+1) = jIndex;
                % Increment the index counter
                this_abs_index = this_abs_index + 1;
            end
        end
    end
    
    
    % We would like to create the mapping as sparse
    % Each element on the diagonal of "psd" variable should be summed from
    % (n-1) elements of the "r" varaibles
    % While each element on the off-diagonal should correspond to only 1
    % element of the "r" variables
    % Hence we expect to have:
    %   ( n * (n-1) )   +   ( n * (n-1) )
    % non-zero elements
    % Hence initialise the indexing variables for building the sparse map:
    this_nnz = this_psd_size * this_psd_size;
    this_map_i = zeros( this_nnz , 1 );
    this_map_j = zeros( this_nnz , 1 );
    this_map_s = ones( this_nnz , 1 );
    
    % Now step through each element of the "psd" matrix and build the
    % sparse indexing for the map
    % Initialise some counting variables
    curr_map_entry = 1;
    curr_psd_vecIndex = 0;
    % Step through every element (even though the "psd" matrix is
    % symmetric, SeDuMi has a variable for every element
    for j_col = 1:this_psd_size
        for i_row = 1:this_psd_size
            
            % Count through the elements
            curr_psd_vecIndex = curr_psd_vecIndex + 1;
            
            if i_row == j_col
                % Get a vector showing which elements in the "r" variables
                % correspond to the current index in the "psd" variable
                this_f_mask = bsxfun(@and,f_index_i==i_row,f_index_j==j_col);
                this_f_index = find(this_f_mask);
                
                % Put the details into the map (note: we are assuming here
                % that find will only return a vector of size 3)
                this_map_i(curr_map_entry,1) = curr_psd_vecIndex;
                this_map_j(curr_map_entry,1) = this_f_index;
                
                % Increment the "curr_map_entry" accordingly
                curr_map_entry = curr_map_entry + 1;
                
            else
                % Get a vector showing which elements in the "r" variables
                % correspond to the current index in the "psd" variable
                % NOTE: by construction "f(abs)_index_i(j)" is such that 
                % j>=i, and because things are symmetric we can switch the
                % search indicies when this is not the case
                if i_row > j_col
                    this_f_mask = bsxfun(@and,f_index_i==j_col,f_index_j==i_row);
                else
                    this_f_mask = bsxfun(@and,f_index_i==i_row,f_index_j==j_col);
                end
                this_f_index = find(this_f_mask);
                
                % Put the details into the map (note: we are assuming here
                % that find will only return a vector of size 1)
                this_map_i(curr_map_entry,1) = curr_psd_vecIndex;
                this_map_j(curr_map_entry,1) = this_f_index;
                
                % Increment the "curr_map_entry" accordingly
                curr_map_entry = curr_map_entry + 1;
            end
            
        end        
    end
    
    % Now store the mapping
    map_f_to_psd{i_psd,1} = sparse( this_map_i , this_map_j , this_map_s , this_psd_size*this_psd_size , this_f_length , this_nnz );
    
    % ------------------------------------------------------------------- %
    % NOW DO THE DIAGONAL DOMINANCE INEQUALITY CONSTRAINT FOR THIS "psd"
    % For the Diagonal Dominance:
    %       -f_ii + \sum_{j~=i} abs_ij <= 0
    % For the absolute value auxilliary variables
    %       f_ij - abs_ij <= 0      for all i~=j
    %      -f_ij - abs_ij <= 0
    A_ineq_f_for_dd{i_psd,1}   = [  -speye(this_psd_size)                              ,   sparse([],[],[],this_psd_size,this_abs_length,0)     ;...
                              sparse([],[],[],this_abs_length,this_psd_size,0)  ,   speye(this_abs_length)                               ;...
                              sparse([],[],[],this_abs_length,this_psd_size,0)  ,  -speye(this_abs_length)                                ...
                          ];
    
    % For the first "this_psd_size" constraint we need to build the
    % Diagonal dominance as a sparse matrix by indices
    this_nnz_abs_for_dd = this_psd_size * (this_psd_size-1);
    A_ineq_abs_for_dd_i = zeros(this_nnz_abs_for_dd,1);
    A_ineq_abs_for_dd_j = zeros(this_nnz_abs_for_dd,1);
    A_ineq_abs_for_dd_s = ones(this_nnz_abs_for_dd,1);
    for iIndex = 1:this_psd_size
        % There are (this_psd_size-1) contributions to each row
        thisRange = (iIndex-1)*((this_psd_size-1))+1 : iIndex*(this_psd_size-1);
        A_ineq_abs_for_dd_i(thisRange) = iIndex;
        
        % Sum all elements with row or col equal to "iIndex"
        this_abs_index = [find(abs_index_j==iIndex) , find(abs_index_i==iIndex)];
        A_ineq_abs_for_dd_j(thisRange) = this_abs_index;
    end
    
    % Hence build the "A_ineq" portion for these "abs" variables
    A_ineq_abs_for_dd{i_psd,1} = [   sparse(A_ineq_abs_for_dd_i,A_ineq_abs_for_dd_j,A_ineq_abs_for_dd_s,this_psd_size,this_abs_length,this_nnz_abs_for_dd) ;...
                             -speye(this_abs_length) ;...
                             -speye(this_abs_length) ...
                          ];
    
    % Keep track of the number of rows in each portion
    A_ineq_numRows_for_dd(i_psd,1) = this_psd_size + 2*this_abs_length;

end


%% --------------------------------------------------------------------- %%
%% 6) USE THE MAPPING TO CONVERT "A" AND "c" TO BE IN TERMS OF THE NEW VARIABLES

% For the indexing, notice that the additional "r" type variables are added
% after the input "r" type variables, and that there are no longer any "s"
% type variables by definition of the conversion.
% Therefore the indexing from "f_start" to "r_in_end" is the same, and
% hence that portion of the "A_in" matrix and "c_in" vector can be used
% directly

% Extract the portion of the "A_in" matrix (and "c_in" vector) for the "s"
% varaibles
A_in_s = A_in(:,(l_end+1):end);
c_in_s = c_in((l_end+1):end,1);

% Get the width (resp. length) of this portion 
[~,temp_width] = size(A_in_s);
temp_length = length( c_in_s );

% and check that it is as expected
s_in_width = sum( s_in.^2 );

checkWidth  = (temp_width  == s_in_width);
checkLength = (temp_length == s_in_width);
if ~(checkWidth && checkLength)
    disp( ' .. ERROR: This should not have happened' );
    error(bbConstants.errorMsg);
end

% Create the full mapping from ALL "r" to ALL "s"
map_f_to_psd_all = blkdiag( map_f_to_psd{:,1} );

% And hence map the portions of the "A" and "c"
A_new_f = A_in_s * map_f_to_psd_all;
c_new_f = (c_in_s' * map_f_to_psd_all)';

% Finally build the new "A" and "c"
A_eq = [ A_in(:,1:l_end) , A_new_f , sparse([],[],[],size(A_new_f,1),abs_for_psd_length,0) ];
cnew = [ c_in(1:l_end,1) ; c_new_f ; sparse([],[],[],abs_for_psd_length,1,0)];


% Check that the width of "A_eq" is correct
checkWidth_A_eq  = (x_length == size(A_eq,2) );
if ~checkWidth_A_eq
    disp( ' .. ERROR: The "A_eq" matrix built had the wrond size:' );
    disp(['           size(A_eq,2) = ',num2str(size(A_eq,2)),', is was expected to be size(A_eq,2) = ',num2str(x_length) ]);
    error(bbConstants.errorMsg);
end

% Check also that the length of "cnew" is correct
checkWidth_cnew  = (x_length == length(cnew) );
if ~checkWidth_cnew
    disp( ' .. ERROR: The "cnew" matrix built had the wrond size:' );
    disp(['           length(cnew) = ',num2str(length(cnew)),', is was expected to be length(cnew) = ',num2str(x_length) ]);
    error(bbConstants.errorMsg);
end


%% --------------------------------------------------------------------- %%
%% 7) THE NEW "b_eq" VECTOR DOES NOT NEED TO BE CHANGED
b_eq = b_in;


%% --------------------------------------------------------------------- %%
%% 8) THE "sdd_2_psd" RETURN VARIABLE SHOLUD BE A CELL ARRAY WITH ONE MAPPING PER "psd" VARIABLE
dd_2_psd = map_f_to_psd;


%% --------------------------------------------------------------------- %%
%% 9) FORMULATE THE INEQUALITY CONSTRAINTS

% Actually, the sedumi format input to this function does not allow for
% inequality constraint, and the non-negative variable are enforced with
% upper and lower bounds
% Hence the only inequality constraints are those required to enforce:
%   > the absolute value auxilliary variables, and
%   > the Diagonal Dominance constraints

A_ineq = [  sparse([],[],[],sum(A_ineq_numRows_for_dd),l_end,0)  ,  blkdiag( A_ineq_f_for_dd{:,1} )  ,  blkdiag( A_ineq_abs_for_dd{:,1} )  ];
b_ineq = sparse([],[],[],sum(A_ineq_numRows_for_dd),1,0);

% Check that the width of "A_ineq" is correct
checkWidth_A_ineq  = (x_length == size(A_ineq,2) );
if ~checkWidth_A_ineq
    disp( ' .. ERROR: The "A_ineq" matrix built had the wrond size:' );
    disp(['           size(A_ineq,2) = ',num2str(size(A_ineq,2)),', is was expected to be size(A_ineq,2) = ',num2str(x_length) ]);
    error(bbConstants.errorMsg);
end

%% --------------------------------------------------------------------- %%
%% 10) CONSTRUCT THE UPPER AND LOWER BOUNDS ON THE NEW DECISION VECTOR
lb = [ -inf * ones(f_end,1) ;...
          0 * ones(l_end-f_end,1) ;...
       -inf * ones(abs_for_psd_end-l_end,1) ...
     ];
 
ub = inf * ones(abs_for_psd_end,1);

% Check that both "lb" and "ub" have the correct length


%% --------------------------------------------------------------------- %%
%% 99) GET THE TIME AT THE END, AND DISPLAY THE ELASPSED TIME
time_conversion_end = clock;

time_conversion_elaspsed = etime(time_conversion_end,time_conversion_start);

% disp([' ... INFO: The SeDuMi formulation was converted form SDP to SDD-SOS in ',num2str(time_conversion_elaspsed),' seconds']);


% ----------------------------------------------------------------------- %
end  % <--- END OF FUNCTION
% ----------------------------------------------------------------------- %