function CAO_TRAIN_EST( CenterPosition, Global_Cost_buffer,day,Systems )
% THIS FUNCTION IS RESPONSIBLE FOR TRAINING EACH CONSTITUENT SYSTEM'S
% PERFORMANCE ESTIMATOR AND CALCULATE THE NEXT CONTROL MATRIX
    
for Instance = 1:Systems
%     h0 = figure(Instance+1);
    %current_folder=['C:\Users\christos\Desktop\Certh_Results\ConstituentSystem',num2str(Instance),'\Day',num2str(day),'\'];
    current_folder=['/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/PCAO/ConstituentSystem',num2str(Instance),'/Day',num2str(day),'/'];
    load([current_folder,'Simulation_Parameters.mat'],'Param');
    load([current_folder,'Buffer.mat'],'Cost_buffer','E_buffer','E_est_buffer','P_ij_buffer','X_buffer','V_buffer','Beta_buffer');
     
    [ L, n, m, num_of_dist, e1, e2, max_order, monomial_number, perturb_num,T_buffer, pole, w_norm, PredictDistHorizon, number_of_constraints, alpha, eta,  ...
      U_MIN, U_MAX, CHI_MIN, CHI_MAX, lambda,PerturbValidationMethod, PerturbCenter,GlobalCapBuffer,NoSystems,dt,Astep ] = Control_PCAO_Local_pnbEdits.readSIMCONSTANTdata(Param);
    LocalTBuffer = T_buffer;
    
    fprintf('\n*********************************')
    fprintf('\nTraining Estimator %d subsystem:',Instance)
    fprintf('\n*********************************')

    
    ActiveBeta_t = Beta_buffer(end);
    cao_counter = size(E_buffer,2)*1; % E_buffer was updated previously on the same timestep

    ActiveBeta_E_buffer = Control_PCAO_Local_pnbEdits.localiseBuffer( E_buffer, Beta_buffer, ActiveBeta_t, LocalTBuffer );
    ActiveBeta_X_buffer = Control_PCAO_Local_pnbEdits.localiseBuffer( X_buffer, Beta_buffer, ActiveBeta_t, LocalTBuffer );
    ActiveBeta_P_ij_buffer = Control_PCAO_Local_pnbEdits.localiseBuffer( P_ij_buffer, Beta_buffer, ActiveBeta_t, LocalTBuffer );


    fprintf('\nActive mixing function: %d\nPerturbation center: %d\n',ActiveBeta_t,CenterPosition)
    
%     CenterPosition
    P_perturb_center = Control_PCAO_Local_pnbEdits.unvectorise3Dmatrix( P_ij_buffer(:,CenterPosition), L );
    
    [ theta, orders, bounds ] = Control_PCAO_Local_pnbEdits.LIP_approximation( max_order, monomial_number, ActiveBeta_X_buffer, ...
        ActiveBeta_P_ij_buffer, ActiveBeta_E_buffer, Global_Cost_buffer, GlobalCapBuffer, w_norm );
    
    [ a ] = Control_PCAO_Local_pnbEdits.calcPERTURBstep( Astep, cao_counter );
    
    [ P_ij, E_est ] = Control_PCAO_Local_pnbEdits.perturbPvalidation( ActiveBeta_X_buffer, Global_Cost_buffer, P_perturb_center, theta, orders, bounds, ...
        e1, e2, a, perturb_num, w_norm, GlobalCapBuffer, PerturbValidationMethod );
    
    E_est_buffer(cao_counter) = E_est;
    P_ij_buffer(:,cao_counter + 1) = Control_PCAO_Local_pnbEdits.vectorise3Dmatrix( P_ij );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%% ONLINE MONITOR RESULTS %%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      refresh(h0)
%      set(h0,'visible','on');                                          %
%      names = {['J'],['dV(z)'],['E'],['E_{est}']};                          %
%      variables = [ Cost_buffer; V_buffer; E_buffer; E_est_buffer ];   %
%      OnlineMonitor( h0, variables, names, ['OptimSubProblem',num2str(Instance)] ); %
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     saveas(h0,[ParentPath,'OptimizationOnlinePlot',num2str(Instance),'.fig'])
% 	print('-dtiff',[ParentPath,'OptimizationOnlinePlot',num2str(Instance)])
%     
%     
%     save( [ ParentPath,'P_ij.mat' ], 'P_ij' )

    
    
    
    save([current_folder,'Buffer.mat'],'Cost_buffer','E_buffer','E_est_buffer','P_ij_buffer','X_buffer','V_buffer','Beta_buffer');
    %current_folder=['C:\Users\christos\Desktop\Certh_Results\ConstituentSystem',num2str(Instance),'\Day',num2str(day+1),'\'];
    current_folder=['/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/PCAO/ConstituentSystem',num2str(Instance),'/Day',num2str(day+1),'/'];
    mkdir(current_folder)
    save([current_folder,'Buffer.mat'],'Cost_buffer','E_buffer','E_est_buffer','P_ij_buffer','X_buffer','V_buffer','Beta_buffer');
    
    
end

end