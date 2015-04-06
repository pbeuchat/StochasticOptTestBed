function [return_x , return_objVal, return_lambda, flag_solvedSuccessfully, retur_time ] = solveSDP_sedumiInputFormat_withRelaxationOption( A_in_sedumi, b_in_sedumi, c_in_sedumi, K_in_sedumi, solverToUse, sdpRelaxation, verboseOptDisplay )
% Defined for the "opt" class, this function solves a standard SDP.
% The formulation of the SDP is expected to be input in the SeDuMi format.
% There is an optional specification for solving the SDP via a relaxation
% method
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        06-Apr-2015
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > 
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

% > Options for "solverToUse"
%       - 'sedumi'
%       - 'gurobi'
%       - 'mosek'
% > And for the "sdpRelaxation"
%       - "none"    means to solve the SDP
%       - "sdd      means to apply the Scaled Diagonally Dominant
%                   relaxation (results in a SOCP to be solved)
%       - "dd       means to apply the Diagonally Dominant relaxation
%                   (results in a LP to be solved)


%% --------------------------------------------------------------------- %%
%% GET THE EXPECTED LENGTH OF THE FULL RETURN VARIABLE "return_x"

% Intialise the length counter - directly from the length of "c"
return_x_expected_length = length(c_in_sedumi);

% % Alternatively, compute the length by counting variables
% return_x_expected_length = 0;
% % Sum the variable length from each possible type specified in
% % "K_in_sedumi"
% % For the "free" variables
% if isfield(K_in_sedumi,'f')
%     if ~isempty(K_in_sedumi.f)
%         return_x_expected_length = return_x_expected_length + sum( K_in_sedumi.f );
%     end
% end
% % For the "non-negative" variables
% if isfield(K_in_sedumi,'l')
%     if ~isempty(K_in_sedumi.l)
%         return_x_expected_length = return_x_expected_length + sum( K_in_sedumi.l );
%     end
% end
% % For the "Lorentz" variables
% if isfield(K_in_sedumi,'q')
%     if ~isempty(K_in_sedumi.q)
%         return_x_expected_length = return_x_expected_length + sum( K_in_sedumi.q );
%     end
% end
% % For the "Rotated Lorentz" variables
% if isfield(K_in_sedumi,'r')
%     if ~isempty(K_in_sedumi.r)
%         return_x_expected_length = return_x_expected_length + sum( K_in_sedumi.r );
%     end
% end
% % For the "Positive Semi-Definite" variables
% if isfield(K_in_sedumi,'s')
%     if ~isempty(K_in_sedumi.s)
%         return_x_expected_length = return_x_expected_length + sum( K_in_sedumi.s );
%     end
% end



%% --------------------------------------------------------------------- %%
%% START THE CONVERSION TIMER
time_toConvert_start = clock;

%% --------------------------------------------------------------------- %%
%% CONVERT THE "SeDuMi" FORMULATION FOR THE REQUESTED "solver" AND "sdp relaxation"
% IF REQUESTED, THEN CONVERT THE FORMULATION TO BE FOR THE:
%   > Requested "solverToUse"
%   > And for the requested "sdpRelaxation"
%       - "none"    means to solve the SDP
%       - "sdd      means to apply the Scaled Diagonally Dominant
%                   relaxation (results in a SOCP to be solved)
%       - "dd       means to apply the Diagonally Dominant relaxation
%                   (results in a LP to be solved)

%% IF: no relaxation was requested
if strcmpi( sdpRelaxation , 'none' )
    % If the selected solver is NOT "sedumi" then convert as requested
    if strcmpi( solverToUse , 'sedumi' )
        % This is exactly the input format, hence nothing to conver
        clear options_sedumi;
        options_sedumi.verbose = verboseOptDisplay;
        
    elseif strcmpi( solverToUse, 'mosek' )
        % CONVERT IT TO MOSEK
        %mosek_prob = opt.convert_sedumi2Mosek(A_sedumi,b_sedumi,c_sedumi,K_sedumi);
        %[mosek_r,mosek_res]     = mosekopt('minimize',mosek_prob);
        % See this website for the defintion and example of an SDP in Mosek:
        % http://docs.mosek.com/7.1/toolbox/A_guided_tour.html#section-node-_A%20guided%20tour_Semidefinite%20optimization
        
    else
        disp( ' ... ERROR: The specified "solverToUse" was not recognised');
        error(bbConstants.errorMsg);
    end
    
