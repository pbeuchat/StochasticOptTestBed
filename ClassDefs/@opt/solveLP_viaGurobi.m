function [return_x , return_objVal, return_lambda, flag_solvedSuccessfully ] = solveLP_viaGurobi( f, c, A_ineq, b_ineq, A_eq, b_eq, lb, ub, inputModelSense, verboseOptDisplay )
% Defined for the "opt" class, this function solves a standard QP using the
% Gurobi solver package
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
%% GET THE EXPECTED SIZE OF THE DECISION VECTOR
return_x_expected_length = length(f);

%% --------------------------------------------------------------------- %%
%% IF ANY OF THE INPUT ARE EMPTY THEN SET THEN TO THEIR DEFAULT
% Set the additive cost constant = 0 by default
if isempty(c)
    c = 0;
end
% Set the Inequalit and equality constraints to be a compatible size
if isempty(A_ineq)
    A_ineq = sparse([],[],[],0,return_x_expected_length,0);
end
if isempty(b_ineq)
    b_ineq = zeros(0,1);
end
if isempty(A_eq)
    A_eq = sparse([],[],[],0,return_x_expected_length,0);
end
if isempty(b_eq)
    b_eq = zeros(0,1);
end
% Set the lower and upper bound to be unconstrained by default
if isempty(lb)
    lb = -1e21*ones(return_x_expected_length,1);
end
if isempty(ub)
    ub =  1e21*ones(return_x_expected_length,1);
end

try
    % Compare with:
    %[xMatlab,fObjValMatlab,QPexitFlagMatlab,QPoutputMatlab,QPlambdaMatlab]  = quadprog(H, f, A, b, Aeq, beq,[],[],[],options_qp);
    
    % Scaling for the objective function to (maybe) help with numerical
    % problems
    % -->> DON'T DO THIS HERE TO MAINTAIN THE GENERALITY OF THE
    % SOLVER
    %objValScaling = 1;
    %objValScalingInv = 1;
    
    %% BUILD THE GUROBI FORMULATION
    % Clear the model vairable for piece of mind
    clear model;
    % Specify the objective fucntion
    model.obj   = full(f);  %  *objValScaling;
    %model.Q     = not required
    % Specify the constraints
    model.A    =       [A_ineq ; A_eq]  ;
    model.rhs  = full( [b_ineq ; b_eq] );
    % Specify the sense of each row in the constraints
    modelSenseCharArray = char.empty(size(A_ineq,1)+size(A_eq,1),0);
    modelSenseCharArray( 1:size(A_ineq,1) , 1 ) = '<';
    modelSenseCharArray( (size(A_ineq,1)+1):(size(A_ineq,1)+size(A_eq,1)) , 1 ) = '=';
    model.sense = modelSenseCharArray;
    % Specify the variable types
    vtypeCharArray = char.empty(size(A_ineq,2),0);
    vtypeCharArray(:,1) = 'C';
    model.vtype = vtypeCharArray;
    % Specify the "model sense", ie. if the model in minimisation or
    % maximisation
    model.modelsense = inputModelSense;
    %model.varnames = names;
    % Specify the Lower and Upper bounds on each variable
    model.lb = lb;
    model.ub = ub;
    % Specify the model name that appears in the Gurobi log, and when
    % writing a model to a file
    model.modelname = 'Generic LP Solver using Gurobi';

    % Display the model if desired
    %gurobi_write(model, 'mip1.lp');

    clear params;
    params.method = -1;  % Options are: -1=automatic(default), 0=primal simplex, 1=dual simplex, 2=barrier, 3=concurrent, 4=deterministic concurrent
    if verboseOptDisplay
        params.outputflag = true;
    else
        params.outputflag = false;
    end
    % Turn this param on to distinguish result status: "INF_OR_UNBD"
    %params.DualReductions = 0;
    
    %% SOLVE THE OPTIMISATION FORMULATION
    result = gurobi(model, params);

    
    %% DISPLAY THE RESULT IF REQUESTED
    if verboseOptDisplay
        disp(result);
    end
    
    %% CHECK IF THE PROBLEM WAS SOLVED SUCCESSFULLY
    if ( strcmp(result.status, 'OPTIMAL') || strcmp(result.status, 'SUBOPTIMAL') );
        return_x                = result.x;
        return_objVal           = result.objval + c;  %  *objValScalingInv;
        lambdatemp              = result.pi;
        return_lambda.ineqlin   = -lambdatemp(1:size(A_ineq,1),1);
        return_lambda.eqlin     =  lambdatemp(size(A_ineq,1)+1:size(A_ineq,1)+size(A_eq,1),1);
        %QPslack                 = result.slack;
        %QPstatus                = result.status;
        %QPnumiter               = max([result.itercount, result.baritercount, result.nodecount]);
        flag_solvedSuccessfully = true;
    else
        % Set the return variable to placeholder values
        return_x                    = NaN * ones(length(f),1);
        return_objVal               = NaN;
        return_lambda               = [];
        flag_solvedSuccessfully     = false;
    
        disp([' ... ERROR: Optimization returned status: ',result.status ]);
        
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
    disp(' ... ERROR: an error occurred while building the LP for Gurobi, with the following message:');
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
if (length(return_x) ~= length(f) )
    error(' ... THE SOLUTION VECTOR "x" FROM THE QP DOES NOT AGREE IN SIZE OF "f"');
