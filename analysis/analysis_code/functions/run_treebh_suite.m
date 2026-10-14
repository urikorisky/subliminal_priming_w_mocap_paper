function [full_stats_tables, tree_figs] = run_treebh_suite(full_stats_tables, within_tbl, fig_output_folder)
% RUN_TREEBH_SUITE Executes the complete multiple-comparisons architecture
%
% Implements:
%   - Tree 1: Main Text Unified Congruency Tree (Flavor 1, Post-Hoc Marked)
%   - Tree S1: Original Pre-Registered Tree (Flavor 1, Un-pruned Heading Angle)
%   - Tree S2: Parallel Standardized Robustness Tree (Flavor 2)
%   - Tree 2: Relative Sensitivity Tree (Flavor 1 vs. Keyboard RT)
%   - Flavor 3: Chronological Trajectory Dynamics (Components 4 & 6)
%
% Generates publication figures, structured output tables, and updates stats struct.

if nargin < 3 || isempty(fig_output_folder)
    fig_output_folder = '../figures/TreeBH';
end

if ~exist(fig_output_folder, 'dir')
    mkdir(fig_output_folder);
end

tree_figs = struct();
alpha_level = 0.05;

%% 1. Tree 1: Main Text Unified Congruency (Flavor 1)
fprintf('\n======================================================\n');
fprintf('Running Tree 1: Main Text Unified Congruency (Flavor 1)\n');
fprintf('======================================================\n');
[G1, ~] = build_tree_graph('Tree1_Main', full_stats_tables);
[G1_out, ~] = treeBH(G1, 0, 0, 1, alpha_level);

fig1_path = fullfile(fig_output_folder, 'Fig_TreeBH_Congruency_Unified');
tree_figs.Tree1_Main = plot_treebh_figure(G1_out, 'Tree 1: Unified Congruency Effects (Flavor 1)', fig1_path, true);

tbl_tree1 = extract_tree_table(G1_out);
disp(tbl_tree1);

% Update analyzed_stats_tables and fullTrajAnalysis with Tree 1 corrected p-values
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
for v = 1:size(var_map, 1)
    n_idx = find(strcmp(G1_out.Nodes.name, var_map{v, 1}));
    if ~isempty(n_idx)
        q_val = G1_out.Nodes.corr_p(n_idx);
        row_idx = find(full_stats_tables.analyzed_stats_tables.name == var_map{v, 2} & full_stats_tables.analyzed_stats_tables.Within_Participant_Standardization == false);
        if ~isempty(row_idx)
            full_stats_tables.analyzed_stats_tables(row_idx, newColName) = table(q_val);
        end
    end
end
if isfield(full_stats_tables, 'fullTrajAnalysis') && istable(full_stats_tables.fullTrajAnalysis)
    dev_n_idx = find(startsWith(G1_out.Nodes.name, 'Spatial_Deviation_Cluster'));
    if ~isempty(dev_n_idx)
        q_val = G1_out.Nodes.corr_p(dev_n_idx(1));
        row_idx = find(full_stats_tables.fullTrajAnalysis.name == "Deviation From center" & full_stats_tables.fullTrajAnalysis.Flavor == "TrajNorm_noStandardization");
        if ~isempty(row_idx)
            full_stats_tables.fullTrajAnalysis(row_idx, newColName) = table(q_val);
        end
    end
    var_n_idx = find(startsWith(G1_out.Nodes.name, 'Spatial_Variation_Cluster'));
    if ~isempty(var_n_idx)
        q_val = G1_out.Nodes.corr_p(var_n_idx(1));
        row_idx = find(full_stats_tables.fullTrajAnalysis.name == "Movement variation" & full_stats_tables.fullTrajAnalysis.Flavor == "TrajNorm_noStandardization");
        if ~isempty(row_idx)
            full_stats_tables.fullTrajAnalysis(row_idx, newColName) = table(q_val);
        end
    end
    iep_n_idx = find(startsWith(G1_out.Nodes.name, 'Implied_End_Point_Cluster'));
    if ~isempty(iep_n_idx)
        q_val = G1_out.Nodes.corr_p(iep_n_idx(1));
        row_idx = find(full_stats_tables.fullTrajAnalysis.name == "iEP" & full_stats_tables.fullTrajAnalysis.Flavor == "TrajNorm_noStandardization");
        if ~isempty(row_idx)
            full_stats_tables.fullTrajAnalysis(row_idx, newColName) = table(q_val);
        end
    end
end

%% 2. Tree S1: Original Pre-Registered Tree (SI, Flavor 1)
fprintf('\n======================================================\n');
fprintf('Running Tree S1: Original Pre-Registered Tree (SI, Flavor 1)\n');
fprintf('======================================================\n');
[GS1, ~] = build_tree_graph('TreeS1_Original', full_stats_tables);
[GS1_out, ~] = treeBH(GS1, 0, 0, 1, alpha_level);

figS1_path = fullfile(fig_output_folder, 'SuppFig_1_TreeBH_OriginalPreReg');
tree_figs.TreeS1_Original = plot_treebh_figure(GS1_out, 'Tree S1: Original Pre-Registered Tree (Flavor 1)', figS1_path, false);