%% ELSEIF: the "sdd" relaxation was requested
elseif strcmpi( sdpRelaxation , 'sdd' )
    % Convert the SeDuMi SDP formulation to a SeDuMi SOCP formulation
    [A_socp_sedumi, b_socp_sedumi, c_socp_sedumi, K_socp_sedumi, sdd_2_psd , index_per_psd_start, index_per_psd_end] = opt.convert_sedumiSDP_2_sedumiSDDP_usingRotLorentzCones(A_in_sedumi,b_in_sedumi,c_in_sedumi,K_in_sedumi);
    % If the selected solver is NOT "sedumi" then convert as requested
    if strcmpi( solverToUse , 'sedumi' )
        % Nothing to do because this is exactly the format converted to
        % above, hence nothing further to convert
        clear options_sedumi;
        options_sedumi.verbose = verboseOptDisplay;
        
    elseif strcmpi( solverToUse, 'mosek' )
        % CONVERT IT TO MOSEK
        %mosek_prob = opt.convert_sedumi2Mosek(A_sedumi,b_sedumi,c_sedumi,K_sedumi);
        %[mosek_r,mosek_res]     = mosekopt('minimize',mosek_prob);
        % See this website for the defintion and example of an SDP in Mosek:
        % http://docs.mosek.com/7.1/toolbox/A_guided_tour.html#section-node-_A%20guided%20tour_Semidefinite%20optimization
        
    elseif strcmpi( solverToUse, 'mosek' )
        
    % ELSE: the specified "solverToUse" was not recognised
    else
        disp( ' ... ERROR: The specified "solverToUse" was not recognised');
        error(bbConstants.errorMsg);
    end
    
%% ELSEIF: the "dd" relaxation was requested
elseif strcmpi( sdpRelaxation , 'dd' )
    % Convert the SeDuMi SDP formulation to a generic LP formulation
    [flag_success, A_ineq, b_ineq, A_eq, b_eq, lb, ub, cnew, dd_2_psd, f_per_psd_start, f_per_psd_end, time_conversion_elaspsed] = opt.convert_sedumiSDP_2_DD_LP(A_in_sedumi,b_in_sedumi,c_in_sedumi,K_in_sedumi);
    % If the conversion was not successful then let the user know
    if ~flag_success
        disp( ' ... ERROR: converting the SeDuMi format Semi-Definte Program to a Diagonally Dominant' );
        disp( '            relaxation did NOT work for some reason...');
        error(bbConstants.errorMsg);
    end
    
%% ELSE: the specified "sdpRelation" method was not recognised
else
    disp( ' ... ERROR: The "sdpRelation" method was not recognised');
    error(bbConstants.errorMsg);
end


%% --------------------------------------------------------------------- %%
%% STOP THE CONVERSION TIMER
time_toConvert_end = clock;


%% --------------------------------------------------------------------- %%
%% START THE SOLVE TIMER
time_toSolve_start = clock;


%% --------------------------------------------------------------------- %%
%% SOLVE THE CONVERTED FORMULATION WITH THE REQUESTED "solver"


%% IF: no relaxation was requested
if strcmpi( sdpRelaxation , 'none' )
    %% ---> Solve with "SEDUMI" - using "NO" relaxation
    if strcmpi( solverToUse , 'sedumi' )
        % Set any parameters as desired
        clear options_sedumi;
        % Silence the output if requested
        options_sedumi.verbose = verboseOptDisplay;
        % PASS TO SEDUMI
        [return_x , return_objVal, return_lambda, flag_solvedSuccessfully] = opt.solveSDP_viaSedumi( A_in_sedumi, b_in_sedumi, c_in_sedumi, K_in_sedumi, options_sedumi );
        
    %% ---> Solve with "MOSEK" - using "NO" relaxation
    elseif strcmpi( solverToUse , 'mosek' )
        %[mosek_r,mosek_res]     = mosekopt('minimize',mosek_prob);
    end
    
