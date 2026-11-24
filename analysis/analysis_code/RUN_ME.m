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
% By default, the final master figures and statistics are written directly
% into analysis/figures and analysis/statistics, respectively.
% All figures are saved directly in .fig, .png (300 DPI), .pdf, and .svg formats
% (plus the formatted Word table Fig_S1f_FullTraj_FDR_Table.docx).
% All statistics are saved directly in All_Statistics.mat and the 16-sheet
% consolidated workbook All_Statistics.xlsx.
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
% 1. Should the analysis start from the raw data files? (default false: uses preprocessed batch)
analysisPrms.fromRawData = false;
% 2. Where are the raw data files? (default: the parent folder of the Git
% repository's folder, under the folder "raw_data_from_OSF")
analysisPrms.rawDataFolder = '../../../raw_data_from_OSF/';
% 3. Should calculation-heavy steps (e.g., permutations, bootstraps) reuse existing cached results?
% If fromRawData is true, we re-run calculations from scratch (false); otherwise default to true.
if analysisPrms.fromRawData
    analysisPrms.usePreprocDataWhereverPossible = false;
else
    analysisPrms.usePreprocDataWhereverPossible = true;
end

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

good_subs = full_stats_tables.good_subs;

%% Excluded Trials Summary & Breakdown Statistics (TrajNorm, noTrajNorm, Keyboard)
if analysisPrms.fromRawData
    proc_tn  = analysisPrms.targetPreProcData_TrajNorm_noStandardization_folder;
    proc_ntn = analysisPrms.targetPreProcData_noTrajNorm_noStandardization_folder;
else
    proc_tn  = analysisPrms.readyPreProcData_TrajNorm_noStandardization_folder;
    proc_ntn = analysisPrms.readyPreProcData_noTrajNorm_noStandardization_folder;
end
full_stats_tables.trialExclusionStats = compute_trial_exclusion_stats(proc_tn, proc_ntn, good_subs);

% Load consolidated All_Statistics.mat once if caching is enabled
all_stats_cache_file = fullfile(analysisPrms.targetStats_allAnalysesCombined, 'All_Statistics.mat');
cached_all_stats = struct();
if analysisPrms.usePreprocDataWhereverPossible && exist(all_stats_cache_file, 'file')
    fprintf('Loading cached Monte Carlo results from %s...\n', all_stats_cache_file);
    loaded_all = load(all_stats_cache_file, 'full_stats_tables');
    if isfield(loaded_all, 'full_stats_tables')
        cached_all_stats = loaded_all.full_stats_tables;
    end
end

%% Effect sizes & Within-Flavor Sensitivity Comparisons (Scoped per Flavor)
fields_to_analyze = {'react', 'mt', 'mad', 'com', 'tot_dist', 'auc', 'ra', 'kb_rt', 'head_angle', 'iep', 'traj', 'x_std'};

if isfield(full_stats_tables, 'dynamic_trajectory_windows')
    trajectory_windows = full_stats_tables.dynamic_trajectory_windows;
else
    trajectory_windows = struct();
end

n_bootstraps = 10000;
if analysisPrms.usePreprocDataWhereverPossible && ...
        isfield(cached_all_stats, 'Effect_Sizes') && isfield(cached_all_stats, 'Effect_Comparisons_Within')
    fprintf('Reusing cached bootstrap effect sizes from All_Statistics.mat...\n');
    effects_tbl = cached_all_stats.Effect_Sizes;
    within_tbl  = cached_all_stats.Effect_Comparisons_Within;
else
    [effects_tbl, within_tbl] = bootstrap_effect_sizes(...
        full_stats_tables.rawAggData, ...
        fields_to_analyze, ...
        'con', 'incon', ...
        trajectory_windows, ...
        n_bootstraps, ...
        good_subs);
end

full_stats_tables.Effect_Sizes = effects_tbl;
full_stats_tables.Effect_Comparisons_Within = within_tbl;

%% 5. Normality Assessment, Outlier Detection & Permutation Testing
if analysisPrms.usePreprocDataWhereverPossible && ...
        isfield(cached_all_stats, 'Normality_and_Permutations') && isfield(cached_all_stats, 'Normality_and_Permutations_Table')
    fprintf('Reusing cached normality and permutations from All_Statistics.mat...\n');
    norm_perm_struct = cached_all_stats.Normality_and_Permutations;
    norm_perm_table  = cached_all_stats.Normality_and_Permutations_Table;
else
    [norm_perm_struct, norm_perm_table] = test_normality_and_permutations(full_stats_tables.rawAggData, good_subs, trajectory_windows);
end
full_stats_tables.Normality_and_Permutations = norm_perm_struct;
full_stats_tables.Normality_and_Permutations_Table = norm_perm_table;

%% 6. Tree-BH FDR Correction Architecture & Chronological Trajectory Dynamics
full_stats_tables = run_treebh_suite(full_stats_tables, within_tbl);

%% 7. Spearman-Brown Split-Half Reliability (5,000 Random Splits)
if analysisPrms.usePreprocDataWhereverPossible && ...
        isfield(cached_all_stats, 'Split_Half_Reliability_Results') && isfield(cached_all_stats, 'Split_Half_Reliability')
    fprintf('Reusing cached split-half reliability from All_Statistics.mat...\n');
    Reliability_Results = cached_all_stats.Split_Half_Reliability_Results;
    Reliability_Table   = cached_all_stats.Split_Half_Reliability;
else
    [Reliability_Results, Reliability_Table] = calc_split_half_reliability(proc_tn, good_subs, 5000);
end
full_stats_tables.Split_Half_Reliability_Results = Reliability_Results;
full_stats_tables.Split_Half_Reliability = Reliability_Table;

%% 8. Supplementary Change-of-Mind (COM) Dwell-Time & Threshold Sweep Statistics
full_stats_tables.Supp_COM_Threshold_Stats = plot_supplementary_com_analysis(proc_tn);

%% 9. Supplementary Information (SI) Appendix: Trial Exclusions & Re-analysis Without Long-Duration Exclusions
fprintf('\n--- Computing Supplementary Information (SI) Appendix Tables & No-Long-Duration Re-Analysis ---\n');
if ~isfield(analysisPrms, 'subs') || isempty(analysisPrms.subs)
    analysisPrms.subs = [47, 49:85, 87:90]; % All 42 tested participants
end
% A. Detailed trial exclusion counts and percentages across all 42 participants
[SI_Exclusion_Counts, SI_Exclusion_Pct] = generate_si_trial_exclusion_tables(...
    proc_tn, good_subs, analysisPrms.subs);
full_stats_tables.SI_Exclusion_All_Subs_Counts = SI_Exclusion_Counts;
full_stats_tables.SI_Exclusion_All_Subs_Pct    = SI_Exclusion_Pct;

% B. Entire re-analysis of the data ignoring offline long-duration exclusions (N = 31 included participants)
si_reanalysis = generate_si_reanalysis_flavor(analysisPrms, within_tbl);
full_stats_tables.SI_Reanalysis               = si_reanalysis;
full_stats_tables.SI_Reanalysis_Summary       = si_reanalysis.si_summary_tbl;
full_stats_tables.By_Sub_SI_noTimeExclusion   = si_reanalysis.si_by_sub_tbl;
full_stats_tables.Full_Traj_Permutation_Stats = si_reanalysis.full_traj_clust_tbl;

%% 10. Perceptual Awareness Scores (PAS) Suite: Table 2, rm-ANOVA & Level-by-Level Paired Tests
if ~isfield(full_stats_tables, 'primeAwarenessDist') || ~isfield(full_stats_tables.primeAwarenessDist, 'PAS_Summary')
    agg_file = fullfile(proc_tn, 'avg_each_day2_target_x_to_subs_47_49-85_87-90.mat');
    if exist(agg_file, 'file')
        c_agg = load(agg_file);
        [pas_summary_table, pas_by_sub_table, pas_stats_table, kb_PAS_Pct_Table, reach_PAS_Pct_Table] = ...
            compute_pas_analyses(c_agg.reach_avg_each, c_agg.keyboard_avg_each, good_subs);
        full_stats_tables.primeAwarenessDist = struct(...
            'Keyboard', kb_PAS_Pct_Table, ...
            'Reaching', reach_PAS_Pct_Table, ...
            'PAS_Summary', pas_summary_table, ...
            'PAS_Statistical_Tests', pas_stats_table, ...
            'PAS_By_Sub', pas_by_sub_table);
    end
end

%% 11. Directly Save Final Master Figures (.fig, .png, .pdf, .svg + Fig_S1f DOCX),
%      All_Statistics.mat, and 16-sheet All_Statistics.xlsx:
printAndSave(final_fig_handles, full_stats_tables, analysisPrms);
