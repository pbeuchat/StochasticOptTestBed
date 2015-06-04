function [return_x , return_objVal, return_lambda, flag_solvedSuccessfully ] = solveQP_viaYalmip( H, f, c, A_ineq, b_ineq, A_eq, b_eq, inputModelSense, verboseOptDisplay )
% Defined for the "opt" class, this function solves a standard QP using the
% Yalmip solver interface package
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



% Specify the decision vector
%u_fullHorizon = sdpvar( double(obj.n_u)*double(obj.statsPredictionHorizon) , 1 , 'full' );

% Specify the objective
%thisObj_fullHorizon = u_fullHorizon' * R_new * u_fullHorizon + r_new * u_fullHorizon + c_new;

% Specify the constraints
%thisCons_fullHorizon = ( obj.A_ineq_input * u_fullHorizon <= obj.b_ineq_input );


% Define the options
    %thisOptions          = sdpsettings;
    %thisOptions.debug    = false;
    %thisOptions.verbose  = true;

    % Call the solver via Yalmip
    % SYNTAX: diagnostics = solvesdp(Constraints,Objective,options)
    %diagnostics = solvesdp(thisCons_fullHorizon,thisObj_fullHorizon,thisOptions);

    % Interpret the results
    %if diagnostics.problem == 0
        %disp(' ... the optimisation formulation was Feasible and has been solved')
    %elseif diagnostics.problem == 1
    %    disp(' ... the optimisation formulation was Infeasible');
    %    error(' Terminating :-( See previous messages and ammend');
    %else
    %    disp(' ... the optimisation formulation was strange, it was neither "Feasible" nor "Infeasible", something else happened...');
    %    error(' Terminating :-( See previous messages and ammend');
    %end

    % Extract the input from the decision variable
    %obj.u_MPC_fullHorizon = double( u_fullHorizon );
    
    