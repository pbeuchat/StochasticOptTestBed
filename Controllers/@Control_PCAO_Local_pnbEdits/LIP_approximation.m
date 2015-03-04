function [ theta, orders, bounds ] = LIP_approximation( max_order, monomial_number, X_buffer, P_ij_buffer, E_buffer, Global_Cost_buffer, GlobalCapBuffer, w )

% P_ij_buffer and E_buffer contain all the T_buffer last values respectively
T_buffer = size(P_ij_buffer,2);
for i = 1:T_buffer
    [ x ] = Control_PCAO_Local_pnbEdits.createTRAININGdata(X_buffer, P_ij_buffer(:,i), Global_Cost_buffer, GlobalCapBuffer, i);
    X(:,i) = x; % bug!!! size of x changes as optimiterations increase (historical buffered data increase)
end
X_elements = size(X,1);

fprintf('\nRandom monomials generation...')
orders = [];
monomial_cluster = round(monomial_number/max_order);
rest_monomials = monomial_number - monomial_cluster*max_order;
for i=1:max_order
    if i==1
        monomials = monomial_cluster + rest_monomials;
    else
        monomials = monomial_cluster;
    end
    [ temp ] = Control_PCAO_Local_pnbEdits.monomialRANDOMorders( monomials, X_elements, i );
    orders = [ orders; temp ];
end
orders = [orders;zeros(1,X_elements)]; % constant term
fprintf(' OK!')
% generate randomly j monomials of the form x(1)^orders(1)*x(2)^orders(2)*x(3)^orders(3)...
for i=1:T_buffer
    [ phi ] = Control_PCAO_Local_pnbEdits.calcPHI( [ X(:,i) ], orders );
    PHI(:,i) = phi;
end
[ PHI, bounds ] = Control_PCAO_Local_pnbEdits.normalise( PHI, w );

% LSQ approximation
fprintf('\nEstimator training process...')
% theta = E_buffer'\PHI';

l = 10;
reg_mat = [eye(monomial_number), zeros(monomial_number,1); zeros(1,monomial_number), 0];
C = [PHI'; sqrt(l)*reg_mat];
d = [E_buffer'; zeros(monomial_number + 1,1)];
theta = lsqlin(C, d, [],[])';

fprintf('OK!')

end