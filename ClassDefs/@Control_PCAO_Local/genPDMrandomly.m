function [ P_blk, P_ij ] = genPDMrandomly( e1, e2, L, dim_subP )

P_blk = [];

A = diag(mean([e2,e1]) + random('uniform',-((e2-e1)/2),((e2-e1)/2),[dim_subP,1]));
for i = 1:L
    Q = orth(randn(dim_subP,dim_subP));
    PDM = Q'*A*Q;
    P_ij(:,:,i) = PDM;
    P_blk = blkdiag(P_blk,P_ij(:,:,i));
end

% for i=1:L
%	temp = randn(dim_subP);
%	[U,ignore] = eig((temp+temp')/2);
%	PDM = U*diag(abs(e1 + (e2-e1)*rand(dim_subP,1)))*U';
%	P_ij(:,:,i) = PDM;
%	P_blk = blkdiag(P_blk,P_ij(:,:,i));
% end
	
end