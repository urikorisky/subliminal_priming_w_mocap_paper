function [fig_handle] = plot_treebh_figure(G_output, title_str, save_path_base, highlight_posthoc, target_ax, show_legend)
% PLOT_TREEBH_FIGURE Generates publication-ready vector figures for TreeBH trees
% Uses a bottom-aligned leaf layout so all leaf hypotheses sit on a single bottom row
% and internal/leaf labels never collide with branches, displaying p, q, and alpha on nodes.
%
% Inputs:
%   G_output          - Digraph output returned by treeBH.m
%   title_str         - Title string for the figure/panel
%   save_path_base    - Base file path (without extension) for saving .fig, .png, .svg ('' to skip)
%   highlight_posthoc - Boolean: if true, highlights the Post-Hoc branch in vivid orange/peach
%   target_ax         - Optional existing axes handle (for multi-panel figures such as Figure S2)
%   show_legend       - Optional boolean (default true)

if nargin < 4 || isempty(highlight_posthoc)
    highlight_posthoc = false;
end
if nargin < 5
    target_ax = [];
end
if nargin < 6 || isempty(show_legend)
    show_legend = true;
end

is_multipanel = ~isempty(target_ax);
if ~is_multipanel
    fig_handle = figure('Name', title_str, 'Color', 'w', 'Position', [50, 50, 1620, 880]);
    ax = axes('Parent', fig_handle);
else
    ax = target_ax;
    fig_handle = ancestor(ax, 'figure');
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

% Compute clean bottom-aligned hierarchical coordinates
[x_coords, y_coords, H] = compute_bottom_aligned_tree_coords(G_output);

% Plot tree graph without MATLAB's single-line auto-labels
p_graph = plot(ax, G_output, ...
    'XData', x_coords, ...
    'YData', y_coords, ...
    'NodeLabel', {}, ...
    'NodeColor', node_colors, ...
    'MarkerSize', 12, ...
    'LineWidth', 1.8, ...
    'ArrowSize', 8, ...
    'EdgeColor', [0.55, 0.55, 0.55]);

% Highlight Post-Hoc edges when enabled
if highlight_posthoc
    edge_table = G_output.Edges;
    for e = 1:height(edge_table)
        source_idx = edge_table.EndNodes(e, 1);
        target_idx = edge_table.EndNodes(e, 2);
        if is_posthoc(target_idx)
            highlight(p_graph, source_idx, target_idx, 'EdgeColor', [0.90, 0.45, 0.00], 'LineWidth', 2.6);
        end
    end
end

% Overlay unclipped node circles so GraphPlot internal edge-highlight bounds never flatten rightmost marker
scatter(ax, x_coords, y_coords, 135, node_colors, 'filled', ...
    'Clipping', 'off', 'HandleVisibility', 'off');

% Render crisp multi-line text labels with collision-free quadrant placement
if is_multipanel
    internal_fs = 8.2;
    leaf_fs     = 7.8;