end


end  %<--- END OF FUNCTION



%% ---------------------------------------------------------------------- %
%% "GUROBI" INFO ...
%
% SEE THIS WEBSITE:
% http://www.gurobi.com/documentation/6.0/reference-manual/matlab_gurobi
%
%
%  PARAMTERS
%  >> Tolerances: These parameters control the allowable feasibility or optimality violations.
%     Parameter name        Purpose
%     ---------------------------------------------------------------------
%     BarConvTol            Barrier convergence tolerance
%                               Default value:	1e-8
%                               Minimum value:	0.0
%                               Maximum value:	1.0
%                               The barrier solver terminates when the relative difference between the primal and dual objective
%                                   values is less than the specified tolerance (with a GRB_OPTIMAL status)
%     BarQCPConvTol         Barrier QCP convergence tolerance
%                               Default value:	1e-6
%                               Minimum value:	0.0
%                               Maximum value:	1.0
%                               When solving a QCP model, the barrier solver terminates when the relative difference between the primal
%                                   and dual objective values is less than the specified tolerance (with a GRB_OPTIMAL status)
%     FeasibilityTol        Primal feasibility tolerance
%                               Default value:	1e-6
%                               Minimum value:	1e-9
%                               Maximum value:	1e-2
%                               All constraints must be satisfied to a tolerance of FeasibilityTol. Tightening this tolerance can
%                                   produce smaller constraint violations, but for numerically challenging models it can sometimes lead
%                                   to much larger iteration counts.
%     IntFeasTol            Integer feasibility tolerance
%                               Default value:	1e-5
%                               Minimum value:	1e-9
%                               Maximum value:	1e-1
%                               An integrality restriction on a variable is considered satisfied when the variable's value is less than
%                                   IntFeasTol from the nearest integer value. 
%     MarkowitzTol          Threshold pivoting tolerance
%                               Default value:	0.0078125
%                               Minimum value:	1e-4
%                               Maximum value:	0.999
%                               The Markowitz tolerance is used to limit numerical error in the simplex algorithm. Specifically, larger
%                                   values reduce the error introduced in the simplex basis factorization. A larger value may avoid numerical
%                                    problems in rare situations, but it will also harm performance
%     MIPGap                Relative MIP optimality gap
%                               Default value:	1e-4
%                               Minimum value:	0
%                               Maximum value:	Infinity
%                               The MIP solver will terminate (with an optimal result) when the relative gap between the lower and upper
%                                   objective bound is less than MIPGap times the upper bound.
%     MIPGapAbs             Absolute MIP optimality gap
%                               Default value:	1e-10
%                               Minimum value:	0
%                               Maximum value:	Infinity
%                               The MIP solver will terminate (with an optimal result) when the absolute gap between the lower and upper
%                                   objective bound is less than MIPGapAbs.
%     OptimalityTol         Dual feasibility tolerance
%                               Default value:	1e-6
%                               Minimum value:	1e-9
%                               Maximum value:	1e-2
%                               Reduced costs must all be smaller than OptimalityTol in the improving direction in order for a model to be
%                                   declared optimal.
%     PSDTol                Positive semi-definite tolerance
%                               Default value:	1e-6
%                               Minimum value:	0
%                               Maximum value:	Infinity
%                               Sets a limit on the amount of diagonal perturbation that the optimizer is allowed to perform on a Q matrix
%                                   in order to correct minor PSD violations. If a larger perturbation is required, the optimizer will
%                                   terminate with a GRB_ERROR_Q_NOT_PSD error.
%
%
% >> Simplex: These parameters control the operation of the simplex algorithms.
%     Parameter name        Purpose
%     ---------------------------------------------------------------------
%     InfUnbdInfo           Generate additional info for infeasible/unbounded models
%                               Type:	int
%                               Default value:	0
%                               Minimum value:	0
%                               Maximum value:	1
%                               Determines whether simplex (and crossover) will compute additional information when a model is determined to
%                                   be infeasible or unbounded.
%     NormAdjust            Simplex pricing norm
%                               Type:	int
%                               Default value:	-1
%                               Minimum value:	-1
%                               Maximum value:	3
%                               Chooses from among multiple pricing norm variants. The details of how this parameter affects the simplex
%                                   pricing algorithm are subtle and difficult to describe, so we've simply labeled the options 0 through 3.
%                                   The default value of -1 chooses automatically.
%     ObjScale              Objective scaling
%                               Default value:	0.0
%                               Minimum value:	-1
%                               Maximum value:	Infinity
%                               Divides the model objective by the specified value to avoid numerical errors that may result from very large
%                                   objective coefficients. The default value of 0 decides on the scaling automatically. A value less than
%                                   zero uses the maximum coefficient to the specified power as the scaling (so ObjScale=-0.5 would scale by
%                                   the square root of the largest objective coefficient).
%                               Objective scaling can be useful when the objective contains extremely large values, but it can also lead to
%                                   large dual violations, so it should be used sparingly.
%     PerturbValue          Simplex perturbation magnitude
%                               Default value:	0.0002
%                               Minimum value:	0
%                               Maximum value:	0.01
%                               Magnitude of the simplex perturbation. Note that perturbation is only applied when progress has stalled,
%                                   so the parameter will often have no effect.
%     Quad                  Quad precision computation in simplex
%                               Type:	int
%                               Default value:	-1
%                               Minimum value:	-1
%                               Maximum value:	1
%                               Enables or disables quad precision computation in simplex. The -1 default setting allows the algorithm to
%                                   decide. Quad precision can sometimes help solve numerically challenging models, but it can also
%                                   significantly increase runtime.
%     ScaleFlag             Model scaling
%                               Type:	int
%                               Default value:	1
%                               Minimum value:	0
%                               Maximum value:	1
%                               Enables or disables model scaling. Scaling usually improves the numerical properties of the model, which
%                                   typically leads to reduced solution times, but it may sometimes lead to larger constraint violations in
%                                   the original, unscaled model.
%     Sifting               Sifting within dual simplex
%                               Type:	int
%                               Default value:	-1
%                               Minimum value:	-1
%                               Maximum value:	2
%                               Enables or disables sifting within dual simplex. Sifting can be useful for LP models where the number of
%                                   variables is many times larger than the number of constraints (we typically only see significant benefits
%                                   when the ratio is 100 or more). Options are Automatic (-1), Off (0), Moderate (1), and Aggressive (2).
%     SiftMethod            LP method used to solve sifting sub-problems
%                               Type:	int
%                               Default value:	-1
%                               Minimum value:	-1
%                               Maximum value:	2
%                               LP method used to solve sifting sub-problems. Options are Automatic (-1), Primal Simplex (0), Dual Simplex (1),
%                                   and Barrier (2). Note that this parameter only has an effect when you are using dual simplex and sifting
%                                   has been selected (either automatically by dual simplex, or through the Sifting parameter).
%                               Changing the value of this parameter rarely produces a significant benefit.
%     SimplexPricing        Simplex variable pricing strategy
%                               Type:	int
%                               Default value:	-1
%                               Minimum value:	-1
%                               Maximum value:	3
%                               Determines the simplex variable pricing strategy. Available options are Automatic (-1), Partial Pricing (0),
%                                   Steepest Edge (1), Devex (2), and Quick-Start Steepest Edge (3).
%                               Changing the value of this parameter rarely produces a significant benefit.