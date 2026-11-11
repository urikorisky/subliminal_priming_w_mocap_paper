function [] = printAndSave(final_fig_handles, full_stats_tables, analysisParameters)
%PRINTANDSAVE Saves all the figures and statistics produced in the analysis

    if nargin == 2
        analysisParameters = full_stats_tables;
        full_stats_tables = final_fig_handles;
        final_fig_handles = struct();
    elseif nargin < 2
        error('printAndSave requires at least full_stats_tables and analysisParameters');
    end

    if ~isfield(analysisParameters, 'targetFigs_allAnalysesCombined')
        baseFigsFldr = '../figures';
    else
        baseFigsFldr = analysisParameters.targetFigs_allAnalysesCombined;
    end
    if ~exist(baseFigsFldr, 'dir'), mkdir(baseFigsFldr); end

    if ~isfield(analysisParameters, 'targetStats_allAnalysesCombined')
        statsFldr = '../statistics';
    else
        statsFldr = analysisParameters.targetStats_allAnalysesCombined;
    end

    % Save all figures by category / flavor at 300 DPI:
    if ~isempty(final_fig_handles) && isstruct(final_fig_handles)
        figFields = fields(final_fig_handles)';
        for cField = figFields
            fieldName = cField{1};
            % TreeBH, Cross-Flavor Trajectory Comparison, Supplementary COM, and JZS Hierarchy are already exported at 300 DPI
            if strcmp(fieldName, 'TreeBH') || strcmp(fieldName, 'Fig_Full_Trajectory_Flavor_Comparison') || ...
               strcmp(fieldName, 'Supplementary_COM') || strcmp(fieldName, 'Fig_JZS_Bayesian_Model_Hierarchy')
                continue;
            end
            val = final_fig_handles.(fieldName);
            if isstruct(val)
                flavorName = fieldName;
                flavorFldr = fullfile(baseFigsFldr, flavorName);
                if ~exist(flavorFldr, 'dir'), mkdir(flavorFldr); end

                subFigFields = fields(val)';
                for cSubFig = subFigFields
                    fHandle = val.(cSubFig{1});
                    if isgraphics(fHandle, 'figure')
                        save_highres_fig(fHandle, fullfile(flavorFldr, cSubFig{1}));
                    end
                end
            elseif isgraphics(val, 'figure')
                save_highres_fig(val, fullfile(baseFigsFldr, fieldName));
            end
        end
    end

    % Save all the statistics in one MAT file:
    if ~exist(statsFldr, 'dir'), mkdir(statsFldr); end
    save(fullfile(statsFldr, 'All_Statistics.mat'), 'full_stats_tables');
    if isfield(full_stats_tables, 'TreeBH_Results')
        TreeBH_Results = full_stats_tables.TreeBH_Results;
        save(fullfile(statsFldr, 'Master_TreeBH_and_Stats_Results.mat'), 'TreeBH_Results');
    end

    % Print all the relevant statistics into one clean workbook:
    xlsxFile = fullfile(statsFldr, 'All_Statistics.xlsx');

    if exist(xlsxFile, 'file')
        try, delete(xlsxFile); catch, end
        if exist(xlsxFile, 'file')
            warning('Could not overwrite %s (file is likely open in Excel). Writing to All_Statistics_updated.xlsx instead.', xlsxFile);
            xlsxFile = fullfile(statsFldr, 'All_Statistics_updated.xlsx');
            if exist(xlsxFile, 'file')
                try, delete(xlsxFile); catch, end
            end
        end
    end

    try
        writeAllStatsWorkbook(xlsxFile, full_stats_tables, analysisParameters);
        fprintf('Successfully exported statistics to: %s\n', xlsxFile);
    catch ME
        warning('Failed writing to %s (%s). Attempting fallback to All_Statistics_updated.xlsx...', xlsxFile, ME.message);
        fallbackFile = fullfile(statsFldr, 'All_Statistics_updated.xlsx');
        if exist(fallbackFile, 'file')
            try, delete(fallbackFile); catch, end
        end
        writeAllStatsWorkbook(fallbackFile, full_stats_tables, analysisParameters);
        fprintf('Successfully exported statistics to fallback: %s\n', fallbackFile);
    end

end

function save_highres_fig(fHandle, basePath)
    try
        savefig(fHandle, [basePath '.fig']);
    catch
        try, saveas(fHandle, [basePath '.fig']); catch, end
    end
    try
        exportgraphics(fHandle, [basePath '.png'], 'Resolution', 300);
    catch
        try, saveas(fHandle, [basePath '.png']); catch, end
    end
end

