% Plots the average (over good subjects) STD in the X axis at each point along the trajectory,
% with progression (Time in ms or Path Traveled in %) on the vertical Y-axis and X-axis S.D. (cm) on the X-axis.
function [outStats] = plotMultiXStd(traj_names, plt_p, p)

    outStats = [];
    plt_p.errbar_type = 'ci';
    for iTraj = 1:length(traj_names)
        good_subs = load([p.PROC_DATA_FOLDER '/good_subs_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  good_subs = good_subs.good_subs;
        avg_each = load([p.PROC_DATA_FOLDER '/avg_each_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  avg_each = avg_each.reach_avg_each;
        subs_avg = load([p.PROC_DATA_FOLDER '/subs_avg_' p.DAY '_' traj_names{iTraj}{1} '_subs_' p.SUBS_STRING '.mat']);  subs_avg = subs_avg.reach_subs_avg;

        % Convert meters to cm for plotting
        x_std_con_cm   = avg_each.x_std.con(:, good_subs) * 100;
        x_std_incon_cm = avg_each.x_std.incon(:, good_subs) * 100;

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

        xlimit = [0 10.5];

        hold on;
        % Plot with vertical progression axis (orientation = 0 -> y_axis on Y, values on X)
        stdshade(x_std_con_cm', plt_p.f_alpha*0.9, plt_p.con_col, y_axis, 0, 0, plt_p.errbar_type, plt_p.alpha_size, plt_p.linewidth);
        stdshade(x_std_incon_cm', plt_p.f_alpha*0.9, plt_p.incon_col, y_axis, 0, 0, plt_p.errbar_type, plt_p.alpha_size, plt_p.linewidth);

        % Deterministic permutation testing
        rng(42, 'twister');
        clusters = permCluster(avg_each.x_std.con(:,good_subs), avg_each.x_std.incon(:,good_subs), plt_p.n_perm, plt_p.n_perm_clust_tests);

        % Plot clusters
        if ~isempty(clusters)
            points = [y_axis(clusters.start)'; y_axis(clusters.end)'];
            if ~isempty(points)
                drawRectangle(points, 'y', xlimit, plt_p);
            end
        end

        set(gca, 'TickDir','out');
        xlabel('X-axis S.D. (cm)');
        xlim(xlimit);
        xticks(0 : 2 : 10);
        ylabel(y_label);
        ylim(ylimit);
        yticks(y_ticks);
        title('Movement Variation');
        set(gca, 'FontSize',plt_p.font_size);
        set(gca, 'FontName',plt_p.font_name);
        set(gca, 'linewidth',plt_p.axes_line_thickness);

        if ~isempty(clusters)
            outStats = printTsStats('Movement variation', clusters);
        end
    end
end
