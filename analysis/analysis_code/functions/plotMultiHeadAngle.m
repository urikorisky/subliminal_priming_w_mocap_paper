% Plots the average heading angle (over subs) at each point along the trajectory.
% Optional 5th arg plotFlag (default true): when false, computes cluster permutation silently without plotting.
function [outStats] = plotMultiHeadAngle(traj_names, plt_p, p, xAxSource, plotFlag)
    if nargin < 5 || isempty(plotFlag)
        plotFlag = true;
    end
    err_bar_type = 'ci';
    outStats = [];

    good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{1}{1} '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;

    if ~plotFlag
        for iTraj = 1:length(traj_names)
            avg_each = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  avg_each = avg_each.reach_avg_each;
            rng(42, 'twister');
            clusters = permCluster(avg_each.head_angle.con(:,good_subs), avg_each.head_angle.incon(:,good_subs), plt_p.n_perm, plt_p.n_perm_clust_tests);
            if ~isempty(clusters)
                outStats = printTsStats('Heading angle', clusters);
            end
        end
        return;
    end

    switch(xAxSource)
        case 'xtime'
            for iTraj = 1:length(traj_names)
                hold on;
                avg_each = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  avg_each = avg_each.reach_avg_each;
                subs_avg = load([p.PROC_DATA_FOLDER '/subs_avg_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  subs_avg = subs_avg.reach_subs_avg;

                if plt_p.x_as_func_of == "time"
                    assert(~p.NORM_TRAJ, "When traj is normalized in space, time isn't relevant and shouldn't be used");
                    x_axis = (1 : size(subs_avg.traj.con_left,1)) * p.SAMPLE_RATE_SEC * 1000;
                    x_label = 'Time (ms)';
                    xlimit = [0 p.MIN_SAMP_LEN * 1000];
                    x_ticks = 0 : 50 : (p.MIN_SAMP_LEN * 1000);
                else
                    x_axis = subs_avg.traj.con_left(:,3) * 100;
                    assert(p.NORM_TRAJ, "Uses identical Z to all trajs, assumes trajs are normalized.");
                    x_label = 'Path Traveled (%)';
                    xlimit = [0 100];
                    x_ticks = 0 : 20 : 100;
                end

                stdshade(avg_each.head_angle(iTraj).con(:,good_subs)', plt_p.f_alpha*0.9, plt_p.con_col, x_axis, 0, 1, err_bar_type, plt_p.alpha_size, plt_p.linewidth);
                stdshade(avg_each.head_angle(iTraj).incon(:,good_subs)', plt_p.f_alpha*0.9, plt_p.incon_col, x_axis, 0, 1, err_bar_type, plt_p.alpha_size, plt_p.linewidth);
                plot(xlimit, [0 0], '--', 'linewidth',2, 'color',[0.15 0.15 0.15 plt_p.f_alpha]);

                rng(42, 'twister');
                clusters = permCluster(avg_each.head_angle.con(:,good_subs), avg_each.head_angle.incon(:,good_subs), plt_p.n_perm, plt_p.n_perm_clust_tests);

                y_lim = [-6 28];
                if ~isempty(clusters)
                    points = [x_axis(clusters.start)'; x_axis(clusters.end)'];
                    drawRectangle(points, 'x', y_lim, plt_p);
                end

                set(gca, 'TickDir','out');
                xlabel(x_label);
                xlim(xlimit);
                xticks(x_ticks);
                ylim(y_lim);
                yticks(-5 : 5 : 25);
                ylabel('Heading Angle (deg)');
                title('Heading Angle');
                set(gca, 'FontSize',plt_p.font_size);
                set(gca, 'FontName',plt_p.font_name);
                set(gca, 'linewidth',plt_p.axes_line_thickness);

                if ~isempty(clusters)
                    outStats = printTsStats('Heading angle', clusters);
                end
            end

        case 'xangle'
            for iTraj = 1:length(traj_names)
                hold on;
                avg_each = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  avg_each = avg_each.reach_avg_each;
                subs_avg = load([p.PROC_DATA_FOLDER '/subs_avg_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  subs_avg = subs_avg.reach_subs_avg;

                if plt_p.x_as_func_of == "time"
                    assert(~p.NORM_TRAJ, "When traj is normalized in space, time isn't relevant and shouldn't be used");
                    y_axis = (1 : size(subs_avg.traj.con_left,1)) * p.SAMPLE_RATE_SEC * 1000;
                    y_label = 'Time (ms)';
                    ylimit = [0 p.MIN_SAMP_LEN * 1000];
                    y_ticks = 0 : 50 : (p.MIN_SAMP_LEN * 1000);
                else
                    y_axis = subs_avg.traj.con_left(:,3) * 100;
                    assert(p.NORM_TRAJ, "Uses identical Z to all trajs, assumes trajs are normalized.");
                    y_label = 'Path Traveled (%)';
                    ylimit = [0 100];
                    y_ticks = 0 : 20 : 100;
                end

                xlimit = [-6 28];

                stdshade(avg_each.head_angle(iTraj).con(:,good_subs)', plt_p.f_alpha*0.9, plt_p.con_col, y_axis, 0, 0, err_bar_type, plt_p.alpha_size, plt_p.linewidth);
                stdshade(avg_each.head_angle(iTraj).incon(:,good_subs)', plt_p.f_alpha*0.9, plt_p.incon_col, y_axis, 0, 0, err_bar_type, plt_p.alpha_size, plt_p.linewidth);
                plot([0 0], ylimit, '--', 'linewidth',2, 'color',[0.15 0.15 0.15 plt_p.f_alpha]);

                rng(42, 'twister');
                clusters = permCluster(avg_each.head_angle.con(:,good_subs), avg_each.head_angle.incon(:,good_subs), plt_p.n_perm, plt_p.n_perm_clust_tests);

                if ~isempty(clusters)
                    points = [y_axis(clusters.start)'; y_axis(clusters.end)'];
                    drawRectangle(points, 'y', xlimit, plt_p);
                end

                set(gca, 'TickDir','out');
                ylabel(y_label);
                ylim(ylimit);
                yticks(y_ticks);
                xlabel('Heading Angle (deg)');
                xlim(xlimit);
                xticks(-5 : 10 : 25);
                title('Heading Angle');
                set(gca, 'FontSize',plt_p.font_size);
                set(gca, 'FontName',plt_p.font_name);
                set(gca, 'linewidth',plt_p.axes_line_thickness);

                if ~isempty(clusters)
                    outStats = printTsStats('Heading angle', clusters);
                end
            end
    end
end
