classdef opt < handle
% This class interfaces the disturbance and system with the controller
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This class is the heart of the simulator
%               > It has the high-level function to take in the:
%                   - current state
%                   - current input
%                   - current disturbance
%               > The model is porgressed
%               > And the following are returned:
%                   - updated state
%                   - stage cost
%                   - infomation about constraint satisfaction
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



    properties(Hidden,Constant)
        % Number of properties required for object instantation
        n_properties@uint64 = uint64(0);
        % Name of this class for displaying relevant messages
        thisClassName@string = 'opt';
    end
   
    properties (Access = public)
        % Very few properties should have public access, otherwise the
        % concept and benefits of Object-Orientated-Programming will be
        % degraded...
    end
    
    properties (Access = private)
        
    end
    
    
    
    methods
        % This is the "CONSTRUCTOR" method
        function obj = opt()
            % Allow the Constructor method to pass through when called with
            % no nput arguments (required for the "empty" object array
            % creator)
            %if nargin > 0
            %end
                
        end
        % END OF: "function obj = opt()"
      
        % This allows the "DECONSTRUCTOR" method to be augmented
        %function delete(obj)
        %end
        % END OF: "function delete(obj)"
        
    end
    % END OF: "methods"
    
    %methods (Static = false , Access = public)
    %end
    % END OF: "methods (Static = false , Access = public)"
    
    %methods (Static = false , Access = private)
    %end
    % END OF: "methods (Static = false , Access = private)"
        
        
    methods (Static = true , Access = public)
        
        [return_x , return_objVal, return_lambda, flag_solvedSuccessfully ] = solveQP_viaGurobi( H, f, c, A_ineq, b_ineq, A_eq, b_eq, inputModelSense, verboseOptDisplay );
        
        [Anew, bnew, cnew, Knew, sdd_2_psd , r_for_psd_start, r_for_psd_end] = convert_sedumiSDP_2_sedumiSDDP(A_in,b_in,c_in,K_in);
        
        [flag_success, A_ineq, b_ineq, A_eq, b_eq, lb, ub, cnew, dd_2_psd, f_per_psd_start, f_per_psd_end, time_conversion_elaspsed] = convert_sedumiSDP_2_DD_LP(A_in,b_in,c_in,K_in);
        
        prob = convert_sedumi2Mosek(A,b,c,K);
        
        [constraints] = create_DD_constraint_for_Yalmip(P);
        
        [constraints] = create_SDD_constraint_for_Yalmip(P);
        
    end
    % END OF: "methods (Static = true , Access = public)"
        
    %methods (Static = true , Access = private)
        
    %end
    % END OF: "methods (Static = true , Access = private)"
    
end

