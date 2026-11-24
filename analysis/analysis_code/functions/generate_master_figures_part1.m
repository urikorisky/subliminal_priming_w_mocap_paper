function generate_master_figures_part1(out_fig_dir, stats_or_fst, proc_root)
% GENERATE_MASTER_FIGURES_PART1 Generates Figures 2, 3, 4, 5, S1, and S2
% directly in .fig, .png (300 DPI), .pdf, and .svg formats from in-memory structs.

if ~exist(out_fig_dir, 'dir'), mkdir(out_fig_dir); end

% Load shared parameters and resolve statistics struct
exp_p = load(fullfile(proc_root, '..', '..', 'experiment', 'RUN_ME', 'code', 'p.mat'));
p = exp_p.p;
p.SUBS = [47, 49:85, 87:90];
p.ORIG_SUBS = p.SUBS;
p.DAY = 'day2';
p.NORMALIZE_WITHIN_SUB = 0;
p.NORM_TRAJ = 1;
p.MIN_SAMP_LEN = 0.1;
p.MIN_TRIM_FRAMES = p.MIN_SAMP_LEN * p.REF_RATE_HZ;
p = defineParams_within_round(p, p.SUBS(1));

if isstruct(stats_or_fst)
    fst = stats_or_fst;
else
    s_all = load(fullfile(stats_or_fst, 'All_Statistics.mat'));
    fst = s_all.full_stats_tables;
end
TreeBH_Results = fst.TreeBH_Results;

% Common plotting parameters
plt_p = struct();
plt_p.con_col   = [0.18, 0.45, 0.78]; % Crisp royal blue
plt_p.incon_col = [0.85, 0.24, 0.20]; % Crisp coral red
plt_p.con_avg_col = 'b';
plt_p.incon_avg_col = 'r';
plt_p.f_alpha = 0.25;
plt_p.alpha_size = 0.05;
plt_p.linewidth = 2.0;
plt_p.avg_plot_width = 2.4;
plt_p.axes_line_thickness = 1.2;
plt_p.font_size = 10;
plt_p.font_name = 'Arial';
plt_p.errbar_type = 'ci';
plt_p.space = 1.2;
plt_p.n_perm = 10000;
plt_p.n_perm_clust_tests = 1000;
plt_p.left_right_ticks = -15:5:15;
plt_p.percent_path_ticks = 0:20:100;

f1_dir = fullfile(proc_root, 'nonStandardized_TrajNorm');
f2_dir = fullfile(proc_root, 'standardized_TrajNorm');
f3_dir = fullfile(proc_root, 'nonStandardized_nonTrajNorm');
traj_name = 'target_x_to';

good_subs = load(fullfile(f1_dir, ['good_subs_day2_' traj_name '_subs_' p.SUBS_STRING '.mat'])).good_subs;
f1_avg = load(fullfile(f1_dir, ['avg_each_day2_' traj_name '_subs_' p.SUBS_STRING '.mat']));
f1_subs = load(fullfile(f1_dir, ['subs_avg_day2_' traj_name '_subs_' p.SUBS_STRING '.mat'])).reach_subs_avg;

% =========================================================================
% 1. Fig_2_Objective_Awareness_Incongruent
% =========================================================================
fprintf('Generating Fig_2_Objective_Awareness_Incongruent...\n');
plt_draft = get_draft_plt_params();
fig2 = figure('Name', 'Fig_2_Objective_Awareness_Incongruent', 'Color', 'w', ...
    'Position', [100, 100, 740, 560], 'Visible', 'off');
ax2 = axes('Parent', fig2, 'Position', [0.16, 0.14, 0.78, 0.76], 'Color', 'w');
hold(ax2, 'on');

reach_incon_acc = f1_avg.reach_avg_each.fc_prime.incon(good_subs) * 100;
kb_incon_acc    = f1_avg.keyboard_avg_each.fc_prime.incon(good_subs) * 100;

all_acc = [reach_incon_acc(:); kb_incon_acc(:)];
min_acc = min(all_acc, [], 'omitnan');
max_acc = max(all_acc, [], 'omitnan');
y_lo = floor((min_acc - 2.5) / 2) * 2;
y_hi = ceil((max_acc + 2.5) / 2) * 2;

xlim(ax2, [0.40, 2.60]);
ylim(ax2, [y_lo, y_hi]);
xticks(ax2, [1, 2]);
xticklabels(ax2, {'Reaching', 'Key Press'});
yticks(ax2, 35:5:65);

% Faint grey chance line at 50% matching draft
yline(ax2, 50, '--', 'Color', [0.75, 0.75, 0.75], 'LineWidth', 2.4, 'HandleVisibility', 'off');

% Both modalities colored in draft Incongruent red (larger markers matching draft)
[~, h_sc_r] = place_non_overlapping_beeswarm(ax2, reach_incon_acc, 1.0, 0.36, plt_draft.incon_col, 9.0, 0.95);
[~, h_sc_k] = place_non_overlapping_beeswarm(ax2, kb_incon_acc,    2.0, 0.36, plt_draft.incon_col, 9.0, 0.95);
if ~isempty(h_sc_r) && isgraphics(h_sc_r), set(h_sc_r, 'MarkerEdgeColor', 'none'); end
if ~isempty(h_sc_k) && isgraphics(h_sc_k), set(h_sc_k, 'MarkerEdgeColor', 'none'); end

% Grand average (draft red + translucent grey bar overlay) + black 95% CI error bars (no in-plot stats text)
n_sub = numel(good_subs);
t_crit = tinv(0.975, n_sub - 1);
m_r = mean(reach_incon_acc, 'omitnan');
ci_r = t_crit * std(reach_incon_acc, 0, 'omitnan') / sqrt(n_sub);
m_k = mean(kb_incon_acc, 'omitnan');
ci_k = t_crit * std(kb_incon_acc, 0, 'omitnan') / sqrt(n_sub);

plot(ax2, [1 - 0.25, 1 + 0.25], [m_r, m_r], '-', 'Color', plt_draft.incon_col, 'LineWidth', 6.0);
plot(ax2, [1 - 0.25, 1 + 0.25], [m_r, m_r], '-', 'Color', [0.70, 0.70, 0.70, 0.50], 'LineWidth', 6.0);
errorbar(ax2, 1, m_r, ci_r, 'k', 'LineStyle', 'none', 'LineWidth', 2.6, 'CapSize', 18);

plot(ax2, [2 - 0.25, 2 + 0.25], [m_k, m_k], '-', 'Color', plt_draft.incon_col, 'LineWidth', 6.0);
plot(ax2, [2 - 0.25, 2 + 0.25], [m_k, m_k], '-', 'Color', [0.70, 0.70, 0.70, 0.50], 'LineWidth', 6.0);
errorbar(ax2, 2, m_k, ci_k, 'k', 'LineStyle', 'none', 'LineWidth', 2.6, 'CapSize', 18);

