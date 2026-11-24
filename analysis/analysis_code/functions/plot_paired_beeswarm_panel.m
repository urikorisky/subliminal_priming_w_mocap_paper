function plot_paired_beeswarm_panel(ax, con_vals, incon_vals, title_str, y_label_str, q_val, dz_val, is_posthoc, plt_p, panel_letter, bg_pad, show_xticks)
% PLOT_PAIRED_BEESWARM_PANEL Renders a publication-quality paired Congruent vs Incongruent
% beeswarm subplot using draft visual language (colors, Calibri font, large typography,
% thicker strokes, larger markers, no x-ticks by default) while placing any post-hoc yellow
% backdrop behind the white plot area.

if nargin < 11 || isempty(bg_pad)
    bg_pad = [0.050, 0.025, 0.012, 0.042];
end
if nargin < 12 || isempty(show_xticks)
    show_xticks = false;
end

font_name = 'Calibri';
if isfield(plt_p, 'font_name') && ~isempty(plt_p.font_name)
    font_name = plt_p.font_name;
end
ax_lw = 2.6;
if isfield(plt_p, 'axes_line_thickness') && ~isempty(plt_p.axes_line_thickness)
    ax_lw = plt_p.axes_line_thickness;
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

con_vals = con_vals(:);
incon_vals = incon_vals(:);
n = numel(con_vals);

hold(ax, 'on');

% Set X limits and optionally remove ticks/tick-labels
xlim(ax, [0.35, 2.65]);
if show_xticks
    xticks(ax, [1, 2]);
    xticklabels(ax, {'Con', 'Incon'});
else
    xticks(ax, []);
    xticklabels(ax, {});
end

% Data-driven Y limits (per-panel zoom)
all_y = [con_vals; incon_vals];
min_y = min(all_y, [], 'omitnan');
max_y = max(all_y, [], 'omitnan');
if isempty(min_y) || isnan(min_y) || min_y >= max_y
    min_y = -1; max_y = 1;
end
yr = max_y - min_y;
if yr == 0, yr = 1; end

is_sig = ~isnan(q_val) && (q_val < 0.05);
if is_sig
    ylim(ax, [min_y - 0.12 * yr, max_y + 0.30 * yr]);
else
    ylim(ax, [min_y - 0.12 * yr, max_y + 0.16 * yr]);
end

% Interior remains pure white for all panels; post-hoc yellow backdrop goes behind the plot
set(ax, 'Color', 'w');
box(ax, 'off');

% Compute larger non-overlapping beeswarm positions
marker_diam_pts = 6.8;
max_hw = 0.36;
[x_con, h_sc1]   = place_non_overlapping_beeswarm(ax, con_vals,   1.0, max_hw, plt_p.con_col,   marker_diam_pts, 0.90);
[x_incon, h_sc2] = place_non_overlapping_beeswarm(ax, incon_vals, 2.0, max_hw, plt_p.incon_col, marker_diam_pts, 0.90);
if ~isempty(h_sc1) && isgraphics(h_sc1), set(h_sc1, 'MarkerEdgeColor', 'none'); end
if ~isempty(h_sc2) && isgraphics(h_sc2), set(h_sc2, 'MarkerEdgeColor', 'none'); end

% Plot individual participant connecting lines underneath scatter markers
h_lines = gobjects(n, 1);
for i = 1:n
    if ~isnan(con_vals(i)) && ~isnan(incon_vals(i))
        if incon_vals(i) >= con_vals(i)
            ls = '-';
        else
            ls = '--';
        end
        h_lines(i) = plot(ax, [x_con(i), x_incon(i)], [con_vals(i), incon_vals(i)], ...
            'LineStyle', ls, 'Color', [0.15, 0.15, 0.15, 0.24], 'LineWidth', 1.6, ...
            'HandleVisibility', 'off');
    end
end
% Bring scatter markers above connecting lines
if ~isempty(h_sc1) && isgraphics(h_sc1), uistack(h_sc1, 'top'); end
if ~isempty(h_sc2) && isgraphics(h_sc2), uistack(h_sc2, 'top'); end

% Plot Grand Mean horizontal bar (draft condition color + translucent grey overlay) + SE error bar
mean_con = mean(con_vals, 'omitnan');
se_con   = std(con_vals, 0, 'omitnan') / sqrt(sum(~isnan(con_vals)));
mean_inc = mean(incon_vals, 'omitnan');
se_inc   = std(incon_vals, 0, 'omitnan') / sqrt(sum(~isnan(incon_vals)));

bar_hw = 0.26;
plot(ax, [1 - bar_hw, 1 + bar_hw], [mean_con, mean_con], '-', 'Color', plt_p.con_col, 'LineWidth', 5.2, 'HandleVisibility', 'off');
plot(ax, [1 - bar_hw, 1 + bar_hw], [mean_con, mean_con], '-', 'Color', [0.70, 0.70, 0.70, 0.50], 'LineWidth', 5.2, 'HandleVisibility', 'off');
errorbar(ax, 1, mean_con, se_con, 'k', 'LineStyle', 'none', 'LineWidth', 2.2, 'CapSize', 7, 'HandleVisibility', 'off');

plot(ax, [2 - bar_hw, 2 + bar_hw], [mean_inc, mean_inc], '-', 'Color', plt_p.incon_col, 'LineWidth', 5.2, 'HandleVisibility', 'off');
plot(ax, [2 - bar_hw, 2 + bar_hw], [mean_inc, mean_inc], '-', 'Color', [0.70, 0.70, 0.70, 0.50], 'LineWidth', 5.2, 'HandleVisibility', 'off');
errorbar(ax, 2, mean_inc, se_inc, 'k', 'LineStyle', 'none', 'LineWidth', 2.2, 'CapSize', 7, 'HandleVisibility', 'off');

% Significance comparison line + asterisk + fine-print q and dz
if is_sig
    y_bar = max_y + 0.08 * yr;
    y_tick_h = 0.03 * yr;
    plot(ax, [1, 1, 2, 2], [y_bar - y_tick_h, y_bar, y_bar, y_bar - y_tick_h], ...
        'k-', 'LineWidth', 2.2, 'HandleVisibility', 'off');

    if q_val < 0.001
        stars = '***';
        q_str = 'q < .001';
    elseif q_val < 0.01
        stars = '**';
        q_str = regexprep(sprintf('q = %.3f', q_val), '0\.', '.');
    else
        stars = '*';
        q_str = regexprep(sprintf('q = %.3f', q_val), '0\.', '.');
    end

    stat_label = sprintf('{\\bf%s} {\\fontsize{9}%s, d_z=%.2f}', stars, q_str, abs(dz_val));
    text(ax, 1.5, y_bar + 0.02 * yr, stat_label, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontName', font_name, 'FontSize', 10.5, 'Color', [0.05, 0.05, 0.05], ...
        'Interpreter', 'tex');
end

ylabel(ax, y_label_str, 'FontSize', lbl_fs, 'FontName', font_name);
title(ax, title_str, 'FontSize', ttl_fs, 'FontWeight', 'bold', 'FontName', font_name);
set(ax, 'TickDir', 'out', 'FontSize', tick_fs, 'FontName', font_name, 'LineWidth', ax_lw);

if nargin >= 10 && ~isempty(panel_letter)
    text(ax, -0.22, 1.07, sprintf('(%s)', panel_letter), 'Units', 'normalized', ...
        'FontSize', let_fs, 'FontWeight', 'bold', 'FontName', font_name, 'Color', 'k');
end

if is_posthoc
    add_posthoc_backdrop(ax, bg_pad);
end

end
