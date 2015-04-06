function [return_x , return_objVal, return_lambda, flag_solvedSuccessfully] = solveSDP_viaSedumi( A, b, c, K, options_in )
% Defined for the "opt" class, this function solves a standard SDP using
% the SeDuMi solver package
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
%% GET THE EXPECTED LENGTH OF THE FULL RETURN VARIABLE "return_x"

% Intialise the length counter - directly from the length of "c"
return_x_expected_length = length(c);

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
%% "TRY" TO BUILD AND SOLVES THE OPTIMISATION PROBLEM
try
    %% OBJECTIVE VALUE SCALING - ***NOT*** DONE BY THIS FUNCTION
    % Scaling for the objective function to (maybe) help with numerical
    % problems
    % -->> DON'T DO THIS HERE TO MAINTAIN THE GENERALITY OF THE
    % SOLVER
    %objValScaling = 1;
    %objValScalingInv = 1;
    
    %% SET ANY SeDuMi PARAMETERS AS DESIRED/SPECIFIED
    clear pars_sedumi;
    pars_sedumi = [];
    % For the "verboseness" of the output
    % NOTE: this field must be "0" or "1", and cannot be "true" or "false"
    if isfield(options_in,'verbose')
        verboseOptDisplay = options_in.verbose;
        if verboseOptDisplay
            pars_sedumi.fid = 1;
        else
            pars_sedumi.fid = 0;
        end
    else
        % By default: silence the output if not specified otherwise
        verboseOptDisplay = 0;
        pars_sedumi.fid = 0;
    end
    % OTHER PARAMETERS
    %pars_sedumi.eps = 1e-3;
    %pars_sedumi.stepdif = 0;
    
    
    
    
    %% SOLVE THE OPTIMISATION FORMULATION
    % SYNTAX: [x,y,info] = sedumi(A,b,c,K,pars)
    [return_x,~,info] = sedumi(A,b,c,K,pars_sedumi);
    %result = gurobi(model, params);

    
    %% DISPLAY THE RESULT IF REQUESTED
    if verboseOptDisplay
        disp(return_x);
    end
    
    %% CHECK IF THE PROBLEM WAS SOLVED SUCCESSFULLY
    %INFO.numerr = 0: desired accuracy achieved (see PARS.eps).
%      (II)  INFO.numerr = 1: numerical problems warning. Results are accurate
%            merely to the level of PARS.bigeps.
%      (III) INFO.numerr = 2: complete failure due to numerical problems.
    if ( (info.numerr == 0) || (info.numerr == 1) );
        % Display a success message only if "verbose output" is on
        if verboseOptDisplay && (info.numerr == 0)
            disp( ' INFO: SeDuMi solved the problem and achieved the desired (see "pars_sedumi.eps"' );
        end
        % Display the "numerical problem warning" always
        if info.numerr == 1
            disp( ' NOTE: SeDuMi solved the problem ***BUT*** warned of numerical problems encountered' );
            disp( '       The results are accurate merely to the level of "pars_sedumi.bigeps"' );
        end
        % The optimal decision vector is already set to the return variable
        %return_x                = return_x;
        % Compute the optimal value of the problem
        return_objVal           = c' * return_x;  %  *objValScalingInv;
        % The return dual variables...
        return_lambda               = [];
        flag_solvedSuccessfully = true;
    else
        % Set the return variable to placeholder values
        return_x                    = NaN * ones(length(f),1);
        return_objVal               = NaN;
        return_lambda               = [];
        flag_solvedSuccessfully     = false;
    
        disp( ' ... ERROR: Optimization returned status: "complete failure due to numerical problems."' );
        
        % --------------------------------------------------------------- %
        %% Interpret the exit conditions
        switch result.status
            case 'LOADED'           % Code: 1
                disp('Model is loaded, but no solution information is available.');
            case 'OPTIMAL'          % Code: 2
                disp('Model was solved to optimality (subject to tolerances), and an optimal solution is available.');
            case 'INFEASIBLE'       % Code: 3
                disp('Model was proven to be infeasible.');
            case 'INF_OR_UNBD'      % Code: 4
                disp('Model was proven to be either infeasible or unbounded. To obtain a more definitive conclusion, set the DualReductions parameter to 0 and reoptimize.');
            case 'UNBOUNDED'        % Code: 5
                disp('Model was proven to be unbounded. Important note: an unbounded status indicates the presence of an unbounded ray that allows the objective to improve without limit. It says nothing about whether the model has a feasible solution. If you require information on feasibility, you should set the objective to zero and reoptimize.');
            case 'CUTOFF'           % Code: 6
                disp('Optimal objective for model was proven to be worse than the value specified in the Cutoff parameter. No solution information is available.');
            case 'ITERATION_LIMIT'  % Code: 7
                disp('Optimization terminated because the total number of simplex iterations performed exceeded the value specified in the IterationLimit parameter, or because the total number of barrier iterations exceeded the value specified in the BarIterLimit parameter.');
            case 'NODE_LIMIT'       % Code: 8
                disp('Optimization terminated because the total number of branch-and-cut nodes explored exceeded the value specified in the NodeLimit parameter.');
            case 'TIME_LIMIT'       % Code: 9
                disp('Optimization terminated because the time expended exceeded the value specified in the TimeLimit parameter.');
            case 'SOLUTION_LIMIT'   % Code: 10
                disp('Optimization terminated because the number of solutions found reached the value specified in the SolutionLimit parameter.');
            case 'INTERRUPTED'      % Code: 11
                disp('Optimization was terminated by the user.');
            case 'NUMERIC'          % Code: 12
                disp('Optimization was terminated due to unrecoverable numerical difficulties.');
            case 'SUBOPTIMAL'       % Code: 14
                disp('Unable to satisfy optimality tolerances; a sub-optimal solution is available.');
            case 'IN_PROGRESS'      % Code: 15
                disp('A non-blocking optimization call was made (by setting the NonBlocking parameter to 1 in a Gurobi Compute Server environment), but the associated optimization run is not yet complete.');
        end

    end
    
    