ylabel(ax2, 'Performance (%)', 'FontSize', 17.0, 'FontWeight', 'bold', 'FontName', plt_draft.font_name);
title(ax2, 'Incongruent Trials', 'FontSize', 19.0, 'FontWeight', 'bold', 'FontName', plt_draft.font_name);
set(ax2, 'TickDir', 'in', 'FontSize', 14.5, 'FontName', plt_draft.font_name, 'LineWidth', 2.8);
box(ax2, 'off');

save_master_fig(fig2, fullfile(out_fig_dir, 'Fig_2_Objective_Awareness_Incongruent'));
close(fig2);

% =========================================================================
% 2. Fig_3_Main_Congruency_PreRegistered
% =========================================================================
fprintf('Generating Fig_3_Main_Congruency_PreRegistered...\n');
fig3 = render_congruency_composite_figure(f1_avg, f1_subs, good_subs, ...
    TreeBH_Results.Tree1_Congruency_Table, fst.TrajNorm_noStandardization, ...
    f1_dir, p, plt_p, false, 'Fig_3_Main_Congruency_PreRegistered');
save_master_fig(fig3, fullfile(out_fig_dir, 'Fig_3_Main_Congruency_PreRegistered'));
close(fig3);

% =========================================================================
% 3. Fig_4_Full_Trajectory_Dynamics
% =========================================================================
fprintf('Generating Fig_4_Full_Trajectory_Dynamics...\n');
fig4 = render_fig4_full_trajectory_dynamics(f1_dir, f3_dir, good_subs, p, plt_p, TreeBH_Results);
save_master_fig(fig4, fullfile(out_fig_dir, 'Fig_4_Full_Trajectory_Dynamics'));
close(fig4);

% =========================================================================
% 4. Fig_5_Effect_Sizes_and_Comparisons
% =========================================================================
fprintf('Generating Fig_5_Effect_Sizes_and_Comparisons...\n');
fig5 = render_fig5_effect_sizes(fst.Effect_Sizes, fst.Effect_Comparisons_Within, TreeBH_Results);
set(findall(fig5, '-property', 'FontName'), 'FontName', 'Calibri');
save_master_fig(fig5, fullfile(out_fig_dir, 'Fig_5_Effect_Sizes_and_Comparisons'));
close(fig5);

% =========================================================================
% 5. Fig_S1a..f (Split full-page-width TreeBH figures + FDR table)
% =========================================================================
fprintf('Generating Fig_S1a..f (split Tree-BH schemes & FDR table)...\n');
render_figS1_split_schemes(TreeBH_Results, out_fig_dir);

% =========================================================================
% 6. Fig_S2_Assumptions_QQ_Plots
% =========================================================================
fprintf('Generating Fig_S2_Assumptions_QQ_Plots...\n');
figS2 = render_figS2_qq_plots(fst, f1_avg, f2_dir, good_subs, p);
save_master_fig(figS2, fullfile(out_fig_dir, 'Fig_S2_Assumptions_QQ_Plots'));
close(figS2);

end

% =========================================================================
% HELPER: Save .fig, .png (300 DPI), .pdf (vector), and .svg (vector)
% =========================================================================
function save_master_fig(fig_h, base_path)
    try
        savefig(fig_h, [base_path, '.fig']);
    catch ME
        warning('Could not save .fig for %s: %s', base_path, ME.message);
    end
    try
        exportgraphics(fig_h, [base_path, '.png'], 'Resolution', 300);
    catch ME
        warning('exportgraphics PNG failed for %s: %s', base_path, ME.message);
        print(fig_h, [base_path, '.png'], '-dpng', '-r300');
    end
    try
        exportgraphics(fig_h, [base_path, '.pdf'], 'ContentType', 'vector');
    catch
        try
            exportgraphics(fig_h, [base_path, '.pdf'], 'Resolution', 300);
        catch ME2
            warning('exportgraphics PDF failed for %s: %s', base_path, ME2.message);
        end
    end
    try
        exportgraphics(fig_h, [base_path, '.svg'], 'ContentType', 'vector');
    catch
        try
            print(fig_h, [base_path, '.svg'], '-dsvg', '-vector');
        catch
            try
                saveas(fig_h, [base_path, '.svg']);
            catch ME3
                warning('SVG export failed for %s: %s', base_path, ME3.message);
            end
        end
    end
end

% =========================================================================
% HELPER: Render Figure 3 (Flavor 1, with panels j-m) or Figure S6 (Flavor 2)
% =========================================================================
function fig_h = render_congruency_composite_figure(avg_struct, subs_avg, good_subs, ...
    tree_con_tbl, flavor_stats_tbl, proc_dir, p, plt_p, is_standardized, fig_name) %#ok<INUSL>

    plt_draft = get_draft_plt_params();
    if ~is_standardized
        y_lbls = {'Time (ms)', 'Area (10^{2} cm^{2})', 'Time (ms)', 'Time (ms)', ...
                  'Distance (cm)', 'COM per Trial', 'MAD (cm)', 'AUC (10^{2} cm^{2})'};
    else
        y_lbls = {'Time (z-score)', 'Area (z-score)', 'Time (z-score)', 'Time (z-score)', ...
                  'Distance (z-score)', 'COM (z-score)', 'MAD (z-score)', 'AUC (z-score)'};
    end
    fig_h = render_congruency_composite_shared(avg_struct, subs_avg, good_subs, ...
        tree_con_tbl, proc_dir, p, plt_draft, is_standardized, fig_name, y_lbls);
end

