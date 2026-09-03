% Plots the average reach area of each subject.
% plt_p - struct of plotting params.
% p - struct of exp params.
% p_val_ra - p-value of the statistical test.
function outStats = plotMultiReachArea(traj_names, plt_p, p,plotFlag)

        for iTraj = 1:length(traj_names)
            good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;
            reach_avg_each = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  reach_avg_each = reach_avg_each.reach_avg_each;
            hold on;
            con_ra = reach_avg_each.ra.con(good_subs);
            incon_ra = reach_avg_each.ra.incon(good_subs);
            if ~p.NORMALIZE_WITHIN_SUB
                if ~p.NORM_TRAJ
                    if mean(con_ra, 'omitnan') < 0.5
                        con_ra = con_ra * 10000;
                        incon_ra = incon_ra * 10000;
                    end
                    yLabel = 'Area (cm^2)';
                else
                    yLabel = 'Area'; % Since traj is in %path_traveled, reach area has no units.
                end
            else
                yLabel = 'Area (z-score)';
            end

            if(plotFlag)    
                % Load data and set params.
                beesdata = {con_ra, incon_ra};
                XTickLabels = ["Congruent","Incongruent"];
                colors = {plt_p.con_col, plt_p.incon_col};
                title_char = 'Reach Area';
                % Plot
                if length(good_subs) > 200 % beeswarm doesn't look good with many subs.
                    makeItRain(beesdata, colors, title_char, yLabel, plt_p);
                else
                    printBeeswarm(beesdata, yLabel, XTickLabels, colors, plt_p.space, title_char, plt_p.errbar_type, plt_p.alpha_size);    
                    % Connect each sub's dots with lines.
                    y_data = [con_ra; incon_ra];
                    x_data = reshape(get(gca,'XTick'), 2,[]);
                    x_data = repelem(x_data,1,length(good_subs));
                    connect_dots(x_data, y_data);
                    if p.NORMALIZE_WITHIN_SUB || ~p.NORM_TRAJ
                        y_all = [beesdata{1}(:); beesdata{2}(:)];
                        min_y = min(y_all, [], 'omitnan');
                        max_y = max(y_all, [], 'omitnan');
                        if isempty(min_y) || isnan(min_y) || min_y >= max_y
                            min_y = -1; max_y = 1;
                        end
                        pad = max(0.1, (max_y - min_y) * 0.15);
                        ylim([min_y - pad, max_y + pad]);
                    else
                        ylim([0.85 4]);
                        yticks(0.5 : 0.5 : 3.5);
                    end
                end
                
                ticks = get(gca,'XTick');
                xticks([]);
                set(gca, 'TickDir','out');
                set(gca, 'FontSize',plt_p.font_size);
                set(gca, 'FontName',plt_p.font_name);
                set(gca, 'linewidth',plt_p.axes_line_thickness);
            end
        % Legend.
%         h = [];
%         h(1) = bar(NaN,NaN,'FaceColor',plt_p.con_col, 'ShowBaseLine','off');
%         h(2) = bar(NaN,NaN,'FaceColor',plt_p.incon_col, 'ShowBaseLine','off');
%         h(3) = plot(NaN,NaN,'k','linewidth',14);
%         legend(h,'Congruent','Incongruent', 'Location','northwest');

            % T-test and Cohen's dz
            [~, p_val_ra, ci_ra, stats_ra] = ttest(reach_avg_each.ra.con(good_subs), reach_avg_each.ra.incon(good_subs));
    %         cohens_dz_ra = stats_ra.tstat / sqrt(length(good_subs));
    %         graph_height = y_limit(2) - y_limit(1);
    %         text(mean(ticks(1:2)), graph_height/10, ['p-value: ' num2str(p_val_ra)], 'HorizontalAlignment','center', 'FontSize',14);
    %         text(mean(ticks(1:2)), graph_height/7, ['Cohens d_z: ' num2str(cohens_dz_ra)], 'HorizontalAlignment','center', 'FontSize',14);
    
            % Print stats to terminal.
            outStats = printStats('Reach Area', reach_avg_each.ra.con(good_subs), ...
                reach_avg_each.ra.incon(good_subs), ["Con","Incon"], p_val_ra, ci_ra, stats_ra);
        end
end