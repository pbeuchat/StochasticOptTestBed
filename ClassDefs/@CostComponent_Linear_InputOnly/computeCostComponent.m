function [returnCost , returnCostPerSubSystem] = computeCostComponent( obj , x , u , xi , currentTime )
% Defined for the "CostComponent" class, this function computes the cost
% for its type without performing any checks on the input
% ----------------------------------------------------------------------- %
%  AUTHOR:      Paul N. Beuchat
%  DATE:        13-Oct-2014
%  GOAL:        Black-Box Simulation-Based Test-Bed for Building Control
%
%  DESCRIPTION: > This function is specific to linear cost functions,
%                 assumptions are made and checks left out in order to
%                 speed up the computations
%               > Computational speed is important for this function
%                 because it is called at every iteration
% ----------------------------------------------------------------------- %


    returnCost = obj.r' * u + obj.c;

    returnCostPerSubSystem = sparse([],[],[], double(obj.n_ss) , 1 , 0);
    %returnCostPerSubSystem = [];
    

end
% END OF FUNCTION


