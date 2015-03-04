function [ P ] = constructBLK( P_ij )
% THIS FUNCTION CONSTRUCTS A BLOCK DIAGONAL MATRIX BY THE 3D INPUT MATRIX
P = [];
diagonal_blocks = size(P_ij,3);
for i=1:diagonal_blocks
	P = blkdiag(P,P_ij(:,:,i));
end

end