%% HANDLE ANY ERRORS THAT OCCUR WHILE BUILDING THE GUROBI FORMULATION
catch matlabExceptionObject
    % Update the user on what occurred
    disp(' ... ERROR: an error occurred while building the SDP for SeDuMi, with the following message:');
    disp(matlabExceptionObject.message);
    
    % Display the "stack" of function leading to the error
    disp(' '); disp(' ');
    disp(' ... ERROR: Following is the full exception report:');
    exceptionReport = matlabExceptionObject.getReport;
    disp(exceptionReport);
    
    % Set the return variable to placeholder values
    return_x                    = NaN * ones(length(f),1);
    return_objVal               = NaN;
    return_lambda               = [];
    flag_solvedSuccessfully     = false;
end


% SANITY CHECK THAT A SOLUTION OF THE CORRECT SIZE WAS RETURNED
if (length(return_x) ~= return_x_expected_length )
    error(' ... THE SOLUTION VECTOR "x" FROM SeDuMi DOES NOT AGREE WITH THE EXPECTED SIZE');
end


end  %<--- END OF FUNCTION



%% ---------------------------------------------------------------------- %
%% "SeDuMi" INFO ...
%
% SEE THIS WEBSITE:
% http://sedumi.ie.lehigh.edu 
%
%
%  PARAMTERS
%  >> Category: ...
%     Parameter name        Purpose
%     ---------------------------------------------------------------------
%     ...                   ...Barrier convergence tolerance
%                               Default value:	...
%                               Minimum value:	...
%                               Maximum value:	...
%                               <description>
%
% FROM THE HELP INFORMATION
%      (1) INFO.pinf=INFO.dinf=0: x is an optimal solution (as above)
%        and y certifies optimality, viz.\ b'*y = c'*x and c - A'*y >= 0.
%        Stated otherwise, y is an optimal solution to
%        MAXIMIZE b'*y SUCH THAT c-A'*y >= 0.
%        If size(A,2)==length(b), then y solves the linear program
%        MAXIMIZE b'*y SUCH THAT c-A*y >= 0.
%  
%      (2) INFO.pinf=1: there cannot be x>=0 with A*x=b, and this is certified
%        by y, viz. b'*y > 0 and A'*y <= 0. Thus y is a Farkas solution.
%  
%      (3) INFO.dinf=1: there cannot be y such that c-A'*y >= 0, and this is
%        certified by x, viz. c'*x <0, A*x = 0, x >= 0. Thus x is a Farkas
%        solution.
%  
%      (I)   INFO.numerr = 0: desired accuracy achieved (see PARS.eps).
%      (II)  INFO.numerr = 1: numerical problems warning. Results are accurate
%            merely to the level of PARS.bigeps.
%      (III) INFO.numerr = 2: complete failure due to numerical problems.
%  
%      INFO.feasratio is the final value of the feasibility indicator. This
%      indicator converges to 1 for problems with a complementary solution, and
%      to -1 for strongly infeasible problems. If feasratio in somewhere in
%      between, the problem may be nasty (e.g. the optimum is not attained),
%      if the problem is NOT purely linear (see below). Otherwise, the reason
%      must lie in numerical problems: try to rescale the problem.
