function [fig_handle] = plot_treebh_figure(G_output, title_str, save_path_base, is_tree1)
% PLOT_TREEBH_FIGURE Generates publication-ready vector figures for TreeBH trees
%
% Inputs:
%   G_output       - Digraph output returned by treeBH.m
%   title_str      - Title string for the figure
%   save_path_base - Base file path (without extension) for saving .fig, .png, .svg
%   is_tree1       - Boolean: if true, explicitly highlights the post-hoc branch in a distinct color

if nargin < 4
    is_tree1 = false;
end

fig_handle = figure('Name', title_str, 'Color', 'w', 'Position', [100, 100, 1200, 750]);
ax = axes('Parent', fig_handle);
hold(ax, 'on');

% Determine node rejection and colors
num_nodes = G_output.numnodes;
is_rejected = false(num_nodes, 1);
if ismember('reject', G_output.Nodes.Properties.VariableNames)
    is_rejected = logical(G_output.Nodes.reject);
end

% Check if is_posthoc property exists
is_posthoc = false(num_nodes, 1);
if ismember('is_posthoc', G_output.Nodes.Properties.VariableNames)
    is_posthoc = logical(G_output.Nodes.is_posthoc);
end

% Set up node colors
% Confirmatory / PR Exploratory: Green/Cyan if rejected, Grey if not rejected
% Post-Hoc Exploratory: Distinct Orange/Coral if rejected, Light Orange if not rejected
node_colors = zeros(num_nodes, 3);
for i = 1:num_nodes
    if is_tree1 && is_posthoc(i)
        if is_rejected(i)
            node_colors(i, :) = [0.90, 0.45, 0.00]; % Vivid Coral/Orange for Significant Post-Hoc
        else
            node_colors(i, :) = [0.95, 0.75, 0.50]; % Light Peach for Non-Significant Post-Hoc
        end
    else
        if is_rejected(i)
            node_colors(i, :) = [0.12, 0.53, 0.90]; % Vivid Blue for Significant Confirmatory/PR
        else
            node_colors(i, :) = [0.65, 0.65, 0.65]; % Neutral Grey for Non-Significant
        end
    end
end

% Build clean node labels
node_labels = cell(num_nodes, 1);
for i = 1:num_nodes
    name_clean = strrep(G_output.Nodes.name{i}, '_', ' ');
    if ismember('corr_p', G_output.Nodes.Properties.VariableNames) && ~isnan(G_output.Nodes.corr_p(i))
        raw_p = G_output.Nodes.p(i);
        adj_p = G_output.Nodes.corr_p(i);
        if isempty(G_output.successors(i))
            % Leaf node
            if isnan(raw_p)
                node_labels{i} = sprintf('%s\n(Pruned)', name_clean);
            elseif ismember('alpha', G_output.Nodes.Properties.VariableNames) && G_output.Nodes.alpha(i) < 0.0499
                node_labels{i} = sprintf('%s\n[p=%.4f, q=%.4f, \\alpha=%.4f]', name_clean, raw_p, adj_p, G_output.Nodes.alpha(i));
            else
                node_labels{i} = sprintf('%s\n[p=%.4f, q=%.4f]', name_clean, raw_p, adj_p);
            end
        else
            % Internal family node
            node_labels{i} = sprintf('%s\n(q_{FDR}=%.4f)', name_clean, adj_p);
        end
    else
        node_labels{i} = name_clean;
    end
end

% Plot tree layout
p_graph = plot(ax, G_output, 'Layout', 'layered', ...
    'Direction', 'down', ...
    'NodeLabel', node_labels, ...
    'NodeColor', node_colors, ...
    'MarkerSize', 12, ...
    'LineWidth', 1.8, ...
    'ArrowSize', 8, ...
    'EdgeColor', [0.35, 0.35, 0.35], ...
    'NodeFontSize', 9, ...
    'NodeFontName', 'Arial');

% Highlight Post-Hoc edges if Tree 1
if is_tree1
    edge_table = G_output.Edges;
    for e = 1:height(edge_table)
        source_idx = edge_table.EndNodes(e, 1);
        target_idx = edge_table.EndNodes(e, 2);
        if is_posthoc(target_idx)
            highlight(p_graph, source_idx, target_idx, 'EdgeColor', [0.90, 0.45, 0.00], 'LineWidth', 2.8);
        end
    end
end

title(ax, title_str, 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
axis(ax, 'off');

% Add Custom Legend
hold(ax, 'on');
h_leg = [];
l_labels = {};

h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.12, 0.53, 0.90], 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
l_labels{end+1} = 'Pre-Reg Significant (TreeBH FDR)';

h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.65, 0.65, 0.65], 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
l_labels{end+1} = 'Pre-Reg Non-Significant';

if is_tree1
    h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.90, 0.45, 0.00], 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
    l_labels{end+1} = 'Post-Hoc Significant (TreeBH FDR)';
    
    h_leg(end+1) = plot(ax, NaN, NaN, 'o', 'MarkerFaceColor', [0.95, 0.75, 0.50], 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
    l_labels{end+1} = 'Post-Hoc Non-Significant';
end

legend(ax, h_leg, l_labels, 'Location', 'southoutside', 'Orientation', 'horizontal', 'Box', 'off', 'FontSize', 9);

% Save outputs if save path provided
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
