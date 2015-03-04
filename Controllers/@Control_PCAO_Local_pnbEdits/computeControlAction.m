% Authors: IAKOVOS MICHAILIDIS & CHRISTOS KORKAS - CERTH, Thessaloniki, Greece
% ========= PCAO version Plug-N-Play setup - Local4Global Project FP7 ========
%                                                                                                                                                                                                                                        
% ============================================================================                                                                                     
%            This function connects PCAO and consistued systems                    
%=============================================================================


function u = computeControlAction(obj , currentTime , x , xi_prev , stageCost_prev , stageCost_this_ss_prev , predictions)


                                %At the beginning of each day reconfingure parameters%
%=============================================================================================================%


%   current_folder(System,:)=['D:\Users\',getenv('USERNAME'),'\Desktop\Certh_Results\ConstituentSystem',num2str(System),'\'];
   iter=double(currentTime.index);
   day=floor((iter-1)/96)+1;
  
   %current_folder=['C:\Users\christos\Desktop\Certh_Results\ConstituentSystem',num2str(obj.idnum),'\Day',num2str(day),'\'];
   %Symbolic_folder=['C:\Users\christos\Desktop\Certh_Results\Symbolic\ConstituentSystem',num2str(obj.idnum),'\'];
   current_folder=['/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/PCAO/ConstituentSystem',num2str(obj.idnum),'/Day',num2str(day),'/'];
   Symbolic_folder=['/Users/pbeuchat/Documents/ETHZ_2014_PhD/L4G/Code/L4G_BuildingTestEnvironment/PCAO/ConstituentSystem',num2str(obj.idnum),'/'];
   Update_flag=0;
   if mod(iter,96)==0
     Update_flag=1;
   end

  if mod(iter-1,96)==0
    mkdir(current_folder);
    mkdir(Symbolic_folder);
    DefineParameters(obj,current_folder,predictions);
  end



                                      %Call of the optimization algorithm PCAO%
%==============================================================================================================%
 System=obj.idnum;
 u=Main_CAO(obj,stageCost_this_ss_prev,Update_flag,current_folder,Symbolic_folder,System,day,x,xi_prev,predictions,iter);





            
end
