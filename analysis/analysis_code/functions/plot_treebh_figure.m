function [fig_handle] = plot_treebh_figure(G_output, title_str, save_path_base, highlight_posthoc, target_ax, show_legend)
% PLOT_TREEBH_FIGURE Generates publication-ready vector figures for TreeBH trees
% Uses a bottom-aligned leaf layout so all leaf hypotheses sit on a single bottom row
% and internal/leaf labels never collide with branches, displaying <=3-decimal stats
% without leading zeros (and <.001 for values < 0.001) in large Calibri typography.

if nargin < 4 || isempty(highlight_posthoc)
    highlight_posthoc = false;
end
if nargin < 5
    target_ax = [];
end
if nargin < 6 || isempty(show_legend)
    show_legend = true;
end

plt_draft = get_draft_plt_params();
font_name = plt_draft.font_name;

is_multipanel = ~isempty(target_ax);
if ~is_multipanel
    fig_handle = figure('Name', title_str, 'Color', 'w', 'Position', [30, 40, 1320, 740], 'Visible', 'off');
    ax = axes('Parent', fig_handle, 'Position', [0.02, 0.06, 0.96, 0.87]);
else
    ax = target_ax;
    fig_handle = ancestor(ax, 'figure');
    ax_orig_units = ax.Units;
    ax.Units = 'normalized';
    ax_p = ax.Position;
    ax.Units = ax_orig_units;
    % Treat standalone full-canvas axes (e.g. Fig. S1a-e) at full-page typography scale
    is_multipanel = (ax_p(3) < 0.80 || ax_p(4) < 0.75);
end
hold(ax, 'on');

% Determine node rejection and colors
num_nodes = G_output.numnodes;
is_rejected = false(num_nodes, 1);
if ismember('reject', G_output.Nodes.Properties.VariableNames)
    is_rejected = logical(G_output.Nodes.reject);
end

is_posthoc = false(num_nodes, 1);
if ismember('is_posthoc', G_output.Nodes.Properties.VariableNames)
    is_posthoc = logical(G_output.Nodes.is_posthoc);
end

node_colors = zeros(num_nodes, 3);
for i = 1:num_nodes
    if highlight_posthoc && is_posthoc(i)
        if is_rejected(i)
            node_colors(i, :) = [0.90, 0.45, 0.00]; % Vivid Coral/Orange for Significant Post-Hoc
        else
            node_colors(i, :) = [0.95, 0.75, 0.50]; % Light Peach for Non-Significant Post-Hoc
        end
    else
        if is_rejected(i)
            node_colors(i, :) = [0.12, 0.53, 0.90]; % Vivid Blue for Significant Pre-Reg
        else
            node_colors(i, :) = [0.65, 0.65, 0.65]; % Neutral Grey for Non-Significant
        end
    end
end

% Compute clean bottom-aligned hierarchical coordinates with wider spacing for large fonts
[x_coords, y_coords, H, root_idx] = compute_bottom_aligned_tree_coords(G_output);
root_x = x_coords(root_idx);

% Plot tree graph without MATLAB's single-line auto-labels
p_graph = plot(ax, G_output, ...
    'XData', x_coords, ...
    'YData', y_coords, ...
    'NodeLabel', {}, ...
    'NodeColor', node_colors, ...
    'MarkerSize', 14, ...
    'LineWidth', 2.2, ...
    'ArrowSize', 10, ...
    'EdgeColor', [0.55, 0.55, 0.55]);

% Highlight Post-Hoc edges when enabled
if highlight_posthoc
    edge_table = G_output.Edges;
    for e = 1:height(edge_table)
        source_idx = edge_table.EndNodes(e, 1);
        target_idx = edge_table.EndNodes(e, 2);
        if is_posthoc(target_idx)
            highlight(p_graph, source_idx, target_idx, 'EdgeColor', [0.90, 0.45, 0.00], 'LineWidth', 3.0);
        end
    end
end

% Overlay unclipped node circles
scatter(ax, x_coords, y_coords, 210, node_colors, 'filled', ...
    'Clipping', 'off', 'HandleVisibility', 'off');

