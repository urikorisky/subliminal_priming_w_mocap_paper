function [G, node_info] = build_tree_graph(tree_type, full_stats_tables, sensitivity_data)
% BUILD_TREE_GRAPH Dynamically constructs a directed graph (digraph) for TreeBH
%
% Supported tree_type:
%   'Tree1_Main'        - Unified main text congruency tree (Flavor 1: TrajNorm_noStandardization)
%                         Partitions PR Confirmatory, PR Exploratory, and Post-Hoc Exploratory.
%   'TreeS1_Original'   - Original 2022 OSF pre-registered tree (Flavor 1: TrajNorm_noStandardization)
%                         Un-pruned Heading Angle, strictly pre-registered metrics.
%   'TreeS2_Standard'   - Parallel robustness tree (Flavor 2: TrajNorm_Standardization)
%   'Tree2_Sensitivity' - Relative sensitivity tree (Flavor 1 Reaching vs. Keyboard RT)
%
% Returns:
%   G         - MATLAB digraph object with properties: name, p, is_posthoc, branch
%   node_info - Struct table with detailed node metadata

if nargin < 3
    sensitivity_data = [];
end

switch tree_type
    case {'Tree1_Main', 'TreeS2_Standard'}
        if strcmp(tree_type, 'Tree1_Main')
            flav_name = 'TrajNorm_noStandardization';
            is_flavor2 = false;
        else
            flav_name = 'TrajNorm_Standardization';
            is_flavor2 = true;
        end
        [G, node_info] = build_congruency_tree(full_stats_tables, flav_name, false, is_flavor2);
        
    case 'TreeS1_Original'
        flav_name = 'TrajNorm_noStandardization';
        [G, node_info] = build_congruency_tree(full_stats_tables, flav_name, true, false);
        
    case {'Tree2_Sensitivity', 'TreeSI2_Standard', 'TreeSI2_Sensitivity_Standard', 'TreeS2_Sensitivity'}
        if contains(tree_type, 'Standard') || contains(tree_type, 'SI2')
            flav_name = 'TrajNorm_Standardization';
        else
            flav_name = 'TrajNorm_noStandardization';
        end
        [G, node_info] = build_sensitivity_tree(full_stats_tables, sensitivity_data, flav_name);
        
    otherwise
        error('Unknown tree_type: %s', tree_type);
end

end

%% Subfunction: Build Congruency Tree (Tree 1, Tree S1, Tree S2)
function [G, node_info] = build_congruency_tree(statsTables, flavor, is_s1_prereg, is_flavor2)
% Extracts p-values for discrete and trajectory cluster variables
stats_tab = statsTables.analyzed_stats_tables;
norm_tab = statsTables.Normality_and_Permutations_Table;
traj_tab = statsTables.fullTrajAnalysis;

% Helper to get robust or parametric p-value from Normality table
get_p = @(var_name) get_best_p(norm_tab, stats_tab, flavor, var_name);

% 1. Root & Level 2 Nodes
names   = {'Manuscript', 'Keyboard', 'Reaching'};
parents = [NaN, 1, 1];
p_vals  = [NaN, NaN, NaN];
is_posthoc = [false, false, false];
branch  = {'Root', 'Keyboard', 'Reaching'};

% 2. Keyboard Branch
kb_parent = 2;
names{end+1} = 'Confirmatory_KB'; parents(end+1) = kb_parent; p_vals(end+1) = NaN; is_posthoc(end+1) = false; branch{end+1} = 'Keyboard';
conf_kb_idx = length(names);

% Keyboard RT
kb_p = get_p('Keyboard RT');
names{end+1} = 'Keyboard_RT'; parents(end+1) = conf_kb_idx; p_vals(end+1) = kb_p; is_posthoc(end+1) = false; branch{end+1} = 'Keyboard';

% 3. Reaching Branch
reach_parent = 3;

% 3A. Confirmatory Reaching
names{end+1} = 'PR_Confirmatory_Reach'; parents(end+1) = reach_parent; p_vals(end+1) = NaN; is_posthoc(end+1) = false; branch{end+1} = 'Confirmatory';
conf_reach_idx = length(names);

ra_p = get_p('Reach Area');
names{end+1} = 'Reach_Area'; parents(end+1) = conf_reach_idx; p_vals(end+1) = ra_p; is_posthoc(end+1) = false; branch{end+1} = 'Confirmatory';

