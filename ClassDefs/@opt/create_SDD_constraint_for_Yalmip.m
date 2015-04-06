function [constraints] = create_SDD_constraint_for_Yalmip(P)
% Defined for the "opt" class, this function takes a symmetric Yalmip
% expression and returns to constraint required to enforce positve
% semi-definiteness via the Scaled Diagonally Dominant method
% ----------------------------------------------------------------------- %
%  AUTHOR:      Angelos Georghiou
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




%% BY PAUL
% [m,n] = size(P);
% 
% constraints = [];
% if (m ~= n)
%     error('matrix is not square');
% end
% 
% % Compute the number of "M" matrices required
% num_M_matrices = (n-1)*((n-1)+1) / 2;
% % Define the "Yalmip" variable for the "M" matrices
% M_all = sdpvar(3,num_M_matrices,'full');
% % Impose the constraint on each "M" matrix
% %constraints = constraints + (M_all(1:2,:) >= 0) + (M_all(1,:).*M_all(2,:)-M_all(3,:).^2 >= 0);
% for iM = 1:num_M_matrices
%     constraints = constraints + cone( [2*M_all(3,iM) , (M_all(1,iM)-M_all(2,iM))] , (M_all(1,iM)+M_all(2,iM)) );
% end
% 
% % Build the index of each element
% M_index_i = zeros(3,num_M_matrices);
% M_index_j = zeros(3,num_M_matrices);
% % We will do this with for loops, which should be fast enough for such
% % simple operations
% thisMcol = 0;
% for iIndex = 1:m
%     for jIndex = iIndex+1:1:m
%         thisMcol = thisMcol + 1;
%         M_index_i(1,thisMcol) = iIndex;
%         M_index_j(1,thisMcol) = iIndex;
%         M_index_i(2,thisMcol) = jIndex;
%         M_index_j(2,thisMcol) = jIndex;
%         M_index_i(3,thisMcol) = iIndex;
%         M_index_j(3,thisMcol) = jIndex;
%     end
% end
% 
% 
% 
% % Impose the equality between the "M" matrices and the input
% %thisMcol = 0;
% for iIndex = 1:1:m
%     for jIndex = iIndex:1:m
%         this_M_index = bsxfun(@and,M_index_i==iIndex,M_index_j==jIndex);
%         constraints = constraints + ( P(iIndex,jIndex) == sum(M_all(this_M_index)) );
%     end
% end
% 
% 
% 
% end  % <-- END OF FUNCTION




%% BY ANGELOS
[m,n] = size(P);

constraints = [];
if (m ~= n)
    error('matrix is not square');
end


% I = sdpvar(m,m,'symmetric');
I = cell(m,m);

for i = 1:1:1
    M = sdpvar(2,2,'symmetric');
    constraints = constraints + cone([2*M(1,2), M(1,1) - M(2,2)],M(1,1) + M(2,2));
    
    I{1,1} = M(1,1);
    constraints = constraints + [P(1,2) == M(1,2)];
    constraints = constraints + [P(2,1) == M(2,1)];
    I{2,2} = M(2,2);
end
for i = 1:1:1
    for j = 3:1:m
        M = sdpvar(2,2,'symmetric');
        constraints = constraints + cone([2*M(1,2), M(1,1) - M(2,2)],M(1,1) + M(2,2));
        
        I{i,i} = [I{i,i}, M(1,1)];
        constraints = constraints + [P(i,j) == M(1,2)];
        constraints = constraints + [P(j,i) == M(2,1)];
        I{j,j} = M(2,2);
    end
end

for i = 2:1:m
    for j = i+1:1:m
        M = sdpvar(2,2,'symmetric');
        constraints = constraints + cone([2*M(1,2), M(1,1) - M(2,2)],M(1,1) + M(2,2));
        
        I{i,i} = [I{i,i}, M(1,1)];
        constraints = constraints + [P(i,j) == M(1,2)];
        constraints = constraints + [P(j,i) == M(2,1)];
        I{j,j} = [I{j,j}, M(2,2)];
    end
end

for i = 1:1:m   
    constraints = constraints + [P(i,i) == sum(I{i,i})];
end

end  % <-- END OF FUNCTION