%% ELSEIF: the "sdd" relaxation was requested
elseif strcmpi( sdpRelaxation , 'sdd' )
    %% ---> Solve with "SEDUMI" - using "SDD" relaxation
    if strcmpi( solverToUse , 'sedumi' )
        % Set any parameters as desired
        clear options_sedumi;
        %pars_sedumi.eps = 1e-3;
        %pars_sedumi.stepdif = 0;
        % Silence the output if requested
        options_sedumi.verbose = verboseOptDisplay;
        % PASS TO SEDUMI
        [return_x_socp , return_objVal, return_lambda_socp, flag_solvedSuccessfully] = opt.solveSOCP_viaSedumi( A_socp_sedumi, b_socp_sedumi, c_socp_sedumi, K_socp_sedumi, options_sedumi );
        % Convert the result back to the PSD variables
        num_psd_variables = length( sdd_2_psd );
        % Build the PSD section first
        length_psd_variables = sum( K_in_sedumi.s .* K_in_sedumi.s );
        return_x_psd_portion = zeros(length_psd_variables,1);
        curr_start_index = 1;        
        for i_psd = 1:num_psd_variables
            % Get the size of this "psd" variable
            this_psd_size = K_in_sedumi.s(i_psd);
            % Get the range into which to put the "psd" varaible
            thisRange = curr_start_index:(curr_start_index+this_psd_size*this_psd_size-1);
            % Use the "sdd_2_psd" mapping to put-in the "psd" varaible
            return_x_psd_portion(thisRange,1) = sdd_2_psd{i_psd,1} * return_x_socp( index_per_psd_start(i_psd)  : index_per_psd_end(i_psd) ,  1 );
            % Update the index counter
            curr_start_index = curr_start_index+this_psd_size*this_psd_size;
        end
        % Get the portion from above the "socp" variables used for the
        % relaxation
        if index_per_psd_start(1) > 1
            return_x_above = return_x_socp( 1 : (index_per_psd_start(1)-1) , 1 );
        else
            return_x_above = zeros(0,1);
        end
        % Get the portion from below the "socp" variables used for the
        % relaxation
        if index_per_psd_end(num_psd_variables) < length(return_x_socp)
            return_x_below = return_x_socp( (index_per_psd_end(num_psd_variables)+1) : length(return_x_socp) , 1 );
        else
            return_x_below = zeros(0,1);
        end
        % Now build the full return variable
        return_x = [ return_x_above         ;...
                     return_x_psd_portion   ;...
                     return_x_below          ...
                   ];
        
    % PASS TO GUROBI
    elseif strcmpi( solverToUse , 'gurobi' )
        %[mosek_r,mosek_res]     = mosekopt('minimize',mosek_prob);
        
    % ELSE: the specified "solverToUse" was not recognised
    else
        disp( ' ... ERROR: The specified "solverToUse" was not recognised');
        error(bbConstants.errorMsg);
    end
    
%% ELSEIF: the "dd" relaxation was requested
elseif strcmpi( sdpRelaxation , 'dd' )
    
    % If requested to solve the resultant LP with "SeDuMi", then change to
    % solving with "Gurobi"
    if ~strcmpi( solverToUse , 'sedumi' )
        % If ask to solve a LP with "SeDuMi" that is a little silly
        % Change to solving with "Gurobi" instead
        solverToUse = gurobi;
        % Inform the user about the change
        disp( ' ... NOTE: the conversion from an SDP to a LP using the Diagonal Dominance relaxation was successful' );
        disp( '           However, it was requested to solve the LP with "SeDuMi". This seems cumbersome...' );
        disp( '           Hence changing to solve the LP with "Gurobi" instead' );
    end
    
    
    %% ---> Solve with "GUROBI" - using "DD" relaxation
    if ~strcmpi( solverToUse , 'sedumi' )
        
        
    end
    
    
    
    