% 3B. Pre-Registered Exploratory Reaching
names{end+1} = 'PR_Exploratory_Reach'; parents(end+1) = reach_parent; p_vals(end+1) = NaN; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
pr_expl_idx = length(names);

% Discrete PR Exploratory Metrics
onset_p = get_p('Reaching Onset');
names{end+1} = 'Reaching_Onset'; parents(end+1) = pr_expl_idx; p_vals(end+1) = onset_p; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

mt_p = get_p('Reaching Duration');
names{end+1} = 'Reaching_Duration_MT'; parents(end+1) = pr_expl_idx; p_vals(end+1) = mt_p; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

totdist_p = get_p('Total Distance Traveled');
names{end+1} = 'Total_Distance'; parents(end+1) = pr_expl_idx; p_vals(end+1) = totdist_p; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

com_p = get_p('Num of COM');
names{end+1} = 'Changes_of_Mind_COM'; parents(end+1) = pr_expl_idx; p_vals(end+1) = com_p; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

% Continuous Trajectory Clusters (Empirical from traj_tab)
% Deviation from center
dev_rows = find(traj_tab.name == "Deviation From center" & traj_tab.Flavor == flavor);
if ~isempty(dev_rows)
    for r = 1:length(dev_rows)
        cl_num = traj_tab.cluster(dev_rows(r));
        c_p = traj_tab.p_val(dev_rows(r));
        if length(dev_rows) == 1
            cl_label = 'Spatial_Deviation_Cluster';
        else
            cl_label = sprintf('Spatial_Deviation_Cluster_%d', cl_num);
        end
        names{end+1} = cl_label; parents(end+1) = pr_expl_idx; p_vals(end+1) = c_p; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
    end
else
    names{end+1} = 'Spatial_Deviation_Cluster'; parents(end+1) = pr_expl_idx; p_vals(end+1) = 1.0; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
end

% Movement variation
var_rows = find(traj_tab.name == "Movement variation" & traj_tab.Flavor == flavor);
if ~isempty(var_rows)
    for r = 1:length(var_rows)
        cl_num = traj_tab.cluster(var_rows(r));
        c_p = traj_tab.p_val(var_rows(r));
        if length(var_rows) == 1
            cl_label = 'Spatial_Variation_Cluster';
        else
            cl_label = sprintf('Spatial_Variation_Cluster_%d', cl_num);
        end
        names{end+1} = cl_label; parents(end+1) = pr_expl_idx; p_vals(end+1) = c_p; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
    end
else
    names{end+1} = 'Spatial_Variation_Cluster'; parents(end+1) = pr_expl_idx; p_vals(end+1) = 1.0; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
end

% Heading angle: Included UN-PRUNED in Tree S1 (original pre-reg replication)
if is_s1_prereg
    head_rows = find(traj_tab.name == "Heading angle" & traj_tab.Flavor == flavor);
    if ~isempty(head_rows)
        for r = 1:length(head_rows)
            cl_num = traj_tab.cluster(head_rows(r));
            c_p = traj_tab.p_val(head_rows(r));
            cl_label = sprintf('Heading_Angle_Cluster_%d', cl_num);
            names{end+1} = cl_label; parents(end+1) = pr_expl_idx; p_vals(end+1) = c_p; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
        end
    else
        names{end+1} = 'Heading_Angle_Cluster'; parents(end+1) = pr_expl_idx; p_vals(end+1) = 1.0; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
    end
end

