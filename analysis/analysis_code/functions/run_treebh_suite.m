function [full_stats_tables, tree_figs] = run_treebh_suite(full_stats_tables, within_tbl, fig_output_folder)
% RUN_TREEBH_SUITE Executes the complete multiple-comparisons architecture
%
% Implements:
%   - Tree 1: Congruency Effect Analysis (TrajNorm_noStandardization)
%   - Tree 2: Sensitivity Analysis vs. Keyboard RT (TrajNorm_noStandardization)
%   - Figure S1: Original Pre-Registered Congruency Effect Analysis (TrajNorm_noStandardization)
%   - Figure S2 (a): Robustness Test of Tree 1 (TrajNorm_Standardization)
%   - Figure S2 (b): Robustness Test of Tree 2 (TrajNorm_Standardization)
%   - Combined Figure S2: Stacked 2-panel (a) & (b) figure
%   - Chronological Trajectory Dynamics (noTrajNorm_noStandardization, Components 4 & 6)

if nargin < 3 || isempty(fig_output_folder)
    fig_output_folder = '../figures/TreeBH';
end

if ~exist(fig_output_folder, 'dir')
    mkdir(fig_output_folder);
end

tree_figs = struct();
alpha_level = 0.05;

%% 1. Tree 1: Congruency Effect Analysis (TrajNorm_noStandardization)
fprintf('\n======================================================\n');
fprintf('Running Tree 1: Congruency Effect Analysis (TrajNorm_noStandardization)\n');
fprintf('======================================================\n');
[G1, ~] = build_tree_graph('Tree1_Main', full_stats_tables);
[G1_out, ~] = treeBH(G1, 0, 0, 1, alpha_level);

fig1_path = fullfile(fig_output_folder, 'Tree_1_Congruency');
tree_figs.Tree_1 = plot_treebh_figure(G1_out, ...
    'Tree 1: Congruency Effect Analysis (TrajNorm_noStandardization)', fig1_path, true);

tbl_tree1 = extract_tree_table(G1_out);
disp(tbl_tree1);

%% 2. Tree 2: Sensitivity Analysis (TrajNorm_noStandardization)
fprintf('\n======================================================\n');
fprintf('Running Tree 2: Sensitivity Analysis (TrajNorm_noStandardization)\n');
fprintf('======================================================\n');
[G2, ~] = build_tree_graph('Tree2_Sensitivity', full_stats_tables, within_tbl);
[G2_out, ~] = treeBH(G2, 0, 0, 1, alpha_level);

fig2_path = fullfile(fig_output_folder, 'Tree_2_Sensitivity');
tree_figs.Tree_2 = plot_treebh_figure(G2_out, ...
    'Tree 2: Sensitivity Analysis vs. Keyboard RT (TrajNorm_noStandardization)', fig2_path, true);

tbl_tree2 = extract_tree_table(G2_out);
disp(tbl_tree2);

%% 3. Figure S1: Original Pre-Registered Congruency Effect Analysis (TrajNorm_noStandardization)
fprintf('\n======================================================\n');
fprintf('Running Figure S1: Original Pre-Registered Congruency Tree\n');
fprintf('======================================================\n');
[GS1, ~] = build_tree_graph('TreeS1_Original', full_stats_tables);
[GS1_out, ~] = treeBH(GS1, 0, 0, 1, alpha_level);

figS1_path = fullfile(fig_output_folder, 'Figure_S1');
tree_figs.Figure_S1 = plot_treebh_figure(GS1_out, ...
    'Figure S1: Original Pre-Registered Congruency Effect Analysis (TrajNorm_noStandardization)', figS1_path, false);

tbl_figS1 = extract_tree_table(GS1_out);
disp(tbl_figS1);

%% 4. Figure S2 (a): Robustness Test of Tree 1 (TrajNorm_Standardization)
fprintf('\n======================================================\n');
fprintf('Running Figure S2 (a): Congruency Robustness Tree (TrajNorm_Standardization)\n');
fprintf('======================================================\n');
[GS2a, ~] = build_tree_graph('TreeS2_Standard', full_stats_tables);
[GS2a_out, ~] = treeBH(GS2a, 0, 0, 1, alpha_level);

figS2a_path = fullfile(fig_output_folder, 'Figure_S2a');
tree_figs.Figure_S2a = plot_treebh_figure(GS2a_out, ...
    'Figure S2 (a): Congruency Effect Robustness Analysis (TrajNorm_Standardization)', figS2a_path, true);

tbl_figS2a = extract_tree_table(GS2a_out);
disp(tbl_figS2a);

