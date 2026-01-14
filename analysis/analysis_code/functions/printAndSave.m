function [] = printAndSave(final_fig_handles,full_stats_tables,analysisParameters)
%PRINTANDSAVE Saves all the figures and statistics produced in the analysis
%   Detailed explanation goes here

    % Save all figures:
    % mkdir(analysisParameters.targetFigs_allAnalysesCombined);
    % for cFig = fields(final_fig_handles)'
    %     saveas(final_fig_handles.(cFig{1}),sprintf('%s/%s.fig',analysisParameters.targetFigs_allAnalysesCombined,cFig{1}))
    %     saveas(final_fig_handles.(cFig{1}),sprintf('%s/%s.png',analysisParameters.targetFigs_allAnalysesCombined,cFig{1}))
    % end

    % Save all the statistics in one MAT file:
    statsFldr = analysisParameters.targetStats_allAnalysesCombined;
    mkdir(statsFldr);
    save(sprintf('%s/All_Statistics.mat',statsFldr),'full_stats_tables');
    
    % Print all the relevant statistics into one workbook:
    writetable(full_stats_tables.analyzed_stats_tables, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Congruency_Effects_FDR_corr');
    writetable(full_stats_tables.fullTrajAnalysis, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Full_Traj_FDR_corr');
    writetable(full_stats_tables.trialScreening.Keyboard, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_1_Keyboard');
    writetable(full_stats_tables.trialScreening.Reaching, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_1_Reaching');
    writetable(full_stats_tables.primeAwarenessDist.Keyboard, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_2_Keyboard');
    writetable(full_stats_tables.primeAwarenessDist.Reaching, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_2_Reaching');
    writetable(full_stats_tables.Prime_Performance_Stats, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Prime_Obj_Aware');

    

end