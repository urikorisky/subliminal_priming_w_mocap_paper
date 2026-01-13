function [] = printAndSave(final_fig_handles,full_stats_tables,analysisParameters)
%PRINTANDSAVE Summary of this function goes here
%   Detailed explanation goes here

% Save all figures:
    % for cFig = fields(final_fig_handles)'
    %     saveas(final_fig_handles.(cFig{1}),sprintf('%s/%s.fig',analysisParameters.targetFigs_allAnalysesCombined,cFig{1}))
    %     saveas(final_fig_handles.(cFig{1}),sprintf('%s/%s.png',analysisParameters.targetFigs_allAnalysesCombined,cFig{1}))
    % end

% Save all the statistics in one MAT file:
statsFldr = analysisParameters.targetStats_allAnalysesCombined;
save(sprintf('%s/All_Statistics.mat',statsFldr),'full_stats_tables');
writetable(full_stats_tables.analyzed_stats_tables, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Congruency_Effects_FDR_corr');
writetable(full_stats_tables.trialScreening.Keyboard, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_1_Keyboard');
writetable(full_stats_tables.trialScreening.Reaching, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_1_Reaching');
writetable(full_stats_tables.primeAwarenessDist.Keyboard, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_2_Keyboard');
writetable(full_stats_tables.primeAwarenessDist.Reaching, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Table_2_Reaching');
writetable(full_stats_tables.Prime_Performance_Stats, sprintf('%s/All_Statistics.xlsx', statsFldr), 'Sheet','Prime_Obj_Aware');


% Print all the statistics into one workbook:
    

end