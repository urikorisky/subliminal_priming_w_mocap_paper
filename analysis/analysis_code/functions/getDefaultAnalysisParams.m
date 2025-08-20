function analysisParams = getDefaultAnalysisParams()
%GETDEFAULTANALYSISPARAMS 

arguments (Output)
    analysisParams
end

prms = struct();
prms.fromRawData = true;
prms.rawDataFolder = '../../../raw_data_from_OSF/';

prms.readyPreProcData_noTrajNorm_noStandardization_folder = '../processed_data_from_paper/nonStandardized_nonTrajNorm_9-1-25_22-10/';
prms.readyPreProcData_TrajNorm_noStandardization_folder = '../processed_data_from_paper/nonStandardized_TrajNorm_6-1-25_18-40/';
prms.readyPreProcData_TrajNorm_Standardization_folder = '../processed_data_from_paper/standardized_TrajNorm_6-1-25_22-40/';

prms.targetPreProcData_noTrajNorm_noStandardization_folder = '../processed_data/nonStandardized_nonTrajNorm/';
prms.targetPreProcData_TrajNorm_noStandardization_folder = '../processed_data/nonStandardized_TrajNorm/';
prms.targetPreProcData_TrajNorm_Standardization_folder = '../processed_data/standardized_TrajNorm/';

prms.analysisRounds = {'noTrajNorm_noStandardization','TrajNorm_noStandardization',...
    'TrajNorm_Standardization'};

analysisParams = prms;

end