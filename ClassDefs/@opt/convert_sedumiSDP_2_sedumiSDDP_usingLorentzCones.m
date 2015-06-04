function [Anew, bnew, cnew, Knew, sdd_2_psd, q_per_psd_start, q_per_psd_end] = convert_sedumiSDP_2_sedumiSDDP_usingLorentzCones(A_in,b_in,c_in,K_in)
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
%% 0) GET THE TIME AT THE START OF PERFORMING THE CONVERSION
time_conversion_start = clock;


%% --------------------------------------------------------------------- %%
%% 1) CHECK THAT ARE ARE ACTUALLY ANY POSITIVE SEMI-DEFINITE VARIABLES

% Check that a field sepcifying "psd" variables even exists
if ~isfield(K_in,'s')
    % If not, then return the formulation like-for-like
    Anew = A_in;
    bnew = b_in;
    cnew = c_in;
    Knew = K_in;
    % With the conversion as empty
    sdd_2_psd = [];
    % Display a message letting the user know
    disp( ' ... NOTE: The SeDuMi problem input does NOT have any positive semi definite field defined' );
    disp( '           (ie. the field "K.s" does NOT exist, "~isfield(K,''s'') == false" )' );
    disp( '           Hence returning the exact same formulation because there is nothing for this function to do' );
    % And now return
    return;
end


% Even if the field exists, it could have been mistakely set as empty
% (which will make SeDuMi fail, but we will let the user find that out via
% SeDuMi and not via this conversion function
if isempty( K_in.s )
    % If not, then return the formulation like-for-like
    Anew = A_in;
    bnew = b_in;
    cnew = c_in;
    Knew = K_in;
    % With the conversion as empty
    sdd_2_psd = [];
    % Display a message letting the user know
    disp( ' ... NOTE: The SeDuMi problem input an EMPTY specification for the positive semi definite field' );
    disp( '           (ie. the field "K.s" exists but it is EMPTY, "isempty( K.s ) = true" )' );
    disp( '           Hence returning the exact same formulation because there is nothing for this function to do' );
    disp( ' ... NOTE: further that this formulation will likely cause SeDuMi to throw an error because the field "s"' );
    disp( '           but is empty' );
    % And now return
    return;
end



%% --------------------------------------------------------------------- %%
%% 2) GET THE POSITIVE DEFINITE VARAIBLES DEFINITION ...

% Get the "s" field from the input that defines the "psd" variables
s_in = K_in.s;

% Check that "s input" is a vector
if ~isvector( s_in )
    % If not, then return the formulation like-for-like
    Anew = A_in;
    bnew = b_in;
    cnew = c_in;
    Knew = K_in;
    % With the conversion as empty
    sdd_2_psd = [];
    % Display a message letting the user know
    disp( ' ... NOTE: For SeDuMi problem input the field "K.s" is NOT a vector' );
    disp( '           (ie. "isvector( K.s ) = false" )' );
    disp( '           A non-vector format cannot be interpretted by this function' );
    disp( ' ... NOTE: further that the exact same formulation is being returned and that this formulation will likely' );
    disp( '           cause SeDuMi to throw an error because the field "K.s" but is not a vector' );
    % And now return
    return;
end

% Get the number of "psd" variables
num_psd_variable = length( s_in );


%% ... AND DEFINE THE ROTATED LORENTZ VARIABLES TO REPLACE THEM

% For each "psd" matrix, let "n" denote the size, then (1/2)*(n-1)*n sub
% matrices are needed to define the equivalent SSD matrix

q_per_psd = 0.5 .* (s_in-1) .* s_in;

q_for_psd = 3 * ones( 1 , sum(q_per_psd) );




%% --------------------------------------------------------------------- %%
%% 3) GET THE OTHER TYPES OF VARIABLES SEPCIFIED IN THE INPUT PROBLEM

% Initialise flags sepcifying which ones are present
flag_include_f = false;         % Free variables
flag_include_l = false;         % Non-negative variables
flag_include_q = false;         % Lorentz variables
flag_include_r = false;         % Rotated Lorentz variables

if isfield(K_in,'f')
    f_in = K_in.f;
    flag_include_f = true;
else
    f_in = [];
end
if isfield(K_in,'l')
    l_in = K_in.l;
    flag_include_l = true;
else
    l_in = [];
end
if isfield(K_in,'q')
    q_in = K_in.q;
    flag_include_q = true;
else
    q_in = [];
end
if isfield(K_in,'r')
    r_in = K_in.r;
    flag_include_r = true;
else
    r_in = [];
end


%% CONVERT THESE TO THE "new" VARIABLES BY ADDING THE "r_for_psd"
clear Knew;
if flag_include_f
    Knew.f = f_in;
end
if flag_include_l
    Knew.l = l_in;