% =========================================================================
% HELPER: Render Figure 4 (Full Trajectory Dynamics: Flavor 1 Top, Flavor 3 Bottom)
% =========================================================================
function fig4 = render_fig4_full_trajectory_dynamics(f1_dir, f3_dir, good_subs, p, plt_p, TreeBH_Results) %#ok<INUSL>
    plt_draft = get_draft_plt_params();
    fig4 = figure('Name', 'Fig_4_Full_Trajectory_Dynamics', 'Color', 'w', ...
        'Position', [30, 40, 1320, 880], 'Visible', 'off');

    f1_avg  = load(fullfile(f1_dir, ['avg_each_day2_target_x_to_subs_' p.SUBS_STRING '.mat'])).reach_avg_each;
    f1_subs = load(fullfile(f1_dir, ['subs_avg_day2_target_x_to_subs_' p.SUBS_STRING '.mat'])).reach_subs_avg;
    f3_avg  = load(fullfile(f3_dir, ['avg_each_day2_target_x_to_subs_' p.SUBS_STRING '.mat'])).reach_avg_each;
    f3_subs = load(fullfile(f3_dir, ['subs_avg_day2_target_x_to_subs_' p.SUBS_STRING '.mat'])).reach_subs_avg;

    y_path = f1_subs.traj.con_left(:, 3) * 100; % 0 to 100%
    y_time = (1:size(f3_subs.traj.con_left, 1)) * p.SAMPLE_RATE_SEC * 1000; % 10 to 340 ms

    col_lefts = [0.120, 0.352, 0.584, 0.810];
    col_w = 0.150;
    top_bot = 0.592;
    bot_bot = 0.098;
    row_h = 0.320;
    bg_pad_r1 = [0.062, 0.065, 0.015, 0.056];
    bg_pad_r2 = [0.062, 0.066, 0.015, 0.054];

    % Full-figure invisible overlay axes for cleanly rotated (+90 deg) row titles matching Fig. 5 colors
    ax_lbl = axes('Parent', fig4, 'Position', [0, 0, 1, 1], 'Visible', 'off', 'HitTest', 'off');
    xlim(ax_lbl, [0, 1]); ylim(ax_lbl, [0, 1]);
    text(ax_lbl, 0.022, top_bot + row_h / 2, 'Pre-Registered Analysis', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Rotation', 90, ...
        'FontSize', plt_draft.title_font_size, 'FontWeight', 'bold', 'FontName', plt_draft.font_name, ...
        'Color', [0.15, 0.52, 0.15]);
    text(ax_lbl, 0.022, bot_bot + row_h / 2, 'Temporal Full-Trajectory Analysis', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Rotation', 90, ...
        'FontSize', plt_draft.title_font_size, 'FontWeight', 'bold', 'FontName', plt_draft.font_name, ...
        'Color', plt_draft.temporal_col);

    % --- TOP ROW: Pre-Registered Analysis (Path Traveled % vertical Y-axis) ---
    % (a) Deviation From Center (contains Condition Legend matching draft)
    ax_a = axes('Parent', fig4, 'Position', [col_lefts(1), top_bot, col_w, row_h]);
    plot_traj_panel_vert(ax_a, y_path, f1_avg, good_subs, 'traj', [0, 100], 0:20:100, ...
        'Path Traveled (%)', 'X (cm)', [-15, 15], -10:5:10, 'Deviation From Center', false, plt_draft, 'a', bg_pad_r1);
    h_leg = [plot(ax_a, nan, nan, '-', 'Color', plt_draft.con_col, 'LineWidth', 3.0), ...
             plot(ax_a, nan, nan, '-', 'Color', plt_draft.incon_col, 'LineWidth', 3.0)];
    legend(ax_a, h_leg, {'Congruent', 'Incongruent'}, 'Location', 'southeast', 'Box', 'off', ...
        'FontSize', plt_draft.font_size, 'FontName', plt_draft.font_name);

    % (b) Horizontal Movement Variation
    ax_b = axes('Parent', fig4, 'Position', [col_lefts(2), top_bot, col_w, row_h]);
    plot_traj_panel_vert(ax_b, y_path, f1_avg, good_subs, 'x_std', [0, 100], 0:20:100, ...
        'Path Traveled (%)', 'X-axis S.D. (cm)', [0, 10.5], 0:2:10, 'Horizontal Movement Variation', false, plt_draft, 'b', bg_pad_r1);

    % (c) Implied Endpoint (Post-Hoc: white plot, light-yellow backdrop behind)
    ax_c = axes('Parent', fig4, 'Position', [col_lefts(3), top_bot, col_w, row_h]);
    plot_traj_panel_vert(ax_c, y_path, f1_avg, good_subs, 'iep', [0, 100], 0:20:100, ...
        'Path Traveled (%)', 'Implied Endpoint (cm)', [-18, 18], -10:5:10, 'Implied Endpoint', true, plt_draft, 'c', bg_pad_r1);

    % --- BOTTOM ROW: Temporal Full-Trajectory Analysis (Post-Hoc: connected light-yellow backdrop behind d-g) ---
    % (d) Deviation From Center
    ax_d = axes('Parent', fig4, 'Position', [col_lefts(1), bot_bot, col_w, row_h]);
    plot_traj_panel_vert(ax_d, y_time, f3_avg, good_subs, 'traj', [0, 340], 0:50:300, ...
        'Time (ms)', 'X (cm)', [-15, 15], -10:5:10, 'Deviation From Center', false, plt_draft, 'd', bg_pad_r2);

    % (e) Horizontal Movement Variation
    ax_e = axes('Parent', fig4, 'Position', [col_lefts(2), bot_bot, col_w, row_h]);
    plot_traj_panel_vert(ax_e, y_time, f3_avg, good_subs, 'x_std', [0, 340], 0:50:300, ...
        'Time (ms)', 'X-axis S.D. (cm)', [0, 10.5], 0:2:10, 'Horizontal Movement Variation', false, plt_draft, 'e', bg_pad_r2);

    % (f) Implied Endpoint
    ax_f = axes('Parent', fig4, 'Position', [col_lefts(3), bot_bot, col_w, row_h]);
    plot_traj_panel_vert(ax_f, y_time, f3_avg, good_subs, 'iep', [0, 340], 0:50:300, ...
        'Time (ms)', 'Implied Endpoint (cm)', [-18, 18], -10:5:10, 'Implied Endpoint', false, plt_draft, 'f', bg_pad_r2);

    % (g) Heading Angle
    ax_g = axes('Parent', fig4, 'Position', [col_lefts(4), bot_bot, col_w, row_h]);
    plot_traj_panel_vert(ax_g, y_time, f3_avg, good_subs, 'head_angle', [0, 340], 0:50:300, ...
        'Time (ms)', 'Angle (degrees)', [-10, 30], -10:10:30, 'Heading Angle', false, plt_draft, 'g', bg_pad_r2);

    add_posthoc_backdrop([ax_d, ax_e, ax_f, ax_g], bg_pad_r2);
end

