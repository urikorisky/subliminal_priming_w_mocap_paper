function analysisParams = getDefaultAnalysisParams()
%GETDEFAULTANALYSISPARAMS 

arguments (Output)
    analysisParams
end

prms = struct();
prms.fromRawData = false;
prms.rawDataFolder = '../../../raw_data_from_OSF/';

% When fromRawData is false, usePreprocDataWhereverPossible defaults to true
% to skip heavy Monte Carlo resampling (permutations, 10k bootstraps, 5k reliability)
% whenever precomputed results are available.
if prms.fromRawData
    prms.usePreprocDataWhereverPossible = false;
else
    prms.usePreprocDataWhereverPossible = true;
end

prms.readyPreProcData_noTrajNorm_noStandardization_folder = '../processed_data/nonStandardized_nonTrajNorm/';
prms.readyPreProcData_TrajNorm_noStandardization_folder = '../processed_data/nonStandardized_TrajNorm/';
prms.readyPreProcData_TrajNorm_Standardization_folder = '../processed_data/standardized_TrajNorm/';
prms.readyPreProcData_noTimeExclusion_TrajNorm_folder = '../processed_data/noTimeExclusion_TrajNorm/';

prms.targetPreProcData_noTrajNorm_noStandardization_folder = '../processed_data/nonStandardized_nonTrajNorm/';
prms.targetPreProcData_TrajNorm_noStandardization_folder = '../processed_data/nonStandardized_TrajNorm/';
prms.targetPreProcData_TrajNorm_Standardization_folder = '../processed_data/standardized_TrajNorm/';
prms.targetPreProcData_noTimeExclusion_TrajNorm_folder = '../processed_data/noTimeExclusion_TrajNorm/';

prms.targetFigs_noTrajNorm_noStandardization_folder = '../new_figures/nonStandardized_nonTrajNorm/';
prms.targetFigs_TrajNorm_noStandardization_folder = '../new_figures/nonStandardized_TrajNorm/';
prms.targetFigs_TrajNorm_Standardization_folder = '../new_figures/standardized_TrajNorm/';

prms.targetFigs_allAnalysesCombined = '../figures/';
prms.targetStats_allAnalysesCombined = '../statistics/';

prms.analysisRounds = {'noTrajNorm_noStandardization','TrajNorm_noStandardization',...
    'TrajNorm_Standardization'};

prms.subs = [47, 49:85, 87:90]; % All 42 tested participants

analysisParams = prms;

end