end
if flag_include_q
    Knew.q = [q_in , q_for_psd];
else
    Knew.q = q_for_psd;
end
if flag_include_r
    Knew.r = r_in;
end


%% --------------------------------------------------------------------- %%
%% 4) CREATE AN INDEX FOR THE START AND END OF EACH VARIABLE TYPE

if flag_include_f
    f_start = 1;
    f_end = f_start + Knew.f - 1;
else
    f_start = 0;
    f_end = 0;
end
if flag_include_l
    l_start = f_end + 1;
    l_end = l_start + Knew.l - 1;
else
    l_start = f_end;
    l_end = l_start;
end

% For the Lorentz variables, index the whole thing and the partitions
q_start = l_end + 1;
q_end = q_start + sum(Knew.q) - 1;


if flag_include_q
    q_in_start = l_end + 1;
    q_in_end = q_in_start + sum(q_in) - 1;
else
    q_in_start = l_end;
    q_in_end = q_in_start;
end

q_for_psd_start = q_in_end + 1;
q_for_psd_end = q_for_psd_start + sum(q_for_psd) - 1;

if flag_include_r
    r_start = q_end + 1;
    r_end = r_start + sum(r_in) - 1;
    
    r_in_start = q_in_end + 1;
    r_in_end = r_in_start + sum(r_in) - 1;
else
    r_start = q_end;
    r_end = r_start;
    
    r_in_start = q_in_end;
    r_in_end = r_in_start;
end


% Index also the set of "q" variables introduced per "psd" variable
% Initialise the variables first
q_per_psd_start = zeros(num_psd_variable,1);
q_per_psd_end = zeros(num_psd_variable,1);
temp_previous_end = q_in_end;
% Then step through the "psd" variables
for i_psd = 1:num_psd_variable
    % Get the number of "q" variable elements for this "i_psd"
    this_q_length = 3 * q_per_psd(i_psd);
    % Compute the start
    q_per_psd_start(i_psd,1) = temp_previous_end + 1;
    % Compute the end
    q_per_psd_end(i_psd,1) = q_per_psd_start(i_psd,1) + this_q_length - 1;
    % Update the temporary variable for passing around the previous end
    temp_previous_end = q_per_psd_end(i_psd,1);
end



%% --------------------------------------------------------------------- %%
%% 5) NOW BUILD A "per psd" MATRIX TO CONVERT THE "r" VARIABLES TO THE "s"

% Initialise a container for the mapping
map_q_to_psd = cell( num_psd_variable , 1 );

