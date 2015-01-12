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

    % Initialise the return cost to be zero
    returnCost = 0;
    returnCostPerSubSystem = zeros(obj.numSubSystemCosts);

    % Step through each of the "Sub-Systems" as defined by the size of the
    % "subSystemCostsArray" array
    for iSubSys = 1 : obj.numSubSystemCosts
        % Compute the cost for this component
        % Assuming that each element of the "obj.subSystemCostsArray" is a
        % primary type of "CostComponent" element and hence returns only a
        % "returnCost" accompanied by an empty "returnCostPerSubSystem"
        [thisReturnCost , ~] = computeCostComponent( obj.subSystemCostsArray(iSubSys,1) , x , u , xi , currentTime );
        % Use this cost as required
        returnCostPerSubSystem(iSubSys,1) = thisReturnCost;
        returnCost = returnCost + thisReturnCost;
    end


end
% END OF FUNCTION