tbl_treeS1 = extract_tree_table(GS1_out);
disp(tbl_treeS1);

%% 3. Tree S2: Standardized Robustness Tree (SI, Flavor 2)
fprintf('\n======================================================\n');
fprintf('Running Tree S2: Standardized Robustness Tree (SI, Flavor 2)\n');
fprintf('======================================================\n');
[GS2, ~] = build_tree_graph('TreeS2_Standard', full_stats_tables);
[GS2_out, ~] = treeBH(GS2, 0, 0, 1, alpha_level);

figS2_path = fullfile(fig_output_folder, 'SuppFig_2_TreeBH_Standardized');
tree_figs.TreeS2_Standard = plot_treebh_figure(GS2_out, 'Tree S2: Standardized Robustness Tree (Flavor 2)', figS2_path, true);

tbl_treeS2 = extract_tree_table(GS2_out);
disp(tbl_treeS2);

%% 4. Tree 2: Relative Sensitivity Tree (Main Text, Flavor 1 vs Keyboard RT)
fprintf('\n======================================================\n');
fprintf('Running Tree 2: Relative Sensitivity Tree (Flavor 1 vs. Keyboard RT)\n');
fprintf('======================================================\n');
[G2, ~] = build_tree_graph('Tree2_Sensitivity', full_stats_tables, within_tbl);
[G2_out, ~] = treeBH(G2, 0, 0, 1, alpha_level);

fig2_path = fullfile(fig_output_folder, 'Fig_TreeBH_Sensitivity_Comparisons');
tree_figs.Tree2_Sensitivity = plot_treebh_figure(G2_out, 'Tree 2: Relative Sensitivity Contrasts vs. Keyboard RT (Flavor 1)', fig2_path, false);

tbl_tree2 = extract_tree_table(G2_out);
disp(tbl_tree2);

%% 5. Tree SI2: Standardized Robustness Tree for Sensitivity (SI, Flavor 2 vs Keyboard RT)
fprintf('\n======================================================\n');
fprintf('Running Tree SI2: Standardized Robustness Tree for Sensitivity (Flavor 2 vs. Keyboard RT)\n');
fprintf('======================================================\n');
[GSI2, ~] = build_tree_graph('TreeSI2_Standard', full_stats_tables, within_tbl);
[GSI2_out, ~] = treeBH(GSI2, 0, 0, 1, alpha_level);

figSI2_path = fullfile(fig_output_folder, 'SuppFig_SI2_TreeBH_Sensitivity_Standardized');
tree_figs.TreeSI2_Sensitivity_Standard = plot_treebh_figure(GSI2_out, 'Tree SI2: Relative Sensitivity Contrasts vs. Keyboard RT (Flavor 2)', figSI2_path, false);

tbl_treeSI2 = extract_tree_table(GSI2_out);
disp(tbl_treeSI2);

%% 6. Chronological Time Domain (Flavor 3, Components 4 & 6)
chrono_results = analyze_chronological_time_domain(full_stats_tables, within_tbl);

%% 7. Attach to Master Stats Struct
full_stats_tables.TreeBH_Results = struct();
full_stats_tables.TreeBH_Results.Tree1_Main_Table     = tbl_tree1;
full_stats_tables.TreeBH_Results.TreeS1_PreReg_Table  = tbl_treeS1;
full_stats_tables.TreeBH_Results.TreeS2_Standard_Table = tbl_treeS2;
full_stats_tables.TreeBH_Results.Tree2_Sensitivity_Table = tbl_tree2;
full_stats_tables.TreeBH_Results.TreeSI2_Sensitivity_Standard_Table = tbl_treeSI2;
full_stats_tables.TreeBH_Results.Component4_Continuous_FDR = chrono_results.Component4_Continuous_FDR;
full_stats_tables.TreeBH_Results.Component6_Sensitivity_Contrasts = chrono_results.Component6_Sensitivity_Contrasts;

full_stats_tables.TreeBH_Results.Graphs = struct();
full_stats_tables.TreeBH_Results.Graphs.G1_out   = G1_out;
full_stats_tables.TreeBH_Results.Graphs.GS1_out  = GS1_out;
full_stats_tables.TreeBH_Results.Graphs.GS2_out  = GS2_out;
full_stats_tables.TreeBH_Results.Graphs.G2_out   = G2_out;
full_stats_tables.TreeBH_Results.Graphs.GSI2_out = GSI2_out;

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
    branch_type(G.Nodes.is_posthoc & is_leaf) = "PostHoc_Leaf";
    branch_type(~G.Nodes.is_posthoc & is_leaf) = "PreReg_Leaf";
else
    branch_type(is_leaf) = "Leaf";
end

t = table(node_names, branch_type, raw_p, adj_p, alpha_crit, rejected, ...
    'VariableNames', {'Node_Name', 'Node_Type', 'Uncorrected_p', 'Within_Family_FDR_q', 'Alpha_Threshold', 'Significant_TreeBH'});
end
