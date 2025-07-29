% Plots the average (over good subs) recognition performance.
% URI function - plots both measures (kb, reach) together in the same plot,
% separate plots for congruent and incongruent trials. The congruent one
% might be added to the SI.
% group - which participants to analyze: 'all_subs', 'good_subs'.
% plt_p - struct of plotting params.
% p - struct of exp params.
function [] = plotMultiRecognition_SepByCong(group, traj_name, plt_p, p)
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
    for conType = congTypes
        conT = conType{1};
        figure();
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
        title_char = [congNames.(conT) ' Trials'];
        printBeeswarm(beesdata, YLabel, XTickLabel, colors, plt_p.space, title_char, plt_p.errbar_type, plt_p.alpha_size);
        % Plot chance level.
        plot([-20 20], [50 50], '--', 'color',[0.3 0.3 0.3 plt_p.f_alpha], 'linewidth',2);
        % ylim([0 100]);
    
        % set(gca, 'TickDir','out');
        % xticks([]);
        % yticks(plt_p.percent_path_ticks);
        set(gca, 'FontSize',plt_p.font_size);
        set(gca, 'FontName',plt_p.font_name);
        set(gca, 'linewidth',plt_p.axes_line_thickness);
        % Legend.
        % h = [];
        % h(1) = plot(nan,nan,'Color',plt_p.con_col, 'linewidth',plt_p.linewidth);
        % h(2) = plot(nan,nan,'Color',plt_p.incon_col, 'linewidth',plt_p.linewidth);
        % graphs = {'Congruent', 'Incongruent'};
        % legend(h, graphs, 'Location','southeast');
        % legend('boxoff');
    
        % T-test on plot.
        % [~, fc_p_val(1) , ~, ~] = ttest(avg_each.fc_prime.con(subs), 50);
        % [~, fc_p_val(2) , fc_ci, fc_stats] = ttest(avg_each.fc_prime.incon(subs), 50);
        % fc_p_val = round(fc_p_val, 3);
    %     text(get(gca, 'xTick'),[10 10], {['p = ' num2str(fc_p_val(1))], ['p = ' num2str(fc_p_val(2))]}, 'FontSize',14, 'HorizontalAlignment','center');
    
        % Print stats to terminal.
        % printStats(['@@@@-----Prime Forced Choice, ' group ', ' cMeas, '------------@@@@'], avg_each.fc_prime.con(subs), ...
        %     avg_each.fc_prime.incon(subs), ["Con","Incon"], fc_p_val(2), fc_ci, fc_stats);
    end
end