function [chrono_results] = analyze_chronological_time_domain(full_stats_tables, within_tbl)
% ANALYZE_CHRONOLOGICAL_TIME_DOMAIN Evaluates Flavor 3 (noTrajNorm, 340 ms cutoff)
%
% Implements:
%   Component 4: Chronological trajectory dynamics across 4 continuous metrics
%                (Tier 1 permutation clusters -> Tier 2 Benjamini-Hochberg FDR)
%   Component 6: Chronological peak sensitivity contrasts against Keyboard RT
%                (Two-sided bootstrap differences -> Benjamini-Hochberg FDR)

flavor = 'noTrajNorm_noStandardization';
traj_tab = full_stats_tables.fullTrajAnalysis;

%% 1. Component 4: 4 Continuous Metrics Multiplicity Control
metrics = {'Deviation From center', 'iEP', 'Heading angle', 'Movement variation'};
metric_labels = {'Deviation_From_Center', 'Implied_End_Point', 'Heading_Angle', 'Movement_Variation'};

cluster_found = false(length(metrics), 1);
raw_cluster_p = ones(length(metrics), 1); % Default to 1.0 if no cluster
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
        % No cluster formed -> enter p = 1.0 per specification
        raw_cluster_p(m) = 1.0;
    end
end

% Tier 2: Standard Benjamini-Hochberg FDR
fdr_adj_p = mafdr(raw_cluster_p, 'BHFDR', true);
rejected  = fdr_adj_p < 0.05;

component4_table = table(string(metric_labels'), cluster_found, cluster_start, cluster_end, ...
    cluster_dz, raw_cluster_p, fdr_adj_p, rejected, ...
    'VariableNames', {'Metric', 'Cluster_Detected', 'Start_Sample', 'End_Sample', 'Cohen_dz', 'Cluster_p_raw', 'FDR_adj_p', 'Significant_FDR'});

%% 2. Component 6: Chronological Peak Sensitivity Contrasts against Keyboard RT
% 3 contrasts: traj vs kb_rt, iep vs kb_rt, head_angle vs kb_rt
comp_metrics = {'traj', 'iep', 'head_angle'};
comp_labels  = {'Peak_Deviation_vs_KB', 'Peak_IEP_vs_KB', 'Peak_Heading_Angle_vs_KB'};

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
        diff_dz(c)    = within_tbl.Effect_Size_Diff(idx(1));
        ci_lower(c)   = within_tbl.CI_Lower(idx(1));
        ci_upper(c)   = within_tbl.CI_Upper(idx(1));
        comp_raw_p(c) = within_tbl.P_Value(idx(1));
    end
end

comp6_adj_p   = mafdr(comp_raw_p, 'BHFDR', true);
comp6_reject  = comp6_adj_p < 0.05;

component6_table = table(string(comp_labels'), diff_dz, ci_lower, ci_upper, comp_raw_p, comp6_adj_p, comp6_reject, ...
    'VariableNames', {'Contrast', 'Delta_dz', 'CI_Lower', 'CI_Upper', 'Raw_p_TwoSided', 'FDR_adj_p', 'Significant_FDR'});

%% Package Results
chrono_results = struct();
chrono_results.Component4_Continuous_FDR = component4_table;
chrono_results.Component6_Sensitivity_Contrasts = component6_table;

fprintf('\n=== Flavor 3: Chronological Trajectory Dynamics (Component 4) ===\n');
disp(component4_table);

fprintf('\n=== Flavor 3: Chronological Peak Sensitivity Contrasts (Component 6) ===\n');
disp(component6_table);

end
