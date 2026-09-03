%% Script for recreating results from Khen, Korisky, Chapman, and Mudrik, 2026
%
% This script reproduces all the plots and statistics mentioned in the
% manuscript.
%
% To analyze the data starting from the raw data files, download them from:
% https://osf.io/ujcep/files/osfstorage
% Under "Data", find the folder "Raw_Data" and download it.
% Put the path to this folder below in the "Parameters" section, as the  
% value of analysisPrms.rawDataFolder
%
% By default, the output figures and statistics will be saved into
% analysis/figures and analysis/statistics, respectively.
% The figures are saved in both FIG and PNG formats.
% The statistics are saved in whole as a MAT file and separately in an XLSX
% file with a different sheet for each analysis that appears in the
% manuscript
%
% Note about p-values:
% Due to the use of permutation analyses to identify clusters of
% significance in the full trajectories, slight differences may exist
% between the p-values reported in the manuscript for these findings
% (appearing in Figure 4)
%
% Dependencies:
% - Bioinformatics Toolbox
% - Curve Fitting Toolbox
% - Image Processing Toolbox
% - Mapping Toolbox
% - Signal Processing Toolbox
% - Statistics and Machine Learning Toolbox


clear;
close all;
addpath(genpath('./functions'));
%% Parameters
analysisPrms = getDefaultAnalysisParams();
% Common parameters for changing:
% 1. Should the analysis start from the raw data files? (default true)
analysisPrms.fromRawData = false;
% 2. Where are the raw data files? (default: the parent folder of the Git
% repository's folder, under the folder "raw_data_from_OSF")
analysisPrms.rawDataFolder = '../../../raw_data_from_OSF/';

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DO NOT EDIT THE CODE BELOW %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use the analysis parameters for changing the analysis without breaking
% the code

%% Iterate over analysis rounds
% Analyses are done in several fashions, depending on these criteria:
% (1) Normalization: Whether the reaching trajectories are normalized over
% time (true) or are trimmed at 340ms (false)
% (2) Standardization: Whether the nominal measures, summing a trajectory
% by one value, are z-scored within a participant, over all the trials.

for iRound = 1:numel(analysisPrms.analysisRounds)
    % close all;
    [figureHandles,statsTables] = analysis_pipeline(analysisPrms,iRound);
    % Update the analysis parameters to include the handles to the figures
    % and the statistics table:
    analysisPrms.figureHandles = figureHandles;
    analysisPrms.statsTables = statsTables;
end

final_fig_handles = analysisPrms.figureHandles;
full_stats_tables = analysisPrms.statsTables;
full_stats_tables.analyzed_stats_tables = extract_relevant_statistics(full_stats_tables,'statistics_print_config.csv');

%% Tree-BH FDR correction:
[full_stats_tables, final_fig_handles.TreeBH] = Calc_and_plot_TreeBH(full_stats_tables);

%% Effect sizes comparisons

% 1. Fields to analyze
fields_to_analyze = {'react', 'mt', 'mad', 'com', 'tot_dist', 'auc', 'max_vel', 'ra', 'kb_rt', 'head_angle','iep','traj','x_std','vel'};

good_subs = full_stats_tables.good_subs;

% 2. Significant time windows for full-trajectory measures
trajectory_windows = struct();
trajectory_windows.head_angle = [15, 31]; % From sample 15 to sample 31
trajectory_windows.iep = [15, 34];
trajectory_windows.traj = [19, 34];
trajectory_windows.vel = [15, 30];

% 3. Cross-flavor comparisons
cross_flavor_pairs = { ...
    {{'kb_rt', 'noTrajNorm_noStandardization'}, {'ra', 'TrajNorm_noStandardization'}}, ...
    {{'kb_rt', 'noTrajNorm_noStandardization'}, {'mt', 'TrajNorm_noStandardization'}}, ...
    {{'kb_rt', 'noTrajNorm_noStandardization'}, {'tot_dist', 'TrajNorm_noStandardization'}}, ...
    {{'kb_rt', 'noTrajNorm_noStandardization'}, {'mad', 'TrajNorm_noStandardization'}} ...
};

n_bootstraps = 10000;

% 4. Master effect size calculation
[effects_tbl, within_tbl, cross_tbl] = bootstrap_effect_sizes(...
    full_stats_tables.rawAggData, ...
    fields_to_analyze, ...
    'con', 'incon', ...
    cross_flavor_pairs, ...
    trajectory_windows, ...
    n_bootstraps, ...
    good_subs);

% Attach to master struct for unified MAT and XLSX export:
full_stats_tables.Effect_Sizes = effects_tbl;
full_stats_tables.Effect_Comparisons_Within = within_tbl;
full_stats_tables.Effect_Comparisons_Cross = cross_tbl;

%% 5. Normality Assessment, Outlier Detection & Permutation Testing
[norm_perm_struct, norm_perm_table] = test_normality_and_permutations(full_stats_tables.rawAggData, good_subs);
full_stats_tables.Normality_and_Permutations = norm_perm_struct;
full_stats_tables.Normality_and_Permutations_Table = norm_perm_table;

%% Plot effect sizes & QQ plots
plot_and_save_effect_sizes(effects_tbl, within_tbl, cross_tbl);
plot_and_save_qq_plots(full_stats_tables.rawAggData, good_subs, analysisPrms.targetFigs_allAnalysesCombined);

%% Save all outcomes (figures, All_Statistics.mat, All_Statistics.xlsx):
printAndSave(final_fig_handles, full_stats_tables, analysisPrms);