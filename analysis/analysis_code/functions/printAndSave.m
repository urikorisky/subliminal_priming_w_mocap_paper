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

    % Save all figures by category / flavor:
    figFields = fields(final_fig_handles)';
    for cField = figFields
        val = final_fig_handles.(cField{1});
        if isstruct(val)
            % It's a flavor struct containing figure handles
            flavorName = cField{1};
            flavorFldr = fullfile(baseFigsFldr, flavorName);
            if ~exist(flavorFldr, 'dir'), mkdir(flavorFldr); end
            
            subFigFields = fields(val)';
            for cSubFig = subFigFields
                fHandle = val.(cSubFig{1});
                if isgraphics(fHandle, 'figure')
                    saveas(fHandle, fullfile(flavorFldr, sprintf('%s.fig', cSubFig{1})));
                    saveas(fHandle, fullfile(flavorFldr, sprintf('%s.png', cSubFig{1})));
                end
            end
        elseif isgraphics(val, 'figure')
            % It's a top-level figure handle (e.g. TreeBH)
            saveas(val, fullfile(baseFigsFldr, sprintf('%s.fig', cField{1})));
            saveas(val, fullfile(baseFigsFldr, sprintf('%s.png', cField{1})));
        end
    end

    % Save all the statistics in one MAT file:
    if ~exist(statsFldr, 'dir'), mkdir(statsFldr); end
    save(fullfile(statsFldr, 'All_Statistics.mat'), 'full_stats_tables');
    if isfield(full_stats_tables, 'TreeBH_Results')
        TreeBH_Results = full_stats_tables.TreeBH_Results;
        save(fullfile(statsFldr, 'Master_TreeBH_and_Stats_Results.mat'), 'TreeBH_Results');
    end
    
    % Print all the relevant statistics into one workbook:
    xlsxFile = fullfile(statsFldr, 'All_Statistics.xlsx');
    
    % If file exists, try to delete it first to ensure clean sheet names without leftover sheets
    if exist(xlsxFile, 'file')
        try
            delete(xlsxFile);
        catch
        end
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