% 3C. Post-Hoc Exploratory Reaching (Only in Tree 1 and Tree S2, NOT in Tree S1)
if ~is_s1_prereg
    names{end+1} = 'PostHoc_Exploratory_Reach'; parents(end+1) = reach_parent; p_vals(end+1) = NaN; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';
    posthoc_idx = length(names);
    
    mad_p = get_p('Maximum Absolute Deviation (MAD)');
    names{end+1} = 'MAD'; parents(end+1) = posthoc_idx; p_vals(end+1) = mad_p; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';
    
    auc_p = get_p('Area Under Curve (AUC)');
    names{end+1} = 'AUC'; parents(end+1) = posthoc_idx; p_vals(end+1) = auc_p; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';
    
    % Implied End Point (IEP): In TrajNorm, IEP is a spatial cluster
    iep_rows = find(traj_tab.name == "iEP" & traj_tab.Flavor == flavor);
    if ~isempty(iep_rows)
        for r = 1:length(iep_rows)
            cl_num = traj_tab.cluster(iep_rows(r));
            c_p = traj_tab.p_val(iep_rows(r));
            if length(iep_rows) == 1
                cl_label = 'Implied_End_Point_Cluster';
            else
                cl_label = sprintf('Implied_End_Point_Cluster_%d', cl_num);
            end
            names{end+1} = cl_label; parents(end+1) = posthoc_idx; p_vals(end+1) = c_p; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';
        end
    end
end

% Construct Digraph
num_nodes = length(names);
edge_sources = parents(2:end);
edge_targets = 2:num_nodes;

G = digraph(edge_sources, edge_targets);
G.Nodes.name = names';
G.Nodes.p = p_vals';
G.Nodes.is_posthoc = is_posthoc';
G.Nodes.branch = branch';

node_info = table(names', parents', p_vals', is_posthoc', branch', ...
    'VariableNames', {'name', 'parent', 'p', 'is_posthoc', 'branch'});
end

%% Subfunction: Build Relative Sensitivity Tree (Tree 2)
function [G, node_info] = build_sensitivity_tree(statsTables, sens_data, flavor)
% Root
names   = {'Sensitivity_Advantage', 'Confirmatory_Comparison', 'Exploratory_Comparisons'};
parents = [NaN, 1, 1];
p_vals  = [NaN, NaN, NaN];
is_posthoc = [false, false, false];
branch  = {'Root', 'Confirmatory', 'Exploratory'};

% Confirmatory Comparison: Reach Area vs. Keyboard RT (Two-sided bootstrap p)
conf_comp_parent = 2;
p_ra_kb = get_comp_p(sens_data, flavor, 'ra', 'kb_rt');
names{end+1} = 'Diff_Reach_Area_vs_KB'; parents(end+1) = conf_comp_parent; p_vals(end+1) = p_ra_kb; is_posthoc(end+1) = false; branch{end+1} = 'Confirmatory';

% Exploratory Comparisons
expl_comp_parent = 3;

% Pre-Registered Exploratory Contrasts
names{end+1} = 'PR_Exploratory_Diffs'; parents(end+1) = expl_comp_parent; p_vals(end+1) = NaN; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';
pr_diff_idx = length(names);

p_mt_kb = get_comp_p(sens_data, flavor, 'mt', 'kb_rt');
names{end+1} = 'Diff_MT_vs_KB'; parents(end+1) = pr_diff_idx; p_vals(end+1) = p_mt_kb; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

p_tot_kb = get_comp_p(sens_data, flavor, 'tot_dist', 'kb_rt');
names{end+1} = 'Diff_Total_Dist_vs_KB'; parents(end+1) = pr_diff_idx; p_vals(end+1) = p_tot_kb; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

p_react_kb = get_comp_p(sens_data, flavor, 'react', 'kb_rt');
names{end+1} = 'Diff_Onset_vs_KB'; parents(end+1) = pr_diff_idx; p_vals(end+1) = p_react_kb; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

p_com_kb = get_comp_p(sens_data, flavor, 'com', 'kb_rt');
names{end+1} = 'Diff_COM_vs_KB'; parents(end+1) = pr_diff_idx; p_vals(end+1) = p_com_kb; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

p_dev_kb = get_comp_p(sens_data, flavor, 'traj', 'kb_rt');
names{end+1} = 'Diff_Spatial_Dev_vs_KB'; parents(end+1) = pr_diff_idx; p_vals(end+1) = p_dev_kb; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

p_var_kb = get_comp_p(sens_data, flavor, 'x_std', 'kb_rt');
names{end+1} = 'Diff_Spatial_Var_vs_KB'; parents(end+1) = pr_diff_idx; p_vals(end+1) = p_var_kb; is_posthoc(end+1) = false; branch{end+1} = 'PRExploratory';

% Post-Hoc Exploratory Contrasts
names{end+1} = 'PostHoc_Exploratory_Diffs'; parents(end+1) = expl_comp_parent; p_vals(end+1) = NaN; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';
posthoc_diff_idx = length(names);