% Step through the "psd" variables
for i_psd = 1:num_psd_variable

    % Start by building an index of which element in the "psd" each "r"
    % variable corresponds to
    
    % Get the number of "r" variable elements for this "i_psd"
    this_psd_size = s_in(i_psd);
    this_q_length = 3 * q_per_psd(i_psd);
    
    % Initialise the index container
    M_index_ii = zeros(1,this_q_length);
    M_scale_ii = zeros(1,this_q_length);
    
    M_index_jj = zeros(1,this_q_length);
    M_scale_jj = zeros(1,this_q_length);
    
    M_index_i = zeros(1,this_q_length);
    M_index_j = zeros(1,this_q_length);
    M_scale_ij = zeros(1,this_q_length);
    % We will do this with for loops, which should be fast enough for such
    % simple operations
    this_q_index = 0;
    for iIndex = 1:this_psd_size
        for jIndex = iIndex+1:1:this_psd_size
            % FOR THE "M_{ii}" TERMS
            M_index_ii(1,this_q_index+1) =  iIndex;
            M_index_ii(1,this_q_index+2) =  iIndex;
            M_scale_ii(1,this_q_index+1) =  0.5*2/sqrt(2);%1;%2/sqrt(2);%0.5;
            M_scale_ii(1,this_q_index+2) =  0.5*2/sqrt(2);%1;%2/sqrt(2);%0.5;
            
            
            % FOR THE "M_{jj}" TERMS
            M_index_jj(1,this_q_index+1) =  jIndex;
            M_index_jj(1,this_q_index+2) =  jIndex;
            M_scale_jj(1,this_q_index+1) =  0.5*1/sqrt(2);%1;%1/sqrt(2);%0.5;
            M_scale_jj(1,this_q_index+2) = -0.5*1/sqrt(2);%-1;%-1/sqrt(2);%-0.5;
            
            
            % FOR THE "M_{ij}" TERMS
            M_index_i( 1,this_q_index+3)  =  iIndex;
            M_index_j( 1,this_q_index+3)  =  jIndex;
            M_scale_ij(1,this_q_index+3)  =  0.5;
            
            this_q_index = this_q_index + 3;
        end
    end
    
    % NOTE: the SeDuMi  Lorentz Constraints enforce the following:
    %   x(1) >= norm( [x(2) ;  x(3)] )
    % ...
    
    % We would like to create the mapping as sparse
    % Each element on the diagonal of "psd" variable should be summed from
    % 2*(n-1) elements of the "q" varaibles
    % While each element on the off-diagonal should correspond to only 1
    % element of the "q" variables
    % Hence we expect to have:
    %   ( 2 * n * (n-1) )   +   ( n * (n-1) )  =  3*n*(n-1)
    % non-zero elements
    % Hence initialise the indexing variables for building the sparse map:
    this_nnz   = 3 * this_psd_size * (this_psd_size-1);
    this_map_i = zeros( 1 , this_nnz );
    this_map_j = zeros( 1 , this_nnz );
    this_map_s = zeros( 1 , this_nnz );
    
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
                this_M_mask_ii = (M_index_ii==i_row);
                this_M_mask_jj = (M_index_jj==i_row);
                this_M_index_ii = find(this_M_mask_ii);
                this_M_index_jj = find(this_M_mask_jj);
                
                % Put the details into the map (note: we are assuming here
                % that "find" will only return a vector of size 2*(n-1))
                this_map_i( 1 , curr_map_entry:(curr_map_entry+2*(this_psd_size-1)-1) )  = curr_psd_vecIndex;
                this_map_j( 1 , curr_map_entry:(curr_map_entry+2*(this_psd_size-1)-1) )  = [this_M_index_ii , this_M_index_jj];
                this_map_s( 1 , curr_map_entry:(curr_map_entry+2*(this_psd_size-1)-1) )  = [M_scale_ii(this_M_index_ii) , M_scale_jj(this_M_index_jj)];
                
                % Increment the "curr_map_entry" accordingly
                curr_map_entry = curr_map_entry + 2*(this_psd_size - 1);
                
            else
                % Get a vector showing which elements in the "r" variables
                % correspond to the current index in the "psd" variable
                % NOTE: for speed up this could be done slightly better
                %       exploiting the fact that M_index_i/j was built with
                %       "j" always greater than "i"
                if j_col>i_row
                    this_M_mask_ij = bsxfun(@and,M_index_i==i_row,M_index_j==j_col);
                else
                    this_M_mask_ij = bsxfun(@and,M_index_i==j_col,M_index_j==i_row);
                end
                this_M_index_ij = find(this_M_mask_ij);
                
                % Put the details into the map (note: we are assuming here
                % that find will only return a vector of size 1)
                this_map_i( 1 , curr_map_entry ) = curr_psd_vecIndex;
                this_map_j( 1 , curr_map_entry ) = this_M_index_ij;
                this_map_s( 1 , curr_map_entry ) = M_scale_ij(this_M_index_ij);
                
                % Increment the "curr_map_entry" accordingly
                curr_map_entry = curr_map_entry + 1;
            end
            
        end        
    end
    
    % Now store the mapping
    map_q_to_psd{i_psd,1} = sparse( this_map_i , this_map_j , this_map_s , this_psd_size*this_psd_size , this_q_length , this_nnz );

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
A_in_s = A_in(:,(r_in_end+1):end);
c_in_s = c_in((r_in_end+1):end,1);

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
map_q_to_psd_all = blkdiag( map_q_to_psd{:,1} );

% And hence map the portions of the "A" and "c"
A_new_q = A_in_s * map_q_to_psd_all;
c_new_q = (c_in_s' * map_q_to_psd_all)';

% Finally build the new "A" and "c"
if flag_include_r
    Anew = [ A_in(:,1:q_in_end) , A_new_q , A_in(:,r_start:r_end) ];
    cnew = [ c_in(1:q_in_end,1) ; c_new_q ; c_in(r_start:r_end,1) ];
else
    Anew = [ A_in(:,1:q_in_end) , A_new_q ];
    cnew = [ c_in(1:q_in_end,1) ; c_new_q ];
end


%% --------------------------------------------------------------------- %%
%% 7) THE NEW "b" VECTOR DOES NOT NEED TO BE CHANGED
bnew = b_in;


%% --------------------------------------------------------------------- %%
%% 7) THE "sdd_2_psd" RETURN VARIABLE SHOLUD BE A CELL ARRAY WITH ONE MAPPING PER "psd" VARIABLE
sdd_2_psd = map_q_to_psd;


%% --------------------------------------------------------------------- %%
%% 99) GET THE TIME AT THE END, AND DISPLAY THE ELASPSED TIME
time_conversion_end = clock;

time_conversion_elaspsed = etime(time_conversion_end,time_conversion_start);

disp([' ... INFO: The SeDuMi formulation was converted form SDP to SDD-SOS in ',num2str(time_conversion_elaspsed),' seconds']);


% ----------------------------------------------------------------------- %
end  % <--- END OF FUNCTION
% ----------------------------------------------------------------------- %