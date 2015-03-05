function [u_tt]=CAO_AUX_CALC( SIMULparam, MEASUREData, UpDateFlag, current_folder,Symbolic_folder,ubarBCS,System,iteration )


% MAIN function inputs description: %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SIMULparam: This file contains all data necessary for optimization ConvCAO algorithm
% MEASUREData: This file contains system measurement data
% Note that [_s/_t/_tt] are reffering to [previous/current/next] timestep values respectively
warning off all %disable all warnings

[ L, n, m, num_of_dist, e1, e2, max_order, monomial_number, perturb_num,T_buffer, pole, w_norm, PredictDistHorizon, number_of_constraints, alpha, eta,  ...
U_MIN, U_MAX, CHI_MIN, CHI_MAX, lambda,PerturbValidationMethod, PerturbCenter,GlobalCapBuffer,NoSystems,dt,Astep ] = Control_PCAO_Local_pnbEdits.readSIMCONSTANTdata(SIMULparam);

LocalTBuffer = T_buffer;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% READING SYSTEM MEASUREMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[ chi_t, ubar_t, dist_t, predict_dist_t, chi_s, ubar_s, dist_s, predict_dist_s, cost_t, cost_s, t ]...
    = Control_PCAO_Local_pnbEdits.readSIMdata_mod(n, m, num_of_dist, PredictDistHorizon, MEASUREData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TIMESTEP INITIALISING ALGORITHM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% [chi_t, ~] = normalise(chi_t,0); % normalising states given [-1,+1] to [0,+1] space
% [chi_s, ~] = normalise(chi_s,0); % normalising states given [-1,+1] to [0,+1] space

[ GC_temp, GC_humid, temp_sigma, humid_sigma ] = Control_PCAO_Local_pnbEdits.beta_creation( L, CHI_MAX, CHI_MIN );

% P matrix squared sublock dimension
dim_subP = n + m + 1 + num_of_dist + PredictDistHorizon + number_of_constraints;

if t==1 % initializing buffer as void files and Jacobian calculation

    
    E_history = [];
    V_history = [];
    cost_history = [];
    ubar_history = [];
    chi_history = []; 
    u_history = [];
    ubarCAO_history = [];

   
  if iteration==1
      
    Cost_buffer = [];
    E_buffer = [];
    E_est_buffer = [];
    P_ij_buffer = [];
    X_buffer = [];
    V_buffer = [];
    Beta_buffer = [];
    delete([current_folder,'Buffer.mat'])
    
    [ fh_Jacobian_xbar, fh_Jacobian_SQRT_beta, fh_SIGMA ] = Control_PCAO_Local_pnbEdits.symbolic_calculations( n, m, num_of_dist, PredictDistHorizon, number_of_constraints, ...
    L, alpha, eta, GC_temp, GC_humid, temp_sigma, humid_sigma, U_MIN, U_MAX, lambda,current_folder,System );

    save([Symbolic_folder,'Symbolic_function'],'fh_Jacobian_xbar','fh_Jacobian_SQRT_beta','fh_SIGMA');
    
  else
      
   load([Symbolic_folder,'Symbolic_function'],'fh_Jacobian_xbar','fh_Jacobian_SQRT_beta','fh_SIGMA');   
   load([current_folder,'Buffer.mat'],'Cost_buffer','E_buffer','E_est_buffer','P_ij_buffer','X_buffer','V_buffer','Beta_buffer');
    
  end
  
   
else % load auxiliary files for calculation
    
    
    load([current_folder,'History.mat'],'E_history','V_history','cost_history','ubar_history','chi_history','u_history','ubarCAO_history');
    load([current_folder,'Buffer.mat'],'Cost_buffer','E_buffer','E_est_buffer','P_ij_buffer','X_buffer','V_buffer','Beta_buffer');
    load([Symbolic_folder,'Symbolic_function'],'fh_Jacobian_xbar','fh_Jacobian_SQRT_beta','fh_SIGMA');
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONTROL SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sym_flag = 0;

[ u_t ] = Control_PCAO_Local_pnbEdits.sigmoid( ubar_t, lambda, U_MIN, U_MAX, sym_flag );
x_t = [chi_t; ubar_t];
sigma_t = str2func(char(fh_SIGMA));
xbar_t = [ dist_t; predict_dist_t;chi_t; 1; u_t];
[ beta_t ] = Control_PCAO_Local_pnbEdits.timestep_calc_beta( L, chi_t, GC_temp, GC_humid, temp_sigma, humid_sigma, sym_flag );
[ ~, ActiveBeta_t ] = max(beta_t);
[ z_t ] = Control_PCAO_Local_pnbEdits.timestep_calc_z( L, beta_t, xbar_t, sym_flag );
z_ref=[15*ones(length(dist_t)+length(predict_dist_t),1);20*ones(length(chi_t),1);1;1.8*ones(length(u_t),1)];

if t>1
    [ u_s ] = Control_PCAO_Local_pnbEdits.sigmoid( ubar_s, lambda, U_MIN, U_MAX, sym_flag );
    x_s = [chi_s; ubar_s];
    xbar_s = [dist_s; predict_dist_s; chi_s; 1; u_s; sigma_t(x_s) ];

    [ beta_s ] = Control_PCAO_Local_pnbEdits.timestep_calc_beta( L, chi_s, GC_temp, GC_humid, temp_sigma, humid_sigma, sym_flag );
    [ z_s ] = Control_PCAO_Local_pnbEdits.timestep_calc_z( L, beta_s, xbar_s, sym_flag );
end

% full Jacobian matrix timestep calculation
Mx  = Control_PCAO_Local_pnbEdits.timestep_calc_Mx( L, xbar_t, 0, x_t, beta_t, fh_Jacobian_xbar, fh_Jacobian_SQRT_beta,current_folder,Symbolic_folder );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ConvCAO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
V_s = 0;
V_t = 0;
E_t = dt*cost_t;
E_est = NaN;

cao_counter = size(E_buffer,2)*1 + 1;
if t == 1 % initial P control matrix

    if cao_counter == 1
        [ ~, P_ij ] = Control_PCAO_Local_pnbEdits.genPDMrandomly( e1, e2, L, dim_subP );
        P_ij_buffer(:,cao_counter) = Control_PCAO_Local_pnbEdits.vectorise3Dmatrix( P_ij );
    else
        P_ij = Control_PCAO_Local_pnbEdits.unvectorise3Dmatrix( P_ij_buffer(:,cao_counter), L );
    end

else
    % ConvCAO updates the controller every UpdateFreq - validating perturbations
    % based on the static simulation total Update period cost
    
     P_ij = Control_PCAO_Local_pnbEdits.unvectorise3Dmatrix( P_ij_buffer(:,cao_counter), L );
   
    [ dV, V_t, V_s, E_t ] = Control_PCAO_Local_pnbEdits.calcLYAP( z_s, z_t, P_ij, cost_t, dt );

    if UpDateFlag
        [ NORMAL_period_total_cost, NORMAL_period_total_error ] = Control_PCAO_Local_pnbEdits.CAOnormBCS_mod ( sum([cost_history, cost_t]), [V_t - V_history(2)],...
		dt, current_folder, t );

        [ P_ij_buffer, E_buffer, E_est_buffer, Cost_buffer, X_buffer, V_buffer, Beta_buffer ] = Control_PCAO_Local_pnbEdits.updateBuffer( P_ij, P_ij_buffer, NORMAL_period_total_error, E_buffer, ...
            E_est, E_est_buffer, NORMAL_period_total_cost, Cost_buffer, z_t, X_buffer, [V_t - V_history(1)], V_buffer, ActiveBeta_t, Beta_buffer, T_buffer, cao_counter );
    end
end

% if ~(PCAO && START_CAO)% outside of PCAO control period
%     P_ij = 0;
%     pole = 1;
% end

[ P ] = Control_PCAO_Local_pnbEdits.constructBLK( P_ij );
B = [ zeros(n,m); eye(m) ];
G = -B'*Mx'*P;
v = G*(z_t-z_ref); % ficticious optimal control actions

if t == 1
    ubarCAO_t = 0;
else
    ubarCAO_t = ubarCAO_history(:,end);
end
ubarCAO_tt = dt*v + (1 - pole)*ubarCAO_t; % integration of v = dot(u_bar)
ubar_tt = ubarBCS + ubarCAO_tt; 

[ u_tt ] = Control_PCAO_Local_pnbEdits.sigmoid( ubar_tt, lambda, U_MIN, U_MAX, sym_flag );


save([current_folder,'U_Actions.mat'],'ubar_tt','u_tt')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HISTORY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ubar_history(:,t) = ubar_tt;
chi_history(:,t) = chi_t;
u_history(:,t) = u_tt;
ubarCAO_history(:,t) = ubarCAO_tt;
E_history(t) = E_t;
V_history(t) = V_s; 
cost_history(t) = cost_t;

save([current_folder,'History.mat'],'E_history','V_history','cost_history','ubar_history','chi_history','u_history','ubarCAO_history');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% BUFFER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save([current_folder,'Buffer.mat'],'Cost_buffer','E_buffer','E_est_buffer','P_ij_buffer','X_buffer','V_buffer','Beta_buffer');

% save([BufferPath,'E_est_buffer.mat'],'E_est_buffer');
% save([ParentPath,'Global_Cost_buffer.mat'],'Global_Cost_buffer');

% refresh(h)
% set(h,'visible','on');

end