function writeAllStatsWorkbook(xlsxFile, full_stats_tables, analysisParameters)
    % 1. Individual Flavor Statistics Sheets (Strictly Scoped to Relevant Analyses)
    if isfield(analysisParameters, 'analysisRounds')
        rounds = analysisParameters.analysisRounds;
    else
        rounds = {'noTrajNorm_noStandardization', 'TrajNorm_noStandardization', 'TrajNorm_Standardization'};
    end
    for iR = 1:numel(rounds)
        rName = matlab.lang.makeValidName(rounds{iR});
        if isfield(full_stats_tables, rName) && istable(full_stats_tables.(rName)) && ~isempty(full_stats_tables.(rName))
            writetable(full_stats_tables.(rName), xlsxFile, 'Sheet', rName);
        end
    end

    % 1b. Participant-Level Statistics Sheets (Per-Subject Measures & Group Averages)
    if isfield(full_stats_tables, 'Participant_Measures') && isstruct(full_stats_tables.Participant_Measures)
        pm = full_stats_tables.Participant_Measures;
        statsFldr = fileparts(xlsxFile);
        if isfield(pm, 'TrajNorm_noStandardization') && istable(pm.TrajNorm_noStandardization)
            writetable(pm.TrajNorm_noStandardization, xlsxFile, 'Sheet', 'By_Sub_TrajNorm_noStd');
            writetable(pm.TrajNorm_noStandardization, fullfile(statsFldr, 'Participant_Measures_TrajNorm_noStandardization.csv'));
        end
        if isfield(pm, 'TrajNorm_Standardization') && istable(pm.TrajNorm_Standardization)
            writetable(pm.TrajNorm_Standardization, xlsxFile, 'Sheet', 'By_Sub_TrajNorm_Std');
            writetable(pm.TrajNorm_Standardization, fullfile(statsFldr, 'Participant_Measures_TrajNorm_Standardization.csv'));
        end
        if isfield(pm, 'noTrajNorm_noStandardization') && istable(pm.noTrajNorm_noStandardization)
            writetable(pm.noTrajNorm_noStandardization, xlsxFile, 'Sheet', 'By_Sub_noTrajNorm');
            writetable(pm.noTrajNorm_noStandardization, fullfile(statsFldr, 'Participant_Measures_noTrajNorm_noStandardization.csv'));
        end
    end

    % 2. Full Trajectory Permutation Stats (Only Relevant Analyzed Features per Flavor)
    if isfield(full_stats_tables, 'fullTrajAnalysis') && istable(full_stats_tables.fullTrajAnalysis)
        writetable(full_stats_tables.fullTrajAnalysis, xlsxFile, 'Sheet', 'Full_Traj_Permutation_Stats');
    end

    % 3. Bootstrap Effect Sizes & Within-Flavor Comparisons (No redundant Cross-Flavor sheet)
    if isfield(full_stats_tables, 'Effect_Sizes') && istable(full_stats_tables.Effect_Sizes)
        writetable(full_stats_tables.Effect_Sizes, xlsxFile, 'Sheet', 'Effect_Sizes_Summary');
    end
    if isfield(full_stats_tables, 'Effect_Comparisons_Within') && istable(full_stats_tables.Effect_Comparisons_Within)
        writetable(full_stats_tables.Effect_Comparisons_Within, xlsxFile, 'Sheet', 'Effect_Comparisons_Within');
    end

    % 4. Normality, Outlier Detection & Permutation Statistics
    if isfield(full_stats_tables, 'Normality_and_Permutations_Table') && istable(full_stats_tables.Normality_and_Permutations_Table)
        writetable(full_stats_tables.Normality_and_Permutations_Table, xlsxFile, 'Sheet', 'Normality_&_Permutations');
    end

    % 5. Curated Discrete Congruency Effects with TreeBH q-values
    if isfield(full_stats_tables, 'analyzed_stats_tables') && istable(full_stats_tables.analyzed_stats_tables)
        writetable(full_stats_tables.analyzed_stats_tables, xlsxFile, 'Sheet', 'Congruency_Effects_FDR_corr');
    end

    % 6. Excluded Trials Statistics (Summary + Per-Modality/Flavor Breakdowns in %)
    if isfield(full_stats_tables, 'trialExclusionStats') && isstruct(full_stats_tables.trialExclusionStats)
        ex = full_stats_tables.trialExclusionStats;
        if isfield(ex, 'Summary') && istable(ex.Summary)
            writetable(ex.Summary, xlsxFile, 'Sheet', 'Excluded_Trials_Summary');
        end
        if isfield(ex, 'Keyboard') && istable(ex.Keyboard)
            writetable(ex.Keyboard, xlsxFile, 'Sheet', 'Table_1_Keyboard');
        end
        if isfield(ex, 'Reach_TrajNorm') && istable(ex.Reach_TrajNorm)
            writetable(ex.Reach_TrajNorm, xlsxFile, 'Sheet', 'Table_1_Reach_TrajNorm');
        end
        if isfield(ex, 'Reach_noTrajNorm') && istable(ex.Reach_noTrajNorm)
            writetable(ex.Reach_noTrajNorm, xlsxFile, 'Sheet', 'Table_1_Reach_noTrajNorm');
        end
    end

    % 7. Prime Awareness Tables (Table 2 Suite)
    if isfield(full_stats_tables, 'primeAwarenessDist')
        pad = full_stats_tables.primeAwarenessDist;
        if isfield(pad, 'PAS_Summary') && istable(pad.PAS_Summary)
            writetable(pad.PAS_Summary, xlsxFile, 'Sheet', 'Table_2_PAS_Summary');
            writetable(pad.PAS_Summary, fullfile(fileparts(xlsxFile), 'Table_2_PAS_Summary.csv'));
        end
        if isfield(pad, 'PAS_Statistical_Tests') && istable(pad.PAS_Statistical_Tests)
            writetable(pad.PAS_Statistical_Tests, xlsxFile, 'Sheet', 'Table_2_PAS_Statistical_Tests');
            writetable(pad.PAS_Statistical_Tests, fullfile(fileparts(xlsxFile), 'Table_2_PAS_Statistical_Tests.csv'));
        end
        if isfield(pad, 'Keyboard') && istable(pad.Keyboard)
            writetable(pad.Keyboard, xlsxFile, 'Sheet', 'Table_2_Keyboard');
        end
        if isfield(pad, 'Reaching') && istable(pad.Reaching)
            writetable(pad.Reaching, xlsxFile, 'Sheet', 'Table_2_Reaching');
        end
        if isfield(pad, 'PAS_By_Sub') && istable(pad.PAS_By_Sub)
            writetable(pad.PAS_By_Sub, xlsxFile, 'Sheet', 'Table_2_PAS_By_Sub');
            writetable(pad.PAS_By_Sub, fullfile(fileparts(xlsxFile), 'Table_2_PAS_By_Sub.csv'));
        end
    end

    if isfield(full_stats_tables, 'Prime_Performance_Stats') && istable(full_stats_tables.Prime_Performance_Stats)
        writetable(full_stats_tables.Prime_Performance_Stats, xlsxFile, 'Sheet', 'Prime_Obj_Aware');
    end
    if isfield(full_stats_tables, 'Prime_Performance_By_Sub') && istable(full_stats_tables.Prime_Performance_By_Sub)
        writetable(full_stats_tables.Prime_Performance_By_Sub, xlsxFile, 'Sheet', 'Prime_Obj_Aware_By_Sub');
        writetable(full_stats_tables.Prime_Performance_By_Sub, fullfile(fileparts(xlsxFile), 'Prime_Obj_Aware_By_Sub.csv'));
    end

    % 8. TreeBH & Chronological FDR Architecture Sheets
    if isfield(full_stats_tables, 'TreeBH_Results') && isstruct(full_stats_tables.TreeBH_Results)
        tb = full_stats_tables.TreeBH_Results;
        if isfield(tb, 'Tree1_Congruency_Table') && istable(tb.Tree1_Congruency_Table)
            writetable(tb.Tree1_Congruency_Table, xlsxFile, 'Sheet', 'Tree1_Congruency');
        end
        if isfield(tb, 'Tree2_Sensitivity_Table') && istable(tb.Tree2_Sensitivity_Table)
            writetable(tb.Tree2_Sensitivity_Table, xlsxFile, 'Sheet', 'Tree2_Sensitivity');
        end
        if isfield(tb, 'FigS1_Original_PreReg_Table') && istable(tb.FigS1_Original_PreReg_Table)
            writetable(tb.FigS1_Original_PreReg_Table, xlsxFile, 'Sheet', 'FigS1_Original_PreReg');
        end
        if isfield(tb, 'FigS2a_Congruency_Std_Table') && istable(tb.FigS2a_Congruency_Std_Table)
            writetable(tb.FigS2a_Congruency_Std_Table, xlsxFile, 'Sheet', 'FigS2a_Congruency_Std');
        end
        if isfield(tb, 'FigS2b_Sensitivity_Std_Table') && istable(tb.FigS2b_Sensitivity_Std_Table)
            writetable(tb.FigS2b_Sensitivity_Std_Table, xlsxFile, 'Sheet', 'FigS2b_Sensitivity_Std');
        end
        if isfield(tb, 'Component4_Continuous_FDR') && istable(tb.Component4_Continuous_FDR)
            writetable(tb.Component4_Continuous_FDR, xlsxFile, 'Sheet', 'Chrono_Traj_Clusters');
        end
        if isfield(tb, 'Component6_Sensitivity_Contrasts') && istable(tb.Component6_Sensitivity_Contrasts)
            writetable(tb.Component6_Sensitivity_Contrasts, xlsxFile, 'Sheet', 'Chrono_Sensitivity_Contrasts');
        end
    end

    % 9. Split-Half Reliability (Spearman-Brown, 5,000 Splits)
    if isfield(full_stats_tables, 'Split_Half_Reliability') && istable(full_stats_tables.Split_Half_Reliability)
        writetable(full_stats_tables.Split_Half_Reliability, xlsxFile, 'Sheet', 'Split_Half_Reliability');
    end

    % 10. Supplementary Change-of-Mind (COM) Dwell-Time & Threshold Analysis
    if isfield(full_stats_tables, 'Supp_COM_Threshold_Stats') && istable(full_stats_tables.Supp_COM_Threshold_Stats)
        writetable(full_stats_tables.Supp_COM_Threshold_Stats, xlsxFile, 'Sheet', 'Supp_COM_Threshold_Stats');
    end
end
