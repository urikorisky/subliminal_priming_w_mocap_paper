%% Script for recreating results from Khen, Korisky, Chapman, and Mudrik, 2025

% The script will prompt the user for preferences, marking the default
% options. For additional explanations, see code below.
clear;
addpath(genpath('./functions'));
%% Scaffolding
analysisPrms = getDebugAnalysisParams();

%% User Prompting
%<TODO>

%% Iterate over analysis rounds
% Analyses are done in several fashions, depending on these criteria:
% (1) Normalization: Whether the reaching trajectories are normalized over
% time (true) or are trimmed at 340ms (false)
% (2) Standardization: Whether the nominal measures, summing a trajectory
% by one value, are z-scored within a participant, over all the trials.

for iRound = 1:numel(analysisPrms.analysisRounds)
    analysis_pipeline(analysisPrms,iRound)
end