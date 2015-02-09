function [ P_ij_perturb ] = perturbPDMrandomly( P_ij, a, e1, e2 )
% THIS FUNCTION PERTURBATES RANDOMLY AROUND THE GIVEN INPUT MATRIX
[ Delta_P_ij, ~ ] = Control_Rand_Local.genPDMrandomly( e1, e2, size(P_ij,3), size(P_ij,1) );
P_ij_perturb = (1-a)*P_ij + a*Delta_P_ij;

end