% Standardize typography to Fig. 3 full-page scale
if is_multipanel
    internal_fs = 11.5;
    leaf_fs     = 10.5;
    ttl_fs      = 15.0;
    leg_fs      = 12.0;
else
    internal_fs = 13.0;
    leaf_fs     = 12.2;
    ttl_fs      = 16.0;
    leg_fs      = 13.0;
end

has_alpha_col = ismember('alpha', G_output.Nodes.Properties.VariableNames);

for i = 1:num_nodes
    raw_name = G_output.Nodes.name{i};
    disp_name = format_tree_node_name(raw_name);
    has_stats = ismember('corr_p', G_output.Nodes.Properties.VariableNames) && ~isnan(G_output.Nodes.corr_p(i));
    kids = G_output.successors(i);
    preds = G_output.predecessors(i);

    if isempty(kids)
        % Leaf hypothesis node (all positioned at y = 1.0)
        if has_stats
            raw_p = G_output.Nodes.p(i);
            adj_p = G_output.Nodes.corr_p(i);
            if isnan(raw_p)
                stat_line = '(Pruned)';
            elseif has_alpha_col && ~isnan(G_output.Nodes.alpha(i))
                a_str = fmt_tree_stat('α', G_output.Nodes.alpha(i)); % fallback replaced below for tex
                a_str = strrep(a_str, 'α', '\alpha');
                stat_line = sprintf('[%s, %s, %s]', fmt_tree_stat('p', raw_p), fmt_tree_stat('q', adj_p), a_str);
            else
                stat_line = sprintf('[%s, %s]', fmt_tree_stat('p', raw_p), fmt_tree_stat('q', adj_p));
            end
            lbl_str = sprintf('{\\bf%s}\n%s', disp_name, stat_line);
        else
            lbl_str = sprintf('{\\bf%s}', disp_name);
        end

        text(ax, x_coords(i) - 0.08, y_coords(i) - 0.14, lbl_str, ...
            'Rotation', -32, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top', ...
            'FontSize', leaf_fs, ...
            'FontName', font_name, ...
            'Color', [0.10, 0.10, 0.10], ...
            'Interpreter', 'tex');
    else
        % Internal family node
        if has_stats
            adj_p = G_output.Nodes.corr_p(i);
            q_part = fmt_tree_stat('q_{FDR}', adj_p);
            if has_alpha_col && ~isnan(G_output.Nodes.alpha(i))
                a_part = fmt_tree_stat('\alpha', G_output.Nodes.alpha(i));
                q_str = sprintf('(%s, %s)', q_part, a_part);
            else
                q_str = sprintf('(%s)', q_part);
            end
        else
            q_str = '';
        end

        if isempty(preds)
            % Root node: centered cleanly above root marker
            lbl_str = strtrim(sprintf('{\\bf%s}  %s', disp_name, q_str));
            text(ax, x_coords(i), y_coords(i) + 0.16, lbl_str, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', internal_fs + 1.0, ...
                'FontName', font_name, ...
                'Color', [0.08, 0.08, 0.08], ...
                'Interpreter', 'tex');
        elseif numel(kids) == 1
            % Place extreme-left chain labels left; place interior left-branch chain labels right below incoming edge
            lbl_str = sprintf('{\\bf%s}\n%s', disp_name, q_str);
            min_x = min(x_coords);
            if x_coords(i) <= min_x + 0.50
                text(ax, x_coords(i) - 0.22, y_coords(i) - 0.02, lbl_str, ...
                    'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', internal_fs, ...
                    'FontName', font_name, ...
                    'Color', [0.10, 0.10, 0.10], ...
                    'Interpreter', 'tex');
            elseif x_coords(i) < root_x
                text(ax, x_coords(i) + 0.22, y_coords(i) - 0.10, lbl_str, ...
                    'HorizontalAlignment', 'left', ...
                    'VerticalAlignment', 'top', ...
                    'FontSize', internal_fs, ...
                    'FontName', font_name, ...
                    'Color', [0.10, 0.10, 0.10], ...
                    'Interpreter', 'tex');
            else
                text(ax, x_coords(i) + 0.22, y_coords(i) - 0.02, lbl_str, ...
                    'HorizontalAlignment', 'left', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', internal_fs, ...
                    'FontName', font_name, ...
                    'Color', [0.10, 0.10, 0.10], ...
                    'Interpreter', 'tex');
            end
        else
            % Branching internal node: place in upper quadrant opposite the incoming parent edge
            p_idx = preds(1);
            lbl_str = sprintf('{\\bf%s}\n%s', disp_name, q_str);
            if x_coords(p_idx) <= x_coords(i)
                text(ax, x_coords(i) + 0.20, y_coords(i) + 0.06, lbl_str, ...
                    'HorizontalAlignment', 'left', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontSize', internal_fs, ...
                    'FontName', font_name, ...
                    'Color', [0.10, 0.10, 0.10], ...
                    'Interpreter', 'tex');
            else
                text(ax, x_coords(i) - 0.20, y_coords(i) + 0.06, lbl_str, ...
                    'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontSize', internal_fs, ...
                    'FontName', font_name, ...
                    'Color', [0.10, 0.10, 0.10], ...
                    'Interpreter', 'tex');
            end
        end
    end
