function [ P_ij_buffer, E_buffer, E_est_buffer, Cost_buffer, X_buffer, V_buffer, Beta_buffer ] = updateBuffer( P_ij, P_ij_buffer, Etot, E_buffer, ...
    E_est, E_est_buffer, dailyCost, Cost_buffer, x_cur, X_buffer, V_t, V_buffer, ActiveBeta_t, Beta_buffer, T_buffer, timestep_counter )

% THIS FUNCTION UPDATES THE BUFFERED VALUES

P_ij_vec = Control_Rand_Local.vectorise3Dmatrix( P_ij );
fprintf('\nUpdating buffer...')
if timestep_counter<=T_buffer
    P_ij_buffer(:,timestep_counter) = P_ij_vec;
    E_buffer = [E_buffer,Etot];
    E_est_buffer = [E_est_buffer,E_est];
    Cost_buffer = [Cost_buffer,dailyCost];
    X_buffer(:,timestep_counter) = x_cur;
    V_buffer(:,timestep_counter) = V_t;
    Beta_buffer(:,timestep_counter) = ActiveBeta_t;

else
    P_ij_buffer(:,1:T_buffer-1) = P_ij_buffer(:,2:T_buffer);
    P_ij_buffer(:,T_buffer) = P_ij_vec;
    E_buffer = [E_buffer(2:T_buffer), Etot];
    E_est_buffer = [E_est_buffer(2:T_buffer), E_est];
    Cost_buffer = [Cost_buffer(2:T_buffer), dailyCost];
    X_buffer(:,1:T_buffer-1) = X_buffer(:,2:T_buffer);
    X_buffer(:,T_buffer) = x_cur;
    V_buffer(:,1:T_buffer-1) = V_buffer(:,2:T_buffer);
    V_buffer(:,T_buffer) = V_t;
	Beta_buffer(:,1:T_buffer-1) = Beta_buffer(:,2:T_buffer);
    Beta_buffer(:,T_buffer) = ActiveBeta_t;
end
fprintf('OK!')

end