function u= Main_CAO(obj,Cost_vector,Update_flag,current_folder,Symbolic_folder,System,day,x,xi,predictions,iteration)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION STARTING POINT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                     
                           %Calculation of u vector for each system
%==========================================================================================%

  fprintf('\nCollecting measurements from Subsystem %d...',System)   
  
 
  load([current_folder,'Simulation_Parameters.mat'],'Param');
 
   if mod(iteration-1,96)~=0
       load([current_folder,'MEASUREData.mat'])
   else
      MEASUREData = [ ];
   end

%    if isempty(MEASUREData)                                                                    
        RBC_actions  = 1.8*ones(Param.NoActions,1);                                            %Use of RBC
%    else
    
    MEASUREData_t=Control_PCAO_Local_pnbEdits.DefineMeasurements(Param,Cost_vector,current_folder,System,x,xi,predictions,Param.NoActions);
    MEASUREData = [ MEASUREData; MEASUREData_t ];                                             %Current time step measurement row augmentation with the previous ones
    save([current_folder,'MEASUREData.mat'],'MEASUREData')
    
    
     actions= Control_PCAO_Local_pnbEdits.CAO_AUX_CALC(Param, MEASUREData, Update_flag, current_folder,Symbolic_folder,RBC_actions,System,iteration);        %Use of PCAO
    
    u=actions;
    

                             %Pertubation and next Pmatrix selection
%===========================================================================================%

if Update_flag==1 && System==7
    [ CenterPosition, Global_Cost_buffer ] = Control_PCAO_Local_pnbEdits.CAO_PERTB_CENTER(Param.NoSystems,day);
    Control_PCAO_Local_pnbEdits.CAO_TRAIN_EST(CenterPosition, Global_Cost_buffer,day,Param.NoSystems);
end

clc