end

title(ax, title_str, 'FontSize', ttl_fs, 'FontWeight', 'bold', 'FontName', font_name, 'Interpreter', 'none');
axis(ax, 'off');

% Add Custom Legend
if show_legend
    hold(ax, 'on');
    h_leg = [];
    l_labels = {};

    h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.12, 0.53, 0.90], 'MarkerEdgeColor', 'k', 'MarkerSize', 11);
    l_labels{end+1} = 'Pre-Reg Significant (TreeBH FDR)';

    h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.65, 0.65, 0.65], 'MarkerEdgeColor', 'k', 'MarkerSize', 11);
    l_labels{end+1} = 'Pre-Reg Non-Significant';

    if highlight_posthoc
        h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.90, 0.45, 0.00], 'MarkerEdgeColor', 'k', 'MarkerSize', 11);
        l_labels{end+1} = 'Post-Hoc Significant (TreeBH FDR)';

        h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.95, 0.75, 0.50], 'MarkerEdgeColor', 'k', 'MarkerSize', 11);
        l_labels{end+1} = 'Post-Hoc Non-Significant';
    end

    legend(ax, h_leg, l_labels, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
        'Box', 'off', 'FontSize', leg_fs, 'FontName', font_name);
end

% Bounding box calibrated for compact leaf spacing and full unclipped rotated leaf labels
x_lo = min(x_coords) - 2.65;
x_hi = max(x_coords) + 3.90;
y_lo = 1.0 - 2.65;
y_hi = H + 0.65;

plot(ax, [x_lo, x_hi], [y_lo, y_hi], 'LineStyle', 'none', 'Marker', 'none', 'HandleVisibility', 'off');
ax.DataAspectRatioMode = 'auto';
ax.PlotBoxAspectRatioMode = 'auto';
xlim(ax, [x_lo, x_hi]);
ylim(ax, [y_lo, y_hi]);

if ~isempty(save_path_base)
    [parent_dir, ~, ~] = fileparts(save_path_base);
    if ~exist(parent_dir, 'dir')
        mkdir(parent_dir);
    end
    try
        savefig(fig_handle, [save_path_base, '.fig']);
    catch ME
        warning('Could not save .fig for %s: %s', save_path_base, ME.message);
    end
    try
        exportgraphics(fig_handle, [save_path_base, '.png'], 'Resolution', 300);
    catch ME
        warning('exportgraphics failed for %s: %s', save_path_base, ME.message);
    end
end

end

function out = fmt_tree_stat(name_str, val)
% Formats p, q, or alpha to <=3 decimal places without leading zero, and <.001 for < 0.001.
    if val < 0.001
        out = [name_str, '<.001'];
    else
        r = round(val, 3);
        if r >= 1
            s = '1';
        else
            s = sprintf('%.3f', r);
            s = regexprep(s, '(\.\d*?)0+$', '$1');
            s = regexprep(s, '\.$', '');
            s = regexprep(s, '^0\.', '.');
        end
        out = [name_str, '=', s];
    end
end

