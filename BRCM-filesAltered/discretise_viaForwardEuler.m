function discretise_viaForwardEuler(obj)
   %DISCRETIZE This method discretizes the building model.
   % ------------------------------------------------------------------------
   % This file is part of the BRCM Toolbox v1.01.
   %
   % The BRCM Toolbox - Building Resistance-Capacitance Modeling for Model Predictive Control.
   % Copyright (C) 2013  Automatic Control Laboratory, ETH Zurich.
   % 
   % The BRCM Toolbox is free software; you can redistribute it and/or modify
   % it under the terms of the GNU General Public License as published by
   % the Free Software Foundation, either version 3 of the License, or
   % (at your option) any later version.
   % 
   % The BRCM Toolbox is distributed in the hope that it will be useful,
   % but WITHOUT ANY WARRANTY; without even the implied warranty of
   % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   % GNU General Public License for more details.
   % 
   % You should have received a copy of the GNU General Public License
   % along with the BRCM Toolbox.  If not, see <http://www.gnu.org/licenses/>.
   %
   % For support check www.brcm.ethz.ch.
   % ------------------------------------------------------------------------
   
   
   
   
   if isempty(obj.Ts_hrs)
      error('discretize:Ts_hrs','Discretization time step ''%s'' not defined.\n','Ts_hrs');
   end
   
   secondsPerHours = 60 * 60;
   Ts_seconds = obj.Ts_hrs * secondsPerHours;
   
   obj.discrete_time_model = struct('A',[],'Bu',[],'Bv',[],'Bxu',[],'Bvu',[],...
      'C',[],'Du',[],'Dv',[],'Dxu',[],'Dvu',[]);
   
   if ~isempty(obj.continuous_time_model)
      B = [obj.continuous_time_model.Bu, obj.continuous_time_model.Bv];
      
      %len_u = size(obj.continuous_time_model.Bu,2);
      %len_v = size(obj.continuous_time_model.Bv,2);
      len_x = size(obj.continuous_time_model.A,2);
      
      obj.discrete_time_model.('A')  = speye(len_x)  + sparse( obj.continuous_time_model.A   * Ts_seconds );
      obj.discrete_time_model.('Bu') =                 sparse( obj.continuous_time_model.Bu  * Ts_seconds );
      obj.discrete_time_model.('Bv') =                 sparse( obj.continuous_time_model.Bv  * Ts_seconds );
      
      obj.discrete_time_model.('Bxu') = obj.continuous_time_model.Bxu;
      obj.discrete_time_model.('Bvu') = obj.continuous_time_model.Bvu;
      
      obj.discrete_time_model.('C')   = obj.continuous_time_model.C;
      obj.discrete_time_model.('Dv')  = obj.continuous_time_model.Dv;
      obj.discrete_time_model.('Du')  = obj.continuous_time_model.Du;
      obj.discrete_time_model.('Dxu') = obj.continuous_time_model.Dxu;
      obj.discrete_time_model.('Dvu') = obj.continuous_time_model.Dvu;
      
   else
      obj.discrete_time_model = struct('A',[],'Bu',[],'Bv',[],'Bxu',[],'Bvu',[],...
         'C',[],'Du',[],'Dv',[],'Dxu',[],'Dvu',[]);
   end
   
end
