function fig_h = render_congruency_composite_shared(avg_struct, subs_avg, good_subs, ...
    tree_con_tbl, proc_dir, p, plt_p, is_standardized, fig_name, y_lbls)
% RENDER_CONRUENCY_COMPOSITE_SHARED Shared renderer for Fig 3 (Pre-registered) and
% Fig S6 (Standardized robustness):
%   - Row 1: (a) Average Trajectory (2/3 width, descriptive only, no cluster shade) + (b)-(d)
%   - Row 2: (e)-(i) 5 wider panels with behind-plot light-yellow backdrops on (h) MAD and (i) AUC
%   - Rows 3-4 (Fig 3 only): (j)-(m) Single-participant trajectories
%   - Large draft-matching fonts, thicker axes spines, no x-ticks on (b)-(i)

    reach_avg_each = avg_struct.reach_avg_each;
    keyboard_avg_each = avg_struct.keyboard_avg_each;

    font_name = 'Calibri';
    if isfield(plt_p, 'font_name') && ~isempty(plt_p.font_name)
        font_name = plt_p.font_name;
    end
    ax_lw = 2.6;
    if isfield(plt_p, 'axes_line_thickness') && ~isempty(plt_p.axes_line_thickness)
        ax_lw = plt_p.axes_line_thickness;
    end
    avg_single_w = 3.5;
    if isfield(plt_p, 'avg_plot_width') && ~isempty(plt_p.avg_plot_width)
        avg_single_w = plt_p.avg_plot_width;
    end
    tick_fs = 12.5;
    if isfield(plt_p, 'font_size') && ~isempty(plt_p.font_size)
        tick_fs = plt_p.font_size;
    end
    lbl_fs = 14.0;
    if isfield(plt_p, 'labels_font_size') && ~isempty(plt_p.labels_font_size)
        lbl_fs = plt_p.labels_font_size;
    end
    ttl_fs = 15.5;
    if isfield(plt_p, 'title_font_size') && ~isempty(plt_p.title_font_size)
        ttl_fs = plt_p.title_font_size;
    end
    let_fs = 15.5;
    if isfield(plt_p, 'panel_letter_size') && ~isempty(plt_p.panel_letter_size)
        let_fs = plt_p.panel_letter_size;
    end

    if ~is_standardized
        % Fig 3: 4-row portrait layout (generous vertical gaps so (a)/(j)/(k) xlabels never touch lower row titles)
        fig_h = figure('Name', fig_name, 'Color', 'w', 'Position', [30, 30, 1320, 1740], 'Visible', 'off');
        r1_bot = 0.788; r1_h = 0.172;
        r2_bot = 0.552; r2_h = 0.172;
        r3_bot = 0.296; r3_h = 0.174;
        r4_bot = 0.048; r4_h = 0.174;
        bg_pad = [0.052, 0.020, 0.012, 0.036];
    else
        % Fig S6: 2-row landscape layout
        fig_h = figure('Name', fig_name, 'Color', 'w', 'Position', [30, 40, 1320, 880], 'Visible', 'off');
        r1_bot = 0.575; r1_h = 0.350;
        r2_bot = 0.075; r2_h = 0.365;
        bg_pad = [0.052, 0.042, 0.012, 0.062];
    end

    % Row 1: (a) narrowed to ~2/3 of 0.49 (~0.320) + (b)-(d) on right
    pos_a        = [0.068, r1_bot, 0.320, r1_h];
    r1_col_lefts = [0.465, 0.655, 0.845];
    r1_panel_w   = 0.125;

    % Row 2: (e)-(i) 5 evenly spaced wider panels across full width
    col_lefts_5  = [0.068, 0.258, 0.448, 0.638, 0.828];
    r2_panel_w   = 0.128;

    % --- Panel (a): Average Trajectory (Descriptive Only — no cluster shade) ---
    ax_a = axes('Parent', fig_h, 'Position', pos_a, 'Color', 'w');
    hold(ax_a, 'on');
    left_axis = subs_avg.traj.con_left(:, 3) * 100;
    con_l = reach_avg_each.traj(1).con_left(:, good_subs, 1) * 100;
    con_r = reach_avg_each.traj(1).con_right(:, good_subs, 1) * 100;
    inc_l = reach_avg_each.traj(1).incon_left(:, good_subs, 1) * 100;
    inc_r = reach_avg_each.traj(1).incon_right(:, good_subs, 1) * 100;

    xlimit = [-12, 12];
    axes(ax_a); %#ok<LAXES>
    stdshade(con_l', plt_p.f_alpha*0.9, plt_p.con_col,   left_axis, 0, 0, 'ci', 0.05, plt_p.linewidth);
    stdshade(con_r', plt_p.f_alpha*0.9, plt_p.con_col,   left_axis, 0, 0, 'ci', 0.05, plt_p.linewidth);
    stdshade(inc_l', plt_p.f_alpha*0.9, plt_p.incon_col, left_axis, 0, 0, 'ci', 0.05, plt_p.linewidth);
    stdshade(inc_r', plt_p.f_alpha*0.9, plt_p.incon_col, left_axis, 0, 0, 'ci', 0.05, plt_p.linewidth);

    xlim(ax_a, xlimit);
    ylim(ax_a, [0, 100]);
    xticks(ax_a, -10:5:10);
    yticks(ax_a, 10:20:90);
    xlabel(ax_a, 'X (cm)', 'FontSize', lbl_fs, 'FontName', font_name);
    ylabel(ax_a, 'Path Traveled (%)', 'FontSize', lbl_fs, 'FontName', font_name);
    title(ax_a, 'Average Trajectory', 'FontSize', ttl_fs, 'FontWeight', 'bold', 'FontName', font_name);
    set(ax_a, 'TickDir', 'out', 'FontSize', tick_fs, 'FontName', font_name, 'LineWidth', ax_lw);
    box(ax_a, 'off');

    h_leg = [plot(ax_a, nan, nan, 'Color', plt_p.con_col, 'LineWidth', plt_p.linewidth), ...
             plot(ax_a, nan, nan, 'Color', plt_p.incon_col, 'LineWidth', plt_p.linewidth)];
    legend(ax_a, h_leg, {'Congruent', 'Incongruent'}, 'Location', 'southeast', 'Box', 'off', ...
        'FontSize', max(11.5, tick_fs - 0.5), 'FontName', font_name);
    text(ax_a, -0.09, 1.07, '(a)', 'Units', 'normalized', 'FontSize', let_fs, 'FontWeight', 'bold', 'FontName', font_name);

    % --- Panels (b)-(i): Discrete Variables ---
    kb_con  = keyboard_avg_each.rt(1).con(good_subs);
    kb_inc  = keyboard_avg_each.rt(1).incon(good_subs);
    if ~is_standardized && mean(kb_con, 'omitnan') < 10
        kb_con = kb_con * 1000; kb_inc = kb_inc * 1000;
    end

    ra_con  = reach_avg_each.ra(1).con(good_subs);
    ra_inc  = reach_avg_each.ra(1).incon(good_subs);

    on_con  = reach_avg_each.react(1).con(good_subs);
    on_inc  = reach_avg_each.react(1).incon(good_subs);

    mt_con  = reach_avg_each.mt(1).con(good_subs);
    mt_inc  = reach_avg_each.mt(1).incon(good_subs);

    td_con  = reach_avg_each.tot_dist(1).con(good_subs);
    td_inc  = reach_avg_each.tot_dist(1).incon(good_subs);
    if ~is_standardized && mean(abs(td_con), 'omitnan') < 2
        td_con = td_con * 100; td_inc = td_inc * 100;
    end

    com_con = reach_avg_each.com(1).con(good_subs);
    com_inc = reach_avg_each.com(1).incon(good_subs);

    mad_con = reach_avg_each.mad(1).con(good_subs);
    mad_inc = reach_avg_each.mad(1).incon(good_subs);
    if ~is_standardized && mean(abs(mad_con), 'omitnan') < 1
        mad_con = mad_con * 100; mad_inc = mad_inc * 100;
    end

    auc_con = reach_avg_each.auc(1).con(good_subs);
    auc_inc = reach_avg_each.auc(1).incon(good_subs);

    var_titles = {'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Reaching Duration', ...
                  'Distance Traveled', 'COM', 'MAD', 'AUC'};
    tree_nodes = {'Keyboard_RT', 'Reach_Area', 'Reaching_Onset', 'Reaching_Duration_MT', ...
                  'Total_Distance', 'Changes_of_Mind_COM', 'MAD', 'AUC'};
    con_cells  = {kb_con, ra_con, on_con, mt_con, td_con, com_con, mad_con, auc_con};
    inc_cells  = {kb_inc, ra_inc, on_inc, mt_inc, td_inc, com_inc, mad_inc, auc_inc};
    posthoc_flags = [false, false, false, false, false, false, true, true];
    panel_lets    = {'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'};

    % Positions: (b)-(d) in Row 1 alongside (a); (e)-(i) across Row 2
    panel_pos = [ ...
        r1_col_lefts(1), r1_bot, r1_panel_w, r1_h; ... % (b) Keyboard RT
        r1_col_lefts(2), r1_bot, r1_panel_w, r1_h; ... % (c) Reach Area
        r1_col_lefts(3), r1_bot, r1_panel_w, r1_h; ... % (d) Reaching Onset
        col_lefts_5(1),  r2_bot, r2_panel_w, r2_h; ... % (e) Reaching Duration
        col_lefts_5(2),  r2_bot, r2_panel_w, r2_h; ... % (f) Distance Traveled
        col_lefts_5(3),  r2_bot, r2_panel_w, r2_h; ... % (g) COM
        col_lefts_5(4),  r2_bot, r2_panel_w, r2_h; ... % (h) MAD [Post-Hoc]
        col_lefts_5(5),  r2_bot, r2_panel_w, r2_h];    % (i) AUC [Post-Hoc]

    ax_vec = gobjects(1, 8);
    for k = 1:8
        ax_k = axes('Parent', fig_h, 'Position', panel_pos(k, :));
        ax_vec(k) = ax_k;

        t_row = strcmp(string(tree_con_tbl.Node_Name), tree_nodes{k});
        if any(t_row)
            q_val = tree_con_tbl.Within_Family_FDR_q(find(t_row, 1));
        else
            [~, q_val] = ttest(con_cells{k}, inc_cells{k});
        end
        diff_vec = con_cells{k}(:) - inc_cells{k}(:);
        dz_val = mean(diff_vec, 'omitnan') / std(diff_vec, 0, 'omitnan');

        k_bg_pad = bg_pad;
        if k == 8
            k_bg_pad(1) = bg_pad(1) + 0.004; % Slightly wider left pad for AUC y-label
        end
        plot_paired_beeswarm_panel(ax_k, con_cells{k}, inc_cells{k}, ...
            var_titles{k}, y_lbls{k}, q_val, dz_val, false, plt_p, panel_lets{k}, k_bg_pad, false);
    end
    if any(posthoc_flags)
        add_posthoc_backdrop(ax_vec(posthoc_flags), bg_pad);
    end

    % --- Panels (j)-(m): Single Participant Trajectories (Fig 3 only, Rows 3 & 4) ---
    if ~is_standardized
        subs_ex   = [53, 59];
        lets_top  = {'j', 'k'};
        lets_bot  = {'l', 'm'};
        sub_lefts = [0.095, 0.565];
        sub_w     = 0.385;

        for s_i = 1:2
            iSub = subs_ex(s_i);
            r_single = load(fullfile(proc_dir, sprintf('sub%d%s_sorted_trials_%s.mat', iSub, p.DAY, 'target_x_to'))).r_trial;
            r_avg    = load(fullfile(proc_dir, sprintf('sub%d%s_avg_%s.mat', iSub, p.DAY, 'target_x_to'))).r_avg;

            % Row 3: Congruent trials (j, k) — remove (Congruent) suffix from title
            ax_top = axes('Parent', fig_h, 'Position', [sub_lefts(s_i), r3_bot, sub_w, r3_h], 'Color', 'w');
            hold(ax_top, 'on');
            plot(ax_top, r_single.trajs.con_left(:,:,1)*100,  r_single.trajs.con_left(:,:,3)*100,  'Color', [plt_p.con_col, 0.20], 'LineWidth', 0.9);
            plot(ax_top, r_single.trajs.con_right(:,:,1)*100, r_single.trajs.con_right(:,:,3)*100, 'Color', [plt_p.con_col, 0.20], 'LineWidth', 0.9);
            plot(ax_top, r_avg.traj.con_left(:,1)*100,  r_avg.traj.con_left(:,3)*100,  'Color', plt_p.con_avg_col, 'LineWidth', avg_single_w);
            plot(ax_top, r_avg.traj.con_right(:,1)*100, r_avg.traj.con_right(:,3)*100, 'Color', plt_p.con_avg_col, 'LineWidth', avg_single_w);
            xlim(ax_top, [-12, 12]); ylim(ax_top, [0, 100]);
            xticks(ax_top, -10:5:10); yticks(ax_top, 10:20:90);
            xlabel(ax_top, 'X (cm)', 'FontSize', lbl_fs, 'FontName', font_name);
            if s_i == 1
                ylabel(ax_top, 'Path Traveled (%)', 'FontSize', lbl_fs, 'FontName', font_name);
            end
            title(ax_top, sprintf('Participant %d', iSub), 'FontSize', ttl_fs, 'FontWeight', 'bold', 'FontName', font_name);
            set(ax_top, 'TickDir', 'out', 'FontSize', tick_fs, 'FontName', font_name, 'LineWidth', ax_lw);
            box(ax_top, 'off');
            text(ax_top, -0.08, 1.07, sprintf('(%s)', lets_top{s_i}), 'Units', 'normalized', 'FontSize', let_fs, 'FontWeight', 'bold', 'FontName', font_name);

            % Row 4: Incongruent trials (l, m) — remove (Incongruent) suffix from title
            ax_bot = axes('Parent', fig_h, 'Position', [sub_lefts(s_i), r4_bot, sub_w, r4_h], 'Color', 'w');
            hold(ax_bot, 'on');
            plot(ax_bot, r_single.trajs.incon_left(:,:,1)*100,  r_single.trajs.incon_left(:,:,3)*100,  'Color', [plt_p.incon_col, 0.20], 'LineWidth', 0.9);
            plot(ax_bot, r_single.trajs.incon_right(:,:,1)*100, r_single.trajs.incon_right(:,:,3)*100, 'Color', [plt_p.incon_col, 0.20], 'LineWidth', 0.9);
            plot(ax_bot, r_avg.traj.incon_left(:,1)*100,  r_avg.traj.incon_left(:,3)*100,  'Color', plt_p.incon_avg_col, 'LineWidth', avg_single_w);
            plot(ax_bot, r_avg.traj.incon_right(:,1)*100, r_avg.traj.incon_right(:,3)*100, 'Color', plt_p.incon_avg_col, 'LineWidth', avg_single_w);
            xlim(ax_bot, [-12, 12]); ylim(ax_bot, [0, 100]);
            xticks(ax_bot, -10:5:10); yticks(ax_bot, 10:20:90);
            xlabel(ax_bot, 'X (cm)', 'FontSize', lbl_fs, 'FontName', font_name);
            if s_i == 1
                ylabel(ax_bot, 'Path Traveled (%)', 'FontSize', lbl_fs, 'FontName', font_name);
            end
            title(ax_bot, sprintf('Participant %d', iSub), 'FontSize', ttl_fs, 'FontWeight', 'bold', 'FontName', font_name);
            set(ax_bot, 'TickDir', 'out', 'FontSize', tick_fs, 'FontName', font_name, 'LineWidth', ax_lw);
            box(ax_bot, 'off');
            text(ax_bot, -0.08, 1.07, sprintf('(%s)', lets_bot{s_i}), 'Units', 'normalized', 'FontSize', let_fs, 'FontWeight', 'bold', 'FontName', font_name);
        end
    end
end