function writeAllStatsWorkbook(xlsxFile, full_stats_tables, analysisParameters)
    % 1. Individual Flavor Statistics Sheets
    if isfield(analysisParameters, 'analysisRounds')
        rounds = analysisParameters.analysisRounds;
    else
        rounds = {'noTrajNorm_noStandardization', 'TrajNorm_noStandardization', 'TrajNorm_Standardization'};
    end
    for iR = 1:numel(rounds)
        rName = matlab.lang.makeValidName(rounds{iR});
        if isfield(full_stats_tables, rName) && istable(full_stats_tables.(rName))
            writetable(full_stats_tables.(rName), xlsxFile, 'Sheet', rName);
        end
    end
    
    % 2. Full Trajectory Permutation Stats
    if isfield(full_stats_tables, 'fullTrajAnalysis') && istable(full_stats_tables.fullTrajAnalysis)
        writetable(full_stats_tables.fullTrajAnalysis, xlsxFile, 'Sheet', 'Full_Traj_Permutation_Stats');
    end
    
    % 3. Effect Sizes & Comparisons
    if isfield(full_stats_tables, 'Effect_Sizes') && istable(full_stats_tables.Effect_Sizes)
        writetable(full_stats_tables.Effect_Sizes, xlsxFile, 'Sheet', 'Effect_Sizes_Summary');
    end
    if isfield(full_stats_tables, 'Effect_Comparisons_Within') && istable(full_stats_tables.Effect_Comparisons_Within)
        writetable(full_stats_tables.Effect_Comparisons_Within, xlsxFile, 'Sheet', 'Effect_Comparisons_Within');
    end
    if isfield(full_stats_tables, 'Effect_Comparisons_Cross') && istable(full_stats_tables.Effect_Comparisons_Cross)
        writetable(full_stats_tables.Effect_Comparisons_Cross, xlsxFile, 'Sheet', 'Effect_Comparisons_Cross');
    end
    
    % 4. Normality, Outlier Detection & Permutation Statistics
    if isfield(full_stats_tables, 'Normality_and_Permutations_Table') && istable(full_stats_tables.Normality_and_Permutations_Table)
        writetable(full_stats_tables.Normality_and_Permutations_Table, xlsxFile, 'Sheet', 'Normality_&_Permutations');
    end

    % 5. Curated FDR-corrected stats (if present)
    if isfield(full_stats_tables, 'analyzed_stats_tables') && istable(full_stats_tables.analyzed_stats_tables)
        writetable(full_stats_tables.analyzed_stats_tables, xlsxFile, 'Sheet', 'Congruency_Effects_FDR_corr');
    end
    
    % 6. Screening & Awareness Tables
    if isfield(full_stats_tables, 'trialScreening')
        if isfield(full_stats_tables.trialScreening, 'Keyboard')
            writetable(full_stats_tables.trialScreening.Keyboard, xlsxFile, 'Sheet', 'Table_1_Keyboard');
        end
        if isfield(full_stats_tables.trialScreening, 'Reaching')
            writetable(full_stats_tables.trialScreening.Reaching, xlsxFile, 'Sheet', 'Table_1_Reaching');
        end
    end
    
    if isfield(full_stats_tables, 'primeAwarenessDist')
        if isfield(full_stats_tables.primeAwarenessDist, 'Keyboard')
            writetable(full_stats_tables.primeAwarenessDist.Keyboard, xlsxFile, 'Sheet', 'Table_2_Keyboard');
        end
        if isfield(full_stats_tables.primeAwarenessDist, 'Reaching')
            writetable(full_stats_tables.primeAwarenessDist.Reaching, xlsxFile, 'Sheet', 'Table_2_Reaching');
        end
    end
    
    if isfield(full_stats_tables, 'Prime_Performance_Stats') && istable(full_stats_tables.Prime_Performance_Stats)
        writetable(full_stats_tables.Prime_Performance_Stats, xlsxFile, 'Sheet', 'Prime_Obj_Aware');
    end
    
    % 7. TreeBH Architecture Sheets
    if isfield(full_stats_tables, 'TreeBH_Results') && isstruct(full_stats_tables.TreeBH_Results)
        tb = full_stats_tables.TreeBH_Results;
        if isfield(tb, 'Tree1_Main_Table') && istable(tb.Tree1_Main_Table)
            writetable(tb.Tree1_Main_Table, xlsxFile, 'Sheet', 'Tree1_Congruency_Flavor1');
        end
        if isfield(tb, 'TreeS1_PreReg_Table') && istable(tb.TreeS1_PreReg_Table)
            writetable(tb.TreeS1_PreReg_Table, xlsxFile, 'Sheet', 'TreeS1_PreReg_Original');
        end
        if isfield(tb, 'TreeS2_Standard_Table') && istable(tb.TreeS2_Standard_Table)
            writetable(tb.TreeS2_Standard_Table, xlsxFile, 'Sheet', 'TreeS2_Standardized');
        end
        if isfield(tb, 'Tree2_Sensitivity_Table') && istable(tb.Tree2_Sensitivity_Table)
            writetable(tb.Tree2_Sensitivity_Table, xlsxFile, 'Sheet', 'Tree2_Relative_Sensitivity');
        end
        if isfield(tb, 'TreeSI2_Sensitivity_Standard_Table') && istable(tb.TreeSI2_Sensitivity_Standard_Table)
            writetable(tb.TreeSI2_Sensitivity_Standard_Table, xlsxFile, 'Sheet', 'TreeSI2_Sensitivity_Standard');
        end
        if isfield(tb, 'Component4_Continuous_FDR') && istable(tb.Component4_Continuous_FDR)
            writetable(tb.Component4_Continuous_FDR, xlsxFile, 'Sheet', 'Chrono_Traj_Clusters');
        end
        if isfield(tb, 'Component6_Sensitivity_Contrasts') && istable(tb.Component6_Sensitivity_Contrasts)
            writetable(tb.Component6_Sensitivity_Contrasts, xlsxFile, 'Sheet', 'Chrono_Sensitivity_Contrasts');
        end
    end
end