%% 5. Figure S2 (b): Robustness Test of Tree 2 (TrajNorm_Standardization)
fprintf('\n======================================================\n');
fprintf('Running Figure S2 (b): Sensitivity Robustness Tree (TrajNorm_Standardization)\n');
fprintf('======================================================\n');
[GS2b, ~] = build_tree_graph('TreeSI2_Standard', full_stats_tables, within_tbl);
[GS2b_out, ~] = treeBH(GS2b, 0, 0, 1, alpha_level);

figS2b_path = fullfile(fig_output_folder, 'Figure_S2b');
tree_figs.Figure_S2b = plot_treebh_figure(GS2b_out, ...
    'Figure S2 (b): Sensitivity Robustness Analysis vs. Keyboard RT (TrajNorm_Standardization)', figS2b_path, true);

tbl_figS2b = extract_tree_table(GS2b_out);
disp(tbl_figS2b);

%% 6. Combined 2-Panel Figure S2 ((a) stacked above (b))
fig_s2_comb = figure('Name', 'Figure S2: Standardized Robustness Trees', ...
    'Color', 'w', 'Position', [60, 40, 1500, 1450]);
tl_s2 = tiledlayout(fig_s2_comb, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax_s2a = nexttile(tl_s2, 1);
plot_treebh_figure(GS2a_out, ...
    '(a) Congruency Effect Robustness Analysis (TrajNorm_Standardization)', '', true, ax_s2a, false);

ax_s2b = nexttile(tl_s2, 2);
plot_treebh_figure(GS2b_out, ...
    '(b) Sensitivity Robustness Analysis vs. Keyboard RT (TrajNorm_Standardization)', '', true, ax_s2b, true);

figS2_comb_path = fullfile(fig_output_folder, 'Figure_S2');
try, savefig(fig_s2_comb, [figS2_comb_path, '.fig']); catch, end
try
    exportgraphics(fig_s2_comb, [figS2_comb_path, '.png'], 'Resolution', 300);
catch
    print(fig_s2_comb, [figS2_comb_path, '.png'], '-dpng', '-r300');
end
try
    exportgraphics(fig_s2_comb, [figS2_comb_path, '.svg'], 'ContentType', 'vector');
catch
end
tree_figs.Figure_S2 = fig_s2_comb;

%% 7. Populate p_Val_TreeBH_Corrected in analyzed_stats_tables & fullTrajAnalysis
newColName = 'p_Val_TreeBH_Corrected';
var_map = {
    'Keyboard_RT', 'Keyboard RT';
    'Reach_Area', 'Reach Area';
    'Reaching_Onset', 'Reaching Onset';
    'Reaching_Duration_MT', 'Reaching Duration';
    'Total_Distance', 'Total Distance Traveled';
    'Changes_of_Mind_COM', 'Num of COM';
    'MAD', 'Maximum Absolute Deviation (MAD)';
    'AUC', 'Area Under Curve (AUC)'
};

if isfield(full_stats_tables, 'analyzed_stats_tables') && istable(full_stats_tables.analyzed_stats_tables)
    full_stats_tables.analyzed_stats_tables.(newColName) = NaN(height(full_stats_tables.analyzed_stats_tables), 1);
    for v = 1:size(var_map, 1)
        % Raw flavor (Tree 1)
        n_idx1 = find(strcmp(G1_out.Nodes.name, var_map{v, 1}));
        if ~isempty(n_idx1)
            q_val1 = G1_out.Nodes.corr_p(n_idx1(1));
            r_idx1 = find(full_stats_tables.analyzed_stats_tables.name == var_map{v, 2} & ...
                          full_stats_tables.analyzed_stats_tables.Within_Participant_Standardization == false);
            if ~isempty(r_idx1)
                full_stats_tables.analyzed_stats_tables.(newColName)(r_idx1) = q_val1;
            end
        end
        % Standardized flavor (Figure S2a)
        n_idx2 = find(strcmp(GS2a_out.Nodes.name, var_map{v, 1}));
        if ~isempty(n_idx2)
            q_val2 = GS2a_out.Nodes.corr_p(n_idx2(1));
            r_idx2 = find(full_stats_tables.analyzed_stats_tables.name == var_map{v, 2} & ...
                          full_stats_tables.analyzed_stats_tables.Within_Participant_Standardization == true);
            if ~isempty(r_idx2)
                full_stats_tables.analyzed_stats_tables.(newColName)(r_idx2) = q_val2;
            end
        end
    end
end

%% 8. Chronological Time Domain (noTrajNorm_noStandardization, Components 4 & 6)
chrono_results = analyze_chronological_time_domain(full_stats_tables, within_tbl);

% Populate corrected p-values in fullTrajAnalysis:
% - TrajNorm_noStandardization: Tree 1 q-values
% - noTrajNorm_noStandardization: Component 4 BH-FDR q-values
if isfield(full_stats_tables, 'fullTrajAnalysis') && istable(full_stats_tables.fullTrajAnalysis)
    full_stats_tables.fullTrajAnalysis.(newColName) = NaN(height(full_stats_tables.fullTrajAnalysis), 1);

    traj_node_map = {
        'Spatial_Deviation_Cluster', 'Deviation From center';
        'Spatial_Variation_Cluster', 'Movement variation';
        'Implied_End_Point_Cluster', 'iEP'
    };
    for tm = 1:size(traj_node_map, 1)
        t_idx = find(startsWith(G1_out.Nodes.name, traj_node_map{tm, 1}));
        if ~isempty(t_idx)
            q_val = G1_out.Nodes.corr_p(t_idx(1));
            row_idx = find(full_stats_tables.fullTrajAnalysis.name == traj_node_map{tm, 2} & ...
                           full_stats_tables.fullTrajAnalysis.Flavor == "TrajNorm_noStandardization");
            if ~isempty(row_idx)
                full_stats_tables.fullTrajAnalysis.(newColName)(row_idx) = q_val;
            end
        end
    end

    c4 = chrono_results.Component4_Continuous_FDR;
    c4_map = {
        'Deviation_From_Center', 'Deviation From center';
        'Implied_End_Point',     'iEP';
        'Heading_Angle',         'Heading angle';
        'Movement_Variation',    'Movement variation'
    };
    for cm = 1:size(c4_map, 1)
        c_row = find(c4.Metric == c4_map{cm, 1}, 1);
        if ~isempty(c_row)
            q_val = c4.FDR_adj_p(c_row);
            row_idx = find(full_stats_tables.fullTrajAnalysis.name == c4_map{cm, 2} & ...
                           full_stats_tables.fullTrajAnalysis.Flavor == "noTrajNorm_noStandardization");
            if ~isempty(row_idx)
                full_stats_tables.fullTrajAnalysis.(newColName)(row_idx) = q_val;
            end
        end
    end
end

%% 9. Attach to Master Stats Struct
full_stats_tables.TreeBH_Results = struct();
full_stats_tables.TreeBH_Results.Tree1_Congruency_Table = tbl_tree1;
full_stats_tables.TreeBH_Results.Tree2_Sensitivity_Table = tbl_tree2;
full_stats_tables.TreeBH_Results.FigS1_Original_PreReg_Table = tbl_figS1;
full_stats_tables.TreeBH_Results.FigS2a_Congruency_Std_Table = tbl_figS2a;
full_stats_tables.TreeBH_Results.FigS2b_Sensitivity_Std_Table = tbl_figS2b;
full_stats_tables.TreeBH_Results.Component4_Continuous_FDR = chrono_results.Component4_Continuous_FDR;
full_stats_tables.TreeBH_Results.Component6_Sensitivity_Contrasts = chrono_results.Component6_Sensitivity_Contrasts;

full_stats_tables.TreeBH_Results.Graphs = struct();
full_stats_tables.TreeBH_Results.Graphs.G1_out   = G1_out;
full_stats_tables.TreeBH_Results.Graphs.G2_out   = G2_out;
full_stats_tables.TreeBH_Results.Graphs.GS1_out  = GS1_out;
full_stats_tables.TreeBH_Results.Graphs.GS2a_out = GS2a_out;
full_stats_tables.TreeBH_Results.Graphs.GS2b_out = GS2b_out;

fprintf('\nAll TreeBH analyses and figures completed successfully!\n');

end

%% Helper: Extract Formatted Table from TreeBH Digraph
function t = extract_tree_table(G)
node_names = string(G.Nodes.name);
raw_p      = G.Nodes.p;
adj_p      = G.Nodes.corr_p;
is_leaf    = arrayfun(@(x) isempty(G.successors(x)), 1:G.numnodes)';
rejected   = logical(G.Nodes.reject);
alpha_crit = G.Nodes.alpha;

branch_type = repmat("Internal_Family", G.numnodes, 1);
if ismember('is_posthoc', G.Nodes.Properties.VariableNames)
    branch_type(G.Nodes.is_posthoc & is_leaf)  = "PostHoc_Leaf";
    branch_type(~G.Nodes.is_posthoc & is_leaf) = "PreReg_Leaf";
else
    branch_type(is_leaf) = "Leaf";
end

t = table(node_names, branch_type, raw_p, adj_p, alpha_crit, rejected, ...
    'VariableNames', {'Node_Name', 'Node_Type', 'Uncorrected_p', 'Within_Family_FDR_q', 'Alpha_Threshold', 'Significant_TreeBH'});
end
