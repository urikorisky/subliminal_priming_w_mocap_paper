% Plots the average MAD of each subject, dividing only by congruency (and
% not side). URI's edit, actually a copy of "plotMultiReachArea.m" which I
% edited.
% plt_p - struct of plotting params.
% p - struct of exp params.
% p_val_ra - p-value of the statistical test.
function [p_val_mad] = plotMultiMad_CongIncong(traj_names, plt_p, p)
    for iTraj = 1:length(traj_names)
        good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;
        reach_avg_each = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  reach_avg_each = reach_avg_each.reach_avg_each;
        hold on;

        % Load data and set aparms.
        beesdata = {reach_avg_each.mad.con(good_subs) reach_avg_each.mad.incon(good_subs)};
        yLabel = 'MAD (cm)';
        XTickLabels = ["Congruent","Incongruent"];
        colors = {plt_p.con_col, plt_p.incon_col};
        title_char = 'MAD';
        % Plot
        if length(good_subs) > 200 % beeswarm doesn't look good with many subs.
            makeItRain(beesdata, colors, title_char, yLabel, plt_p);
        else
            printBeeswarm(beesdata, yLabel, XTickLabels, colors, plt_p.space, title_char, plt_p.errbar_type, plt_p.alpha_size);    
            % Connect each sub's dots with lines.
            y_data = [reach_avg_each.mad.con(good_subs); reach_avg_each.mad.incon(good_subs)];
            x_data = reshape(get(gca,'XTick'), 2,[]);
            x_data = repelem(x_data,1,length(good_subs));
            connect_dots(x_data, y_data);
            ylims=ylim();
            ylim([ylims(1),ylims(2)*1.2]);
            yticklabels(cellfun(@(x) round(100*str2double(x)), yticklabels));
            
            % yticks(0.5 : 0.5 : 3.5);
        end
        
        ticks = get(gca,'XTick');
        xticks([]);
        set(gca, 'TickDir','out');
        set(gca, 'FontSize',plt_p.font_size);
        set(gca, 'FontName',plt_p.font_name);
        set(gca, 'linewidth',plt_p.axes_line_thickness);
        % Legend.
%         h = [];
%         h(1) = bar(NaN,NaN,'FaceColor',plt_p.con_col, 'ShowBaseLine','off');
%         h(2) = bar(NaN,NaN,'FaceColor',plt_p.incon_col, 'ShowBaseLine','off');
%         h(3) = plot(NaN,NaN,'k','linewidth',14);
%         legend(h,'Congruent','Incongruent', 'Location','northwest');

        % T-test and Cohen's dz
        [~, p_val_mad, ci_mad, stats_mad] = ttest(reach_avg_each.mad.con(good_subs), reach_avg_each.mad.incon(good_subs));
%         cohens_dz_ra = stats_ra.tstat / sqrt(length(good_subs));
%         graph_height = y_limit(2) - y_limit(1);
%         text(mean(ticks(1:2)), graph_height/10, ['p-value: ' num2str(p_val_ra)], 'HorizontalAlignment','center', 'FontSize',14);
%         text(mean(ticks(1:2)), graph_height/7, ['Cohens d_z: ' num2str(cohens_dz_ra)], 'HorizontalAlignment','center', 'FontSize',14);

        % Print stats to terminal.
        printStats('-----Reach Area------------', reach_avg_each.mad.con(good_subs), ...
            reach_avg_each.mad.incon(good_subs), ["Con","Incon"], p_val_mad, ci_mad, stats_mad);
    end
end