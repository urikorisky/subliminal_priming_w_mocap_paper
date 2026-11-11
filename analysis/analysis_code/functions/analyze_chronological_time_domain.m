function [chrono_results] = analyze_chronological_time_domain(full_stats_tables, within_tbl)
% ANALYZE_CHRONOLOGICAL_TIME_DOMAIN Evaluates noTrajNorm_noStandardization (340 ms cutoff)
%
% Implements:
%   Component 4: Chronological trajectory dynamics across the 4 valid continuous metrics
%                (Tier 1 permutation clusters -> Tier 2 Benjamini-Hochberg FDR)
%   Component 6: Chronological peak sensitivity contrasts against Keyboard RT
%                for all detected temporal clusters (Two-sided bootstrap differences -> BH FDR)

flavor = 'noTrajNorm_noStandardization';
traj_tab = full_stats_tables.fullTrajAnalysis;

%% 1. Component 4: 4 Continuous Metrics Multiplicity Control
metrics       = {'Deviation From center', 'iEP', 'Heading angle', 'Movement variation'};
metric_codes  = {'traj', 'iep', 'head_angle', 'x_std'};
metric_labels = {'Deviation_From_Center', 'Implied_End_Point', 'Heading_Angle', 'Movement_Variation'};
contrast_lbls = {'Peak_Deviation_vs_KB', 'Peak_IEP_vs_KB', 'Peak_Heading_Angle_vs_KB', 'Peak_Movement_Variation_vs_KB'};

cluster_found = false(length(metrics), 1);
raw_cluster_p = ones(length(metrics), 1);
cluster_start = NaN(length(metrics), 1);
cluster_end   = NaN(length(metrics), 1);
cluster_dz    = NaN(length(metrics), 1);

for m = 1:length(metrics)
    m_name = metrics{m};
    idx = find(traj_tab.name == m_name & traj_tab.Flavor == flavor);
    if ~isempty(idx)
        cluster_found(m) = true;
        raw_cluster_p(m) = traj_tab.p_val(idx(1));
        cluster_start(m) = traj_tab.start_time(idx(1));
        cluster_end(m)   = traj_tab.end_time(idx(1));
        cluster_dz(m)    = traj_tab.cohens_dz(idx(1));
    else
        raw_cluster_p(m) = 1.0;
    end
end

% Tier 2: Standard Benjamini-Hochberg FDR across all 4 analyzed features
fdr_adj_p = mafdr(raw_cluster_p, 'BHFDR', true);
rejected  = fdr_adj_p < 0.05;

start_ms = cluster_start * 10;
end_ms   = cluster_end * 10;

component4_table = table(string(metric_labels'), cluster_found, cluster_start, cluster_end, ...
    start_ms, end_ms, cluster_dz, raw_cluster_p, fdr_adj_p, rejected, ...
    'VariableNames', {'Metric', 'Cluster_Detected', 'Start_Sample', 'End_Sample', ...
                      'Start_ms', 'End_ms', 'Cohen_dz', 'Cluster_p_raw', 'FDR_adj_p', 'Significant_FDR'});

%% 2. Component 6: Chronological Peak Sensitivity Contrasts against Keyboard RT
active_idx  = find(cluster_found);
comp_metrics = metric_codes(active_idx);
comp_labels  = contrast_lbls(active_idx);

diff_dz    = NaN(length(comp_metrics), 1);
ci_lower   = NaN(length(comp_metrics), 1);
ci_upper   = NaN(length(comp_metrics), 1);
comp_raw_p = ones(length(comp_metrics), 1);

for c = 1:length(comp_metrics)
    c_m = comp_metrics{c};
    pat1 = sprintf('%s_minus_kb_rt', c_m);
    pat2 = sprintf('kb_rt_minus_%s', c_m);

    idx = find(within_tbl.Flavor == flavor & (within_tbl.Comparison == pat1 | within_tbl.Comparison == pat2));
    if ~isempty(idx)
        row = within_tbl(idx(1), :);
        if row.Comparison == pat1
            diff_dz(c)  = row.Effect_Size_Diff;
            ci_lower(c) = row.CI_Lower;
            ci_upper(c) = row.CI_Upper;
        else
            diff_dz(c)  = -row.Effect_Size_Diff;
            ci_lower(c) = -row.CI_Upper;
            ci_upper(c) = -row.CI_Lower;
        end
        comp_raw_p(c) = row.P_Value;
    end
end

comp_fdr_p    = mafdr(comp_raw_p, 'BHFDR', true);
comp_rejected = comp_fdr_p < 0.05;

component6_table = table(string(comp_labels'), diff_dz, ci_lower, ci_upper, comp_raw_p, comp_fdr_p, comp_rejected, ...
    'VariableNames', {'Contrast', 'Delta_dz_Reach_minus_KB', 'CI_95_Lower', 'CI_95_Upper', 'Bootstrap_p_2sided', 'FDR_adj_p', 'Significant_FDR'});

chrono_results = struct();
chrono_results.Component4_Continuous_FDR = component4_table;
chrono_results.Component6_Sensitivity_Contrasts = component6_table;

fprintf('\n--- Chronological Time-Domain Trajectory Clusters (Component 4) ---\n');
disp(component4_table);

fprintf('\n--- Chronological Peak Sensitivity Contrasts vs Keyboard RT (Component 6) ---\n');
disp(component6_table);

end
