% Plots the average (over good subs) recognition performance.
% Plots both measures (kb, reach) together in the same plot,
% separate plots for congruent and incongruent trials.

% group - which participants to analyze: 'all_subs', 'good_subs'.
% plt_p - struct of plotting params.
% p - struct of exp params.
function [figHandles,outStats] = plotMultiRecognition_SepByCong(group, traj_name, plt_p, p)
    outStats = table();    

    good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_name '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;
    
    % Change plot parameter to make it plot CIs and not SE:
    plt_p.errbar_type = 'ci';

    % What subs to analyze.
    if isequal(group, 'all_subs')
        subs = p.SUBS;
    elseif isequal(group, 'good_subs')
        subs = good_subs;
    else
        error('Wrong input, use all_subs or good_subs.');
    end
    
    measures = {'reach','keyboard'};
    measureNames = {'Reaching','Key Press'};
    congTypes = {'incon','con'};
    congNames.incon = 'Incongruent';
    congNames.con = 'Congruent';
    figNames.incon = 'Figure 2';
    figNames.con = 'Supp. Figure 3';
    for conType = congTypes
        conT = conType{1};
        title_char = [congNames.(conT) ' Trials'];
        title_char = sprintf('%s: Objective Awareness Task Performance, %s',figNames.(conT),title_char);
        figHandles.(conT) = figure("Name",title_char);
        for measure=measures
            cMeas = measure{1};
            % Load data.
            avg_each.(cMeas) = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_name '_subs_' p.SUBS_STRING '.mat']);  avg_each.(cMeas) = avg_each.(cMeas).([cMeas '_avg_each']);
            % Convert to %.
            avg_each.(cMeas).fc_prime.(conT) = avg_each.(cMeas).fc_prime.(conT)* 100;
        end
        beesdata = {avg_each.(measures{1}).fc_prime.(conT)(subs), avg_each.(measures{2}).fc_prime.(conT)(subs)};
        % Plot.
        YLabel = "Performance (%)";
        XTickLabel = measureNames;
        colors = {plt_p.([conT '_col']), plt_p.([conT '_col'])};%{plt_p.con_col, plt_p.incon_col};
        
        printBeeswarm(beesdata, YLabel, XTickLabel, colors, plt_p.space, title_char, plt_p.errbar_type, plt_p.alpha_size);
        % Plot chance level.
        plot([-20 20], [50 50], '--', 'color',[0.3 0.3 0.3 plt_p.f_alpha], 'linewidth',2);

        set(gca, 'FontSize',plt_p.font_size);
        set(gca, 'FontName',plt_p.font_name);
        set(gca, 'linewidth',plt_p.axes_line_thickness);

    
        % T-test on plot.
        kb_data = avg_each.(measures{2}).fc_prime.(conT)(subs);
        reach_data = avg_each.(measures{1}).fc_prime.(conT)(subs);
        [~, fc_p_val_reach , fc_ci_reach, fc_stats_reach] = ttest(reach_data, 50);
        [~, fc_p_val_kb , fc_ci_kb, fc_stats_kb] = ttest(kb_data, 50);

        cStats = struct(...
            'Trial_Type',string(conT),...
            'kb_avg',mean(kb_data),...
            'kb_std',std(kb_data),...
            'reach_avg',mean(reach_data),...
            'reach_std',std(reach_data),...
            'kb_tVal',fc_stats_kb.tstat,...
            'kb_df',fc_stats_kb.df,...
            'kb_pVal',fc_p_val_kb,...
            'kb_CI_low',fc_ci_kb(1),...
            'kb_CI_high',fc_ci_kb(2),...
            'reach_tVal',fc_stats_reach.tstat,...
            'reach_df',fc_stats_reach.df,...
            'reach_pVal',fc_p_val_reach,...
            'reach_CI_low',fc_ci_reach(1),...
            'reach_CI_high',fc_ci_reach(2)...
        );
        outStats = transferStatsToStatsTable(struct2table(cStats),outStats);

    end
end