function plot_traj_panel_vert(ax, y_prog, avg_each, good_subs, feat_name, y_lim, y_ticks, y_lbl, x_lbl, x_lim, x_ticks, title_str, is_posthoc, plt_p, panel_let, bg_pad)
    hold(ax, 'on');
    set(ax, 'Color', 'w');
    box(ax, 'off');

    is_f1 = (y_lim(2) == 100);
    clusters = [];
    switch feat_name
        case 'traj'
            con_l = avg_each.traj(1).con_left(:, good_subs, 1) * 100;
            con_r = avg_each.traj(1).con_right(:, good_subs, 1) * 100;
            inc_l = avg_each.traj(1).incon_left(:, good_subs, 1) * 100;
            inc_r = avg_each.traj(1).incon_right(:, good_subs, 1) * 100;
            if is_f1
                clusters = struct('start', 34, 'end', 189);
            else
                clusters = struct('start', 19, 'end', 34);
            end
        case 'iep'
            con_l = avg_each.iep(1).con_left(:, good_subs) * 100;
            con_r = avg_each.iep(1).con_right(:, good_subs) * 100;
            inc_l = avg_each.iep(1).incon_left(:, good_subs) * 100;
            inc_r = avg_each.iep(1).incon_right(:, good_subs) * 100;
            if is_f1
                clusters = struct('start', 20, 'end', 158);
            else
                clusters = struct('start', 15, 'end', 34);
            end
        case 'x_std'
            con_m = avg_each.x_std(1).con(:, good_subs) * 100;
            inc_m = avg_each.x_std(1).incon(:, good_subs) * 100;
            if is_f1
                clusters = struct('start', 94, 'end', 195);
            end
        case 'head_angle'
            con_m = avg_each.head_angle(1).con(:, good_subs);
            inc_m = avg_each.head_angle(1).incon(:, good_subs);
            if ~is_f1
                rng(42, 'twister');
                clusters = permCluster(con_m, inc_m, 10000, 1);
            end
    end

    % Gray cluster shading matching draft
    if ~isempty(clusters)
        pts = [y_prog(clusters.start)'; y_prog(clusters.end)'];
        for c_i = 1:size(pts, 2)
            patch(ax, [x_lim(1), x_lim(2), x_lim(2), x_lim(1)], ...
                [pts(1, c_i), pts(1, c_i), pts(2, c_i), pts(2, c_i)], ...
                [0, 0, 0], 'FaceAlpha', 0.11, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        end
    end

    axes(ax); %#ok<LAXES>
    if ismember(feat_name, {'traj', 'iep'})
        stdshade(con_l', plt_p.f_alpha*0.9, plt_p.con_col,   y_prog, 0, 0, 'ci', 0.05, plt_p.linewidth);
        stdshade(con_r', plt_p.f_alpha*0.9, plt_p.con_col,   y_prog, 0, 0, 'ci', 0.05, plt_p.linewidth);
        stdshade(inc_l', plt_p.f_alpha*0.9, plt_p.incon_col, y_prog, 0, 0, 'ci', 0.05, plt_p.linewidth);
        stdshade(inc_r', plt_p.f_alpha*0.9, plt_p.incon_col, y_prog, 0, 0, 'ci', 0.05, plt_p.linewidth);
    else
        stdshade(con_m', plt_p.f_alpha*0.9, plt_p.con_col,   y_prog, 0, 0, 'ci', 0.05, plt_p.linewidth);
        stdshade(inc_m', plt_p.f_alpha*0.9, plt_p.incon_col, y_prog, 0, 0, 'ci', 0.05, plt_p.linewidth);
    end

    xlim(ax, x_lim); ylim(ax, y_lim);
    xticks(ax, x_ticks); yticks(ax, y_ticks);
    xlabel(ax, x_lbl, 'FontSize', plt_p.labels_font_size, 'FontName', plt_p.font_name);
    ylabel(ax, y_lbl, 'FontSize', plt_p.labels_font_size, 'FontName', plt_p.font_name);
    title(ax, title_str, 'FontSize', plt_p.title_font_size, 'FontWeight', 'bold', 'FontName', plt_p.font_name);
    set(ax, 'TickDir', 'out', 'FontSize', plt_p.font_size, 'FontName', plt_p.font_name, ...
        'LineWidth', plt_p.axes_line_thickness, 'Layer', 'top');
    text(ax, -0.34, 1.075, sprintf('(%s)', panel_let), 'Units', 'normalized', ...
        'FontSize', plt_p.panel_letter_size, 'FontWeight', 'bold', 'FontName', plt_p.font_name);

    if is_posthoc
        add_posthoc_backdrop(ax, bg_pad);
    end
end

% =========================================================================
% HELPER: Render Figure 5 (Effect Sizes & Comparisons vs Keyboard RT)
% =========================================================================
function fig5 = render_fig5_effect_sizes(effects_tbl, within_tbl, TreeBH_Results)
    plt_draft = get_draft_plt_params();
    fig5 = figure('Name', 'Fig_5_Effect_Sizes_and_Comparisons', 'Color', 'w', ...
        'Position', [30, 40, 1320, 840], 'Visible', 'off');

    % Row order (15 rows total, top to bottom: Y = 15 down to 1):
    % Top 11 rows: Pre-Registered & Robustness Analyses (in Tree-BH order)
    % Bottom 4 rows: Temporal Full-Trajectory Analysis
    row_labels = { ...
        'Keyboard RT', ...
        'Reach Area', ...
        'Reaching Onset', ...
        'Reaching Duration', ...
        'Distance Traveled', ...
        'COM', ...
        'MAD (Post-Hoc)', ...
        'AUC (Post-Hoc)', ...
        'Deviance From Center', ...
        'Horizontal Movement Variation', ...
        'Implied Endpoint (Post-Hoc)', ...
        'Deviance From Center', ...
        'Horizontal Movement Variation', ...
        'Implied Endpoint (Post-Hoc)', ...
        'Heading Angle'};

    eff_keys_11 = { ...
        'kb_rt', 'ra', 'react', 'mt', ...
        'tot_dist', 'com', 'mad', ...
        'auc', 'traj', 'x_std', ...
        'iep'};
    eff_keys_f3 = { ...
        'traj', 'x_std', ...
        'iep', 'head_angle'};

    n_rows = 15;
    y_positions = n_rows:-1:1;

    % Analysis color palette matching Fig. 4
    col_f1 = [0.40, 0.80, 0.38];
    edg_f1 = [0.15, 0.52, 0.15];
    col_f2 = [0.06, 0.38, 0.16];
    edg_f2 = [0.02, 0.24, 0.08];
    col_f3 = plt_draft.temporal_col;
    edg_f3 = [0.28, 0.12, 0.46];

    ax_left  = axes('Parent', fig5, 'Position', [0.290, 0.140, 0.325, 0.780]);
    ax_right = axes('Parent', fig5, 'Position', [0.650, 0.140, 0.325, 0.780]);
    hold(ax_left, 'on');
    hold(ax_right, 'on');

    y_lim = [0.3, 18.0];
    xlim_left  = [-0.25, 2.40];
    xlim_right = [-2.08, 1.35];

    % Background bands & alternating stripes (pushed strictly behind axis spines)
    bg_left = gobjects(0);
    bg_right = gobjects(0);
    bg_left(end+1) = patch(ax_left, [xlim_left(1), xlim_left(2), xlim_left(2), xlim_left(1)], ...
        [0.35, 0.35, 4.50, 4.50], plt_draft.temporal_bg, 'FaceAlpha', 0.72, ...
        'EdgeColor', [0.76, 0.68, 0.88], 'LineWidth', 1.2, 'HandleVisibility', 'off');
    yline(ax_right, 4.50, ':', 'Color', [0.60, 0.60, 0.60], 'LineWidth', 1.4, 'HandleVisibility', 'off');

    for k = 1:11
        yk = y_positions(k);
        if mod(k, 2) == 0
            bg_left(end+1) = patch(ax_left, [xlim_left(1), xlim_left(2), xlim_left(2), xlim_left(1)], ...
                [yk-0.48, yk-0.48, yk+0.48, yk+0.48], [0.95, 0.96, 0.95], ...
                'EdgeColor', 'none', 'HandleVisibility', 'off'); %#ok<AGROW>
            bg_right(end+1) = patch(ax_right, [xlim_right(1), xlim_right(2), xlim_right(2), xlim_right(1)], ...
                [yk-0.48, yk-0.48, yk+0.48, yk+0.48], [0.95, 0.96, 0.95], ...
                'EdgeColor', 'none', 'HandleVisibility', 'off'); %#ok<AGROW>
        end
    end
    uistack(bg_left, 'bottom');
    uistack(bg_right, 'bottom');

    xline(ax_left,  0, 'k--', 'LineWidth', 1.6, 'HandleVisibility', 'off');
    xline(ax_right, 0, 'k--', 'LineWidth', 1.6, 'HandleVisibility', 'off');

    dy = 0.16;

    % --- Plot Top 11 Rows (Pre-Registered & Robustness) ---
    for k = 1:11
        yk = y_positions(k);
        key_str = eff_keys_11{k};

        [est1, ci1_l, ci1_u] = lookup_effect_row(effects_tbl, 'TrajNorm_noStandardization', key_str);
        if ~isnan(est1)
            plot(ax_left, [ci1_l, ci1_u], [yk + dy, yk + dy], '-', 'Color', edg_f1, 'LineWidth', 2.6, 'HandleVisibility', 'off');
            plot(ax_left, est1, yk + dy, 'o', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f1, 'MarkerEdgeColor', edg_f1, 'LineWidth', 1.4, 'HandleVisibility', 'off');
        end

        [est2, ci2_l, ci2_u] = lookup_effect_row(effects_tbl, 'TrajNorm_Standardization', key_str);
        if ~isnan(est2)
            plot(ax_left, [ci2_l, ci2_u], [yk - dy, yk - dy], '-', 'Color', edg_f2, 'LineWidth', 2.6, 'HandleVisibility', 'off');
            plot(ax_left, est2, yk - dy, 's', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f2, 'MarkerEdgeColor', edg_f2, 'LineWidth', 1.4, 'HandleVisibility', 'off');
        end

        if k > 1
            [d1, d1_l, d1_u, ~] = lookup_within_row(within_tbl, 'TrajNorm_noStandardization', key_str);
            if ~isnan(d1)
                plot(ax_right, [d1_l, d1_u], [yk + dy, yk + dy], '-', 'Color', edg_f1, 'LineWidth', 2.6, 'HandleVisibility', 'off');
                plot(ax_right, d1, yk + dy, 'o', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f1, 'MarkerEdgeColor', edg_f1, 'LineWidth', 1.4, 'HandleVisibility', 'off');
                q1 = lookup_sens_q(TreeBH_Results.Tree2_Sensitivity_Table, key_str);
                if ~isnan(q1) && q1 < 0.05
                    q_txt = ['* q=' strrep(sprintf('%.3f', q1), '0.', '.')];
                    if d1 >= 0
                        text(ax_right, d1_u + 0.03, yk + dy, q_txt, 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', edg_f1, 'VerticalAlignment', 'middle');
                    else
                        text(ax_right, d1_l - 0.03, yk + dy, q_txt, 'HorizontalAlignment', 'right', 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', edg_f1, 'VerticalAlignment', 'middle');
                    end
                end
            end

            [d2, d2_l, d2_u, ~] = lookup_within_row(within_tbl, 'TrajNorm_Standardization', key_str);
            if ~isnan(d2)
                plot(ax_right, [d2_l, d2_u], [yk - dy, yk - dy], '-', 'Color', edg_f2, 'LineWidth', 2.6, 'HandleVisibility', 'off');
                plot(ax_right, d2, yk - dy, 's', 'MarkerSize', 9.0, 'MarkerFaceColor', col_f2, 'MarkerEdgeColor', edg_f2, 'LineWidth', 1.4, 'HandleVisibility', 'off');
                q2 = lookup_sens_q(TreeBH_Results.FigS2b_Sensitivity_Std_Table, key_str);
                if ~isnan(q2) && q2 < 0.05
                    q_txt = ['* q=' strrep(sprintf('%.3f', q2), '0.', '.')];
                    if d2 >= 0
                        text(ax_right, d2_u + 0.03, yk - dy, q_txt, 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', edg_f2, 'VerticalAlignment', 'middle');
                    else
                        text(ax_right, d2_l - 0.03, yk - dy, q_txt, 'HorizontalAlignment', 'right', 'FontSize', 11.5, 'FontWeight', 'bold', 'FontName', 'Calibri', 'Color', edg_f2, 'VerticalAlignment', 'middle');
                    end
                end
            end
        end
    end

    % --- Plot Bottom 4 Rows (Temporal Full-Trajectory Analysis, Left Panel only) ---
    for m = 1:4
        yk = y_positions(11 + m);
        key_str = eff_keys_f3{m};
        [est3, ci3_l, ci3_u] = lookup_effect_row(effects_tbl, 'noTrajNorm_noStandardization', key_str);
        if ~isnan(est3)
            plot(ax_left, [ci3_l, ci3_u], [yk, yk], '-', 'Color', edg_f3, 'LineWidth', 2.8, 'HandleVisibility', 'off');
            plot(ax_left, est3, yk, 'd', 'MarkerSize', 9.5, 'MarkerFaceColor', col_f3, 'MarkerEdgeColor', edg_f3, 'LineWidth', 1.4, 'HandleVisibility', 'off');
        else
            plot(ax_left, 0, yk, 'd', 'MarkerSize', 8.5, 'MarkerFaceColor', [0.82, 0.78, 0.88], 'MarkerEdgeColor', edg_f3, 'LineWidth', 1.2, 'HandleVisibility', 'off');
            text(ax_left, 0.06, yk, 'No cluster (q = 1)', 'FontSize', 12.5, 'FontAngle', 'italic', 'FontName', 'Calibri', 'Color', edg_f3, 'VerticalAlignment', 'middle');
        end
    end

    % Legend
    h_f1 = plot(ax_left, nan, nan, 'o-', 'Color', edg_f1, 'MarkerFaceColor', col_f1, 'MarkerEdgeColor', edg_f1, 'MarkerSize', 9.0, 'LineWidth', 2.4);
    h_f2 = plot(ax_left, nan, nan, 's-', 'Color', edg_f2, 'MarkerFaceColor', col_f2, 'MarkerEdgeColor', edg_f2, 'MarkerSize', 9.0, 'LineWidth', 2.4);
    h_f3 = plot(ax_left, nan, nan, 'd-', 'Color', edg_f3, 'MarkerFaceColor', col_f3, 'MarkerEdgeColor', edg_f3, 'MarkerSize', 9.5, 'LineWidth', 2.4);
    legend(ax_left, [h_f1, h_f2, h_f3], ...
        {'Pre-registered analysis', ...
         'Robustness analysis (Z-scored)', ...
         'Temporal full-trajectory analysis'}, ...
        'Location', 'northeast', 'FontSize', 13.0, 'FontName', 'Calibri', 'Box', 'on', 'Color', 'w');

    xlim(ax_left, xlim_left); ylim(ax_left, y_lim);
    yticks(ax_left, fliplr(y_positions));
    yticklabels(ax_left, fliplr(row_labels));
    xlabel(ax_left, {'Effect Size', '(|d_z| / Dependent AKP, \pm95% CI)'}, 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
    title(ax_left, '(a) Congruency Effect Sizes Across Analyses', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
    set(ax_left, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', 'Calibri', 'LineWidth', 2.6, 'Layer', 'top');
    box(ax_left, 'off');

    xlim(ax_right, xlim_right); ylim(ax_right, y_lim);
    yticks(ax_right, fliplr(y_positions));
    yticklabels(ax_right, {});
    xlabel(ax_right, {'Sensitivity vs. Keyboard RT', '(\Delta|d_z| = |d_{z,Reach}| - |d_{z,KB}|, \pm95% CI)'}, 'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Calibri');
    title(ax_right, '(b) Sensitivity Comparison to Keyboard RT', 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');
    set(ax_right, 'TickDir', 'out', 'FontSize', 13.0, 'FontName', 'Calibri', 'LineWidth', 2.6, 'Layer', 'top');
    box(ax_right, 'off');
end

function [est, ci_l, ci_u] = lookup_effect_row(effects_tbl, flavor_str, key_str)
    est = NaN; ci_l = NaN; ci_u = NaN;
    rows = strcmp(string(effects_tbl.Flavor), flavor_str) & strcmp(string(effects_tbl.Effect), key_str);
    if ~any(rows) && strcmp(flavor_str, 'TrajNorm_Standardization') && ismember(key_str, {'traj', 'x_std', 'iep'})
        rows = strcmp(string(effects_tbl.Flavor), 'TrajNorm_noStandardization') & strcmp(string(effects_tbl.Effect), key_str);
    end
    if any(rows)
        idx = find(rows, 1);
        raw_est = effects_tbl.Reported_Effect_Size(idx);
        raw_l   = effects_tbl.CI_Lower(idx);
        raw_u   = effects_tbl.CI_Upper(idx);
        if raw_est < 0
            est  = -raw_est;
            ci_l = -raw_u;
            ci_u = -raw_l;
        else
            est  = raw_est;
            ci_l = raw_l;
            ci_u = raw_u;
        end
    end
end

function [d_est, d_l, d_u, p_val] = lookup_within_row(within_tbl, flavor_str, key_str)
    d_est = NaN; d_l = NaN; d_u = NaN; p_val = NaN;
    r_pos = strcmp(string(within_tbl.Flavor), flavor_str) & strcmp(string(within_tbl.Comparison), [key_str, '_minus_kb_rt']);
    r_neg = strcmp(string(within_tbl.Flavor), flavor_str) & strcmp(string(within_tbl.Comparison), ['kb_rt_minus_', key_str]);
    if any(r_pos)
        idx = find(r_pos, 1);
        d_est = within_tbl.Effect_Size_Diff(idx);
        d_l   = within_tbl.CI_Lower(idx);
        d_u   = within_tbl.CI_Upper(idx);
        p_val = within_tbl.P_Value(idx);
    elseif any(r_neg)
        idx = find(r_neg, 1);
        d_est = -within_tbl.Effect_Size_Diff(idx);
        d_l   = -within_tbl.CI_Upper(idx);
        d_u   = -within_tbl.CI_Lower(idx);
        p_val = within_tbl.P_Value(idx);
    end
end

function q_val = lookup_sens_q(sens_tbl, key_str)
    q_val = NaN;
    switch key_str
        case 'ra',       node = 'Reach_Area_vs_KB';
        case 'react',    node = 'Onset_vs_KB';
        case 'mt',       node = 'MT_vs_KB';
        case 'tot_dist', node = 'Total_Dist_vs_KB';
        case 'com',      node = 'COM_vs_KB';
        case 'mad',      node = 'MAD_vs_KB';
        case 'auc',      node = 'AUC_vs_KB';
        case 'traj',     node = 'Spatial_Dev_vs_KB';
        case 'x_std',    node = 'Spatial_Var_vs_KB';
        case 'iep',      node = 'IEP_vs_KB';
        otherwise,       node = '';
    end
    if ~isempty(node)
        r = strcmp(string(sens_tbl.Node_Name), node);
        if any(r)
            q_val = sens_tbl.Within_Family_FDR_q(find(r, 1));
        end
    end
end

% =========================================================================
% HELPER: Render Figure S1a..f (Split full-page-width TreeBH + FDR Table)
% =========================================================================
function render_figS1_split_schemes(TreeBH_Results, out_fig_dir)
    G = TreeBH_Results.Graphs;
    trees = { ...
        G.GS1_out,  '(a) Pure Pre-Registered Tree-BH [Pre-Registered Analysis]',                 false, false, 'Fig_S1a_TreeBH_Pure_PreRegistered'; ...
        G.G1_out,   '(b) Pre-Registered Tree + Post-Hoc Variables [Pre-Registered Analysis]',     true,  true,  'Fig_S1b_TreeBH_PreReg_PostHoc'; ...
        G.GS2a_out, '(c) Congruency Effect Robustness Tree [Robustness analysis (Z-scored)]',     true,  false, 'Fig_S1c_TreeBH_Robustness'; ...
        G.G2_out,   '(d) Sensitivity Comparison Tree [Pre-Registered Analysis]',                  true,  false, 'Fig_S1d_TreeBH_Sensitivity'; ...
        G.GS2b_out, '(e) Sensitivity Robustness Tree [Robustness analysis (Z-scored)]',           true,  false, 'Fig_S1e_TreeBH_Sensitivity_Robustness'};

    for i = 1:size(trees, 1)
        fig_nm = trees{i, 5};
        fig_h = figure('Name', fig_nm, 'Color', 'w', 'Position', [30, 40, 1320, 740], 'Visible', 'off');
        ax_h = axes('Parent', fig_h, 'Position', [0.02, 0.06, 0.96, 0.87]);
        plot_treebh_figure(trees{i, 1}, trees{i, 2}, '', trees{i, 3}, ax_h, trees{i, 4});
        save_master_fig(fig_h, fullfile(out_fig_dir, fig_nm));
        close(fig_h);
    end

    % Panel (f): Standalone Full-Page-Width FDR Table + Formatted DOCX Export
    tbl_nm = 'Fig_S1f_FullTraj_FDR_Table';
    c4 = TreeBH_Results.Component4_Continuous_FDR;
    disp_names = {'Deviance From Center', 'Implied Endpoint', 'Heading Angle', 'Horizontal Movement Variation'};
    status_str = {'Pre-Registered', 'Post-Hoc', 'Pre-Registered', 'Pre-Registered'};
    headers = {'Full-Trajectory Measure', 'Status', 'Cluster Window', 'Cluster |dz|', 'Raw p', 'FDR q', 'Significant'};
    tbl_title = '(f) Benjamini-Hochberg FDR Correction [Temporal Full-Trajectory Analysis]';

    fig_f = figure('Name', tbl_nm, 'Color', 'w', 'Position', [40, 40, 1320, 440], 'Visible', 'off');
    ax_f = axes('Parent', fig_f, 'Position', [0.015, 0.05, 0.97, 0.82]);
    axis(ax_f, 'off');
    hold(ax_f, 'on');
    xlim(ax_f, [0, 1]); ylim(ax_f, [0, 1]);

    title(ax_f, tbl_title, 'FontSize', 16.0, 'FontWeight', 'bold', 'FontName', 'Calibri');

    col_x = [0.012, 0.340, 0.490, 0.635, 0.745, 0.835, 0.932];
    patch(ax_f, [0, 1, 1, 0], [0.78, 0.78, 0.95, 0.95], [0.20, 0.32, 0.50], 'EdgeColor', 'none');
    for h_i = 1:numel(headers)
        h_al = 'center';
        if h_i == 1, h_al = 'left'; end
        text(ax_f, col_x(h_i), 0.865, headers{h_i}, 'Color', 'w', 'FontWeight', 'bold', ...
            'FontSize', 14.5, 'FontName', 'Calibri', 'HorizontalAlignment', h_al);
    end

    row_y = [0.65, 0.48, 0.31, 0.14];
    for r = 1:height(c4)
        if strcmp(status_str{r}, 'Post-Hoc')
            bg_col = [1.00, 0.985, 0.89];
        else
            bg_col = [0.965, 0.975, 0.99];
        end
        y_lo_r = row_y(r) - 0.080;
        y_hi_r = row_y(r) + 0.080;
        patch(ax_f, [0, 1, 1, 0], [y_lo_r, y_lo_r, y_hi_r, y_hi_r], bg_col, 'EdgeColor', 'none');
        plot(ax_f, [0, 1], [y_lo_r, y_lo_r], '-', 'Color', [0.82, 0.85, 0.89], 'LineWidth', 1.0);

        if c4.Cluster_Detected(r)
            win_str = sprintf('%d-%d ms', c4.Start_ms(r), c4.End_ms(r));
            dz_str  = sprintf('%.2f', abs(c4.Cohen_dz(r)));
            p_str   = sprintf('%.4f', c4.Cluster_p_raw(r));
            q_str   = sprintf('%.4f', c4.FDR_adj_p(r));
            sig_str = 'Yes (q < .05)';
            sig_col = [0.08, 0.45, 0.15];
        else
            win_str = 'No Cluster';
            dz_str  = '---';
            p_str   = '1.0000';
            q_str   = '1.0000';
            sig_str = 'No';
            sig_col = [0.55, 0.15, 0.15];
        end

        vals = {disp_names{r}, status_str{r}, win_str, dz_str, p_str, q_str};
        for c_i = 1:numel(vals)
            c_al = 'center';
            if c_i == 1, c_al = 'left'; end
            text(ax_f, col_x(c_i), row_y(r), vals{c_i}, 'Color', [0.1, 0.1, 0.1], ...
                'FontSize', 13.0, 'FontName', 'Calibri', 'HorizontalAlignment', c_al);
        end
        text(ax_f, col_x(7), row_y(r), sig_str, 'Color', sig_col, 'FontWeight', 'bold', ...
            'FontSize', 13.0, 'FontName', 'Calibri', 'HorizontalAlignment', 'center');
    end

    save_master_fig(fig_f, fullfile(out_fig_dir, tbl_nm));
    close(fig_f);

    docx_path = fullfile(out_fig_dir, [tbl_nm '.docx']);
    export_figS1f_table_docx(c4, disp_names, status_str, headers, tbl_title, docx_path);
end

function export_figS1f_table_docx(c4, disp_names, status_str, headers, tbl_title, docx_path)
    n_r = height(c4);
    rows_cell = cell(1, n_r);
    for r = 1:n_r
        is_sig = logical(c4.Cluster_Detected(r));
        if is_sig
            win_str = sprintf('%d-%d ms', c4.Start_ms(r), c4.End_ms(r));
            dz_str  = sprintf('%.2f', abs(c4.Cohen_dz(r)));
            p_str   = sprintf('%.4f', c4.Cluster_p_raw(r));
            q_str   = sprintf('%.4f', c4.FDR_adj_p(r));
            sig_str = 'Yes (q < .05)';
        else
            win_str = 'No Cluster';
            dz_str  = '---';
            p_str   = '1.0000';
            q_str   = '1.0000';
            sig_str = 'No';
        end
        rows_cell{r} = struct( ...
            'cells', {{disp_names{r}, status_str{r}, win_str, dz_str, p_str, q_str, sig_str}}, ...
            'posthoc', strcmp(status_str{r}, 'Post-Hoc'), ...
            'significant', is_sig);
    end
    payload = struct('title', tbl_title, 'headers', {headers}, 'rows', {rows_cell});
    tmp_json = [tempname, '.json'];
    fid = fopen(tmp_json, 'w', 'n', 'UTF-8');
    if fid < 0
        warning('Could not write temporary JSON for Fig. S1f DOCX export.');
        return;
    end
    fwrite(fid, jsonencode(payload), 'char');
    fclose(fid);

    this_dir = fileparts(mfilename('fullpath'));
    py_script = fullfile(this_dir, 'export_figS1f_docx.py');
    cmd = sprintf('python "%s" --json "%s" --out "%s"', py_script, tmp_json, docx_path);
    [status_py, out_py] = system(cmd);
    if exist(tmp_json, 'file'), delete(tmp_json); end
    if status_py ~= 0
        warning('Fig. S1f DOCX export failed: %s', out_py);
    end
end

% =========================================================================
% HELPER: Render Figure S2 (Unstandardized Measures Violating Normality)
% =========================================================================
function figS2 = render_figS2_qq_plots(fst, f1_avg, f2_dir, good_subs, p) %#ok<INUSL>
    plt_draft = get_draft_plt_params();
    figS2 = figure('Name', 'Fig_S2_Assumptions_QQ_Plots', 'Color', 'w', ...
        'Position', [40, 40, 1320, 470], 'Visible', 'off');

    win_f1 = fst.dynamic_trajectory_windows.TrajNorm_noStandardization;
    vecs_f1 = extract_11_diff_vectors(f1_avg.reach_avg_each, f1_avg.keyboard_avg_each, good_subs, win_f1, false);

    % Pre-Registered Congruency Difference (Con - Incon) measures violating parametric assumptions
    % (non-normality OR 1.5*IQR outliers, including post-hoc):
    % idx 3 = Reaching Onset (Lilliefors p=.0113, 3 outliers),
    % idx 10 = Horizontal Movement Variation (JB p=.0308, 4 outliers),
    % idx 7 = MAD (Post-Hoc; 1 outlier at 1.5*IQR).
    panels = { ...
        vecs_f1{3},  '(a) Reaching Onset', false; ...
        vecs_f1{10}, '(b) Horizontal Movement Variation', false; ...
        vecs_f1{7},  '(c) MAD', true};

    tl = tiledlayout(figS2, 1, 3, 'TileSpacing', 'loose', 'Padding', 'compact'); %#ok<NASGU>
    ax_list = gobjects(size(panels, 1), 1);
    for k = 1:size(panels, 1)
        ax = nexttile(k);
        ax_list(k) = ax;
        plot_draft_qq_panel(ax, panels{k, 1}, panels{k, 2}, plt_draft, k == 1);
    end
    drawnow;
    for k = 1:size(panels, 1)
        if panels{k, 3}
            ax = ax_list(k);
            ti = ax.TightInset;
            add_posthoc_backdrop(ax, [ti(1) + 0.008, ti(2) + 0.010, ti(3) + 0.010, ti(4) + 0.012]);
        end
    end
end

function vecs = extract_11_diff_vectors(r_avg, k_avg, good_subs, win, is_std)
    kb = k_avg.rt(1).con(good_subs) - k_avg.rt(1).incon(good_subs);
    if ~is_std && mean(abs(k_avg.rt(1).con(good_subs)), 'omitnan') < 10
        kb = kb * 1000;
    end
    ra  = r_avg.ra(1).con(good_subs) - r_avg.ra(1).incon(good_subs);
    on  = r_avg.react(1).con(good_subs) - r_avg.react(1).incon(good_subs);
    mt  = r_avg.mt(1).con(good_subs) - r_avg.mt(1).incon(good_subs);
    td  = (r_avg.tot_dist(1).con(good_subs) - r_avg.tot_dist(1).incon(good_subs));
    if ~is_std && mean(abs(r_avg.tot_dist(1).con(good_subs)), 'omitnan') < 2
        td = td * 100;
    end
    com = r_avg.com(1).con(good_subs) - r_avg.com(1).incon(good_subs);
    mad = r_avg.mad(1).con(good_subs) - r_avg.mad(1).incon(good_subs);
    if ~is_std && mean(abs(r_avg.mad(1).con(good_subs)), 'omitnan') < 1
        mad = mad * 100;
    end
    auc = r_avg.auc(1).con(good_subs) - r_avg.auc(1).incon(good_subs);

    dev = mean(r_avg.traj(1).con(win.traj(1):win.traj(2), good_subs, 1) - r_avg.traj(1).incon(win.traj(1):win.traj(2), good_subs, 1), 1)';
    xst = mean(r_avg.x_std(1).con(win.x_std(1):win.x_std(2), good_subs) - r_avg.x_std(1).incon(win.x_std(1):win.x_std(2), good_subs), 1)';
    iep = mean(r_avg.iep(1).con(win.iep(1):win.iep(2), good_subs, 1) - r_avg.iep(1).incon(win.iep(1):win.iep(2), good_subs, 1), 1)';
    if ~is_std
        dev = dev * 100; xst = xst * 100; iep = iep * 100;
    end

    vecs = {kb(:), ra(:), on(:), mt(:), td(:), com(:), mad(:), auc(:), dev(:), xst(:), iep(:)};
end

function plot_draft_qq_panel(ax, d_vec, title_str, plt_p, show_legend)
    if nargin < 5
        show_legend = false;
    end
    d_vec = d_vec(~isnan(d_vec));
    e_vec = d_vec - mean(d_vec);
    n = numel(e_vec);

    e_sorted = sort(e_vec);
    p_grid = ((1:n)' - 0.5) / n;
    theo_z = norminv(p_grid);

    q25 = prctile(e_sorted, 25);
    q75 = prctile(e_sorted, 75);
    z25_75 = norminv([0.25; 0.75]);
    slope = (q75 - q25) / diff(z25_75);
    intercept = q25 - slope * z25_75(1);

    % Smooth 95% pointwise envelope in scaled ~N quantile units (matching Draft Supp Fig 2)
    p_fine = linspace(p_grid(1), p_grid(end), 240)';
    z_fine = norminv(p_fine);
    theo_fine = slope * z_fine;
    line_fine = intercept + theo_fine;
    se_band = (slope ./ normpdf(z_fine)) .* sqrt(p_fine .* (1 - p_fine) / n);
    half_w = tinv(0.975, n - 1) * se_band;
    upper = line_fine + half_w;
    lower = line_fine - half_w;

    theo_x = slope * theo_z;
    line_grid = intercept + theo_x;
    se_grid = (slope ./ normpdf(theo_z)) .* sqrt(p_grid .* (1 - p_grid) / n);
    half_grid = tinv(0.975, n - 1) * se_grid;
    upper_grid = line_grid + half_grid;
    lower_grid = line_grid - half_grid;

    hold(ax, 'on');
    set(ax, 'Color', 'w');

    % Identify 1.5*IQR outliers and pointwise 95% normal-band violations.
    % Priority: outlier (red) overrides normality violation (light gray); both default to red.
    q25_raw = prctile(e_vec, 25);
    q75_raw = prctile(e_vec, 75);
    iqr_raw = q75_raw - q25_raw;
    is_out       = (e_sorted < (q25_raw - 1.5 * iqr_raw)) | (e_sorted > (q75_raw + 1.5 * iqr_raw));
    is_band_viol = (e_sorted < lower_grid) | (e_sorted > upper_grid);
    is_norm_only = is_band_viol & ~is_out;
    is_normal_pt = ~is_out & ~is_band_viol;

    fill(ax, [theo_fine; flipud(theo_fine)], [lower; flipud(upper)], ...
        [0.68, 0.68, 0.68], 'FaceAlpha', 0.82, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(ax, theo_fine, line_fine, 'k-', 'LineWidth', 2.4, 'HandleVisibility', 'off');

    h_norm = plot(ax, theo_x(is_normal_pt), e_sorted(is_normal_pt), 'ko', ...
        'MarkerSize', 7.5, 'MarkerFaceColor', 'k', 'LineWidth', 1.0, 'DisplayName', 'Normal (within 95% CI)');
    h_viol = gobjects(0);
    if any(is_norm_only)
        h_viol = plot(ax, theo_x(is_norm_only), e_sorted(is_norm_only), 'o', ...
            'MarkerSize', 8.0, 'MarkerFaceColor', [0.78, 0.78, 0.78], ...
            'MarkerEdgeColor', [0.35, 0.35, 0.35], 'LineWidth', 1.1, 'DisplayName', 'Normality violation');
    end
    h_out = gobjects(0);
    if any(is_out)
        h_out = plot(ax, theo_x(is_out), e_sorted(is_out), 'o', 'MarkerSize', 8.2, ...
            'MarkerFaceColor', plt_p.incon_col, 'MarkerEdgeColor', [0.55, 0.05, 0.02], ...
            'LineWidth', 1.1, 'DisplayName', 'Outlier (1.5{\times}IQR)');
    end

    if show_legend && ~isempty(h_viol) && ~isempty(h_out)
        legend(ax, [h_norm, h_viol, h_out], ...
            {'Within 95% CI', 'Normality violation', 'Outlier (1.5{\times}IQR)'}, ...
            'Location', 'northwest', 'Box', 'off', ...
            'FontSize', max(11.5, plt_p.font_size - 1.0), 'FontName', plt_p.font_name);
    end

    all_x = theo_fine;
    all_y = [e_sorted; lower; upper];
    xr = max(all_x) - min(all_x);
    yr = max(all_y) - min(all_y);
    xlim(ax, [min(all_x) - 0.06 * xr, max(all_x) + 0.06 * xr]);
    ylim(ax, [min(all_y) - 0.06 * yr, max(all_y) + 0.06 * yr]);

    xlabel(ax, 'Theoretical Quantiles', 'FontSize', plt_p.labels_font_size, 'FontName', plt_p.font_name);
    ylabel(ax, 'Sample Quantiles', 'FontSize', plt_p.labels_font_size, 'FontName', plt_p.font_name);
    title(ax, title_str, 'FontSize', plt_p.title_font_size, 'FontWeight', 'bold', 'FontName', plt_p.font_name);
    set(ax, 'TickDir', 'out', 'FontSize', plt_p.font_size, 'FontName', plt_p.font_name, ...
        'LineWidth', plt_p.axes_line_thickness, 'Layer', 'top');
    box(ax, 'off');
end
