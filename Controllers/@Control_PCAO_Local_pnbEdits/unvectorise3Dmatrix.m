function [ P_ij ] = unvectorise3Dmatrix( P_vec, L )

elements = size(P_vec,1);
sublock_elements = elements/L;
dim_subP = sqrt(sublock_elements);

for i=1:L
    P_ij(:,:,i) = reshape(P_vec((i-1)*sublock_elements+1:i*sublock_elements,1),dim_subP,dim_subP);
end

end

