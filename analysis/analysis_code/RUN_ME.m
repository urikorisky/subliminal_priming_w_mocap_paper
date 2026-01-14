%% Script for recreating results from Khen, Korisky, Chapman, and Mudrik, 2026
%
% This script reproduces all the plots and statistics mentioned in the
% manuscript.
%
% To analyze the data starting from the raw data files, download them from:
% https://osf.io/8dsvp
% copy the files to a designated folder, and put its path below in the
% "Parameters" section, for analysisPrms.rawDataFolder
%
% By default, the output figures and statistics will be saved into
% analysis/figures and analysis/statistics, respectively.
% The figures are saved in both FIG and PNG formats.
% The statistics are saved in whole as a MAT file and separately in an XLSX
% file with a different sheet for each analysis that appears in the
% manuscript
%
% Technical Requirements:
% - Matlab's bioinformatics toolbox (for the mafdr() function used in the
% FDR correction)


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

[FDR_corr_analyzed_stats_tables,final_fig_handles.TreeBH] = Calc_and_plot_TreeBH(full_stats_tables);
% full_stats_tables.FDR_corr_analyzed_stats_tables = FDR_corr_analyzed_stats_tables;
%% Save all outcomes:

printAndSave(final_fig_handles,FDR_corr_analyzed_stats_tables,analysisPrms)
