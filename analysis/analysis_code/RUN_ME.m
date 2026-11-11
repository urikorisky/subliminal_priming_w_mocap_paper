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

%% Cross-Flavor Full-Trajectory Comparison Figure (Fig. 4 side-by-side across flavors)
final_fig_handles.Fig_Full_Trajectory_Flavor_Comparison = ...
    plot_cross_flavor_trajectories(analysisPrms, analysisPrms.targetFigs_allAnalysesCombined);

%% Effect sizes & Within-Flavor Sensitivity Comparisons (Scoped per Flavor)
fields_to_analyze = {'react', 'mt', 'mad', 'com', 'tot_dist', 'auc', 'ra', 'kb_rt', 'head_angle', 'iep', 'traj', 'x_std'};

if isfield(full_stats_tables, 'dynamic_trajectory_windows')
    trajectory_windows = full_stats_tables.dynamic_trajectory_windows;
else
    trajectory_windows = struct();
end

n_bootstraps = 10000;
boot_cache_file = fullfile(analysisPrms.targetStats_allAnalysesCombined, 'Bootstrap_Stats_Tables.mat');

if analysisPrms.usePreprocDataWhereverPossible && exist(boot_cache_file, 'file')
    fprintf('Loading cached bootstrap effect sizes from %s...\n', boot_cache_file);
    loaded_boot = load(boot_cache_file);
    effects_tbl = loaded_boot.effects_tbl;
    within_tbl  = loaded_boot.within_tbl;
else
    [effects_tbl, within_tbl] = bootstrap_effect_sizes(...
        full_stats_tables.rawAggData, ...
        fields_to_analyze, ...
        'con', 'incon', ...
        trajectory_windows, ...
        n_bootstraps, ...
        good_subs);
    save(boot_cache_file, 'effects_tbl', 'within_tbl');
end

full_stats_tables.Effect_Sizes = effects_tbl;
full_stats_tables.Effect_Comparisons_Within = within_tbl;

%% 5. Normality Assessment, Outlier Detection & Permutation Testing
norm_cache_file = fullfile(analysisPrms.targetStats_allAnalysesCombined, 'Normality_Permutations_Results.mat');
if analysisPrms.usePreprocDataWhereverPossible && exist(norm_cache_file, 'file')
    fprintf('Loading cached normality and permutations from %s...\n', norm_cache_file);
    loaded_norm = load(norm_cache_file);
    norm_perm_struct = loaded_norm.norm_perm_struct;
    norm_perm_table  = loaded_norm.norm_perm_table;
else
    [norm_perm_struct, norm_perm_table] = test_normality_and_permutations(full_stats_tables.rawAggData, good_subs, trajectory_windows);
    save(norm_cache_file, 'norm_perm_struct', 'norm_perm_table');
end
full_stats_tables.Normality_and_Permutations = norm_perm_struct;
full_stats_tables.Normality_and_Permutations_Table = norm_perm_table;

%% 6. Tree-BH FDR Correction Architecture & Chronological Trajectory Dynamics
treebh_fig_dir = fullfile(analysisPrms.targetFigs_allAnalysesCombined, 'TreeBH');
[full_stats_tables, final_fig_handles.TreeBH] = run_treebh_suite(full_stats_tables, within_tbl, treebh_fig_dir);

%% 7. Spearman-Brown Split-Half Reliability (5,000 Random Splits)
rel_cache_file = fullfile(analysisPrms.targetStats_allAnalysesCombined, 'Split_Half_Reliability_Results.mat');
if analysisPrms.usePreprocDataWhereverPossible && exist(rel_cache_file, 'file')
    fprintf('Loading cached split-half reliability from %s...\n', rel_cache_file);
    loaded_rel = load(rel_cache_file);
    Reliability_Results = loaded_rel.Reliability_Results;
    Reliability_Table   = loaded_rel.Reliability_Table;
else
    [Reliability_Results, Reliability_Table] = calc_split_half_reliability(proc_tn, good_subs, 5000);
    save(rel_cache_file, 'Reliability_Results', 'Reliability_Table');
end
full_stats_tables.Split_Half_Reliability_Results = Reliability_Results;
full_stats_tables.Split_Half_Reliability = Reliability_Table;
final_fig_handles.Fig_Split_Half_Reliability = plot_reliability_forest(Reliability_Table, analysisPrms.targetFigs_allAnalysesCombined);