else
    internal_fs = 8.8;
    leaf_fs     = 8.3;
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
                stat_line = sprintf('[p=%.4f, q=%.4f, \\alpha=%.4f]', raw_p, adj_p, G_output.Nodes.alpha(i));
            else
                stat_line = sprintf('[p=%.4f, q=%.4f]', raw_p, adj_p);
            end
            lbl_str = sprintf('{\\bf%s}\n%s', disp_name, stat_line);
        else
            lbl_str = sprintf('{\\bf%s}', disp_name);
        end

        text(ax, x_coords(i) - 0.05, y_coords(i) - 0.13, lbl_str, ...
            'Rotation', -30, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top', ...
            'FontSize', leaf_fs, ...
            'FontName', 'Arial', ...
            'Color', [0.12, 0.12, 0.12], ...
            'Interpreter', 'tex');
    else
        % Internal family node
        if has_stats
            adj_p = G_output.Nodes.corr_p(i);
            if has_alpha_col && ~isnan(G_output.Nodes.alpha(i))
                q_str = sprintf('(q_{FDR}=%.4f, \\alpha=%.4f)', adj_p, G_output.Nodes.alpha(i));
            else
                q_str = sprintf('(q_{FDR}=%.4f)', adj_p);
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
                'FontSize', internal_fs + 0.5, ...
                'FontName', 'Arial', ...
                'Color', [0.10, 0.10, 0.10], ...
                'Interpreter', 'tex');
        elseif numel(kids) == 1
            % Vertical single-child chain node: place 2-line label cleanly to the right
            lbl_str = sprintf('{\\bf%s}\n%s', disp_name, q_str);
            text(ax, x_coords(i) + 0.20, y_coords(i) - 0.03, lbl_str, ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top', ...
                'FontSize', internal_fs, ...
                'FontName', 'Arial', ...
                'Color', [0.12, 0.12, 0.12], ...
                'Interpreter', 'tex');
        else
            % Branching internal node: place in upper quadrant opposite the incoming parent edge
            p_idx = preds(1);
            lbl_str = sprintf('{\\bf%s}\n%s', disp_name, q_str);
            if x_coords(p_idx) <= x_coords(i)
                text(ax, x_coords(i) + 0.18, y_coords(i) + 0.06, lbl_str, ...
                    'HorizontalAlignment', 'left', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontSize', internal_fs, ...
                    'FontName', 'Arial', ...
                    'Color', [0.12, 0.12, 0.12], ...
                    'Interpreter', 'tex');
            else
                text(ax, x_coords(i) - 0.18, y_coords(i) + 0.06, lbl_str, ...
                    'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontSize', internal_fs, ...
                    'FontName', 'Arial', ...
                    'Color', [0.12, 0.12, 0.12], ...
                    'Interpreter', 'tex');
            end
        end
    end
end

title(ax, title_str, 'FontSize', 13, 'FontWeight', 'bold', 'Interpreter', 'none');
axis(ax, 'off');

% Add Custom Legend
if show_legend
    hold(ax, 'on');
    h_leg = [];
    l_labels = {};

    h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.12, 0.53, 0.90], 'MarkerEdgeColor', 'k', 'MarkerSize', 9);
    l_labels{end+1} = 'Pre-Reg Significant (TreeBH FDR)';

    h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.65, 0.65, 0.65], 'MarkerEdgeColor', 'k', 'MarkerSize', 9);
    l_labels{end+1} = 'Pre-Reg Non-Significant';

    if highlight_posthoc
        h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.90, 0.45, 0.00], 'MarkerEdgeColor', 'k', 'MarkerSize', 9);
        l_labels{end+1} = 'Post-Hoc Significant (TreeBH FDR)';

        h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.95, 0.75, 0.50], 'MarkerEdgeColor', 'k', 'MarkerSize', 9);
        l_labels{end+1} = 'Post-Hoc Non-Significant';
    end

    legend(ax, h_leg, l_labels, 'Location', 'southoutside', 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 9.5);
end

% Anchor data bounding box with an invisible line so exportgraphics tight-limit pass never clips edge markers
plot(ax, [min(x_coords) - 0.80, max(x_coords) + 3.30], [1.0 - 1.50, H + 0.55], ...
    'LineStyle', 'none', 'Marker', 'none', 'HandleVisibility', 'off');
ax.DataAspectRatioMode = 'auto';
ax.PlotBoxAspectRatioMode = 'auto';
xlim(ax, [min(x_coords) - 0.80, max(x_coords) + 3.30]);
ylim(ax, [1.0 - 1.50, H + 0.55]);

% Save outputs if save_path_base provided
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
        warning('exportgraphics failed for %s: %s. Falling back to print...', save_path_base, ME.message);
        try
            print(fig_handle, [save_path_base, '.png'], '-dpng', '-r300');
        catch ME2
            warning('Fallback print failed for %s: %s', save_path_base, ME2.message);
        end
    end

    try
        exportgraphics(fig_handle, [save_path_base, '.svg'], 'ContentType', 'vector');
    catch ME
        warning('Could not save .svg for %s: %s', save_path_base, ME.message);
    end
end

end

function [x_coords, y_coords, H] = compute_bottom_aligned_tree_coords(G)
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
            state.cur_x = state.cur_x + 1.40;
            x_coords(u) = state.cur_x;
        else
            state.cur_x = state.cur_x + 2.55;
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
        otherwise
            disp_name = strrep(raw_name, '_', ' ');
    end
end