%% ELSE: the specified "sdpRelation" method was not recognised
else
    disp( ' ... ERROR: The "sdpRelation" method was not recognised');
    error(bbConstants.errorMsg);
end

% % Set any parameters as desired
% clear pars_sedumi;
% pars_sedumi = [];
% %pars_sedumi.eps = 1e-3;
% %pars_sedumi.stepdif = 0;
% % Silence the output
% pars_sedumi.fid = 1;
% 
% % Get the current clock for timing the solver
% tempTime = clock;
% 
% % Call SeDuMi
% % SYNTAX: [x,y,info] = sedumi(A,b,c,K,pars)
% [x,~,~] = sedumi(A_in_sedumi,b_in_sedumi,c_in_sedumi,K_in_sedumi,pars_sedumi);
% 
% 
% % Get the current clock and compute the solver time
% time_forSDP = etime(clock,tempTime);
% disp([' ... INFO: SeDuMi solved the problem in: ',num2str(time_forSDP),' seconds']);




%% --------------------------------------------------------------------- %%
%% STOP THE SOLVE TIMER
time_toSolve_end = clock;



% --------------------------------------------------------------------- %%
% EXTRACT THE RETURN VARIABLES FROM THE OPTIMAL DECISION VECTOR
% 
% 
% Pnew = cell( numIter , 1 );
% pnew = cell( numIter , 1 );
% snew = cell( numIter , 1 );
% 
% if strcmpi( sdpRelaxation , 'none' )
%     for iIter = 1:numIter
%         Pnew{iIter,1} = mat( x( (P_start - 1 + P_index(iIter,1)) : (P_start - 1 + P_index(iIter,1) + P_size(iIter,1) - 1)  ,  1 ) , n_x );
%         pnew{iIter,1} =      x( (p_start - 1 + p_index(iIter,1)) : (p_start - 1 + p_index(iIter,1) + p_size(iIter,1) - 1)  ,  1 );
%         snew{iIter,1} =      x(  s_start - 1 + s_index(iIter,1) ,  1 );
%     end
% elseif strcmpi( sdpRelaxation , 'sdd' )
%     for iIter = 1:numIter
%         Pnew{iIter,1} = mat( sdd_2_psd{iIter,1} * x( r_per_psd_start((iIter-1)*2+1,1)  : r_per_psd_end((iIter-1)*2+1,1) ,  1 ) , n_x );
%         pnew{iIter,1} =      x( (p_start - 1 + p_index(iIter,1)) : (p_start - 1 + p_index(iIter,1) + p_size(iIter,1) - 1)  ,  1 );
%         snew{iIter,1} =      x(  s_start - 1 + s_index(iIter,1) ,  1 );
%     end
% elseif strcmpi( sdpRelaxation , 'dd' )
%     
% else
%     disp( ' ... ERROR: The "sdpRelation" method was not recognised');
%     error(bbConstants.errorMsg);
% end


%% --------------------------------------------------------------------- %%
%% @TODO - SET THE RETURN DUAL VARIABLES - THIS IS A HACK AT THE MOMENT
return_lambda = [];


%% --------------------------------------------------------------------- %%
%% COMPUTE THE RETURN TIMER RESULTS
clear returnTime;
retur_time.convert = etime( time_toConvert_end , time_toConvert_start);
retur_time.solve   = etime( time_toSolve_end   , time_toSolve_start);

%% --------------------------------------------------------------------- %%
%% SANITY CHECK THAT A DECISION VECTOR OF THE CORRECT SIZE WAS FOUND
if (length(return_x) ~= return_x_expected_length )
    error(' ... THE SOLUTION VECTOR "x" FROM THE SDP DOES NOT AGREE WITH THE EXPECTED SIZE');
end


end  %  <-- END OF FUNCTION