function [x_coords, y_coords, H, root_idx] = compute_bottom_aligned_tree_coords(G)
    n = G.numnodes;
    root_idx = find(indegree(G) == 0, 1);
    if isempty(root_idx)
        root_idx = 1;
    end

    depths = zeros(n, 1);
    queue = root_idx;
    while ~isempty(queue)
        u = queue(1);
        queue(1) = [];
        kids = G.successors(u);
        for k = 1:numel(kids)
            depths(kids(k)) = depths(u) + 1;
            queue(end+1) = kids(k); %#ok<AGROW>
        end
    end

    H = max(depths) + 1;
    x_coords = zeros(1, n);
    y_coords = zeros(1, n);

    for i = 1:n
        if isempty(G.successors(i))
            y_coords(i) = 1.0;
        else
            y_coords(i) = double(H - depths(i));
        end
    end

    state = struct('cur_x', 1.0, 'prev_parent', -1);
    [x_coords, ~] = dfs_assign_x(G, root_idx, -1, x_coords, state);
end

function [x_coords, state] = dfs_assign_x(G, u, parent_idx, x_coords, state)
    kids = G.successors(u);
    if isempty(kids)
        if state.prev_parent == -1
            x_coords(u) = state.cur_x;
        elseif state.prev_parent == parent_idx
            state.cur_x = state.cur_x + 1.15;
            x_coords(u) = state.cur_x;
        else
            state.cur_x = state.cur_x + 1.98;
            x_coords(u) = state.cur_x;
        end
        state.prev_parent = parent_idx;
    else
        for k = 1:numel(kids)
            [x_coords, state] = dfs_assign_x(G, kids(k), u, x_coords, state);
        end
        x_coords(u) = mean(x_coords(kids));
    end
end

function [disp_name] = format_tree_node_name(raw_name)
    switch raw_name
        case 'Pre_Registered'
            disp_name = 'Pre-Registered';
        case 'Post_Hoc'
            disp_name = 'Post-Hoc';
        case 'Confirmatory_KB'
            disp_name = 'Confirmatory (KB)';
        case 'Confirmatory_Reach'
            disp_name = 'Confirmatory (Reach)';
        case 'Exploratory_Reach'
            disp_name = 'Exploratory (Reach)';
        case 'Sensitivity_Advantage'
            disp_name = 'Sensitivity Advantage';
        case 'Keyboard_RT'
            disp_name = 'Keyboard RT';
        case 'Reach_Area'
            disp_name = 'Reach Area';
        case 'Reaching_Onset'
            disp_name = 'Reaching Onset';
        case 'Reaching_Duration_MT'
            disp_name = 'Reaching Duration';
        case 'Total_Distance'
            disp_name = 'Distance Traveled';
        case 'Changes_of_Mind_COM'
            disp_name = 'COM';
        case 'Spatial_Deviation_Cluster'
            disp_name = 'Deviance From Center';
        case 'Spatial_Variation_Cluster'
            disp_name = 'Horiz. Mvmnt Variation';
        case 'Implied_End_Point_Cluster'
            disp_name = 'Implied Endpoint';
        case 'Reach_Area_vs_KB'
            disp_name = 'Reach Area vs. KB';
        case 'Onset_vs_KB'
            disp_name = 'Reaching Onset vs. KB';
        case 'MT_vs_KB'
            disp_name = 'Reaching Duration vs. KB';
        case 'Total_Dist_vs_KB'
            disp_name = 'Distance Traveled vs. KB';
        case 'COM_vs_KB'
            disp_name = 'COM vs. KB';
        case 'Spatial_Dev_vs_KB'
            disp_name = 'Deviance From Center vs. KB';
        case 'Spatial_Var_vs_KB'
            disp_name = 'Horiz. Mvmnt Var. vs. KB';
        case 'MAD_vs_KB'
            disp_name = 'MAD vs. KB';
        case 'AUC_vs_KB'
            disp_name = 'AUC vs. KB';
        case 'IEP_vs_KB'
            disp_name = 'Implied Endpoint vs. KB';
        otherwise
            disp_name = strrep(raw_name, '_', ' ');
    end
end
