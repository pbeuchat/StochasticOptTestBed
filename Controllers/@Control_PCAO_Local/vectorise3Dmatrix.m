function [ P_vec ] = vectorise3Dmatrix( P_ij )

dim_subP = size(P_ij,1);
controller_L = size(P_ij,3);

P_vec = [];
for ii=1:controller_L
    if ii==1
        P_vec = reshape(P_ij(:,:,ii),dim_subP*dim_subP,1);
    else
        P_vec = [P_vec;reshape(P_ij(:,:,ii),dim_subP*dim_subP,1)];
    end
end

end