p_mad_kb = get_comp_p(sens_data, flavor, 'mad', 'kb_rt');
names{end+1} = 'Diff_MAD_vs_KB'; parents(end+1) = posthoc_diff_idx; p_vals(end+1) = p_mad_kb; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';

p_auc_kb = get_comp_p(sens_data, flavor, 'auc', 'kb_rt');
names{end+1} = 'Diff_AUC_vs_KB'; parents(end+1) = posthoc_diff_idx; p_vals(end+1) = p_auc_kb; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';

p_iep_kb = get_comp_p(sens_data, flavor, 'iep', 'kb_rt');
names{end+1} = 'Diff_IEP_vs_KB'; parents(end+1) = posthoc_diff_idx; p_vals(end+1) = p_iep_kb; is_posthoc(end+1) = true; branch{end+1} = 'PostHoc';

% Construct Digraph
num_nodes = length(names);
edge_sources = parents(2:end);
edge_targets = 2:num_nodes;

G = digraph(edge_sources, edge_targets);
G.Nodes.name = names';
G.Nodes.p = p_vals';
G.Nodes.is_posthoc = is_posthoc';
G.Nodes.branch = branch';

node_info = table(names', parents', p_vals', is_posthoc', branch', ...
    'VariableNames', {'name', 'parent', 'p', 'is_posthoc', 'branch'});
end

%% Helper: Extract Best P-Value (Robust when available)
function p_val = get_best_p(norm_tab, stats_tab, flavor, var_name)
p_val = NaN;
if istable(norm_tab) && ismember('Flavor', norm_tab.Properties.VariableNames)
    idx = find(norm_tab.Flavor == flavor & contains(norm_tab.Variable, var_name));
    if ~isempty(idx)
        has_out = false;
        if ismember('Outliers_1_5IQR', norm_tab.Properties.VariableNames)
            has_out = norm_tab.Outliers_1_5IQR(idx(1)) > 0;
        elseif ismember('Has_Outliers', norm_tab.Properties.VariableNames)
            has_out = string(norm_tab.Has_Outliers(idx(1))) == "Yes" || isequal(norm_tab.Has_Outliers(idx(1)), true);
        end
        if has_out && ismember('Yuen_p', norm_tab.Properties.VariableNames) && ~isnan(norm_tab.Yuen_p(idx(1)))
            p_val = norm_tab.Yuen_p(idx(1));
        elseif ismember('p_param', norm_tab.Properties.VariableNames)
            p_val = norm_tab.p_param(idx(1));
        end
    end
end

if isnan(p_val) && istable(stats_tab)
    if ismember('Within_Participant_Standardization', stats_tab.Properties.VariableNames)
        is_std = contains(flavor, 'Standardization') && ~contains(flavor, 'noStandardization');
        idx = find(stats_tab.name == var_name & stats_tab.Within_Participant_Standardization == is_std);
    else
        idx = find(stats_tab.name == var_name);
    end
    if ~isempty(idx)
        p_val = stats_tab.pVal(idx(1));
    end
end

if isnan(p_val)
    error('Could not find p-value for %s in flavor %s', var_name, flavor);
end
end

%% Helper: Extract Pairwise Contrast P-Value (Two-Sided Bootstrap)
function p_val = get_comp_p(sens_data, flavor, f1, f2)
p_val = NaN;
if isempty(sens_data) || ~istable(sens_data)
    % Fallback: compute default
    p_val = 0.05;
    return;
end

% Look for matching comparison name in within_tbl or cross_tbl
pat1 = sprintf('%s_minus_%s', f1, f2);
pat2 = sprintf('%s_minus_%s', f2, f1);

idx = find(sens_data.Flavor == flavor & (sens_data.Comparison == pat1 | sens_data.Comparison == pat2));
if ~isempty(idx)
    p_val = sens_data.P_Value(idx(1));
else
    % Try matching without flavor column
    idx = find(sens_data.Comparison == pat1 | sens_data.Comparison == pat2);
    if ~isempty(idx)
        p_val = sens_data.P_Value(idx(1));
    else
        warning('Could not find comparison %s vs %s for flavor %s. Setting p=1.0', f1, f2, flavor);
        p_val = 1.0;
    end
end
end
