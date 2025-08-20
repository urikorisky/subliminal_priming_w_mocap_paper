% Plots the average (over good subjects) STD in the X axis on each point along the taj.
% Seperates to conditions and sides.
% subplot_p - parameters for 'subplot' command for each of the 2 subplots.
% plt_p - struct of plotting params.
% p - struct of exp params.
function [] = plotMultiXStd_URI(traj_names, plt_p, p)

    for iTraj = 1:length(traj_names)
        left_right = ["left", "right"];
        good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;
        % Avg of each sub.
        avg_each = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  avg_each = avg_each.reach_avg_each;
        % Avg over all subs.
        subs_avg = load([p.PROC_DATA_FOLDER '/subs_avg_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  subs_avg = subs_avg.reach_subs_avg;

        % Plot time instead of Z axis.
        if plt_p.x_as_func_of == "time"
            assert(~p.NORM_TRAJ, "When traj is normalized in space, time isn't releveant and shouldnt be used");
            % Array with timing of each sample.
            time_series = (1 : size(subs_avg.traj.con_left,1)) * p.SAMPLE_RATE_SEC;
            x_axis = time_series;
            x_label = 'Time (ms)';
            xlimit = [0 p.MIN_SAMP_LEN]; % For plot.
        else
            x_axis = subs_avg.traj.con_left(:,3)*100;
            assert(p.NORM_TRAJ, "Uses identical Z to all trajs, assumes trajs are normalized.")
            x_label = '% Path traveled';
            xlimit = [0, 100];
        end

        % Unite sides to single var.
        x_std_con = {subs_avg.x_std.con_left, subs_avg.x_std.con_right};
        x_std_incon = {subs_avg.x_std.incon_left, subs_avg.x_std.incon_right};
        
        
        hold on;
        % Plot.
        stdshade(avg_each.x_std.con(:,good_subs)', plt_p.f_alpha, plt_p.con_col, x_axis, 0, 1, plt_p.errbar_type, plt_p.alpha_size, plt_p.linewidth);
        stdshade(avg_each.x_std.incon(:,good_subs)', plt_p.f_alpha, plt_p.incon_col, x_axis, 0, 1, plt_p.errbar_type, plt_p.alpha_size, plt_p.linewidth);

        % plot(xlimit, [0 0], '--', 'linewidth',3, 'color',[0.15 0.15 0.15 plt_p.f_alpha]); % Zero line.

        % Permutation testing.
        clusters = permCluster(avg_each.x_std.con(:,good_subs), avg_each.x_std.incon(:,good_subs), plt_p.n_perm, plt_p.n_perm_clust_tests);

        % Plot clusters.
        if ~isempty(clusters)
            y_lim = get(gca, 'ylim');
            points = [x_axis(clusters.start)'; x_axis(clusters.end)'];
            drawRectangle(points, 'x', y_lim, plt_p);
        end

        set(gca, 'TickDir','out');
        xlabel(x_label);

        labels_s=xticklabels();
        labels_ms = cellfun(@(x) num2str(round(str2double(x)*1000)),labels_s,'UniformOutput',false);
        xticklabels(labels_ms);


        ylabel('X-axis S.D.');
        title('Trajectory X-axis Standard Deviation');
        set(gca, 'FontSize',plt_p.font_size);
        set(gca, 'FontName',plt_p.font_name);
        set(gca,'linewidth',plt_p.axes_line_thickness);
        % Legend.
        h = [];
        h(1) = plot(nan,nan,'Color',plt_p.con_col, 'linewidth',plt_p.linewidth);
        h(2) = plot(nan,nan,'Color',plt_p.incon_col, 'linewidth',plt_p.linewidth);
        graphs = {'Congruent', 'Incongruent'};
%         if ~isempty(clusters)
%             h(3) = plot(nan,nan,'Color',[1, 1, 1, plt_p.f_alpha/2], 'linewidth',plt_p.linewidth);
%             graphs{3} = 'Significant';
%         end
        legend(h, graphs, 'Location','northwest');
        legend('boxoff');

        % Print stats to terminal.
        printTsStats('----Movement variation--------', clusters);
    end
end