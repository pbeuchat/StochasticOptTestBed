function [  FilePath, BufferPath, JacobiansPath, HistoryPath, PlotPath ] = CreateDirectories(current_folder)
    
% this function creates directories in the machines hard disk for file
% saving and loading (only once in the first simulation call)

% FilePath = [current_folder,'SimuFiles\'];
% BufferPath = [current_folder,'BufferFiles\'];
% JacobiansPath = [current_folder,'SymbolicFunctions\'];
% HistoryPath = [current_folder,'HistoricalData\'];
% PlotPath = [current_folder,'PlotPath\'];


FilePath = [current_folder,'SimuFiles/'];
BufferPath = [current_folder,'BufferFiles/'];
JacobiansPath = [current_folder,'SymbolicFunctions/'];
HistoryPath = [current_folder,'HistoricalData/'];
PlotPath = [current_folder,'PlotPath/'];



mkdir(HistoryPath)
mkdir(JacobiansPath)
mkdir(FilePath)
mkdir(BufferPath)
mkdir(PlotPath)

end