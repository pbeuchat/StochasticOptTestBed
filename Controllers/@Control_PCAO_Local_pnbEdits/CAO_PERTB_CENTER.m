function [ best, Global_Cost_buffer ] = CAO_PERTB_CENTER( Systems,day)
% THIS FUNCTION DECIDES THE PERTURBATION CENTER RESPECT TO GLOBAL SYSTEM
% % PERFORMANCE INDEX
% h = figure(1);

 %MainPath=['C:\Users\christos\Desktop\Certh_Results\System\'];
 MainPath=['/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/PCAO'];
 if day==1
 
 mkdir(MainPath);
 delete([MainPath,'Global_Cost_buffer.mat'])
end

TotalCost = 0;
for Instance = 1:Systems
   current_folder=['/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/PCAO/ConstituentSystem',num2str(Instance),'/Day',num2str(day),'/'];
   
    load([current_folder,'Buffer.mat'],'Cost_buffer','E_buffer','E_est_buffer','P_ij_buffer','X_buffer','V_buffer','Beta_buffer');
    TotalCost = TotalCost + Cost_buffer(end);
end


if exist([MainPath,'Global_Cost_buffer.mat'],'file')
    load([MainPath,'Global_Cost_buffer.mat'])
else
    
    Global_Cost_buffer = [ ];
end
Global_Cost_buffer = [ Global_Cost_buffer; TotalCost ];
save([MainPath,'Global_Cost_buffer.mat'],'Global_Cost_buffer')

[~, best] = min(Global_Cost_buffer);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% ONLINE MONITOR GLOBAL RESULTS %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% refresh(h)
% set(h,'visible','on');                                           %
% names = {'J_{g}'};                                               %
% variables = Global_Cost_buffer';                                 %
% OnlineMonitor( h, variables, names, 'Global Performance' );      %
% 
% saveas(h,[MainPath,'OptimizationOnlinePlotGlobal.fig'])
% print('-dtiff',[MainPath,'OptimizationOnlinePlotGlobal'])

end