%% 8. Supplementary Change-of-Mind (COM) Dwell-Time & Threshold Analysis (3 Figures + Stats)
supp_com_fig_dir = fullfile(analysisPrms.targetFigs_allAnalysesCombined, 'Supplementary_COM');
[Supp_COM_Stats, final_fig_handles.Supplementary_COM] = ...
    plot_supplementary_com_analysis(supp_com_fig_dir, proc_tn, analysisPrms.targetStats_allAnalysesCombined);
full_stats_tables.Supp_COM_Threshold_Stats = Supp_COM_Stats;

%% 9. JZS Bayesian Model & Objective Prime Awareness Inference Figure
final_fig_handles.Fig_JZS_Bayesian_Model_Hierarchy = ...
    plot_jzs_bayesian_hierarchy(analysisPrms.targetFigs_allAnalysesCombined, proc_tn);

%% 10. Supplementary Information (SI) Appendix: Trial Exclusions, Timing Histograms, and Full Re-analysis
fprintf('\n--- Generating Supplementary Information (SI) Appendix Tables, Histograms, and Re-Analysis ---\n');
if ~isfield(analysisPrms, 'subs') || isempty(analysisPrms.subs)
    analysisPrms.subs = [47, 49:85, 87:90]; % All 42 tested participants
end
% A. Detailed trial exclusion counts and percentages across all 42 participants
[SI_Exclusion_Counts, SI_Exclusion_Pct] = generate_si_trial_exclusion_tables(...
    proc_tn, good_subs, analysisPrms.subs, analysisPrms.targetStats_allAnalysesCombined);
full_stats_tables.SI_Exclusion_All_Subs_Counts = SI_Exclusion_Counts;
full_stats_tables.SI_Exclusion_All_Subs_Pct    = SI_Exclusion_Pct;

% B. Participant-level timing histograms (Onset, Duration, Response Duration) With vs Without time exclusions
si_hist_fig_dir = fullfile(analysisPrms.targetFigs_allAnalysesCombined, 'SI_Participant_Time_Histograms');
generate_si_timing_histograms(proc_tn, good_subs, analysisPrms.subs, si_hist_fig_dir);

% C. Entire re-analysis of the data ignoring time-sensitive exclusion criteria (N = 36 included participants)
% Results saved in dedicated standalone workbook: SI_Reanalysis_noTimeExclusions.xlsx
[SI_Reanalysis_Summary, By_Sub_SI_noTimeExclusion, Full_Traj_Permutation_Stats] = ...
    generate_si_reanalysis_flavor(analysisPrms);
full_stats_tables.SI_Reanalysis_Summary       = SI_Reanalysis_Summary;
full_stats_tables.By_Sub_SI_noTimeExclusion   = By_Sub_SI_noTimeExclusion;
full_stats_tables.Full_Traj_Permutation_Stats = Full_Traj_Permutation_Stats;

%% Plot effect sizes & QQ plots
plot_and_save_effect_sizes(effects_tbl, within_tbl);
plot_and_save_qq_plots(full_stats_tables.rawAggData, good_subs, analysisPrms.targetFigs_allAnalysesCombined);

%% 11. Perceptual Awareness Scores (PAS) Suite: Table 2, rm-ANOVA & Level-by-Level Paired Tests
if ~isfield(full_stats_tables, 'primeAwarenessDist') || ~isfield(full_stats_tables.primeAwarenessDist, 'PAS_Summary')
    agg_file = fullfile(proc_tn, 'avg_each_day2_target_x_to_subs_47_49-85_87-90.mat');
    if exist(agg_file, 'file')
        c_agg = load(agg_file);
        [pas_summary_table, pas_by_sub_table, pas_stats_table, kb_PAS_Pct_Table, reach_PAS_Pct_Table] = ...
            compute_pas_analyses(c_agg.reach_avg_each, c_agg.keyboard_avg_each, good_subs, analysisPrms.targetStats_allAnalysesCombined);
        full_stats_tables.primeAwarenessDist = struct(...
            'Keyboard', kb_PAS_Pct_Table, ...
            'Reaching', reach_PAS_Pct_Table, ...
            'PAS_Summary', pas_summary_table, ...
            'PAS_Statistical_Tests', pas_stats_table, ...
            'PAS_By_Sub', pas_by_sub_table);
    end
end

%% Save all outcomes (figures, All_Statistics.mat, All_Statistics.xlsx, Master_TreeBH_and_Stats_Results.mat):
printAndSave(final_fig_handles, full_stats_tables, analysisPrms);
