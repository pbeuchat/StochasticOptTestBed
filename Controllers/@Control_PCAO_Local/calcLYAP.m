function [ dV, V_t, V_s, E_t ] = calcLYAP( z_old, z_new, P_ij, cost, dt )

% calculating error from the optimal cost function (i.e. from the optimal controller)
[ P_blk ] = Control_PCAO_Local_pnbEdits.constructBLK( P_ij );

V_s = z_old'*P_blk*z_old;
V_t = z_new'*P_blk*z_new;
dV = V_t - V_s;
%dV = 0; % CAO mod
E_t = (dV + dt*cost);
end