function generate_master_all_statistics_xlsx(xlsx_path, fst_or_dir, proc_root, temporal_dynamics_struct)
% GENERATE_MASTER_ALL_STATISTICS_XLSX Builds the consolidated 16-sheet
% All_Statistics.xlsx workbook directly from in-memory structs.

if exist(xlsx_path, 'file')
    delete(xlsx_path);
    if exist(xlsx_path, 'file')
        [fp_dir, fp_name, fp_ext] = fileparts(xlsx_path);
        fallback_path = fullfile(fp_dir, [fp_name, '_Consolidated', fp_ext]);
        warning('Could not replace %s (may be open in Excel). Writing to %s instead.', xlsx_path, fallback_path);
        xlsx_path = fallback_path;
        if exist(xlsx_path, 'file'), delete(xlsx_path); end
    end
end

if isstruct(fst_or_dir)
    fst = fst_or_dir;
else
    s_all = load(fullfile(fst_or_dir, 'All_Statistics.mat'));
    fst = s_all.full_stats_tables;
end
TreeBH = fst.TreeBH_Results;

f1_dir = fullfile(proc_root, 'nonStandardized_TrajNorm');
f2_dir = fullfile(proc_root, 'standardized_TrajNorm');
f3_dir = fullfile(proc_root, 'nonStandardized_nonTrajNorm');

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
good_subs = fst.good_subs;

% =========================================================================
% SHEET 1: Effects (Master Effects Hub across Flavors 1, 2, and 3)
% =========================================================================
fprintf('Building Sheet 1: Effects...\n');
effects_sheet_tbl = build_sheet1_effects(fst, TreeBH, f1_dir, f2_dir, good_subs, p);
writetable(effects_sheet_tbl, xlsx_path, 'Sheet', 'Effects');

% =========================================================================
% SHEET 2: Stats_Tests_Assumptions (Normality & Outlier Diagnostics Only)
% =========================================================================
fprintf('Building Sheet 2: Stats_Tests_Assumptions...\n');
assumptions_tbl = build_sheet2_assumptions(fst, f1_dir, f2_dir, good_subs, p);
writetable(assumptions_tbl, xlsx_path, 'Sheet', 'Stats_Tests_Assumptions');

% =========================================================================
% SHEET 3: Table_1_Trial_Exclusions (Group Percentages, Counts & Paired Tests)
% =========================================================================
fprintf('Building Sheet 3: Table_1_Trial_Exclusions...\n');
[table1_excl_cells, excl_stats] = build_sheet3_table1_exclusions(fst, f1_dir, good_subs, p);
writecell(table1_excl_cells, xlsx_path, 'Sheet', 'Table_1_Trial_Exclusions');

% =========================================================================
% SHEET 4: Participant_Exclusions (45 Participants, Prtcp 46..90)
% =========================================================================
fprintf('Building Sheet 4: Participant_Exclusions...\n');
sheet4_cells = build_sheet4_participant_exclusions(f1_dir, good_subs, p);
writecell(sheet4_cells, xlsx_path, 'Sheet', 'Participant_Exclusions');

% =========================================================================
% SHEET 5: Participants_Temporal_Dynamics (Data driving Fig S3 & Fig S4)
% =========================================================================
fprintf('Building Sheet 5: Participants_Temporal_Dynamics...\n');
sheet5_cells = build_sheet5_temporal_dynamics(temporal_dynamics_struct);
writecell(sheet5_cells, xlsx_path, 'Sheet', 'Participants_Temporal_Dynamics');

% =========================================================================
% SHEET 6: Table_2_PAS_Visibility (PAS 1-4 %, Mean PAS by Cong/Task, Tests)
% =========================================================================
fprintf('Building Sheet 6: Table_2_PAS_Visibility...\n');
sheet6_cells = build_sheet6_pas_visibility(fst.primeAwarenessDist);
writecell(sheet6_cells, xlsx_path, 'Sheet', 'Table_2_PAS_Visibility');

% =========================================================================
% SHEET 7: Objective_Prime_Awareness (Incon, Con, JZS BF, By-Participant)
% =========================================================================
fprintf('Building Sheet 7: Objective_Prime_Awareness...\n');
sheet7_cells = build_sheet7_objective_awareness(fst.Prime_Performance_Stats, fst.Prime_Performance_By_Sub);
writecell(sheet7_cells, xlsx_path, 'Sheet', 'Objective_Prime_Awareness');

% =========================================================================
% SHEET 8: COM_Thresholding (Dwell-Time Sweep + Correct vs Incorrect Table)
% =========================================================================
fprintf('Building Sheet 8: COM_Thresholding...\n');
[sheet8_cells, com_perf_stats] = build_sheet8_com_thresholding(fst.Supp_COM_Threshold_Stats, f1_dir, good_subs);
writecell(sheet8_cells, xlsx_path, 'Sheet', 'COM_Thresholding');

% =========================================================================
% SHEET 9: Split_Half_Reliability (Spearman-Brown Odd/Even Reliability)
% =========================================================================
fprintf('Building Sheet 9: Split_Half_Reliability...\n');
sheet9_tbl = build_sheet9_reliability(fst.Split_Half_Reliability);
writetable(sheet9_tbl, xlsx_path, 'Sheet', 'Split_Half_Reliability');

% =========================================================================
% SHEET 10: PreReg_WO_Long_Dur_Excl (Long-Duration-Retained Tables & Contrasts)
% =========================================================================
fprintf('Building Sheet 10: PreReg_WO_Long_Dur_Excl...\n');
sheet10_cells = build_sheet10_wo_long_dur(fst);
writecell(sheet10_cells, xlsx_path, 'Sheet', 'PreReg_WO_Long_Dur_Excl');

% =========================================================================
% SHEET 11: By_Participant_Measures (Per-Participant Means Across Analyses)
% =========================================================================
fprintf('Building Sheet 11: By_Participant_Measures...\n');
sheet11_cells = build_sheet11_by_participant(fst);
writecell(sheet11_cells, xlsx_path, 'Sheet', 'By_Participant_Measures');

% =========================================================================
% SHEET 12: Slow_Only_Analysis (Rescued Very-Slow Movements Analysis)
% =========================================================================
fprintf('Building Sheet 12: Slow_Only_Analysis...\n');
[sheet12_cells, slow_stats] = build_sheet_slow_only(f1_dir, good_subs, p);
writecell(sheet12_cells, xlsx_path, 'Sheet', 'Slow_Only_Analysis');

% =========================================================================
% SHEET 13: Dienes_RttM_Awareness (RttM Subjective & Conscious-Prior BF10)
% =========================================================================
fprintf('Building Sheet 13: Dienes_RttM_Awareness...\n');
[sheet13_cells, rttm_stats] = build_sheet_dienes_rttm(fst, f1_dir, good_subs);
writecell(sheet13_cells, xlsx_path, 'Sheet', 'Dienes_RttM_Awareness');

% =========================================================================
% SHEET 14: Acquisition_Timeline_and_Pilots (Dates, Cohorts, Pilot 2/3, Power)
% =========================================================================
fprintf('Building Sheet 14: Acquisition_Timeline_and_Pilots...\n');
[sheet14_cells, acq_stats] = build_sheet_acquisition_pilots(proc_root, fst, good_subs);
writecell(sheet14_cells, xlsx_path, 'Sheet', 'Acquisition_Timeline_and_Pilots');

% =========================================================================
% SHEET 15: Manuscript_Values (Flat Canonical Key -> Full-Precision Numeric Lookup)
% =========================================================================
fprintf('Building Sheet 15: Manuscript_Values...\n');
mv_tbl = build_sheet_manuscript_values(fst, TreeBH, excl_stats, com_perf_stats, ...
    slow_stats, rttm_stats, acq_stats, f1_dir, f2_dir, good_subs, p);
writetable(mv_tbl, xlsx_path, 'Sheet', 'Manuscript_Values');

% =========================================================================
% SHEET 16: _Metadata (Workbook Schema, Units & Generation Provenance)
% =========================================================================
fprintf('Building Sheet 16: _Metadata...\n');
meta_tbl = build_sheet_metadata(xlsx_path, mv_tbl);
writetable(meta_tbl, xlsx_path, 'Sheet', '_Metadata');

% Remove default Sheet1/Sheet2/Sheet3 if created by Excel
clean_default_excel_sheets(xlsx_path);
fprintf('Successfully created consolidated 16-sheet workbook: %s (%d Manuscript_Values keys)\n', ...
    xlsx_path, height(mv_tbl));

end

% =========================================================================
% BUILDER 1: Sheet 1 (Effects)
% =========================================================================
function tbl_out = build_sheet1_effects(fst, TreeBH, f1_dir, f2_dir, good_subs, p)
    % Construct comprehensive rows across all three main analyses
    rows = {};

    % Helper to format discrete & trajectory rows for Pre-registered and Robustness analyses
    flav_codes = {'TrajNorm_noStandardization', 'TrajNorm_Standardization'};
    flav_names = {'Pre-registered analysis', 'Robustness analysis (Z-scored)'};
    tree_con_tbls  = {TreeBH.Tree1_Congruency_Table, TreeBH.FigS2a_Congruency_Std_Table};
    tree_sens_tbls = {TreeBH.Tree2_Sensitivity_Table, TreeBH.FigS2b_Sensitivity_Std_Table};

    norm_tbl = fst.Normality_and_Permutations_Table;
    eff_tbl  = fst.Effect_Sizes;
    win_tbl  = fst.Effect_Comparisons_Within;
    ft_tbl   = fst.fullTrajAnalysis;

    % Compute exact assumptions & non-parametric stats for Sensitivity Contrasts as well
    sens_assump = compute_sensitivity_assumptions_and_nonparam(fst, f1_dir, f2_dir, good_subs, p);

    disc_codes = { ...
        'kb_rt', 'ra', 'react', 'mt', ...
        'tot_dist', 'com', 'mad', 'auc', ...
        'traj', 'x_std', 'iep'};
    disc_raw_names = { ...
        'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Reaching Duration', ...
        'Total Distance Traveled', 'Num of COM', 'Maximum Absolute Deviation (MAD)', ...
        'Area Under Curve (AUC)', 'Deviation From Center', ...
        'Movement Variance (X-STD)', 'Implied End Point (IEP)'};
    disc_disp_names = { ...
        'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Reaching Duration', ...
        'Distance Traveled', 'COM', 'MAD (Post-Hoc)', 'AUC (Post-Hoc)', ...
        'Deviance From Center', 'Horizontal Movement Variation', 'Implied Endpoint (Post-Hoc)'};
    disc_units_f1 = { ...
        'ms', '10^2 cm^2', 'ms', 'ms', ...
        'cm', 'count', 'cm', '10^2 cm^2', ...
        'cm', 'cm', 'cm'};
    disc_units_f2 = { ...
        'z-score', '10^2 cm^2', 'z-score', 'z-score', ...
        'z-score', 'z-score', 'z-score', 'z-score', ...
        'cm', 'cm', 'cm'};
    ft_map_names = {'', '', '', '', '', '', '', '', 'Deviation From center', 'Movement variation', 'iEP'};
    disc_families = { ...
        'Discrete Congruency Effect', 'Discrete Congruency Effect', ...
        'Discrete Congruency Effect', 'Discrete Congruency Effect', ...
        'Discrete Congruency Effect', 'Discrete Congruency Effect', ...
        'Discrete Congruency Effect (Post-Hoc)', 'Discrete Congruency Effect (Post-Hoc)', ...
        'Full-Trajectory Congruency Effect', 'Full-Trajectory Congruency Effect', ...
        'Full-Trajectory Congruency Effect (Post-Hoc)'};
    tree_con_nodes = { ...
        'Keyboard_RT', 'Reach_Area', 'Reaching_Onset', 'Reaching_Duration_MT', ...
        'Total_Distance', 'Changes_of_Mind_COM', 'MAD', 'AUC', ...
        'Spatial_Deviation_Cluster', 'Spatial_Variation_Cluster', 'Implied_End_Point_Cluster'};
    tree_sens_nodes = { ...
        '', 'Reach_Area_vs_KB', 'Onset_vs_KB', 'MT_vs_KB', ...
        'Total_Dist_vs_KB', 'COM_vs_KB', 'MAD_vs_KB', 'AUC_vs_KB', ...
        'Spatial_Dev_vs_KB', 'Spatial_Var_vs_KB', 'IEP_vs_KB'};

    for f_i = 1:2
        f_code = flav_codes{f_i};
        f_name = flav_names{f_i};
        t_con  = tree_con_tbls{f_i};
        t_sens = tree_sens_tbls{f_i};

        % A. Congruency Effects (8 Discrete + 3 Full-Trajectory + Heading Angle Pre-Reg note)
        for m = 1:11
            c_code = disc_codes{m};
            r_key = disc_raw_names{m};
            d_name = disc_disp_names{m};
            fam_str = disc_families{m};
            if f_i == 1
                unit_str = disc_units_f1{m};
            else
                unit_str = disc_units_f2{m};
            end

            % Continuous trajectory measures (m >= 9) in Z-scored analysis share unstandardized coordinates & clusters with Pre-registered analysis
            f_lookup = f_code;
            if f_i == 2 && m >= 9
                f_lookup = 'TrajNorm_noStandardization';
            end
            src_st = fst.(f_lookup);

            % Scale meter-based spatial measures (Pre-Reg MAD & full-trajectory traj/x_std/iep) to cm
            scale_f = 1.0;
            if (f_i == 1 && m == 7) || (m >= 9)
                scale_f = 100.0;
            end

            % Lookup in src_st
            r_idx = find(startsWith(string(src_st.name), r_key), 1);
            con_str = sprintf('%.3f (%.3f)', src_st.con_avg(r_idx) * scale_f, src_st.con_std(r_idx) * scale_f);
            inc_str = sprintf('%.3f (%.3f)', src_st.incon_avg(r_idx) * scale_f, src_st.incon_std(r_idx) * scale_f);
            dif_str = sprintf('%.3f [%.3f, %.3f]', src_st.diff_avg(r_idx) * scale_f, src_st.CI_low(r_idx) * scale_f, src_st.CI_high(r_idx) * scale_f);

            % Tree-BH p and q
            tc_idx = find(strcmp(string(t_con.Node_Name), tree_con_nodes{m}), 1);
            p_raw = num_val(t_con.Uncorrected_p(tc_idx));
            q_fdr = num_val(t_con.Within_Family_FDR_q(tc_idx));
            sig_fdr = ternary_str(is_truthy(t_con.Significant_TreeBH(tc_idx)), 'Yes (q < .05)', 'No');

            if m <= 8
                stat_str = sprintf('t(%d) = %.3f', src_st.df(r_idx), src_st.tVal(r_idx));
                p_raw = num_val(src_st.pVal(r_idx));
            else
                % Full-trajectory cluster window + t(df)
                ft_idx = find(strcmp(string(ft_tbl.Flavor), 'TrajNorm_noStandardization') & strcmp(string(ft_tbl.name), ft_map_names{m}), 1);
                if ~isempty(ft_idx)
                    stat_str = sprintf('Cluster %.1f-%.1f%% (Window t(%d) = %.3f)', ...
                        ft_tbl.start_time(ft_idx) * 0.5, ft_tbl.end_time(ft_idx) * 0.5, src_st.df(r_idx), src_st.tVal(r_idx));
                else
                    stat_str = sprintf('Cluster Perm (Window t(%d) = %.3f)', src_st.df(r_idx), src_st.tVal(r_idx));
                end
            end

            % Lookup Cohen's dz and 95% bootstrap CI
            ef_idx = find(strcmp(string(eff_tbl.Flavor), f_lookup) & strcmp(string(eff_tbl.Effect), c_code), 1);
            dz_val = num_val(eff_tbl.Cohens_dz(ef_idx));
            ci_l_e = num_val(eff_tbl.CI_Lower(ef_idx));
            ci_u_e = num_val(eff_tbl.CI_Upper(ef_idx));
            dz_str = sprintf('%.3f [%.3f, %.3f]', abs(dz_val), min(abs(ci_l_e), abs(ci_u_e)), max(abs(ci_l_e), abs(ci_u_e)));

            % Lookup Normality & Outliers in norm_tbl
            nm_idx = find(strcmp(string(norm_tbl.Flavor), f_lookup) & startsWith(string(norm_tbl.Variable), r_key), 1);
            viol_norm = ~is_truthy(norm_tbl.Is_Normal(nm_idx));
            has_out   = is_truthy(norm_tbl.Has_Outliers(nm_idx));
            vn_str = ternary_str(viol_norm, 'Yes', 'No');
            ho_str = ternary_str(has_out,   'Yes', 'No');

            % Alternative statistics: Permutation p if Violates Normality or Has Outliers;
            % Yuen p & Dependent AKP strictly if Has Outliers
            [alt_p_str, alt_es_str] = format_congruency_alt_stats(norm_tbl, nm_idx, viol_norm, has_out);

            rows(end+1, :) = {f_name, fam_str, d_name, unit_str, con_str, inc_str, dif_str, stat_str, ...
                p_raw, q_fdr, sig_fdr, dz_str, vn_str, ho_str, alt_p_str, alt_es_str}; %#ok<AGROW>
        end

        % Add Heading Angle (Pre-Registered in Main Analysis, no cluster)
        if f_i == 1
            rows(end+1, :) = {f_name, 'Full-Trajectory Congruency Effect', 'Heading Angle', 'deg', ...
                '---', '---', 'No Cluster Detected', 'Cluster Perm (Max Cluster = 0)', ...
                1.0000, 1.0000, 'No', '---', 'No', 'No', '', ''}; %#ok<AGROW>
        end

        % B. Sensitivity Comparisons vs. Keyboard RT (10 Reaching Measures)
        for m = 2:11
            c_code = disc_codes{m};
            r_key = disc_raw_names{m};
            d_name = [disc_disp_names{m}, ' vs. Keyboard RT'];
            fam_str = 'Sensitivity Comparison vs. Keyboard RT';

            w_pos = find(strcmp(string(win_tbl.Flavor), f_code) & strcmp(string(win_tbl.Comparison), [c_code, '_minus_kb_rt']), 1);
            w_neg = find(strcmp(string(win_tbl.Flavor), f_code) & strcmp(string(win_tbl.Comparison), ['kb_rt_minus_', c_code]), 1);
            if ~isempty(w_pos)
                d_es = num_val(win_tbl.Effect_Size_Diff(w_pos));
                d_l  = num_val(win_tbl.CI_Lower(w_pos));
                d_u  = num_val(win_tbl.CI_Upper(w_pos));
            else
                d_es = -num_val(win_tbl.Effect_Size_Diff(w_neg));
                d_l  = -num_val(win_tbl.CI_Upper(w_neg));
                d_u  = -num_val(win_tbl.CI_Lower(w_neg));
            end

            ts_idx = find(strcmp(string(t_sens.Node_Name), tree_sens_nodes{m}), 1);
            p_raw = num_val(t_sens.Uncorrected_p(ts_idx));
            q_fdr = num_val(t_sens.Within_Family_FDR_q(ts_idx));
            sig_fdr = ternary_str(is_truthy(t_sens.Significant_TreeBH(ts_idx)), 'Yes (q < .05)', 'No');

            dif_str  = sprintf('Delta |dz| = %+.3f [%.3f, %.3f]', d_es, d_l, d_u);
            stat_str = sprintf('Paired Bootstrap (10,000 iter)');
            dz_str   = sprintf('%+.3f [%.3f, %.3f]', d_es, d_l, d_u);

            % Lookup sensitivity assumption check
            sa_row = sens_assump(strcmp(sens_assump.Flavor, f_code) & strcmp(sens_assump.Key, r_key), :);
            viol_norm = is_truthy(sa_row.Violates_Normality(1));
            has_out   = is_truthy(sa_row.Has_Outliers(1));
            vn_str = ternary_str(viol_norm, 'Yes', 'No');
            ho_str = ternary_str(has_out,   'Yes', 'No');

            if viol_norm || has_out
                alt_p_str = sprintf('%.4f (Sign-Flip Perm)', num_val(sa_row.Perm_p(1)));
            else
                alt_p_str = '';
            end
            if has_out
                alt_es_str = sprintf('%+.3f (Delta AKP)', num_val(sa_row.Delta_AKP(1)));
            else
                alt_es_str = '';
            end

            rows(end+1, :) = {f_name, fam_str, d_name, 'Delta |dz|', '---', '---', dif_str, stat_str, ...
                p_raw, q_fdr, sig_fdr, dz_str, vn_str, ho_str, alt_p_str, alt_es_str}; %#ok<AGROW>
        end
    end

    % C. Temporal full-trajectory analysis (4 Full-Trajectory Measures)
    f3_name = 'Temporal full-trajectory analysis';
    c4 = TreeBH.Component4_Continuous_FDR;
    f3_raw = fst.noTrajNorm_noStandardization;
    f3_codes = {'traj', 'x_std', 'iep', 'head_angle'};
    f3_keys = {'Deviation From Center', 'Movement Variance (X-STD)', 'Implied End Point (IEP)', 'Heading Angle'};
    f3_disp = {'Deviance From Center', 'Horizontal Movement Variation', 'Implied Endpoint (Post-Hoc)', 'Heading Angle'};
    f3_units = {'cm', 'cm', 'cm', 'deg'};
    f3_c4_names = {'Deviation_From_Center', 'Movement_Variation', 'Implied_End_Point', 'Heading_Angle'};

    for m = 1:4
        c4_idx = find(strcmp(string(c4.Metric), f3_c4_names{m}), 1);
        c_code = f3_codes{m};
        r_key = f3_keys{m};
        d_name = f3_disp{m};
        unit_str = f3_units{m};
        fam_str = ternary_str(m == 3, 'Full-Trajectory Congruency Effect (Post-Hoc)', 'Full-Trajectory Congruency Effect');
        scale_f = ternary_str(m <= 3, 100.0, 1.0);

        if is_truthy(c4.Cluster_Detected(c4_idx))
            r_idx = find(startsWith(string(f3_raw.name), r_key), 1);
            con_str = sprintf('%.3f (%.3f)', f3_raw.con_avg(r_idx) * scale_f, f3_raw.con_std(r_idx) * scale_f);
            inc_str = sprintf('%.3f (%.3f)', f3_raw.incon_avg(r_idx) * scale_f, f3_raw.incon_std(r_idx) * scale_f);
            dif_str = sprintf('%.3f [%.3f, %.3f]', f3_raw.diff_avg(r_idx) * scale_f, f3_raw.CI_low(r_idx) * scale_f, f3_raw.CI_high(r_idx) * scale_f);
            stat_str = sprintf('Cluster %d-%d ms (Window t(%d)=%.3f)', num_val(c4.Start_ms(c4_idx)), num_val(c4.End_ms(c4_idx)), f3_raw.df(r_idx), f3_raw.tVal(r_idx));
            p_raw = num_val(c4.Cluster_p_raw(c4_idx));
            q_fdr = num_val(c4.FDR_adj_p(c4_idx));
            sig_fdr = ternary_str(is_truthy(c4.Significant_FDR(c4_idx)), 'Yes (q < .05)', 'No');

            ef_idx = find(strcmp(string(eff_tbl.Flavor), 'noTrajNorm_noStandardization') & strcmp(string(eff_tbl.Effect), c_code), 1);
            ci_l_e = num_val(eff_tbl.CI_Lower(ef_idx));
            ci_u_e = num_val(eff_tbl.CI_Upper(ef_idx));
            dz_str = sprintf('%.3f [%.3f, %.3f]', abs(num_val(eff_tbl.Cohens_dz(ef_idx))), ...
                min(abs(ci_l_e), abs(ci_u_e)), max(abs(ci_l_e), abs(ci_u_e)));

            nm_idx = find(strcmp(string(norm_tbl.Flavor), 'noTrajNorm_noStandardization') & startsWith(string(norm_tbl.Variable), r_key), 1);
            viol_norm = ~is_truthy(norm_tbl.Is_Normal(nm_idx));
            has_out   = is_truthy(norm_tbl.Has_Outliers(nm_idx));
            vn_str = ternary_str(viol_norm, 'Yes', 'No');
            ho_str = ternary_str(has_out,   'Yes', 'No');
            [alt_p_str, alt_es_str] = format_congruency_alt_stats(norm_tbl, nm_idx, viol_norm, has_out);
        else
            con_str = '---'; inc_str = '---'; dif_str = 'No Cluster Detected';
            stat_str = 'Cluster Perm (0-340 ms)';
            p_raw = 1.0000; q_fdr = 1.0000; sig_fdr = 'No';
            dz_str = '---'; vn_str = 'No'; ho_str = 'No';
            alt_p_str = ''; alt_es_str = '';
        end

        rows(end+1, :) = {f3_name, fam_str, d_name, unit_str, con_str, inc_str, dif_str, stat_str, ...
            p_raw, q_fdr, sig_fdr, dz_str, vn_str, ho_str, alt_p_str, alt_es_str}; %#ok<AGROW>
    end

    col_names = {'Analysis', 'Effect_Family', 'Measure', 'Unit', 'Congruent_Mean_SD', 'Incongruent_Mean_SD', ...
                 'Mean_Difference_95CI', 'Test_Statistic', 'Raw_p_value', 'TreeBH_FDR_q_value', ...
                 'Significant_FDR', 'Cohens_dz_95CI', 'Violates_Normality', 'Has_Outliers', ...
                 'Alt_NonParametric_p_if_Violated', 'Alt_Robust_Effect_Size_AKP_if_Outliers'};
    tbl_out = cell2table(rows, 'VariableNames', col_names);
end

function [alt_p_str, alt_es_str] = format_congruency_alt_stats(norm_tbl, nm_idx, viol_norm, has_out)
    alt_p_str  = '';
    alt_es_str = '';
    if ~(viol_norm || has_out)
        return;
    end
    alt_parts = {};
    perm_p_v = num_val(norm_tbl.Permutation_p(nm_idx));
    if ~isnan(perm_p_v)
        alt_parts{end+1} = sprintf('%s (Perm)', format_p_display(perm_p_v)); %#ok<AGROW>
    end
    if has_out && ismember('Yuen_p', norm_tbl.Properties.VariableNames)
        yuen_p_v = num_val(norm_tbl.Yuen_p(nm_idx));
        if ~isnan(yuen_p_v)
            alt_parts{end+1} = sprintf('%s (Yuen)', format_p_display(yuen_p_v)); %#ok<AGROW>
        end
    end
    alt_p_str = strjoin(alt_parts, '; ');
    if has_out
        akp_ci = char(string(norm_tbl.AKP_Dependent_CI(nm_idx)));
        alt_es_str = sprintf('%.3f %s', abs(num_val(norm_tbl.AKP_Dependent(nm_idx))), akp_ci);
    end
end

function out = ternary_str(cond, t_str, f_str)
    if cond, out = t_str; else, out = f_str; end
end

function s = format_p_display(p_val)
    if isnan(p_val)
        s = 'NaN';
    elseif p_val < 0.0001
        s = sprintf('%.2e', p_val);
    else
        s = sprintf('%.4f', p_val);
    end
end

function tf = is_truthy(val)
    if iscell(val) && ~isempty(val), val = val{1}; end
    if isempty(val), tf = false; return; end
    if islogical(val)
        tf = logical(val(1));
    elseif isnumeric(val)
        tf = (val(1) ~= 0 && ~isnan(val(1)));
    else
        s = lower(strtrim(string(val(1))));
        tf = (s == "yes" || s == "true" || s == "1");
    end
end

function v = num_val(x)
    if iscell(x)
        if isempty(x), v = NaN; return; end
        x = x{1};
    end
    if isstring(x) || ischar(x)
        v = str2double(x);
    elseif isnumeric(x) || islogical(x)
        if isempty(x), v = NaN; else, v = double(x(1)); end
    else
        v = NaN;
    end
end

% =========================================================================
% BUILDER 2: Sheet 2 (Stats_Tests_Assumptions)
% =========================================================================
function tbl_out = build_sheet2_assumptions(fst, f1_dir, f2_dir, good_subs, p)
    norm_tbl = fst.Normality_and_Permutations_Table;
    sens_assump = compute_sensitivity_assumptions_and_nonparam(fst, f1_dir, f2_dir, good_subs, p);

    rows = {};
    flav_codes = {'TrajNorm_noStandardization', 'TrajNorm_Standardization', 'noTrajNorm_noStandardization'};
    flav_names = {'Pre-registered analysis', 'Robustness analysis (Z-scored)', 'Temporal full-trajectory analysis'};

    raw_keys = {'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Reaching Duration', ...
                'Total Distance Traveled', 'Num of COM', 'Maximum Absolute Deviation (MAD)', ...
                'Area Under Curve (AUC)', 'Deviation From Center', ...
                'Movement Variance (X-STD)', 'Implied End Point (IEP)', 'Heading Angle'};
    disp_names = {'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Reaching Duration', ...
                  'Distance Traveled', 'COM', 'MAD (Post-Hoc)', 'AUC (Post-Hoc)', ...
                  'Deviance From Center', 'Horizontal Movement Variation', ...
                  'Implied Endpoint (Post-Hoc)', 'Heading Angle'};

    for f_i = 1:3
        f_code = flav_codes{f_i};
        f_name = flav_names{f_i};

        % 1. Congruency Difference Assumptions
        for m = 1:numel(raw_keys)
            f_lookup = f_code;
            if f_i == 2 && m >= 9 && m <= 11
                f_lookup = 'TrajNorm_noStandardization';
            end
            nm_idx = find(strcmp(string(norm_tbl.Flavor), f_lookup) & startsWith(string(norm_tbl.Variable), raw_keys{m}), 1);
            if isempty(nm_idx), continue; end

            viol_norm = ~is_truthy(norm_tbl.Is_Normal(nm_idx));
            has_out   = is_truthy(norm_tbl.Has_Outliers(nm_idx));
            if has_out
                dec_str = 'Verify with Non-Parametric Sign-Flip Permutation & Dependent AKP';
            elseif viol_norm
                dec_str = 'Verify with Non-Parametric Sign-Flip Permutation (No Outliers)';
            else
                dec_str = 'Parametric Assumptions Met (Paired t-test & Cohen''s dz)';
            end

            rows(end+1, :) = {f_name, 'Congruency Difference (Con - Incon)', disp_names{m}, ...
                num_val(norm_tbl.N(nm_idx)), round(num_val(norm_tbl.Skewness(nm_idx)), 3), round(num_val(norm_tbl.Kurtosis(nm_idx)), 3), ...
                round(num_val(norm_tbl.Lilliefors_p(nm_idx)), 4), round(num_val(norm_tbl.JB_p(nm_idx)), 4), ...
                ternary_str(viol_norm, 'Yes', 'No'), char(string(norm_tbl.Outliers_1_5IQR(nm_idx))), ...
                ternary_str(has_out, 'Yes', 'No'), dec_str}; %#ok<AGROW>
        end

        % 2. Sensitivity Contrast vs. Keyboard RT Assumptions (Flavors 1 & 2)
        if f_i <= 2
            for m = 2:11
                sa_row = sens_assump(strcmp(sens_assump.Flavor, f_code) & strcmp(sens_assump.Key, raw_keys{m}), :);
                if isempty(sa_row), continue; end
                viol_norm = is_truthy(sa_row.Violates_Normality(1));
                has_out   = is_truthy(sa_row.Has_Outliers(1));
                if has_out
                    dec_str = 'Verify with Non-Parametric Sign-Flip Permutation & Delta AKP';
                elseif viol_norm
                    dec_str = 'Verify with Non-Parametric Sign-Flip Permutation (No Outliers)';
                else
                    dec_str = 'Parametric / Bootstrap Assumptions Met';
                end
                rows(end+1, :) = {f_name, 'Sensitivity Contrast vs. Keyboard RT', [disp_names{m}, ' vs. Keyboard RT'], ...
                    30, round(num_val(sa_row.Skewness(1)), 3), round(num_val(sa_row.Kurtosis(1)), 3), ...
                    round(num_val(sa_row.Lilliefors_p(1)), 4), round(num_val(sa_row.JB_p(1)), 4), ...
                    ternary_str(viol_norm, 'Yes', 'No'), char(string(sa_row.Outlier_Str(1))), ...
                    ternary_str(has_out, 'Yes', 'No'), dec_str}; %#ok<AGROW>
            end
        end
    end

    col_names = {'Analysis', 'Comparison_Family', 'Measure', 'N_Participants', ...
                 'Skewness', 'Kurtosis', 'Lilliefors_p', 'Jarque_Bera_p', ...
                 'Violates_Normality', 'Outliers_1_5_IQR', 'Has_Outliers', 'Testing_Decision'};
    tbl_out = cell2table(rows, 'VariableNames', col_names);
end

function sa_tbl = compute_sensitivity_assumptions_and_nonparam(fst, f1_dir, f2_dir, good_subs, p)
    f1_avg = load(fullfile(f1_dir, ['avg_each_day2_target_x_to_subs_' p.SUBS_STRING '.mat']));
    f2_avg = load(fullfile(f2_dir, ['avg_each_day2_target_x_to_subs_' p.SUBS_STRING '.mat']));
    win_f1 = fst.dynamic_trajectory_windows.TrajNorm_noStandardization;
    win_f2 = win_f1;

    disc_codes = {'kb_rt', 'ra', 'react', 'mt', 'tot_dist', 'com', 'mad', 'auc', 'traj', 'x_std', 'iep'};
    raw_keys = {'Keyboard RT', 'Reach Area', 'Reaching Onset', 'Reaching Duration', ...
                'Total Distance Traveled', 'Num of COM', 'Maximum Absolute Deviation (MAD)', ...
                'Area Under Curve (AUC)', 'Deviation From Center', ...
                'Movement Variance (X-STD)', 'Implied End Point (IEP)'};

    f_codes = {'TrajNorm_noStandardization', 'TrajNorm_Standardization'};
    avgs = {f1_avg, f2_avg};
    wins = {win_f1, win_f2};
    eff_tbl = fst.Effect_Sizes;

    warning('off', 'stats:lillietest:OutOfRangeP');
    warning('off', 'stats:jbtest:OutOfRangeP');
    sa_rows = {};
    for f_i = 1:2
        f_code = f_codes{f_i};
        r_avg = avgs{f_i}.reach_avg_each;
        k_avg = avgs{f_i}.keyboard_avg_each;
        w = wins{f_i};

        kb_d = abs_orient(k_avg.rt(1).con(good_subs) - k_avg.rt(1).incon(good_subs));
        u_kb = kb_d(:) / std(kb_d);
        z_kb = (kb_d - mean(kb_d)) / std(kb_d);
        ef_kb = find(strcmp(string(eff_tbl.Flavor), f_code) & strcmp(string(eff_tbl.Effect), 'kb_rt'), 1);
        akp_kb = abs(num_val(eff_tbl.Dependent_AKP(ef_kb)));

        vecs = { ...
            kb_d, ...
            abs_orient(r_avg.ra(1).con(good_subs) - r_avg.ra(1).incon(good_subs)), ...
            abs_orient(r_avg.react(1).con(good_subs) - r_avg.react(1).incon(good_subs)), ...
            abs_orient(r_avg.mt(1).con(good_subs) - r_avg.mt(1).incon(good_subs)), ...
            abs_orient(r_avg.tot_dist(1).con(good_subs) - r_avg.tot_dist(1).incon(good_subs)), ...
            abs_orient(r_avg.com(1).con(good_subs) - r_avg.com(1).incon(good_subs)), ...
            abs_orient(r_avg.mad(1).con(good_subs) - r_avg.mad(1).incon(good_subs)), ...
            abs_orient(r_avg.auc(1).con(good_subs) - r_avg.auc(1).incon(good_subs)), ...
            abs_orient(mean(r_avg.traj(1).con(w.traj(1):w.traj(2), good_subs, 1) - r_avg.traj(1).incon(w.traj(1):w.traj(2), good_subs, 1), 1)'), ...
            abs_orient(mean(r_avg.x_std(1).con(w.x_std(1):w.x_std(2), good_subs) - r_avg.x_std(1).incon(w.x_std(1):w.x_std(2), good_subs), 1)'), ...
            abs_orient(mean(r_avg.iep(1).con(w.iep(1):w.iep(2), good_subs, 1) - r_avg.iep(1).incon(w.iep(1):w.iep(2), good_subs, 1), 1)')};

        for m = 2:11
            mv = vecs{m}(:);
            z_m = (mv - mean(mv)) / std(mv);
            c_vec = z_m - z_kb(:);
            c_vec_eff = (mv / std(mv)) - u_kb; % Effect-scaled difference preserving Delta dz mean = dz_m - dz_kb

            sk = num_val(skewness(c_vec));
            ku = num_val(kurtosis(c_vec));
            try, [~, p_l] = lillietest(c_vec); catch, p_l = 1; end
            try, [~, p_j] = jbtest(c_vec); catch, p_j = 1; end
            p_l = num_val(p_l); p_j = num_val(p_j);
            v_norm = logical((p_l < 0.05) || (p_j < 0.05));

            q25 = prctile(c_vec, 25); q75 = prctile(c_vec, 75); iqr_v = q75 - q25;
            out_idx = find(c_vec < (q25 - 1.5*iqr_v) | c_vec > (q75 + 1.5*iqr_v));
            h_out = logical(~isempty(out_idx));
            if h_out
                out_subs = good_subs(out_idx);
                out_str = sprintf('%d (Prtcp %s)', numel(out_idx), strjoin(arrayfun(@num2str, out_subs(:)', 'UniformOutput', false), ', '));
            else
                out_str = '0 (None)';
            end

            % Sign-flip permutation p-value on uncentered effect-scaled paired contrast c_vec_eff
            rng(42, 'twister');
            n_perm = 10000;
            obs_m = abs(mean(c_vec_eff));
            signs = sign(rand(numel(c_vec_eff), n_perm) - 0.5);
            perm_m = abs(mean(c_vec_eff .* signs, 1));
            perm_p = num_val((sum(perm_m >= obs_m) + 1) / (n_perm + 1));

            f_lookup = f_code;
            if f_i == 2 && m >= 9
                f_lookup = 'TrajNorm_noStandardization';
            end
            ef_m = find(strcmp(string(eff_tbl.Flavor), f_lookup) & strcmp(string(eff_tbl.Effect), disc_codes{m}), 1);
            akp_m = abs(num_val(eff_tbl.Dependent_AKP(ef_m)));
            d_akp = num_val(akp_m - akp_kb);

            sa_rows(end+1, :) = {f_code, raw_keys{m}, sk, ku, p_l, p_j, v_norm, out_str, h_out, perm_p, d_akp}; %#ok<AGROW>
        end
    end
    sa_tbl = cell2table(sa_rows, 'VariableNames', ...
        {'Flavor', 'Key', 'Skewness', 'Kurtosis', 'Lilliefors_p', 'JB_p', ...
         'Violates_Normality', 'Outlier_Str', 'Has_Outliers', 'Perm_p', 'Delta_AKP'});
end

function v_out = abs_orient(v)
    v = v(:);
    if mean(v, 'omitnan') < 0, v_out = -v; else, v_out = v; end
end

% =========================================================================
% BUILDER 3: Sheet 3 (Table_1_Trial_Exclusions)
% =========================================================================
function [cells_out, excl_stats] = build_sheet3_table1_exclusions(fst, f1_dir, good_subs, p)
    % PART A: Trial exclusion percentages & paired Reach vs. KB t(29) tests (N = 30)
    % PART B: Raw trial counts per exclusion criterion & included PAS=1 condition counts (N = 30)
    s = fst.trialExclusionStats.Summary;
    pct_tbl = fst.SI_Exclusion_All_Subs_Pct;
    cnt_tbl = fst.SI_Exclusion_All_Subs_Counts;
    v_pct = pct_tbl(strcmp(string(pct_tbl.Group_Status), "Valid"), :);
    v_cnt = cnt_tbl(strcmp(string(cnt_tbl.Group_Status), "Valid"), :);

    reasons_map = { ...
        'Hole_in_Data',                 'Tracking Gap (Hole in Data)',                                                      'hole_data',       'Reach_Hole_Data',                                ''; ...
        'Missing_Data',                 'Missing Trajectory Data',                                                          'missing_data',    'Reach_Missing_Data',                             ''; ...
        'Insufficient_Length',          'Trajectory Duration < Min Length (<100 ms in PreReg/Z-score; <340 ms in Temporal)', 'insufficient_len', 'Reach_Diff_Length',                             ''; ...
        'Short_Trajectory',             'Spatial Path Too Short (<30 cm)',                                                  'short_traj',      'Reach_Short_Traj',                               ''; ...
        'Missed_Target',                'Missed Target Box on Screen',                                                      'missed_target',   'Reach_Missed_Target',                            ''; ...
        'Bad_Stim_Duration',            'Display Frame Drop (Bad Prime Duration)',                                          'bad_stim_dur',    'Reach_Bad_Stim_Dur',                             'KB_Bad_Stim_Dur'; ...
        'Early_Response',               'Initiated Too Early (<100 ms)',                                                    'early_res',       'Reach_Early_Res',                                'KB_Early_Res'; ...
        'Late_Response',                'Initiated / Responded Too Late (Reaching >340 ms; Keyboard >740 ms)',               'late_res',        'Reach_Late_Res',                                 'KB_Late_Res'; ...
        'Very_Slow_Movement',           'Off-line Analysis Slow Movement (> Mean + 3 SD Duration)',                         'very_slow',       'Reach_Very_Slow_Mvmnt',                          ''; ...
        'Incorrect_Target',             'Incorrect Target / Key Choice',                                                    'incorrect',       'Reach_Incorrect',                                'KB_Incorrect'; ...
        'Quit',                         'Aborted / Quit Trial',                                                             'quit',            'Reach_Quit',                                     'KB_Quit'; ...
        'Total_Offline_Screen',         'Total Excluded by Behavioral & Kinematic Criteria',                                'total_offline',   'Reach_Total_Offline_Technical_and_Behavioral',   'KB_Total_Offline_Technical_and_Behavioral'; ...
        'PAS_gt_1',                     'Subliminal Awareness Criterion (PAS > 1)',                                         'pas_gt_1',        'Reach_PAS_gt_1',                                 'KB_PAS_gt_1'; ...
        'Total_Excluded_incl_PAS_gt_1', 'Grand Total Excluded Trials (Including PAS > 1)',                                  'total_excl',      'Reach_Total_Excluded_incl_PAS',                  'KB_Total_Excluded_incl_PAS'};

    partA_rows = {};
    partB_rows = {};
    excl_stats = struct();
    excl_stats.items = {};

    for i = 1:size(reasons_map, 1)
        r_code  = reasons_map{i, 1};
        r_label = reasons_map{i, 2};
        r_key   = reasons_map{i, 3};
        c_r     = reasons_map{i, 4};
        c_k     = reasons_map{i, 5};
        idx = find(strcmp(string(s.Exclusion_Reason), r_code), 1);
        if isempty(idx), continue; end

        r_f1_m = num_val(s.Reach_TrajNorm_Mean_Pct(idx));
        r_f1_s = num_val(s.Reach_TrajNorm_SD_Pct(idx));
        r_f3_m = num_val(s.Reach_noTrajNorm_Mean_Pct(idx));
        r_f3_s = num_val(s.Reach_noTrajNorm_SD_Pct(idx));
        r_f1_str = sprintf('%.2f%% (%.2f%%)', r_f1_m, r_f1_s);
        r_f3_str = sprintf('%.2f%% (%.2f%%)', r_f3_m, r_f3_s);

        k_m = num_val(s.Keyboard_Mean_Pct(idx));
        k_s = num_val(s.Keyboard_SD_Pct(idx));
        if isnan(k_m)
            kb_str = 'N/A (Reaching Only)';
            pct_t_str = 'N/A (Reaching Only)';
            pct_p_str = 'N/A';
            pct_ci_str = 'N/A';
            pct_dz_str = 'N/A';
            ps_pct = struct('t', NaN, 'df', NaN, 'p', NaN, 'diff_mean', NaN, 'ci_low', NaN, 'ci_high', NaN, 'dz', NaN);
        else
            kb_str = sprintf('%.2f%% (%.2f%%)', k_m, k_s);
            rp = v_pct.([c_r '_Pct']);
            kp = v_pct.([c_k '_Pct']);
            ps_pct = calc_paired_stats(rp, kp);
            if ps_pct.sd_diff == 0
                pct_t_str = sprintf('t(%d) = 0.000 (0%% both)', ps_pct.df);
                pct_p_str = '1.0000';
                pct_ci_str = '0.00% [0.00%, 0.00%]';
                pct_dz_str = '0.000';
            else
                pct_t_str  = sprintf('t(%d) = %.3f', ps_pct.df, ps_pct.t);
                pct_p_str  = format_p_display(ps_pct.p);
                pct_ci_str = sprintf('%.2f%% [%.2f%%, %.2f%%]', ps_pct.diff_mean, ps_pct.ci_low, ps_pct.ci_high);
                pct_dz_str = sprintf('%.3f', ps_pct.dz);
            end
        end

        partA_rows(end+1, :) = {r_label, r_f1_str, r_f3_str, kb_str, pct_t_str, pct_p_str, pct_ci_str, pct_dz_str}; %#ok<AGROW>

        % Raw counts for PART B
        rc_vec = v_cnt.(c_r);
        r_sum = sum(rc_vec); r_c_m = mean(rc_vec); r_c_s = std(rc_vec);
        r_cnt_str = sprintf('%.2f (%.2f)', r_c_m, r_c_s);

        if isempty(c_k)
            k_sum = NaN; k_c_m = NaN; k_c_s = NaN;
            k_sum_out = 'N/A';
            k_cnt_str = 'N/A (Reaching Only)';
            cnt_t_str = 'N/A (Reaching Only)';
            cnt_p_str = 'N/A';
            cnt_ci_str = 'N/A';
            cnt_dz_str = 'N/A';
            ps_cnt = struct('t', NaN, 'df', NaN, 'p', NaN, 'diff_mean', NaN, 'ci_low', NaN, 'ci_high', NaN, 'dz', NaN);
        else
            kc_vec = v_cnt.(c_k);
            k_sum = sum(kc_vec); k_c_m = mean(kc_vec); k_c_s = std(kc_vec);
            k_sum_out = k_sum;
            k_cnt_str = sprintf('%.2f (%.2f)', k_c_m, k_c_s);
            ps_cnt = calc_paired_stats(rc_vec, kc_vec);
            if ps_cnt.sd_diff == 0
                cnt_t_str  = sprintf('t(%d) = 0.000 (0 both)', ps_cnt.df);
                cnt_p_str  = '1.0000';
                cnt_ci_str = '0.00 [0.00, 0.00]';
                cnt_dz_str = '0.000';
            else
                cnt_t_str  = sprintf('t(%d) = %.3f', ps_cnt.df, ps_cnt.t);
                cnt_p_str  = format_p_display(ps_cnt.p);
                cnt_ci_str = sprintf('%.2f [%.2f, %.2f]', ps_cnt.diff_mean, ps_cnt.ci_low, ps_cnt.ci_high);
                cnt_dz_str = sprintf('%.3f', ps_cnt.dz);
            end
        end

        partB_rows(end+1, :) = {r_label, r_sum, r_cnt_str, k_sum_out, k_cnt_str, cnt_t_str, cnt_p_str, cnt_ci_str, cnt_dz_str}; %#ok<AGROW>

        it = struct('key', r_key, 'label', r_label, ...
            'reach_pct_mean', r_f1_m, 'reach_pct_sd', r_f1_s, ...
            'reach_temp_pct_mean', r_f3_m, 'reach_temp_pct_sd', r_f3_s, ...
            'kb_pct_mean', k_m, 'kb_pct_sd', k_s, ...
            'pct_cmp', ps_pct, ...
            'reach_cnt_sum', r_sum, 'reach_cnt_mean', r_c_m, 'reach_cnt_sd', r_c_s, ...
            'kb_cnt_sum', k_sum, 'kb_cnt_mean', k_c_m, 'kb_cnt_sd', k_c_s, ...
            'cnt_cmp', ps_cnt);
        excl_stats.items{end+1} = it; %#ok<AGROW>
    end

    % Append Online Speed-Up Warning (>420 ms, not offline-excluded) + Valid Included Trial Counts to PART B
    rc_online = v_cnt.Reach_Slow_Mvmnt_Online;
    partB_rows(end+1, :) = {'On-line ''Speed Up'' Feedback (>420 ms, Not Excluded)', sum(rc_online), ...
        sprintf('%.2f (%.2f)', mean(rc_online), std(rc_online)), 'N/A', 'N/A (Reaching Only)', ...
        'N/A', 'N/A', 'N/A', 'N/A'}; %#ok<AGROW>
    excl_stats.online_slow_sum = sum(rc_online);
    excl_stats.online_slow_mean = mean(rc_online);
    excl_stats.online_slow_sd = std(rc_online);

    pm1 = fst.Participant_Measures.TrajNorm_noStandardization;
    pm1_v = filter_pm_by_good_subs(pm1, good_subs);
    inc_specs = { ...
        'Included Valid PAS=1 Trials (Total)',       'valid_total', 'N_Reach_Valid', 'N_KB_Valid'; ...
        'Included Valid PAS=1 Trials (Congruent)',   'valid_con',   'N_Reach_Con',   'N_KB_Con'; ...
        'Included Valid PAS=1 Trials (Incongruent)', 'valid_incon', 'N_Reach_Incon', 'N_KB_Incon'};
    excl_stats.included = {};
    for k = 1:size(inc_specs, 1)
        rc_v = pm1_v.(inc_specs{k, 3});
        kc_v = pm1_v.(inc_specs{k, 4});
        ps_v = calc_paired_stats(rc_v, kc_v);
        partB_rows(end+1, :) = {inc_specs{k, 1}, sum(rc_v), sprintf('%.2f (%.2f)', mean(rc_v), std(rc_v)), ...
            sum(kc_v), sprintf('%.2f (%.2f)', mean(kc_v), std(kc_v)), ...
            sprintf('t(%d) = %.3f', ps_v.df, ps_v.t), format_p_display(ps_v.p), ...
            sprintf('%.2f [%.2f, %.2f]', ps_v.diff_mean, ps_v.ci_low, ps_v.ci_high), sprintf('%.3f', ps_v.dz)}; %#ok<AGROW>
        excl_stats.included{end+1} = struct('key', inc_specs{k, 2}, ...
            'reach_sum', sum(rc_v), 'reach_mean', mean(rc_v), 'reach_sd', std(rc_v), ...
            'kb_sum', sum(kc_v), 'kb_mean', mean(kc_v), 'kb_sd', std(kc_v), 'cmp', ps_v); %#ok<AGROW>
    end

    t_A = cell2table(partA_rows, 'VariableNames', ...
        {'Exclusion_Criterion', 'Reaching_Task_PreReg_Mean_SD_Pct', 'Reaching_Task_TemporalFullTraj_Mean_SD_Pct', ...
         'Keyboard_Task_Mean_SD_Pct', 'Reach_vs_KB_t_df', 'Reach_vs_KB_p_value', ...
         'Reach_vs_KB_Mean_Diff_95CI_Pct', 'Reach_vs_KB_Cohens_dz'});
    t_B = cell2table(partB_rows, 'VariableNames', ...
        {'Criterion', 'Reaching_Sum_Count', 'Reaching_Mean_SD_Count', 'Keyboard_Sum_Count', 'Keyboard_Mean_SD_Count', ...
         'Reach_vs_KB_t_df', 'Reach_vs_KB_p_value', 'Reach_vs_KB_Mean_Diff_95CI_Count', 'Reach_vs_KB_Cohens_dz'});

    c1 = table_to_titled_cells('PART A: TRIAL EXCLUSION PERCENTAGES & PAIRED REACHING VS. KEYBOARD TESTS (N = 30)', t_A);
    c2 = table_to_titled_cells('PART B: RAW TRIAL COUNTS PER CRITERION & INCLUDED PAS=1 TRIALS (Valid Cohort N = 30, 240 trials/task/participant)', t_B);
    max_w = max(size(c1, 2), size(c2, 2));
    cells_out = vertcat_pad({c1, cell(2, max_w), c2}, max_w);
end

% =========================================================================
% BUILDER 4: Sheet 4 (Participant_Exclusions)
% =========================================================================
function cells_out = build_sheet4_participant_exclusions(f1_dir, good_subs, p)
    all_45_subs = 46:90;
    n_45 = numel(all_45_subs);

    % Numeric matrices for the 45 participants (NaN for no-data participants 46, 48, 86)
    % Columns (20 numeric columns):
    % Reaching (12 cols):
    %  1. Total Reaching Trials
    %  2. Invalid / Bad Tracking (Hole + Missing +Missed Target + Bad Stim Dur + Quit)
    %  3. Trajectory Too Short (<100 ms / <30 cm)
    %  4. Initiated Too Early (<100 ms)
    %  5. Initiated Too Late (>340 ms)
    %  6. Incorrect Target Choice
    %  7. Off-line Analysis Slow Movement (>3 SD)
    %  8. Subliminal Awareness Excluded (PAS > 1)
    %  9. Total Excluded Reaching Trials
    % 10. Included PAS=1 Trials: Congruent
    % 11. Included PAS=1 Trials: Incongruent
    % 12. On-line 'Speed Up' Feedback (>420 ms, Not Excluded) [Placed AFTER summary cols!]
    % Keyboard (8 cols):
    % 13. Total Keyboard Trials
    % 14. Bad Stim Dur / Quit
    % 15. Response Too Early (<100 ms)
    % 16. Response Too Late (>740 ms)
    % 17. Incorrect Key Press
    % 18. Subliminal Awareness Excluded (PAS > 1)
    % 19. Total Excluded Keyboard Trials
    % 20. Included PAS=1 Trials: Congruent
    % 21. Included PAS=1 Trials: Incongruent

    mat_counts = nan(n_45, 21);
    mat_pcts   = nan(n_45, 21);
    status_strs = cell(n_45, 1);
    has_data_mask = false(n_45, 1);
    is_incl_mask  = false(n_45, 1);

    bt = load(fullfile(f1_dir, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat'));

    for i = 1:n_45
        s = all_45_subs(i);
        rd_file = fullfile(f1_dir, sprintf('sub%dday2_reach_data_proc.mat', s));
        kd_file = fullfile(f1_dir, sprintf('sub%dday2_keyboard_data_proc.mat', s));
        st_file = fullfile(f1_dir, sprintf('sub%dday2_sorted_trials_target_x_to.mat', s));

        if ~exist(rd_file, 'file') || ~exist(kd_file, 'file') || s > numel(bt.reach_bad_trials) || isempty(bt.reach_bad_trials{s})
            status_strs{i} = 'Technical Issue - No Data Collected';
            continue;
        end
        has_data_mask(i) = true;
        is_inc = ismember(s, good_subs);
        is_incl_mask(i) = is_inc;

        rd = load(rd_file).reach_data_table;
        rd(rd.practice >= 1, :) = [];
        kd = load(kd_file).keyboard_data_table;
        kd(kd.practice >= 1, :) = [];
        r_bt = bt.reach_bad_trials{s};
        k_bt = bt.keyboard_bad_trials{s};
        st = load(st_file);

        n_r = height(rd);
        n_k = height(kd);

        % Reaching columns
        r_bad_track = (r_bt.hole_in_data > 0) | (r_bt.missing_data > 0) | ...
                      (r_bt.missed_target > 0) | (r_bt.bad_stim_dur > 0) | (r_bt.quit > 0);
        r_short     = (r_bt.diff_len > 0) | (r_bt.short_traj > 0);
        r_early     = (r_bt.early_res > 0);
        r_late      = (r_bt.late_res > 0);
        r_incorr    = (r_bt.incorrect > 0);
        r_vslow     = (r_bt.very_slow_mvmnt > 0);
        r_online_fb = (r_bt.slow_mvmnt > 0);

        r_behav_excl = r_bad_track | r_short | r_early | r_late | r_incorr | r_vslow;
        r_pas_gt1    = ismember(rd.pas, [2, 3, 4]);
        r_tot_excl   = r_behav_excl | ~ismember(rd.pas, 1);

        r_con_inc = numel(st.r_trial.react.con);
        r_inc_inc = numel(st.r_trial.react.incon);

        % Keyboard columns
        k_bad_stim = (k_bt.bad_stim_dur > 0) | (k_bt.quit > 0);
        k_early    = (k_bt.early_res > 0);
        k_late     = (k_bt.late_res > 0);
        k_incorr   = (k_bt.incorrect > 0);
        k_behav_excl = k_bad_stim | k_early | k_late | k_incorr;
        k_pas_gt1  = ismember(kd.pas, [2, 3, 4]);
        k_tot_excl = k_behav_excl | ~ismember(kd.pas, 1);

        k_con_inc = numel(st.k_trial.rt.con);
        k_inc_inc = numel(st.k_trial.rt.incon);

        if is_inc
            status_strs{i} = 'Included (Main Sample, >=25 Trials/Cond)';
        else
            status_strs{i} = sprintf('Excluded (<25 Valid PAS=1 Trials/Cond: Reach=%d/%d, KB=%d/%d)', ...
                r_con_inc, r_inc_inc, k_con_inc, k_inc_inc);
        end

        c_row = [n_r, sum(r_bad_track), sum(r_short), sum(r_early), sum(r_late), ...
                 sum(r_incorr), sum(r_vslow), sum(r_pas_gt1), sum(r_tot_excl), ...
                 r_con_inc, r_inc_inc, sum(r_online_fb), ...
                 n_k, sum(k_bad_stim), sum(k_early), sum(k_late), sum(k_incorr), ...
                 sum(k_pas_gt1), sum(k_tot_excl), k_con_inc, k_inc_inc];
        mat_counts(i, :) = c_row;

        p_row = [100, c_row(2:12) / n_r * 100, 100, c_row(14:21) / n_k * 100];
        mat_pcts(i, :) = round(p_row, 2);
    end

    % Build formatted cell array with super-header row ("Reaching Task" and "Keyboard Task")
    super_hdr = cell(1, 23);
    super_hdr{1} = 'PARTICIPANT INFO';
    super_hdr{3} = '=== REACHING TASK ===';
    super_hdr{15} = '=== KEYBOARD TASK ===';

    col_hdr = { ...
        'Participant', 'Inclusion Status', ...
        'Total Reaching Trials', 'Invalid / Bad Tracking', 'Trajectory Too Short (<100 ms)', ...
        'Initiated Too Early (<100 ms)', 'Initiated Too Late (>340 ms)', 'Incorrect Target Choice', ...
        'Off-line Analysis Slow Movement (>3 SD)', 'Subliminal Awareness Excluded (PAS > 1)', ...
        'Total Excluded Reaching Trials', 'Included PAS=1 Trials: Congruent', ...
        'Included PAS=1 Trials: Incongruent', 'On-line ''Speed Up'' Feedback (>420 ms, Not Excluded)', ...
        'Total Keyboard Trials', 'Display / Quit Error', 'Response Too Early (<100 ms)', ...
        'Response Too Late (>740 ms)', 'Incorrect Key Press', 'Subliminal Awareness Excluded (PAS > 1)', ...
        'Total Excluded Keyboard Trials', 'Included PAS=1 Trials: Congruent', ...
        'Included PAS=1 Trials: Incongruent'};

    cells_counts = build_participant_excl_block('PART A: TRIAL COUNTS PER PARTICIPANT (N = 45 Recruited Participants: Prtcp 46 to Prtcp 90)', ...
        super_hdr, col_hdr, all_45_subs, status_strs, has_data_mask, is_incl_mask, mat_counts, false);

    cells_pcts = build_participant_excl_block('PART B: TRIAL PERCENTAGES (%) PER PARTICIPANT (N = 45 Recruited Participants: Prtcp 46 to Prtcp 90)', ...
        super_hdr, col_hdr, all_45_subs, status_strs, has_data_mask, is_incl_mask, mat_pcts, true);

    blank_row = cell(1, 23);
    cells_out = [cells_counts; blank_row; blank_row; cells_pcts];
end

function tf = col_nz(tbl, col_name)
    tf = false(height(tbl), 1);
    if ismember(col_name, tbl.Properties.VariableNames)
        c = tbl.(col_name);
        if iscell(c) || isstring(c)
            tf = ~cellfun(@isempty, cellstr(c));
        else
            tf = (c ~= 0 & ~isnan(c));
        end
    end
end

function block_cells = build_participant_excl_block(sec_title, super_hdr, col_hdr, all_45_subs, status_strs, has_data_mask, is_incl_mask, mat_vals, is_pct)
    n_cols = numel(col_hdr);
    title_row = cell(1, n_cols);
    title_row{1} = sec_title;

    data_rows = cell(numel(all_45_subs), n_cols);
    for i = 1:numel(all_45_subs)
        data_rows{i, 1} = sprintf('Prtcp %d', all_45_subs(i));
        data_rows{i, 2} = status_strs{i};
        if has_data_mask(i)
            for c = 1:size(mat_vals, 2)
                if is_pct
                    data_rows{i, c + 2} = round(mat_vals(i, c), 2);
                else
                    data_rows{i, c + 2} = mat_vals(i, c);
                end
            end
        end
    end

    % Summary Group 1: Included Participants (N = 30)
    inc_mat = mat_vals(is_incl_mask, :);
    sum_inc = build_3_summary_rows('Included Participants (N = 30)', inc_mat, n_cols);

    % Summary Group 2: Excluded Participants With Data (N = 12)
    excl_data_mask = has_data_mask & ~is_incl_mask;
    exc_mat = mat_vals(excl_data_mask, :);
    sum_exc = build_3_summary_rows('Excluded Participants With Data (N = 12)', exc_mat, n_cols);

    % Summary Group 3: No-Data Participants (N = 3: Prtcp 46, 48, 86)
    nodata_row = cell(1, n_cols);
    nodata_row{1} = 'No-Data Participants (N = 3: Prtcp 46, 48, 86)';
    nodata_row{2} = 'Technical Issue - No Data Collected (3 Participants)';

    blank_row = cell(1, n_cols);
    block_cells = [title_row; super_hdr; col_hdr; data_rows; blank_row; sum_inc; blank_row; sum_exc; blank_row; nodata_row];
end

function s_rows = build_3_summary_rows(grp_label, m_vals, n_cols)
    s_rows = cell(3, n_cols);
    s_rows{1, 1} = [grp_label, ' - Mean'];
    s_rows{2, 1} = [grp_label, ' - SD'];
    s_rows{3, 1} = [grp_label, ' - Range (Min - Max)'];
    s_rows{1, 2} = 'Group Mean';
    s_rows{2, 2} = 'Group Standard Deviation';
    s_rows{3, 2} = 'Group Minimum to Maximum';

    for c = 1:size(m_vals, 2)
        v = m_vals(:, c);
        s_rows{1, c + 2} = round(mean(v, 'omitnan'), 2);
        s_rows{2, c + 2} = round(std(v, 0, 'omitnan'), 2);
        s_rows{3, c + 2} = sprintf('%.1f - %.1f', min(v, [], 'omitnan'), max(v, [], 'omitnan'));
    end
end

% =========================================================================
% BUILDER 5: Sheet 5 (Participants_Temporal_Dynamics)
% =========================================================================
function cells_out = build_sheet5_temporal_dynamics(td)
    c1 = table_to_titled_cells('PART A: GROUP-LEVEL REACHING ONSET DISTRIBUTIONS (All PAS & Target Choices; N = 42 Valid & Analytic Cohorts N = 30 / N = 31; Drives Fig S3a)', td.Group_Onset_Bins);
    c2 = table_to_titled_cells('PART B: GROUP-LEVEL REACHING DURATION DISTRIBUTIONS (All PAS & Target Choices; N = 42 Valid & Analytic Cohorts N = 30 / N = 31; Drives Fig S3b)', td.Group_MT_Bins);
    c3 = table_to_titled_cells('PART C: GROUP-LEVEL OVERALL RESPONSE DURATION DISTRIBUTIONS (All PAS & Target Choices; N = 42 Valid & Analytic Cohorts N = 30 / N = 31; Drives Fig S3c)', td.Group_Overall_RT_Bins);
    c4 = table_to_titled_cells('PART D: PARTICIPANT-LEVEL TEMPORAL PARAMETERS & ACTIVE MOVEMENT COUNTS OVER TIME (N = 45 Participants: Prtcp 46 to Prtcp 90; Drives Fig S4)', td.Participant_Temporal_Summary);

    max_w = max([size(c1,2), size(c2,2), size(c3,2), size(c4,2)]);
    cells_out = vertcat_pad({c1, cell(2, max_w), c2, cell(2, max_w), c3, cell(2, max_w), c4}, max_w);
end

% =========================================================================
% BUILDER 6: Sheet 6 (Table_2_PAS_Visibility)
% =========================================================================
function cells_out = build_sheet6_pas_visibility(pas_struct)
    c1 = table_to_titled_cells('PART A: SUBJECTIVE VISIBILITY (PAS 1-4) DISTRIBUTION & MEAN SCORES BY TASK AND CONGRUENCY (N = 30)', pas_struct.PAS_Summary);
    c2 = table_to_titled_cells('PART B: STATISTICAL COMPARISONS OF SUBJECTIVE VISIBILITY (PAS) ACROSS TASKS AND CONGRUENCY', pas_struct.PAS_Statistical_Tests);

    by_sub = pas_struct.PAS_By_Sub;
    if ismember('Participant', by_sub.Properties.VariableNames)
        by_sub.Participant = format_prtcp_col(by_sub.Participant);
    elseif ismember('Sub', by_sub.Properties.VariableNames)
        by_sub.Sub = format_prtcp_col(by_sub.Sub);
        by_sub.Properties.VariableNames{'Sub'} = 'Participant';
    end
    c3 = table_to_titled_cells('PART C: PARTICIPANT-LEVEL SUBJECTIVE VISIBILITY (PAS) BREAKDOWN (N = 30)', by_sub);

    max_w = max([size(c1,2), size(c2,2), size(c3,2)]);
    cells_out = vertcat_pad({c1, cell(2, max_w), c2, cell(2, max_w), c3}, max_w);
end

% =========================================================================
% BUILDER 7: Sheet 7 (Objective_Prime_Awareness)
% =========================================================================
function cells_out = build_sheet7_objective_awareness(pps, pps_sub)
    % Format summary table with readable labels
    pps.Trial_Type = ["Incongruent Trials (Main Text Fig 2)"; "Congruent Trials (Supplementary Fig S5a)"];

    % Build JZS Bayes Factor Prior Sensitivity Table (Fig S5b)
    r_scales = [0.10, 0.25, 0.50, sqrt(2)/2, 1.00, 1.50]';
    r_labels = {'Ultrafine (r = 0.10)'; 'Narrow (r = 0.25)'; 'Medium-Narrow (r = 0.50)'; ...
                'Default JZS Medium (r = 0.707)'; 'Wide (r = 1.00)'; 'Ultrawide (r = 1.50)'};
    bf_rows = cell(numel(r_scales), 6);
    for i = 1:numel(r_scales)
        r = r_scales(i);
        bf_r_inc = compute_jzs_bf01_local(pps.reach_tVal(1), pps.reach_df(1), r);
        bf_k_inc = compute_jzs_bf01_local(pps.kb_tVal(1),    pps.kb_df(1),    r);
        bf_r_con = compute_jzs_bf01_local(pps.reach_tVal(2), pps.reach_df(2), r);
        bf_k_con = compute_jzs_bf01_local(pps.kb_tVal(2),    pps.kb_df(2),    r);
        bf_rows(i, :) = {r_labels{i}, round(r, 3), round(bf_r_inc, 3), round(bf_k_inc, 3), round(bf_r_con, 3), round(bf_k_con, 3)};
    end
    bf_tbl = cell2table(bf_rows, 'VariableNames', ...
        {'Cauchy_Prior_Specification', 'Scale_Factor_r', ...
         'Reaching_Incongruent_BF01', 'Keyboard_Incongruent_BF01', ...
         'Reaching_Congruent_BF01', 'Keyboard_Congruent_BF01'});

    if ismember('Sub', pps_sub.Properties.VariableNames)
        pps_sub.Sub = format_prtcp_col(pps_sub.Sub);
        pps_sub.Properties.VariableNames{'Sub'} = 'Participant';
    elseif ismember('Participant', pps_sub.Properties.VariableNames)
        pps_sub.Participant = format_prtcp_col(pps_sub.Participant);
    end

    c1 = table_to_titled_cells('PART A: OBJECTIVE PRIME AWARENESS GROUP SUMMARY & ONE-SAMPLE TESTS VS. CHANCE (50%)', pps);
    c2 = table_to_titled_cells('PART B: JZS BAYES FACTOR PRIOR SENSITIVITY ANALYSIS (BF01 IN FAVOR OF NULL HYPOTHESIS; Drives Fig S5b)', bf_tbl);
    c3 = table_to_titled_cells('PART C: PARTICIPANT-LEVEL OBJECTIVE PRIME AWARENESS ACCURACY (N = 30)', pps_sub);

    max_w = max([size(c1,2), size(c2,2), size(c3,2)]);
    cells_out = vertcat_pad({c1, cell(2, max_w), c2, cell(2, max_w), c3}, max_w);
end

function bf01 = compute_jzs_bf01_local(t_val, df, r_scale)
    n_obs = df + 1;
    num_null = (1 + (t_val^2) / df)^(-(df + 1) / 2);
    integrand = @(g) ((1 + n_obs .* g .* (r_scale^2)).^(-0.5)) .* ...
                     ((1 + (t_val^2) ./ ((1 + n_obs .* g .* (r_scale^2)) .* df)).^(-(df + 1) / 2)) .* ...
                     ((2 * pi)^(-0.5)) .* (g.^(-1.5)) .* exp(-1 ./ (2 .* g));
    denom_alt = integral(integrand, 0, Inf, 'RelTol', 1e-8, 'AbsTol', 1e-11);
    bf01 = num_null / denom_alt;
end

% =========================================================================
% BUILDER 8: Sheet 8 (COM_Thresholding)
% =========================================================================
function [cells_out, com_perf_stats] = build_sheet8_com_thresholding(com_sweep_tbl, f1_dir, good_subs)
    c1 = table_to_titled_cells('PART A: CHANGES OF MIND (COM) DWELL-TIME THRESHOLD SWEEP (CORRECT VS. INCORRECT & CONGRUENCY; Drives Fig S7)', com_sweep_tbl);

    % Compute PART B directly from processed trial data (All PAS & PAS=1, minIncorr >= 8)
    bt = load(fullfile(f1_dir, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat'));
    all_c_m = []; all_i_m = []; all_c_cell = {}; all_i_n = [];
    p1_c_m  = []; p1_i_m  = [];
    for s = good_subs(:)'
        rd_f = fullfile(f1_dir, sprintf('sub%dday2_reach_data_proc.mat', s));
        rd = load(rd_f).reach_data_table;
        rd(rd.practice >= 1, :) = [];
        r_bt = bt.reach_bad_trials{s};
        other_bad = (r_bt.hole_in_data > 0) | (r_bt.missing_data > 0) | (r_bt.diff_len > 0) | ...
                    (r_bt.short_traj > 0) | (r_bt.missed_target > 0) | (r_bt.bad_stim_dur > 0) | ...
                    (r_bt.late_res > 0) | (r_bt.very_slow_mvmnt > 0) | (r_bt.early_res > 0) | (r_bt.quit > 0);
        c_mask = ~other_bad & (rd.target_correct == 1);
        i_mask = ~other_bad & (rd.target_correct == 0);
        if sum(i_mask) >= 8
            all_c_m(end+1, 1) = mean(rd.com(c_mask)); %#ok<AGROW>
            all_i_m(end+1, 1) = mean(rd.com(i_mask)); %#ok<AGROW>
            all_c_cell{end+1} = rd.com(c_mask); %#ok<AGROW>
            all_i_n(end+1, 1) = sum(i_mask); %#ok<AGROW>
        end
        c_p1 = c_mask & (rd.pas == 1);
        i_p1 = i_mask & (rd.pas == 1);
        if sum(i_p1) >= 8
            p1_c_m(end+1, 1) = mean(rd.com(c_p1)); %#ok<AGROW>
            p1_i_m(end+1, 1) = mean(rd.com(i_p1)); %#ok<AGROW>
        end
    end

    ps_main = calc_paired_stats(all_c_m, all_i_m);
    ps_pas1 = calc_paired_stats(p1_c_m, p1_i_m);

    % 10,000-iteration random downsampling of correct trials to match min(n_inc, 8) / participant n_inc
    rng(42, 'twister');
    n_iter = 10000;
    n_sub_c = numel(all_c_cell);
    boot_p  = nan(n_iter, 1);
    boot_dz = nan(n_iter, 1);
    n_c_avail = cellfun(@numel, all_c_cell);
    for it = 1:n_iter
        ds_c = nan(n_sub_c, 1);
        for si = 1:n_sub_c
            k_pick = randperm(n_c_avail(si), all_i_n(si));
            ds_c(si) = mean(all_c_cell{si}(k_pick));
        end
        d_ds = ds_c - all_i_m;
        sd_ds = std(d_ds);
        boot_dz(it) = mean(d_ds) / sd_ds;
        t_ds = mean(d_ds) / (sd_ds / sqrt(n_sub_c));
        boot_p(it) = 2 * tcdf(-abs(t_ds), n_sub_c - 1);
    end

    t2_rows = { ...
        'Current Offline Pipeline (All PAS, minIncorr >= 8)', numel(all_c_m), ...
        sprintf('%.3f (%.3f)', mean(all_c_m), std(all_c_m)), ...
        sprintf('%.3f (%.3f)', mean(all_i_m), std(all_i_m)), ...
        sprintf('%.3f (%.3f)', ps_main.diff_mean, ps_main.sd_diff), ...
        sprintf('[%.3f, %.3f]', ps_main.ci_low, ps_main.ci_high), ...
        sprintf('t(%d) = %.4f', ps_main.df, ps_main.t), format_p_display(ps_main.p), ...
        sprintf('%.4f', ps_main.dz), ...
        sprintf('mean p = %s (100%% < .05=%s)', format_p_display(mean(boot_p)), sprintf('%.2f%%', mean(boot_p < 0.05)*100)), ...
        sprintf('median dz = %.4f', median(boot_dz)), ...
        'Computed directly from f1_dir using offline very_slow_mvmnt exclusion (excludes PAS-unfiltered slow/bad trials)'; ...
        'Sensitivity Check (PAS = 1 Only, minIncorr >= 8)', numel(p1_c_m), ...
        sprintf('%.3f (%.3f)', mean(p1_c_m), std(p1_c_m)), ...
        sprintf('%.3f (%.3f)', mean(p1_i_m), std(p1_i_m)), ...
        sprintf('%.3f (%.3f)', ps_pas1.diff_mean, ps_pas1.sd_diff), ...
        sprintf('[%.3f, %.3f]', ps_pas1.ci_low, ps_pas1.ci_high), ...
        sprintf('t(%d) = %.4f', ps_pas1.df, ps_pas1.t), format_p_display(ps_pas1.p), ...
        sprintf('%.4f', ps_pas1.dz), 'N/A', 'N/A', ...
        'Restricted strictly to subliminal PAS = 1 trials'; ...
        'Legacy Archival Reference (24-10-24 Pre-AccThresh MAT)', 25, ...
        '1.860 (0.410)', '1.390 (0.540)', '0.470 (0.410)', '[0.300, 0.640]', ...
        't(24) = 5.6848', '7.43e-06', '1.1370', 'Reproduced by permutation', '1.15 (Ver01)', ...
        'Archival note: Legacy 24-10-24 MAT used earlier acceleration threshold (note Ver01 had t(25) typo for df=24)'};

    t2_tbl = cell2table(t2_rows, 'VariableNames', ...
        {'Analysis_Scope', 'N_Participants', 'Correct_Mean_SD', 'Incorrect_Mean_SD', ...
         'Diff_Correct_minus_Incorrect_Mean_SD', 'CI_95', 'Test_Statistic', 'p_value', ...
         'Cohens_dz', 'Downsample_10k_p', 'Downsample_10k_dz', 'Notes'});
    c2 = table_to_titled_cells('PART B: DIRECT COMPARISON OF CHANGES OF MIND (COM) IN CORRECT VS. INCORRECT TRIALS (Min Incorrect >= 8)', t2_tbl);
    max_w = max(size(c1,2), size(c2,2));
    cells_out = vertcat_pad({c1, cell(2, max_w), c2}, max_w);

    com_perf_stats = struct( ...
        'main', struct('n', numel(all_c_m), 'corr_mean', mean(all_c_m), 'corr_sd', std(all_c_m), ...
                       'inc_mean', mean(all_i_m), 'inc_sd', std(all_i_m), 'ps', ps_main, ...
                       'ds_mean_p', mean(boot_p), 'ds_med_dz', median(boot_dz), 'ds_sig_pct', mean(boot_p < 0.05)*100), ...
        'pas1', struct('n', numel(p1_c_m), 'corr_mean', mean(p1_c_m), 'corr_sd', std(p1_c_m), ...
                       'inc_mean', mean(p1_i_m), 'inc_sd', std(p1_i_m), 'ps', ps_pas1), ...
        'legacy', struct('n', 25, 'df', 24, 'corr_mean', 1.86, 'corr_sd', 0.41, ...
                         'inc_mean', 1.39, 'inc_sd', 0.54, 'diff_mean', 0.47, 'diff_sd', 0.41, ...
                         'ci_low', 0.30, 'ci_high', 0.64, 't', 5.6848, 'p', 7.43e-6, 'dz', 1.1370));
end

% =========================================================================
% BUILDER 9: Sheet 9 (Split_Half_Reliability)
% =========================================================================
function tbl_out = build_sheet9_reliability(rel_tbl)
    tbl_out = rel_tbl;
    if ismember('Flavor', tbl_out.Properties.VariableNames)
        f_col = string(tbl_out.Flavor);
        f_col = replace(f_col, "TrajNorm_noStandardization", "Pre-registered analysis");
        f_col = replace(f_col, "TrajNorm_Standardization",   "Robustness analysis (Z-scored)");
        f_col = replace(f_col, "noTrajNorm_noStandardization", "Temporal full-trajectory analysis");
        tbl_out.Flavor = cellstr(f_col);
        tbl_out.Properties.VariableNames{'Flavor'} = 'Analysis';
    end
    if ismember('Measure', tbl_out.Properties.VariableNames)
        m_col = string(tbl_out.Measure);
        m_col = replace(m_col, "Total Distance", "Distance Traveled");
        m_col = replace(m_col, "Reaching MT", "Reaching Duration");
        m_col = replace(m_col, "Changes of Mind (COM)", "COM");
        m_col = replace(m_col, "Deviation From Center", "Deviance From Center");
        m_col = replace(m_col, "Movement Variation (X-STD)", "Horizontal Movement Variation");
        m_col = replace(m_col, "Implied End Point (IEP)", "Implied Endpoint (Post-Hoc)");
        tbl_out.Measure = cellstr(m_col);
    end
end

% =========================================================================
% BUILDER 10: Sheet 10 (PreReg_WO_Long_Dur_Excl)
% =========================================================================
function cells_out = build_sheet10_wo_long_dur(fst)
    si = fst.SI_Reanalysis;
    t_sum   = scrub_flavor_in_table(si.si_summary_tbl);
    t_dec   = scrub_flavor_in_table(si.decomp_tbl);
    t_ft    = scrub_flavor_in_table(si.full_traj_clust_tbl);
    t_eff   = scrub_flavor_in_table(si.effects_tbl_f4);
    t_kb    = scrub_flavor_in_table(si.within_tbl_f4);
    t_f4f1  = scrub_flavor_in_table(si.f4_vs_f1_tbl);

    c1 = table_to_titled_cells('PART A: PRE-REGISTERED ANALYSIS WITHOUT EXCLUDING LONG MOVEMENT DURATIONS (N = 31) CONGRUENCY SUMMARY VS. PRE-REGISTERED ANALYSIS (N = 30)', t_sum);
    c2 = table_to_titled_cells('PART B: TRIAL-LEVEL VS. PARTICIPANT-LEVEL DECOMPOSITION WITHOUT LONG-DURATION EXCLUSION (INCLUDING REACH AREA & FULL-TRAJECTORY MEASURES)', t_dec);
    c3 = table_to_titled_cells('PART C: FULL-TRAJECTORY CLUSTER PERMUTATION STATISTICS (WITHOUT LONG-DURATION EXCLUSION, N = 31)', t_ft);
    c4 = table_to_titled_cells('PART D: BOOTSTRAP EFFECT SIZES SUMMARY WITHOUT LONG-DURATION EXCLUSION (Drives Fig S9a)', t_eff);
    c5 = table_to_titled_cells('PART E: SENSITIVITY COMPARISONS VS. KEYBOARD RT WITHOUT LONG-DURATION EXCLUSION (Drives Fig S9b)', t_kb);
    c6 = table_to_titled_cells('PART F: DIRECT PAIRED & FULL-SAMPLE EFFECT SIZE CONTRASTS (WITHOUT LONG-DURATION EXCLUSION VS. PRE-REGISTERED ANALYSIS)', t_f4f1);

    max_w = max([size(c1,2), size(c2,2), size(c3,2), size(c4,2), size(c5,2), size(c6,2)]);
    cells_out = vertcat_pad({c1, cell(2, max_w), c2, cell(2, max_w), c3, cell(2, max_w), ...
                             c4, cell(2, max_w), c5, cell(2, max_w), c6}, max_w);
end

% =========================================================================
% BUILDER 11: Sheet 11 (By_Participant_Measures)
% =========================================================================
function cells_out = build_sheet11_by_participant(fst)
    pm_struct = fst.Participant_Measures;
    t_f1 = scale_pm_columns(format_pm_table(pm_struct.TrajNorm_noStandardization), ...
        {'MAD_', 'Dev_From_Center_', 'IEP_', 'Movement_Variance_'}, 100.0);
    t_f2 = scale_pm_columns(format_pm_table(pm_struct.TrajNorm_Standardization), ...
        {'Dev_From_Center_', 'IEP_', 'Movement_Variance_'}, 100.0);
    t_f3 = scale_pm_columns(format_pm_table(pm_struct.noTrajNorm_noStandardization), ...
        {'MAD_', 'Dev_From_Center_', 'IEP_'}, 100.0);

    t_f4 = format_pm_table(scrub_flavor_in_table(fst.SI_Reanalysis.si_by_sub_tbl));

    c1 = table_to_titled_cells('PART A: PRE-REGISTERED ANALYSIS (N = 30) BY-PARTICIPANT MEANS (times ms, distances/spatial deviations cm, areas 10^2 cm^2)', t_f1);
    c2 = table_to_titled_cells('PART B: ROBUSTNESS ANALYSIS (Z-SCORED DISCRETE MEASURES; SPATIAL TRAJECTORY CLUSTERS cm, N = 30) BY-PARTICIPANT MEANS', t_f2);
    c3 = table_to_titled_cells('PART C: TEMPORAL FULL-TRAJECTORY ANALYSIS (N = 30) BY-PARTICIPANT MEANS (distances/spatial deviations cm, heading angle deg)', t_f3);
    c4 = table_to_titled_cells('PART D: PRE-REGISTERED ANALYSIS WITHOUT EXCLUDING LONG MOVEMENT DURATIONS (N = 31) BY-PARTICIPANT MEANS (distances/MAD cm, areas 10^2 cm^2)', t_f4);

    max_w = max([size(c1,2), size(c2,2), size(c3,2), size(c4,2)]);
    cells_out = vertcat_pad({c1, cell(2, max_w), c2, cell(2, max_w), c3, cell(2, max_w), c4}, max_w);
end

function tbl = scale_pm_columns(tbl, prefixes, factor)
    vn = tbl.Properties.VariableNames;
    for k = 1:numel(vn)
        name = vn{k};
        match = any(cellfun(@(pf) startsWith(name, pf), prefixes));
        if match && isnumeric(tbl.(name))
            tbl.(name) = tbl.(name) * factor;
        end
    end
end

function tbl = scrub_flavor_in_table(tbl)
    vn = tbl.Properties.VariableNames;
    for k = 1:numel(vn)
        s = vn{k};
        s = regexprep(s, '^Flavor_4_', 'WO_Long_Dur_', 'ignorecase');
        s = regexprep(s, '^F4_', 'WO_Long_Dur_', 'ignorecase');
        s = regexprep(s, '^F1_', 'PreReg_', 'ignorecase');
        if strcmpi(s, 'Flavor')
            s = 'Analysis';
        else
            s = regexprep(s, 'Flavor', 'Analysis', 'ignorecase');
        end
        vn{k} = s;
    end
    tbl.Properties.VariableNames = matlab.lang.makeUniqueStrings(vn);

    for k = 1:width(tbl)
        col = tbl{:, k};
        if isstring(col) || iscellstr(col) || iscell(col)
            is_str_col = isstring(col);
            for r = 1:numel(col)
                v = col(r);
                if iscell(v), val = v{1}; else, val = v; end
                if ~(ischar(val) || isstring(val)), continue; end
                txt = char(val);
                txt = regexprep(txt, 'TrajNorm_noStandardization', 'Pre-registered analysis');
                txt = regexprep(txt, 'TrajNorm_Standardization', 'Robustness analysis (Z-scored)');
                txt = regexprep(txt, 'noTrajNorm_noStandardization', 'Temporal full-trajectory analysis');
                txt = regexprep(txt, 'TrajNorm_noTimeExclusion', 'Pre-registered analysis without excluding long movement durations', 'ignorecase');
                txt = regexprep(txt, 'noTimeExclusion[_\s]*N31', 'Pre-registered analysis without excluding long movement durations (N = 31)', 'ignorecase');
                txt = regexprep(txt, 'Flavor\s*1', 'Pre-registered analysis', 'ignorecase');
                txt = regexprep(txt, 'Flavor\s*2', 'Robustness analysis (Z-scored)', 'ignorecase');
                txt = regexprep(txt, 'Flavor\s*3', 'Temporal full-trajectory analysis', 'ignorecase');
                txt = regexprep(txt, 'Flavor\s*4', 'Pre-registered analysis without excluding long movement durations', 'ignorecase');
                txt = regexprep(txt, '\<flavors\>', 'analyses', 'ignorecase');
                txt = regexprep(txt, '\<flavor\>', 'analysis', 'ignorecase');
                if is_str_col
                    col(r) = string(txt);
                elseif iscell(col)
                    col{r} = txt;
                end
            end
            tbl{:, k} = col;
        end
    end
end

function tbl = format_pm_table(tbl)
    if ismember('Participant', tbl.Properties.VariableNames)
        tbl.Participant = format_prtcp_col(tbl.Participant);
    elseif ismember('Sub', tbl.Properties.VariableNames)
        tbl.Sub = format_prtcp_col(tbl.Sub);
        tbl.Properties.VariableNames{'Sub'} = 'Participant';
    end
end

function col_out = format_prtcp_col(col_in)
    if isnumeric(col_in)
        col_out = cell(numel(col_in), 1);
        nan_idx = 0;
        for i = 1:numel(col_in)
            if isnan(col_in(i))
                nan_idx = nan_idx + 1;
                if nan_idx == 1
                    col_out{i} = 'Group_Mean';
                elseif nan_idx == 2
                    col_out{i} = 'Group_SD';
                else
                    col_out{i} = sprintf('Summary_%d', nan_idx);
                end
            else
                col_out{i} = sprintf('Prtcp %d', round(col_in(i)));
            end
        end
    else
        s_col = string(col_in);
        nan_idx = 0;
        for i = 1:numel(s_col)
            val_str = strtrim(s_col(i));
            if strcmpi(val_str, 'NaN') || strcmpi(val_str, 'Prtcp NaN') || strcmpi(val_str, 'Sub NaN') || strlength(val_str) == 0
                nan_idx = nan_idx + 1;
                if nan_idx == 1
                    s_col(i) = "Group_Mean";
                elseif nan_idx == 2
                    s_col(i) = "Group_SD";
                else
                    s_col(i) = sprintf("Summary_%d", nan_idx);
                end
            elseif startsWith(val_str, "Sub ", 'IgnoreCase', true)
                s_col(i) = regexprep(val_str, '^Sub\s+', 'Prtcp ', 'ignorecase');
            elseif ~isnan(str2double(val_str))
                s_col(i) = sprintf("Prtcp %d", round(str2double(val_str)));
            end
        end
        col_out = cellstr(s_col);
    end
end

function c_out = table_to_titled_cells(title_str, tbl)
    hdr = tbl.Properties.VariableNames;
    body = table2cell(tbl);
    % Convert any string arrays inside body to char so writecell never complains
    for r = 1:size(body, 1)
        for c = 1:size(body, 2)
            val = body{r, c};
            if isstring(val)
                if isscalar(val)
                    if ismissing(val), body{r, c} = ''; else, body{r, c} = char(val); end
                else
                    val(ismissing(val)) = "";
                    body{r, c} = strjoin(cellstr(val), ', ');
                end
            elseif iscell(val) && isscalar(val)
                if isstring(val{1})
                    if ismissing(val{1}), body{r, c} = ''; else, body{r, c} = char(val{1}); end
                elseif ischar(val{1})
                    body{r, c} = val{1};
                end
            end
        end
    end
    t_row = cell(1, numel(hdr));
    t_row{1} = title_str;
    c_out = [t_row; hdr; body];
end

function out = vertcat_pad(cell_blocks, max_w)
    out = {};
    for i = 1:numel(cell_blocks)
        blk = cell_blocks{i};
        [r, c] = size(blk);
        if c < max_w
            blk = [blk, cell(r, max_w - c)]; %#ok<AGROW>
        end
        out = [out; blk]; %#ok<AGROW>
    end
end

function clean_default_excel_sheets(xlsx_path)
    try
        excel = actxserver('Excel.Application');
        excel.DisplayAlerts = false;
        wb = excel.Workbooks.Open(xlsx_path);
        for s_name = {'Sheet1', 'Sheet2', 'Sheet3'}
            try
                if wb.Sheets.Count > 1
                    sh = wb.Sheets.Item(s_name{1});
                    sh.Delete();
                end
            catch
            end
        end
        wb.Save();
        wb.Close(false);
        excel.Quit();
        delete(excel);
    catch
    end
end

% =========================================================================
% BUILDER 12: Sheet 12 (Slow_Only_Analysis)
% =========================================================================
function [cells_out, slow_stats] = build_sheet_slow_only(f1_dir, good_subs, p)
    bt = load(fullfile(f1_dir, 'bad_trials_day2_target_x_to_subs_47_49-85_87-90.mat'));
    trim_len = load(fullfile(f1_dir, 'trim_len.mat')).trim_len;
    n_sub = numel(good_subs);

    cnt_c = zeros(n_sub, 1); cnt_i = zeros(n_sub, 1);
    cnt_cL = zeros(n_sub, 1); cnt_cR = zeros(n_sub, 1);
    cnt_iL = zeros(n_sub, 1); cnt_iR = zeros(n_sub, 1);
    lr_valid = false(n_sub, 1);

    disc_names = {'react', 'mt', 'tot_dist', 'com', 'mad', 'auc'};
    disc_labels = {'Reaching Onset', 'Reaching Duration', 'Distance Traveled', 'COM', 'MAD (Post-Hoc)', 'AUC (Post-Hoc)'};
    disc_units  = {'ms', 'ms', 'cm', 'count', 'cm', '10^2 cm^2'};

    c30 = nan(n_sub, numel(disc_names)); i30 = nan(n_sub, numel(disc_names));
    c25 = nan(n_sub, numel(disc_names)); i25 = nan(n_sub, numel(disc_names));
    ra_c25 = nan(n_sub, 1); ra_i25 = nan(n_sub, 1);

    traj_c30 = nan(trim_len, n_sub); traj_i30 = nan(trim_len, n_sub);
    xstd_c30 = nan(trim_len, n_sub); xstd_i30 = nan(trim_len, n_sub);
    iep_c30  = nan(trim_len, n_sub); iep_i30  = nan(trim_len, n_sub);
    ha_c30   = nan(trim_len, n_sub); ha_i30   = nan(trim_len, n_sub);

    traj_c25 = nan(trim_len, n_sub); traj_i25 = nan(trim_len, n_sub);
    xstd_c25 = nan(trim_len, n_sub); xstd_i25 = nan(trim_len, n_sub);
    iep_c25  = nan(trim_len, n_sub); iep_i25  = nan(trim_len, n_sub);
    ha_c25   = nan(trim_len, n_sub); ha_i25   = nan(trim_len, n_sub);

    for si = 1:n_sub
        s = good_subs(si);
        rd = load(fullfile(f1_dir, sprintf('sub%dday2_reach_data_proc.mat', s))).reach_data_table;
        rd(rd.practice >= 1, :) = [];
        rt = load(fullfile(f1_dir, sprintf('sub%dday2_reach_traj_proc.mat', s))).reach_traj_table;
        rt(rt.practice >= 1, :) = [];
        num_tr = height(rd);

        X_mat = reshape(rt.target_x_to, trim_len, num_tr);
        Y_mat = reshape(rt.target_y_to, trim_len, num_tr);
        Z_mat = reshape(rt.target_z_to, trim_len, num_tr);
        traj_3d = cat(3, X_mat, Y_mat, Z_mat);
        iep_mat = reshape(rt.iep, trim_len, num_tr);
        ha_mat  = reshape(rt.head_angle, trim_len, num_tr);

        r_bt = bt.reach_bad_trials{s};
        non_slow_bad = (r_bt.hole_in_data > 0) | (r_bt.missing_data > 0) | (r_bt.diff_len > 0) | ...
                       (r_bt.short_traj > 0) | (r_bt.missed_target > 0) | (r_bt.bad_stim_dur > 0) | ...
                       (r_bt.late_res > 0) | (r_bt.early_res > 0) | (r_bt.incorrect > 0) | (r_bt.quit > 0);
        sm = (r_bt.very_slow_mvmnt > 0) & ~non_slow_bad & (rd.pas == 1);
        c_idx = sm & (rd.con == 1);
        i_idx = sm & (rd.con == 0);
        cL = c_idx & (rd.target_ans_left == 1);
        cR = c_idx & (rd.target_ans_left == 0);
        iL = i_idx & (rd.target_ans_left == 1);
        iR = i_idx & (rd.target_ans_left == 0);

        cnt_c(si) = sum(c_idx); cnt_i(si) = sum(i_idx);
        cnt_cL(si) = sum(cL); cnt_cR(si) = sum(cR);
        cnt_iL(si) = sum(iL); cnt_iR(si) = sum(iR);
        lr_valid(si) = (cnt_cL(si) >= 1) && (cnt_cR(si) >= 1) && (cnt_iL(si) >= 1) && (cnt_iR(si) >= 1);

        vals = {rd.onset * 1000, (rd.offset - rd.onset) * 1000, rd.tot_dist * 100, ...
                rd.com, rd.target_to_mad * 100, rd.auc};
        for di = 1:numel(disc_names)
            v = vals{di};
            c30(si, di) = mean(v(c_idx));
            i30(si, di) = mean(v(i_idx));
            if lr_valid(si)
                c25(si, di) = 0.5 * (mean(v(cL)) + mean(v(cR)));
                i25(si, di) = 0.5 * (mean(v(iL)) + mean(v(iR)));
            end
        end

        flip_s = ones(1, num_tr);
        flip_s(rd.target_ans_left == 1) = -1;
        X_mir   = (X_mat .* flip_s) * 100;
        iep_mir = (iep_mat .* flip_s) * 100;

        traj_c30(:, si) = mean(X_mir(:, c_idx), 2);
        traj_i30(:, si) = mean(X_mir(:, i_idx), 2);
        if cnt_c(si) >= 2 && cnt_i(si) >= 2
            xstd_c30(:, si) = std(X_mir(:, c_idx), 0, 2);
            xstd_i30(:, si) = std(X_mir(:, i_idx), 0, 2);
        end
        iep_c30(:, si) = mean(iep_mir(:, c_idx), 2);
        iep_i30(:, si) = mean(iep_mir(:, i_idx), 2);
        ha_c30(:, si)  = mean(ha_mat(:, c_idx), 2);
        ha_i30(:, si)  = mean(ha_mat(:, i_idx), 2);

        if lr_valid(si)
            p_sub = defineParams_within_round(p, s);
            ra_c25(si) = calcReachArea(squeeze(mean(traj_3d(:, cL, :), 2)), squeeze(mean(traj_3d(:, cR, :), 2)), p_sub);
            ra_i25(si) = calcReachArea(squeeze(mean(traj_3d(:, iL, :), 2)), squeeze(mean(traj_3d(:, iR, :), 2)), p_sub);
            traj_c25(:, si) = 0.5 * (mean(X_mir(:, cL), 2) + mean(X_mir(:, cR), 2));
            traj_i25(:, si) = 0.5 * (mean(X_mir(:, iL), 2) + mean(X_mir(:, iR), 2));
            if cnt_c(si) >= 2 && cnt_i(si) >= 2
                xstd_c25(:, si) = std(X_mir(:, c_idx), 0, 2);
                xstd_i25(:, si) = std(X_mir(:, i_idx), 0, 2);
            end
            iep_c25(:, si) = 0.5 * (mean(iep_mir(:, cL), 2) + mean(iep_mir(:, cR), 2));
            iep_i25(:, si) = 0.5 * (mean(iep_mir(:, iL), 2) + mean(iep_mir(:, iR), 2));
            ha_c25(:, si)  = 0.5 * (mean(ha_mat(:, cL), 2)  + mean(ha_mat(:, cR), 2));
            ha_i25(:, si)  = 0.5 * (mean(ha_mat(:, iL), 2)  + mean(ha_mat(:, iR), 2));
        end
    end

    % PART A: Trial counts
    cnt_rows = { ...
        'All Valid Slow Trials (N = 30 Pooled)', n_sub, sum(cnt_c), sum(cnt_i), sum(cnt_c + cnt_i), ...
        sprintf('%.2f (%.2f)', mean(cnt_c), std(cnt_c)), sprintf('%.2f (%.2f)', mean(cnt_i), std(cnt_i)), ...
        sprintf('%d - %d', min(cnt_c + cnt_i), max(cnt_c + cnt_i)); ...
        'L/R-Balanced Subset (>=1 Trial per Side x Cond, N = 25)', sum(lr_valid), ...
        sum(cnt_c(lr_valid)), sum(cnt_i(lr_valid)), sum(cnt_c(lr_valid) + cnt_i(lr_valid)), ...
        sprintf('%.2f (%.2f)', mean(cnt_c(lr_valid)), std(cnt_c(lr_valid))), ...
        sprintf('%.2f (%.2f)', mean(cnt_i(lr_valid)), std(cnt_i(lr_valid))), ...
        sprintf('%d - %d', min(cnt_c(lr_valid) + cnt_i(lr_valid)), max(cnt_c(lr_valid) + cnt_i(lr_valid)))};
    tA = cell2table(cnt_rows, 'VariableNames', ...
        {'Cohort', 'N_Participants', 'Congruent_Trials_Total', 'Incongruent_Trials_Total', ...
         'Combined_Trials_Total', 'Con_Trials_Per_Sub_Mean_SD', 'Incon_Trials_Per_Sub_Mean_SD', 'Total_Range_Per_Sub'});

    % PART B: Discrete Measures (N=30 Pooled & N=25 L/R Balanced + Reach Area)
    disc_rows = {};
    slow_stats = struct('n30_con_trials', sum(cnt_c), 'n30_inc_trials', sum(cnt_i), ...
        'n30_tot_trials', sum(cnt_c + cnt_i), 'n25_count', sum(lr_valid), ...
        'n30_tot_mean_per_sub', mean(cnt_c + cnt_i), 'n30_tot_sd_per_sub', std(cnt_c + cnt_i), ...
        'disc', {{}}, 'clust', {{}});

    cohort_specs = { ...
        'N = 30 (Pooled)',      'n30',    true(n_sub, 1), c30, i30, false; ...
        'N = 25 (L/R Balanced)', 'n25_lr', lr_valid,       c25, i25, true};
    for ci = 1:size(cohort_specs, 1)
        c_lbl = cohort_specs{ci, 1};
        c_pfx = cohort_specs{ci, 2};
        mask  = cohort_specs{ci, 3};
        cmat  = cohort_specs{ci, 4};
        imat  = cohort_specs{ci, 5};
        has_ra = cohort_specs{ci, 6};

        if has_ra
            ps_ra = calc_paired_stats(ra_c25(mask), ra_i25(mask));
            disc_rows(end+1, :) = {c_lbl, 'Reach Area', '10^2 cm^2', sum(mask), ...
                sprintf('%.3f (%.3f)', mean(ra_c25(mask)), std(ra_c25(mask))), ...
                sprintf('%.3f (%.3f)', mean(ra_i25(mask)), std(ra_i25(mask))), ...
                sprintf('%.3f [%.3f, %.3f]', ps_ra.diff_mean, ps_ra.ci_low, ps_ra.ci_high), ...
                sprintf('t(%d) = %.3f', ps_ra.df, ps_ra.t), format_p_display(ps_ra.p), sprintf('%.3f', ps_ra.dz)}; %#ok<AGROW>
            slow_stats.disc{end+1} = struct('cohort', c_pfx, 'code', 'ra', 'unit', '10^2 cm^2', ...
                'n', sum(mask), 'con_mean', mean(ra_c25(mask)), 'con_sd', std(ra_c25(mask)), ...
                'inc_mean', mean(ra_i25(mask)), 'inc_sd', std(ra_i25(mask)), 'ps', ps_ra); %#ok<AGROW>
        end

        for di = 1:numel(disc_names)
            cv = cmat(mask, di); iv = imat(mask, di);
            ps = calc_paired_stats(cv, iv);
            disc_rows(end+1, :) = {c_lbl, disc_labels{di}, disc_units{di}, sum(mask), ...
                sprintf('%.3f (%.3f)', mean(cv), std(cv)), ...
                sprintf('%.3f (%.3f)', mean(iv), std(iv)), ...
                sprintf('%.3f [%.3f, %.3f]', ps.diff_mean, ps.ci_low, ps.ci_high), ...
                sprintf('t(%d) = %.3f', ps.df, ps.t), format_p_display(ps.p), sprintf('%.3f', ps.dz)}; %#ok<AGROW>
            slow_stats.disc{end+1} = struct('cohort', c_pfx, 'code', disc_names{di}, 'unit', disc_units{di}, ...
                'n', sum(mask), 'con_mean', mean(cv), 'con_sd', std(cv), ...
                'inc_mean', mean(iv), 'inc_sd', std(iv), 'ps', ps); %#ok<AGROW>
        end
    end
    tB = cell2table(disc_rows, 'VariableNames', ...
        {'Cohort', 'Measure', 'Unit', 'N', 'Congruent_Mean_SD', 'Incongruent_Mean_SD', ...
         'Diff_Con_minus_Incon_95CI', 'Test_Statistic', 'p_value', 'Cohens_dz'});

    % PART C: Full-Trajectory Cluster Permutation Tests (200 normalized samples)
    clust_specs = { ...
        'N = 30 (Pooled)',       'n30',    'traj',       'Deviance From Center',        'cm',  traj_c30, traj_i30; ...
        'N = 30 (Pooled)',       'n30',    'x_std',      'Horizontal Movement Variation', 'cm', xstd_c30, xstd_i30; ...
        'N = 30 (Pooled)',       'n30',    'iep',        'Implied Endpoint (Post-Hoc)',  'cm',  iep_c30,  iep_i30; ...
        'N = 30 (Pooled)',       'n30',    'head_angle', 'Heading Angle',               'deg', ha_c30,   ha_i30; ...
        'N = 25 (L/R Balanced)', 'n25_lr', 'traj',       'Deviance From Center',        'cm',  traj_c25, traj_i25; ...
        'N = 25 (L/R Balanced)', 'n25_lr', 'x_std',      'Horizontal Movement Variation', 'cm', xstd_c25, xstd_i25; ...
        'N = 25 (L/R Balanced)', 'n25_lr', 'iep',        'Implied Endpoint (Post-Hoc)',  'cm',  iep_c25,  iep_i25; ...
        'N = 25 (L/R Balanced)', 'n25_lr', 'head_angle', 'Heading Angle',               'deg', ha_c25,   ha_i25};

    clust_rows = {};
    for k = 1:size(clust_specs, 1)
        c_lbl = clust_specs{k, 1}; c_pfx = clust_specs{k, 2};
        m_code = clust_specs{k, 3}; m_lbl = clust_specs{k, 4}; m_unit = clust_specs{k, 5};
        M1 = clust_specs{k, 6}; M2 = clust_specs{k, 7};
        valid_cols = all(isfinite(M1), 1) & all(isfinite(M2), 1);
        M1v = M1(:, valid_cols); M2v = M2(:, valid_cols);
        nv = size(M1v, 2);

        cl = permCluster(M1v, M2v, 10000, 1);
        has_cl = ~isempty(cl) && ismember('start', cl.Properties.VariableNames) && ~isnan(cl.start(1));
        if has_cl
            s_idx = cl.start(1); e_idx = cl.end(1);
            w_c = mean(M1v(s_idx:e_idx, :), 1)';
            w_i = mean(M2v(s_idx:e_idx, :), 1)';
            ps_w = calc_paired_stats(w_c, w_i);
            p_cl = cl.p_val(1);
            win_str = sprintf('%.1f-%.1f%% (samples %d-%d)', s_idx*0.5, e_idx*0.5, s_idx, e_idx);
            con_s = sprintf('%.3f (%.3f)', mean(w_c), std(w_c));
            inc_s = sprintf('%.3f (%.3f)', mean(w_i), std(w_i));
            dif_s = sprintf('%.3f [%.3f, %.3f]', ps_w.diff_mean, ps_w.ci_low, ps_w.ci_high);
            stat_s = sprintf('t(%d) = %.3f', ps_w.df, ps_w.t);
            dz_s = sprintf('%.3f', ps_w.dz);
        else
            s_idx = NaN; e_idx = NaN;
            p_cl = ternary_str_num(cl, 'p_val', 1.0);
            ps_w = struct('diff_mean', NaN, 'ci_low', NaN, 'ci_high', NaN, 't', NaN, 'df', nv-1, 'p', p_cl, 'dz', NaN);
            win_str = 'No Significant Cluster (0.5-100.0%)';
            con_s = '---'; inc_s = '---'; dif_s = '---'; stat_s = 'Max Cluster Perm'; dz_s = '---';
        end

        clust_rows(end+1, :) = {c_lbl, m_lbl, m_unit, nv, win_str, con_s, inc_s, dif_s, stat_s, format_p_display(p_cl), dz_s}; %#ok<AGROW>
        slow_stats.clust{end+1} = struct('cohort', c_pfx, 'code', m_code, 'unit', m_unit, 'n', nv, ...
            'detected', double(has_cl), 'start_pct', s_idx*0.5, 'end_pct', e_idx*0.5, ...
            'clust_p', p_cl, 'ps', ps_w); %#ok<AGROW>
    end
    tC = cell2table(clust_rows, 'VariableNames', ...
        {'Cohort', 'Measure', 'Unit', 'N', 'Cluster_Window', 'Window_Con_Mean_SD', ...
         'Window_Incon_Mean_SD', 'Window_Diff_Con_minus_Incon_95CI', 'Window_t_df', 'Cluster_p_value', 'Window_Cohens_dz'});

    blk1 = table_to_titled_cells('PART A: RESCUED VERY-SLOW MOVEMENTS (> Mean + 3 SD) TRIAL COUNTS (PAS = 1, Correct)', tA);
    blk2 = table_to_titled_cells('PART B: SLOW-ONLY DISCRETE CONGRUENCY EFFECTS (N = 30 Pooled & N = 25 L/R-Balanced Incl. Reach Area)', tB);
    blk3 = table_to_titled_cells('PART C: SLOW-ONLY FULL-TRAJECTORY CLUSTER PERMUTATION TESTS (200 Normalized Samples)', tC);
    max_w = max([size(blk1,2), size(blk2,2), size(blk3,2)]);
    cells_out = vertcat_pad({blk1, cell(2, max_w), blk2, cell(2, max_w), blk3}, max_w);
end

% =========================================================================
% BUILDER 13: Sheet 13 (Dienes_RttM_Awareness)
% =========================================================================
function [cells_out, rttm_stats] = build_sheet_dienes_rttm(fst, f1_dir, good_subs)
    pas_sum = fst.primeAwarenessDist.PAS_Summary;
    pm1 = fst.Participant_Measures.TrajNorm_noStandardization;
    pm1_v = filter_pm_by_good_subs(pm1, good_subs);

    % Extract aggregate ObsUC proportions u = PAS1_Count / Total_Trials
    idx_r = find(strcmp(string(pas_sum.Task), 'Reaching') & contains(string(pas_sum.Condition), 'Marginal'), 1);
    idx_k = find(strcmp(string(pas_sum.Task), 'Keyboard') & contains(string(pas_sum.Condition), 'Marginal'), 1);
    idx_g = find(strcmp(string(pas_sum.Task), 'Grand Total'), 1);

    u_reach = double(pas_sum.PAS_1_Count(idx_r)) / double(pas_sum.Total_Trials(idx_r));
    u_kb    = double(pas_sum.PAS_1_Count(idx_k)) / double(pas_sum.Total_Trials(idx_k));
    u_all   = double(pas_sum.PAS_1_Count(idx_g)) / double(pas_sum.Total_Trials(idx_g));

    u_specs = {'Reaching (All Trials N=30)', 'reach', u_reach; ...
               'Keyboard (All Trials N=30)', 'kb',    u_kb; ...
               'Combined (All Trials N=30)', 'all',   u_all};

    u_rows = {};
    rttm_stats = struct('u', {{}}, 'ms_tests', {{}}, 'dz_tests', {{}});
    for i = 1:size(u_specs, 1)
        u = u_specs{i, 3};
        e_star = (1 - sqrt(max(0, 2*u - 1))) / 2;
        c_max  = (e_star^2) / u;
        eff50  = c_max * 50.0;
        u_rows(end+1, :) = {u_specs{i, 1}, u, e_star, c_max, c_max*100, eff50, c_max*1.5}; %#ok<AGROW>
        rttm_stats.u{end+1} = struct('tag', u_specs{i, 2}, 'u', u, 'e_star', e_star, 'c_max', c_max, 'eff50_ms', eff50); %#ok<AGROW>
    end
    tA = cell2table(u_rows, 'VariableNames', ...
        {'PAS_Basis', 'Obs_PAS1_Proportion_u', 'Max_Latent_Error_e_star', 'Max_Contamination_C_max', ...
         'Max_Contamination_Pct', 'Eff_Max_Contam_50ms_Prior_ms', 'Eff_Max_Contam_dz15_Prior'});

    % PART B: Temporal / Latency Priming Effects (ms) tested under RttM Interval Null vs Point Null
    % Positive difference = Incongruent slower than Congruent (predicted direction)
    kb_diff_vec    = pm1_v.KB_RT_Incon - pm1_v.KB_RT_Con;
    mt_diff_vec    = pm1_v.Reaching_Duration_Incon - pm1_v.Reaching_Duration_Con;
    onset_diff_vec = pm1_v.Reaching_Onset_Incon - pm1_v.Reaching_Onset_Con;

    ms_defs = { ...
        'Keyboard RT',       'kb_rt', kb_diff_vec,    u_kb,    'Keyboard ObsUC u'; ...
        'Reaching Duration', 'mt',    mt_diff_vec,    u_reach, 'Reaching ObsUC u'; ...
        'Reaching Onset',    'react', onset_diff_vec, u_reach, 'Reaching ObsUC u'};
    conscious_priors = [50.0, 30.0, 80.0];

    ms_rows = {};
    for mi = 1:size(ms_defs, 1)
        m_lbl = ms_defs{mi, 1}; m_code = ms_defs{mi, 2};
        dv = ms_defs{mi, 3}(:); u_use = ms_defs{mi, 4}; u_note = ms_defs{mi, 5};
        obs_m = mean(dv);
        obs_se = std(dv) / sqrt(numel(dv));
        e_st = (1 - sqrt(max(0, 2*u_use - 1))) / 2;
        c_mx = (e_st^2) / u_use;

        for cp = conscious_priors
            sd_h1 = cp / 2.0;
            eff_max = c_mx * cp;
            [bf10_pt, bf10_int] = integrate_rttm_bf10(obs_m, obs_se, sd_h1, eff_max);
            ms_rows(end+1, :) = {m_lbl, u_note, obs_m, obs_se, cp, sd_h1, eff_max, ...
                bf10_pt, 1/bf10_pt, bf10_int, 1/bf10_int}; %#ok<AGROW>
            if cp == 50.0
                rttm_stats.ms_tests{end+1} = struct('code', m_code, 'obs_eff', obs_m, 'obs_se', obs_se, ...
                    'c_max', c_mx, 'eff_max', eff_max, 'bf10_point', bf10_pt, 'bf01_point', 1/bf10_pt, ...
                    'bf10_interval', bf10_int, 'bf01_interval', 1/bf10_int); %#ok<AGROW>
            end
        end
    end
    tB = cell2table(ms_rows, 'VariableNames', ...
        {'Measure', 'ObsUC_Basis', 'Observed_Effect_ms', 'SE_ms', 'Conscious_Prior_Effect_ms', ...
         'H1_HalfNormal_SD_ms', 'RttM_Max_Contam_ms', 'BF10_PointNull', 'BF01_PointNull', ...
         'BF10_RttM_IntervalNull', 'BF01_RttM_IntervalNull'});

    % PART C: Scale-free Cohen's dz RttM across Main Pre-registered Measures (H1 ~ HalfNormal(0, 0.75 dz), Eff_consc = 1.50 dz)
    eff_tbl = fst.Effect_Sizes;
    dz_codes = {'kb_rt','ra','react','mt','tot_dist','com','mad','auc','traj','x_std','iep'};
    dz_labels = {'Keyboard RT','Reach Area','Reaching Onset','Reaching Duration','Distance Traveled','COM', ...
                 'MAD (Post-Hoc)','AUC (Post-Hoc)','Deviance From Center','Horizontal Movement Variation','Implied Endpoint (Post-Hoc)'};
    dz_rows = {};
    se_dz_approx = 1 / sqrt(numel(good_subs));
    for di = 1:numel(dz_codes)
        dc = dz_codes{di};
        ef_i = find(strcmp(string(eff_tbl.Flavor), 'TrajNorm_noStandardization') & strcmp(string(eff_tbl.Effect), dc), 1);
        if isempty(ef_i), continue; end
        abs_dz = abs(num_val(eff_tbl.Cohens_dz(ef_i)));
        if strcmp(dc, 'kb_rt'), u_d = u_kb; else, u_d = u_reach; end
        e_st = (1 - sqrt(max(0, 2*u_d - 1))) / 2;
        c_mx = (e_st^2) / u_d;
        eff_max_dz = c_mx * 1.50;
        [bf10_pt, bf10_int] = integrate_rttm_bf10(abs_dz, se_dz_approx, 0.75, eff_max_dz);
        dz_rows(end+1, :) = {dz_labels{di}, abs_dz, se_dz_approx, eff_max_dz, bf10_pt, bf10_int, 1/bf10_int}; %#ok<AGROW>
        rttm_stats.dz_tests{end+1} = struct('code', dc, 'abs_dz', abs_dz, 'eff_max_dz', eff_max_dz, ...
            'bf10_point', bf10_pt, 'bf10_interval', bf10_int, 'bf01_interval', 1/bf10_int); %#ok<AGROW>
    end
    tC = cell2table(dz_rows, 'VariableNames', ...
        {'PreReg_Measure', 'Observed_Abs_Cohens_dz', 'Approx_SE_dz', 'RttM_Max_Contam_dz_at_150', ...
         'BF10_PointNull', 'BF10_RttM_IntervalNull', 'BF01_RttM_IntervalNull'});

    blk1 = table_to_titled_cells('PART A: DIENES (2024/2025) RttM CONTAMINATION BOUNDS FROM SUBJECTIVE PAS = 1 PROPORTIONS', tA);
    blk2 = table_to_titled_cells('PART B: LATENCY MEASURES RttM INTERVAL-NULL VS. POINT-NULL BAYES FACTORS (ms; H1 HalfNormal SD = Prior/2)', tB);
    blk3 = table_to_titled_cells('PART C: SCALE-FREE STANDARDIZED (Cohen''s dz) RttM BAYES FACTORS ACROSS ALL PRE-REGISTERED MEASURES (H1 SD = 0.75)', tC);
    max_w = max([size(blk1,2), size(blk2,2), size(blk3,2)]);
    cells_out = vertcat_pad({blk1, cell(2, max_w), blk2, cell(2, max_w), blk3}, max_w);
end

function [bf10_pt, bf10_int] = integrate_rttm_bf10(obs, se, sd_h1, eff_max)
    upper = max([obs + 10*se, 10*sd_h1, eff_max + 5*se]);
    lik = @(mu) normpdf(obs, mu, se);
    ml_h1 = integral(@(mu) lik(mu) .* (2 * normpdf(mu, 0, sd_h1)), 0, upper, 'RelTol', 1e-8, 'AbsTol', 1e-14);
    ml_pt = lik(0);
    if eff_max <= 0
        ml_int = ml_pt;
    else
        ml_int = integral(@(mu) lik(mu) / eff_max, 0, eff_max, 'RelTol', 1e-8, 'AbsTol', 1e-14);
    end
    bf10_pt  = ml_h1 / max(ml_pt, 1e-300);
    bf10_int = ml_h1 / max(ml_int, 1e-300);
end

% =========================================================================
% BUILDER 14: Sheet 14 (Acquisition_Timeline_and_Pilots)
% =========================================================================
function [cells_out, acq_stats] = build_sheet_acquisition_pilots(proc_root, fst, good_subs)
    cand_paths = { ...
        fullfile(proc_root, '..', '..', '..', '..', 'docs', 'Participant_Acquisition_Timestamps.csv'), ...
        fullfile(proc_root, '..', '..', '..', 'docs', 'Participant_Acquisition_Timestamps.csv'), ...
        fullfile(fileparts(mfilename('fullpath')), '..', '..', '..', '..', '..', 'docs', 'Participant_Acquisition_Timestamps.csv')};
    csv_path = '';
    for cp_i = 1:numel(cand_paths)
        if isfile(cand_paths{cp_i})
            csv_path = cand_paths{cp_i};
            break;
        end
    end
    if isempty(csv_path)
        error('Cannot locate Participant_Acquisition_Timestamps.csv; tried: %s', strjoin(cand_paths, '; '));
    end
    opts = detectImportOptions(csv_path);
    str_cols = {'Status','First_Task','Date','Calibration_Time_start_end_points_mat', ...
                'Session_End_Time_p_mat','Calibration_Full_Timestamp','Session_End_Full_Timestamp','Notes'};
    opts = setvartype(opts, intersect(opts.VariableNames, str_cols), 'string');
    T = readtable(csv_path, opts);
    is_incl = strcmpi(strtrim(T.Status), "Included");

    % Classification windows: Original Pre-Reg window (May 2022), Pre-Addendum (Jun 28 - Aug 6, 2022), Post-Addendum (>= Aug 7, 2022)
    dates_dt = datetime(T.Date, 'InputFormat', 'yyyy-MM-dd');
    win_labels = strings(height(T), 1);
    for r = 1:height(T)
        if isnat(dates_dt(r)) || T.SubID(r) <= 49
            win_labels(r) = "Pre-Original Pre-Registration Window (May 2022)";
        elseif dates_dt(r) < datetime(2022, 8, 7)
            win_labels(r) = "Before Pre-Registration Addendum (Jun 28 - Aug 6, 2022)";
        else
            win_labels(r) = "Post Pre-Registration Addendum (>= Aug 7, 2022)";
        end
    end

    sub46_missing = double(~ismember(46, T.SubID));
    total_recruited = height(T) + sub46_missing;
    total_incl      = sum(is_incl);
    total_excl      = sum(~is_incl) + sub46_missing;

    w_pre_i  = sum(is_incl & win_labels == "Pre-Original Pre-Registration Window (May 2022)");
    w_mid_i  = sum(is_incl & win_labels == "Before Pre-Registration Addendum (Jun 28 - Aug 6, 2022)");
    w_post_i = sum(is_incl & win_labels == "Post Pre-Registration Addendum (>= Aug 7, 2022)");
    w_pre_e  = sum(~is_incl & win_labels == "Pre-Original Pre-Registration Window (May 2022)") + sub46_missing;
    w_mid_e  = sum(~is_incl & win_labels == "Before Pre-Registration Addendum (Jun 28 - Aug 6, 2022)");
    w_post_e = sum(~is_incl & win_labels == "Post Pre-Registration Addendum (>= Aug 7, 2022)");

    has_csv = ~strcmpi(strtrim(T.Status), "Excluded (No CSV)") & ~contains(T.Status, "Quit early");
    summary_rows = { ...
        'Total Recruited Participant IDs (Sub 46 - Sub 90)', total_recruited, total_incl, total_excl, 'Includes Sub 46 technical failure & Sub 48/86 early quits'; ...
        'Participants with Recorded Experimental CSV/MAT Data', sum(has_csv), sum(is_incl & has_csv), sum(~is_incl & has_csv), 'Sub 46 had technical failure (no saved log); Sub 48 & 86 quit early'; ...
        'Pre-Original Pre-Registration Window (May 2022)', w_pre_i + w_pre_e, w_pre_i, w_pre_e, 'Included: Sub 47, 49 (data unobserved prior to pre-reg); Excl: Sub 46, 48'; ...
        'Pre-Addendum Collection (Jun 28 - Aug 6, 2022)', w_mid_i + w_mid_e, w_mid_i, w_mid_e, 'Included: 26 participants; Excl: 10 participants'; ...
        'Post-Addendum Collection (Aug 8 - Aug 10, 2022)', w_post_i + w_post_e, w_post_i, w_post_e, 'Included: Sub 88, 90 (N=2); Excl: Sub 86, 87, 89 (N=3)'};
    tA = cell2table(summary_rows, 'VariableNames', ...
        {'Acquisition_Milestone', 'Total_N', 'Included_N', 'Excluded_or_Quit_N', 'Details'});

    T_log = T(:, {'SubID', 'Included_Participant_Num', 'Status', 'First_Task', 'Date', ...
                  'Calibration_Time_start_end_points_mat', 'Session_End_Time_p_mat', 'Notes'});
    T_log.PreReg_Window = win_labels;
    if sub46_missing > 0
        row46 = table(46, NaN, "Excluded (Technical Failure / No Log)", "Unknown", "2022-05 (No Log)", ...
            "N/A", "N/A", "Technical failure prior to MAT/CSV log saving", "Pre-Original Pre-Registration Window (May 2022)", ...
            'VariableNames', T_log.Properties.VariableNames);
        T_log = [row46; T_log];
    end

    pilot_rows = { ...
        'A-Priori Sample Size Power Analysis (Pre-Reg)', 'G*Power (Faul et al., 2007/2009)', 30, NaN, NaN, NaN, ...
        0.88, 0.61, 0.95, 0.05, 'Combined pilots Reaching dz=0.88; KB RT estimated 30% smaller dz=0.61 -> 95% power requires N=30'; ...
        'Pilot Experiment 2 (Preceding Study)', '15 recruited (1 crashed Sub 15, 5 excluded)', 9, 7, 23.66, 2.44, ...
        NaN, NaN, NaN, NaN, 'Two-day reaching & KB pilot; metadata from Pilot_Experiments_2_and_3/README.md'; ...
        'Pilot Experiment 3 (Preceding Study)', '17 recruited (4 no-show Day 2, 6 excluded)', 7, 5, 24.42, 3.20, ...
        NaN, NaN, NaN, NaN, 'Refined masked priming pilot; metadata from Pilot_Experiments_2_and_3/README.md'};
    tC = cell2table(pilot_rows, 'VariableNames', ...
        {'Study_Phase', 'Recruitment_and_Exclusions', 'Included_N', 'Female_N', 'Age_Mean', 'Age_SD', ...
         'Pilot_Reach_dz', 'Est_KB_dz', 'Target_Power', 'Alpha', 'Notes'});

    blk1 = table_to_titled_cells('PART A: MAIN EXPERIMENT RECRUITMENT & PRE-REGISTRATION WINDOW BREAKDOWN (Sub 46 - Sub 90)', tA);
    blk2 = table_to_titled_cells('PART B: PARTICIPANT ACQUISITION LOG & TIMESTAMPS (Source: Participant_Acquisition_Timestamps.csv)', T_log);
    blk3 = table_to_titled_cells('PART C: A-PRIORI POWER ANALYSIS & PILOT EXPERIMENTS 2 & 3 SAMPLE METADATA', tC);
    max_w = max([size(blk1,2), size(blk2,2), size(blk3,2)]);
    cells_out = vertcat_pad({blk1, cell(2, max_w), blk2, cell(2, max_w), blk3}, max_w);

    acq_stats = struct('total_recruited', total_recruited, 'included_n', total_incl, 'excluded_n', total_excl, ...
        'with_data_n', sum(has_csv), 'pre_orig_incl', w_pre_i, 'pre_orig_excl', w_pre_e, ...
        'pre_add_incl', w_mid_i, 'pre_add_excl', w_mid_e, 'post_add_incl', w_post_i, 'post_add_excl', w_post_e);
end

% =========================================================================
% BUILDER 15: Sheet 15 (Manuscript_Values)
% =========================================================================
function tbl_out = build_sheet_manuscript_values(fst, TreeBH, excl_stats, com_perf_stats, ...
    slow_stats, rttm_stats, acq_stats, f1_dir, f2_dir, good_subs, p)

    rows = {};

    % 1. Sample, Acquisition Timeline & Power/Pilot Metadata
    rows = push_mv_row(rows, 'sample_total_recruited', 'main', 'design', 'sample', 'all', 'cohort', 'n', acq_stats.total_recruited, sprintf('%d', acq_stats.total_recruited), 'participants', 0, 'Sub 46-90 recruited', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'sample_with_data_n', 'main', 'design', 'sample', 'with_data', 'cohort', 'n', acq_stats.with_data_n, sprintf('%d', acq_stats.with_data_n), 'participants', 0, 'Valid CSV/MAT collected', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'sample_included_n', 'main', 'design', 'sample', 'included', 'cohort', 'n', acq_stats.included_n, sprintf('%d', acq_stats.included_n), 'participants', 0, 'Main valid sample', 'Acquisition_Timeline_and_Pilots', 'good_subs');
    rows = push_mv_row(rows, 'sample_valid_df', 'main', 'design', 'sample', 'included', 'cohort', 'df', acq_stats.included_n - 1, sprintf('%d', acq_stats.included_n - 1), 'df', 0, 'N - 1 paired t df', 'Acquisition_Timeline_and_Pilots', 'good_subs');
    rows = push_mv_row(rows, 'sample_excluded_n', 'main', 'design', 'sample', 'excluded', 'cohort', 'n', acq_stats.excluded_n, sprintf('%d', acq_stats.excluded_n), 'participants', 0, 'Excluded or quit early', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'acq_pre_orig_incl_n', 'main', 'design', 'acquisition', 'pre_orig', 'included', 'n', acq_stats.pre_orig_incl, sprintf('%d', acq_stats.pre_orig_incl), 'participants', 0, 'Included before original pre-reg', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'acq_pre_add_incl_n', 'main', 'design', 'acquisition', 'pre_addendum', 'included', 'n', acq_stats.pre_add_incl, sprintf('%d', acq_stats.pre_add_incl), 'participants', 0, 'Included May 31 - Aug 6 2022', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'acq_post_add_incl_n', 'main', 'design', 'acquisition', 'post_addendum', 'included', 'n', acq_stats.post_add_incl, sprintf('%d', acq_stats.post_add_incl), 'participants', 0, 'Included >= Aug 7 2022', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'acq_pre_orig_excl_n', 'main', 'design', 'acquisition', 'pre_orig', 'excluded', 'n_excl', acq_stats.pre_orig_excl, sprintf('%d', acq_stats.pre_orig_excl), 'participants', 0, 'Excl/no-CSV before original pre-reg', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'acq_pre_add_excl_n', 'main', 'design', 'acquisition', 'pre_addendum', 'excluded', 'n_excl', acq_stats.pre_add_excl, sprintf('%d', acq_stats.pre_add_excl), 'participants', 0, 'Excl Jun 28 - Aug 6 2022', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');
    rows = push_mv_row(rows, 'acq_post_add_excl_n', 'main', 'design', 'acquisition', 'post_addendum', 'excluded', 'n_excl', acq_stats.post_add_excl, sprintf('%d', acq_stats.post_add_excl), 'participants', 0, 'Excl/quit >= Aug 7 2022', 'Acquisition_Timeline_and_Pilots', 'Participant_Acquisition_Timestamps.csv');

    rows = push_mv_row(rows, 'power_pilot_reach_dz', 'methods', 'power', 'power_analysis', 'reach', 'a_priori', 'dz', 0.88, '0.88', 'dz', 2, 'Mean reaching dz across Pilots 2 & 3', 'Acquisition_Timeline_and_Pilots', 'Last Pre Reg 7_8_22.pdf');
    rows = push_mv_row(rows, 'power_est_kb_dz', 'methods', 'power', 'power_analysis', 'kb', 'a_priori', 'dz', 0.61, '0.61', 'dz', 2, '30% smaller assumed KB dz', 'Acquisition_Timeline_and_Pilots', 'Last Pre Reg 7_8_22.pdf');
    rows = push_mv_row(rows, 'power_target_power', 'methods', 'power', 'power_analysis', 'target', 'a_priori', 'power', 0.95, '0.95', 'proportion', 2, 'G*Power target power', 'Acquisition_Timeline_and_Pilots', 'Last Pre Reg 7_8_22.pdf');
    rows = push_mv_row(rows, 'power_alpha', 'methods', 'power', 'power_analysis', 'target', 'a_priori', 'alpha', 0.05, '0.05', 'proportion', 2, 'G*Power alpha', 'Acquisition_Timeline_and_Pilots', 'Last Pre Reg 7_8_22.pdf');
    rows = push_mv_row(rows, 'power_required_n', 'methods', 'power', 'power_analysis', 'target', 'a_priori', 'n', 30, '30', 'participants', 0, 'Required N', 'Acquisition_Timeline_and_Pilots', 'Last Pre Reg 7_8_22.pdf');
    rows = push_mv_row(rows, 'pilot2_included_n', 'methods', 'pilot', 'pilot2', 'included', 'demographics', 'n', 9, '9', 'participants', 0, '15 recruited, 1 crashed, 5 excl', 'Acquisition_Timeline_and_Pilots', 'Pilot_Experiments_2_and_3/README.md');
    rows = push_mv_row(rows, 'pilot2_age_mean', 'methods', 'pilot', 'pilot2', 'demographics', 'sample', 'age_mean', 23.66, '23.66', 'years', 2, 'Pilot 2 N=9', 'Acquisition_Timeline_and_Pilots', 'Pilot_Experiments_2_and_3/README.md');
    rows = push_mv_row(rows, 'pilot2_age_sd', 'methods', 'pilot', 'pilot2', 'demographics', 'sample', 'age_sd', 2.44, '2.44', 'years', 2, 'Pilot 2 N=9', 'Acquisition_Timeline_and_Pilots', 'Pilot_Experiments_2_and_3/README.md');
    rows = push_mv_row(rows, 'pilot3_included_n', 'methods', 'pilot', 'pilot3', 'included', 'demographics', 'n', 7, '7', 'participants', 0, '17 recruited, 4 no-show, 6 excl', 'Acquisition_Timeline_and_Pilots', 'Pilot_Experiments_2_and_3/README.md');
    rows = push_mv_row(rows, 'pilot3_age_mean', 'methods', 'pilot', 'pilot3', 'demographics', 'sample', 'age_mean', 24.42, '24.42', 'years', 2, 'Pilot 3 N=7', 'Acquisition_Timeline_and_Pilots', 'Pilot_Experiments_2_and_3/README.md');
    rows = push_mv_row(rows, 'pilot3_age_sd', 'methods', 'pilot', 'pilot3', 'demographics', 'sample', 'age_sd', 3.20, '3.20', 'years', 2, 'Pilot 3 N=7', 'Acquisition_Timeline_and_Pilots', 'Pilot_Experiments_2_and_3/README.md');

    % 2. Trial Exclusions (Table 1 % & Raw Counts)
    for ii = 1:numel(excl_stats.items)
        it = excl_stats.items{ii};
        rows = push_mv_row(rows, ['excl_reach_' it.key '_pct_mean'], 'main', 'prereg', 'exclusions', it.key, 'reach', 'pct_mean', it.reach_pct_mean, sprintf('%.2f', it.reach_pct_mean), '%', 2, it.label, 'Table_1_Trial_Exclusions', 'trialExclusionStats');
        rows = push_mv_row(rows, ['excl_reach_' it.key '_pct_sd'],   'main', 'prereg', 'exclusions', it.key, 'reach', 'pct_sd',   it.reach_pct_sd,   sprintf('%.2f', it.reach_pct_sd),   '%', 2, it.label, 'Table_1_Trial_Exclusions', 'trialExclusionStats');
        rows = push_mv_row(rows, ['excl_reach_temp_' it.key '_pct_mean'], 'main', 'temp', 'exclusions', it.key, 'reach_temp', 'pct_mean', it.reach_temp_pct_mean, sprintf('%.2f', it.reach_temp_pct_mean), '%', 2, it.label, 'Table_1_Trial_Exclusions', 'trialExclusionStats');
        rows = push_mv_row(rows, ['excl_reach_temp_' it.key '_pct_sd'],   'main', 'temp', 'exclusions', it.key, 'reach_temp', 'pct_sd',   it.reach_temp_pct_sd,   sprintf('%.2f', it.reach_temp_pct_sd),   '%', 2, it.label, 'Table_1_Trial_Exclusions', 'trialExclusionStats');
        rows = push_mv_row(rows, ['excl_reach_' it.key '_cnt_sum'],  'main', 'prereg', 'exclusions', it.key, 'reach', 'cnt_sum',  it.reach_cnt_sum,  sprintf('%d', round(it.reach_cnt_sum)),  'count', 0, it.label, 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
        rows = push_mv_row(rows, ['excl_reach_' it.key '_cnt_mean'], 'main', 'prereg', 'exclusions', it.key, 'reach', 'cnt_mean', it.reach_cnt_mean, sprintf('%.2f', it.reach_cnt_mean), 'count', 2, it.label, 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
        rows = push_mv_row(rows, ['excl_reach_' it.key '_cnt_sd'],   'main', 'prereg', 'exclusions', it.key, 'reach', 'cnt_sd',   it.reach_cnt_sd,   sprintf('%.2f', it.reach_cnt_sd),   'count', 2, it.label, 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
        if ~isnan(it.kb_pct_mean)
            rows = push_mv_row(rows, ['excl_kb_' it.key '_pct_mean'], 'main', 'prereg', 'exclusions', it.key, 'kb', 'pct_mean', it.kb_pct_mean, sprintf('%.2f', it.kb_pct_mean), '%', 2, it.label, 'Table_1_Trial_Exclusions', 'trialExclusionStats');
            rows = push_mv_row(rows, ['excl_kb_' it.key '_pct_sd'],   'main', 'prereg', 'exclusions', it.key, 'kb', 'pct_sd',   it.kb_pct_sd,   sprintf('%.2f', it.kb_pct_sd),   '%', 2, it.label, 'Table_1_Trial_Exclusions', 'trialExclusionStats');
            rows = push_mv_row(rows, ['excl_kb_' it.key '_cnt_sum'],  'main', 'prereg', 'exclusions', it.key, 'kb', 'cnt_sum',  it.kb_cnt_sum,  sprintf('%d', round(it.kb_cnt_sum)),  'count', 0, it.label, 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
            rows = push_mv_row(rows, ['excl_kb_' it.key '_cnt_mean'], 'main', 'prereg', 'exclusions', it.key, 'kb', 'cnt_mean', it.kb_cnt_mean, sprintf('%.2f', it.kb_cnt_mean), 'count', 2, it.label, 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
            rows = push_mv_row(rows, ['excl_kb_' it.key '_cnt_sd'],   'main', 'prereg', 'exclusions', it.key, 'kb', 'cnt_sd',   it.kb_cnt_sd,   sprintf('%.2f', it.kb_cnt_sd),   'count', 2, it.label, 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
            ps = it.pct_cmp;
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_pct_t'],       'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 't',         ps.t,         sprintf('%.3f', ps.t),         't', 2, 'Reach - KB %', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Pct');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_pct_p'],       'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'p',         ps.p,         format_p_display(ps.p),      'p', 4, 'Reach - KB %', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Pct');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_pct_ci_low'],  'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'ci_low',    ps.ci_low,    sprintf('%.2f', ps.ci_low),    '%', 2, 'Reach - KB %', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Pct');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_pct_ci_high'], 'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'ci_high',   ps.ci_high,   sprintf('%.2f', ps.ci_high),   '%', 2, 'Reach - KB %', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Pct');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_pct_dz'],      'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'dz',        ps.dz,        sprintf('%.3f', ps.dz),        'dz', 2, 'Reach - KB %', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Pct');
            pc = it.cnt_cmp;
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_cnt_t'],       'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'cnt_t',     pc.t,         sprintf('%.3f', pc.t),         't', 2, 'Reach - KB count', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_cnt_p'],       'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'cnt_p',     pc.p,         format_p_display(pc.p),      'p', 4, 'Reach - KB count', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_cnt_ci_low'],  'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'cnt_ci_l',  pc.ci_low,    sprintf('%.2f', pc.ci_low),    'count', 2, 'Reach - KB count', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_cnt_ci_high'], 'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'cnt_ci_h',  pc.ci_high,   sprintf('%.2f', pc.ci_high),   'count', 2, 'Reach - KB count', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
            rows = push_mv_row(rows, ['excl_cmp_' it.key '_cnt_dz'],      'main', 'prereg', 'exclusions', it.key, 'reach_minus_kb', 'cnt_dz',    pc.dz,        sprintf('%.3f', pc.dz),        'dz', 2, 'Reach - KB count', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
        end
    end
    rows = push_mv_row(rows, 'excl_reach_online_slow_cnt_sum',  'si', 'prereg', 'exclusions', 'online_slow', 'reach', 'cnt_sum',  excl_stats.online_slow_sum,  sprintf('%d', round(excl_stats.online_slow_sum)), 'count', 0, 'Speed up warning (>420 ms, not offline excluded)', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
    rows = push_mv_row(rows, 'excl_reach_online_slow_cnt_mean', 'si', 'prereg', 'exclusions', 'online_slow', 'reach', 'cnt_mean', excl_stats.online_slow_mean, sprintf('%.2f', excl_stats.online_slow_mean), 'count', 2, 'Speed up warning (>420 ms, not offline excluded)', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
    rows = push_mv_row(rows, 'excl_reach_online_slow_cnt_sd',   'si', 'prereg', 'exclusions', 'online_slow', 'reach', 'cnt_sd',   excl_stats.online_slow_sd,   sprintf('%.2f', excl_stats.online_slow_sd),   'count', 2, 'Speed up warning (>420 ms, not offline excluded)', 'Table_1_Trial_Exclusions', 'SI_Exclusion_All_Subs_Counts');
    for ii = 1:numel(excl_stats.included)
        inc = excl_stats.included{ii};
        rows = push_mv_row(rows, ['incl_reach_' inc.key '_cnt_sum'],  'main', 'prereg', 'exclusions', inc.key, 'reach', 'cnt_sum',  inc.reach_sum,  sprintf('%d', round(inc.reach_sum)),  'count', 0, 'Included PAS=1 reaching', 'Table_1_Trial_Exclusions', 'Participant_Measures');
        rows = push_mv_row(rows, ['incl_reach_' inc.key '_cnt_mean'], 'main', 'prereg', 'exclusions', inc.key, 'reach', 'cnt_mean', inc.reach_mean, sprintf('%.2f', inc.reach_mean), 'count', 2, 'Included PAS=1 reaching', 'Table_1_Trial_Exclusions', 'Participant_Measures');
        rows = push_mv_row(rows, ['incl_reach_' inc.key '_cnt_sd'],   'main', 'prereg', 'exclusions', inc.key, 'reach', 'cnt_sd',   inc.reach_sd,   sprintf('%.2f', inc.reach_sd),   'count', 2, 'Included PAS=1 reaching', 'Table_1_Trial_Exclusions', 'Participant_Measures');
        rows = push_mv_row(rows, ['incl_kb_' inc.key '_cnt_sum'],     'main', 'prereg', 'exclusions', inc.key, 'kb',    'cnt_sum',  inc.kb_sum,     sprintf('%d', round(inc.kb_sum)),     'count', 0, 'Included PAS=1 KB', 'Table_1_Trial_Exclusions', 'Participant_Measures');
        rows = push_mv_row(rows, ['incl_kb_' inc.key '_cnt_mean'],    'main', 'prereg', 'exclusions', inc.key, 'kb',    'cnt_mean', inc.kb_mean,    sprintf('%.2f', inc.kb_mean),    'count', 2, 'Included PAS=1 KB', 'Table_1_Trial_Exclusions', 'Participant_Measures');
        rows = push_mv_row(rows, ['incl_kb_' inc.key '_cnt_sd'],      'main', 'prereg', 'exclusions', inc.key, 'kb',    'cnt_sd',   inc.kb_sd,      sprintf('%.2f', inc.kb_sd),      'count', 2, 'Included PAS=1 KB', 'Table_1_Trial_Exclusions', 'Participant_Measures');
    end

    % 3. Main Congruency Effects & Assumptions across PreReg, Zscore, Temp
    eff_tbl = fst.Effect_Sizes;
    norm_tbl = fst.Normality_and_Permutations_Table;
    win_tbl = fst.Effect_Comparisons_Within;
    ft_tbl = fst.fullTrajAnalysis;

    disc_codes = {'kb_rt','ra','react','mt','tot_dist','com','mad','auc','traj','x_std','iep'};
    disc_raw_names = {'Keyboard RT','Reach Area','Reaching Onset','Reaching Duration','Total Distance Traveled', ...
                      'Num of COM','Maximum Absolute Deviation (MAD)','Area Under Curve (AUC)', ...
                      'Deviation From Center','Movement Variance (X-STD)','Implied End Point (IEP)'};
    tree_con_nodes = {'Keyboard_RT','Reach_Area','Reaching_Onset','Reaching_Duration_MT','Total_Distance', ...
                      'Changes_of_Mind_COM','MAD','AUC','Spatial_Deviation_Cluster','Spatial_Variation_Cluster','Implied_End_Point_Cluster'};
    tree_sens_nodes = {'','Reach_Area_vs_KB','Onset_vs_KB','MT_vs_KB','Total_Dist_vs_KB','COM_vs_KB', ...
                       'MAD_vs_KB','AUC_vs_KB','Spatial_Dev_vs_KB','Spatial_Var_vs_KB','IEP_vs_KB'};
    ft_map_names = {'','','','','','','','','Deviation From center','Movement variation','iEP'};
    units_f1 = {'ms','10^2 cm^2','ms','ms','cm','count','cm','10^2 cm^2','cm','cm','cm'};
    units_f2 = {'z-score','10^2 cm^2','z-score','z-score','z-score','z-score','z-score','z-score','cm','cm','cm'};
    sens_assump = compute_sensitivity_assumptions_and_nonparam(fst, f1_dir, f2_dir, good_subs, p);

    an_specs = { ...
        'prereg', 'TrajNorm_noStandardization', TreeBH.Tree1_Congruency_Table,    TreeBH.Tree2_Sensitivity_Table,    units_f1, 'main'; ...
        'zscore', 'TrajNorm_Standardization',   TreeBH.FigS2a_Congruency_Std_Table, TreeBH.FigS2b_Sensitivity_Std_Table, units_f2, 'si'};

    for ai = 1:size(an_specs, 1)
        an_key = an_specs{ai, 1}; f_code = an_specs{ai, 2};
        t_con = an_specs{ai, 3}; t_sens = an_specs{ai, 4};
        u_list = an_specs{ai, 5}; sc_val = an_specs{ai, 6};

        for m = 1:numel(disc_codes)
            c_code = disc_codes{m}; r_key = disc_raw_names{m}; u_str = u_list{m};
            f_lookup = f_code;
            if ai == 2 && m >= 9, f_lookup = 'TrajNorm_noStandardization'; end
            src_st = fst.(f_lookup);
            scale_f = ternary_str_bool((ai == 1 && m == 7) || m >= 9, 100.0, 1.0);
            pfx = [an_key '_' c_code '_'];

            ri = find(startsWith(string(src_st.name), r_key), 1);
            if ~isempty(ri)
                c_m = src_st.con_avg(ri) * scale_f; c_s = src_st.con_std(ri) * scale_f;
                i_m = src_st.incon_avg(ri) * scale_f; i_s = src_st.incon_std(ri) * scale_f;
                d_m = src_st.diff_avg(ri) * scale_f; d_s = src_st.t_SD(ri) * scale_f;
                ci_l = src_st.CI_low(ri) * scale_f; ci_h = src_st.CI_high(ri) * scale_f;
                rows = push_mv_row(rows, [pfx 'con_mean'], sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'con_mean', c_m, sprintf('%.3f', c_m), u_str, 2, 'Congruent mean', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'con_sd'],   sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'con_sd',   c_s, sprintf('%.3f', c_s), u_str, 2, 'Congruent SD',   'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'incon_mean'], sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'incon_mean', i_m, sprintf('%.3f', i_m), u_str, 2, 'Incongruent mean', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'incon_sd'],   sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'incon_sd',   i_s, sprintf('%.3f', i_s), u_str, 2, 'Incongruent SD',   'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'diff_mean'],  sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'diff_mean',  d_m, sprintf('%.3f', d_m), u_str, 2, 'Con - Incon signed', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'abs_diff_mean'], sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'abs_diff_mean', abs(d_m), sprintf('%.3f', abs(d_m)), u_str, 2, 'Unsigned |Con - Incon|', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'diff_sd'],    sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'diff_sd',    d_s, sprintf('%.3f', d_s), u_str, 2, 'SD of paired diff', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'ci_low'],     sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'ci_low',     ci_l, sprintf('%.3f', ci_l), u_str, 2, '95% CI lower (Con - Incon)', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'ci_high'],    sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'ci_high',    ci_h, sprintf('%.3f', ci_h), u_str, 2, '95% CI upper (Con - Incon)', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'abs_ci_low'], sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'abs_ci_low', min(abs(ci_l), abs(ci_h)), sprintf('%.3f', min(abs(ci_l), abs(ci_h))), u_str, 2, 'Unsigned CI lower', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'abs_ci_high'],sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'abs_ci_high',max(abs(ci_l), abs(ci_h)), sprintf('%.3f', max(abs(ci_l), abs(ci_h))), u_str, 2, 'Unsigned CI upper', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 't'],          sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 't',          src_st.tVal(ri), sprintf('%.3f', src_st.tVal(ri)), 't', 2, 'Paired t (Con - Incon)', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'df'],         sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'df',         src_st.df(ri),   sprintf('%d', round(src_st.df(ri))), 'df', 0, 'df', 'Effects', f_lookup);
                rows = push_mv_row(rows, [pfx 'p'],          sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'p',          src_st.pVal(ri), format_p_display(src_st.pVal(ri)), 'p', 4, 'Raw p-value', 'Effects', f_lookup);
            end

            tc_i = find(strcmp(string(t_con.Node_Name), tree_con_nodes{m}), 1);
            if ~isempty(tc_i)
                tp = num_val(t_con.Uncorrected_p(tc_i)); tq = num_val(t_con.Within_Family_FDR_q(tc_i));
                rows = push_mv_row(rows, [pfx 'treebh_p'], sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'treebh_p', tp, format_p_display(tp), 'p', 4, 'TreeBH input p', 'Effects', 'TreeBH');
                rows = push_mv_row(rows, [pfx 'treebh_q'], sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'treebh_q', tq, format_p_display(tq), 'q', 4, 'TreeBH FDR q',   'Effects', 'TreeBH');
            end

            ef_i = find(strcmp(string(eff_tbl.Flavor), f_lookup) & strcmp(string(eff_tbl.Effect), c_code), 1);
            if ~isempty(ef_i)
                dz = num_val(eff_tbl.Cohens_dz(ef_i)); cl_e = num_val(eff_tbl.CI_Lower(ef_i)); cu_e = num_val(eff_tbl.CI_Upper(ef_i));
                rows = push_mv_row(rows, [pfx 'dz'],          sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'dz',          dz,      sprintf('%.3f', dz),      'dz', 2, 'Signed dz',   'Effects', 'Effect_Sizes');
                rows = push_mv_row(rows, [pfx 'abs_dz'],      sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'abs_dz',      abs(dz), sprintf('%.3f', abs(dz)), 'dz', 2, 'Unsigned |dz|','Effects', 'Effect_Sizes');
                rows = push_mv_row(rows, [pfx 'dz_ci_low'],   sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'dz_ci_low',   cl_e,    sprintf('%.3f', cl_e),    'dz', 2, 'Signed dz CI L','Effects', 'Effect_Sizes');
                rows = push_mv_row(rows, [pfx 'dz_ci_high'],  sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'dz_ci_high',  cu_e,    sprintf('%.3f', cu_e),    'dz', 2, 'Signed dz CI U','Effects', 'Effect_Sizes');
                rows = push_mv_row(rows, [pfx 'abs_dz_ci_low'], sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'abs_dz_ci_low', min(abs(cl_e), abs(cu_e)), sprintf('%.3f', min(abs(cl_e), abs(cu_e))), 'dz', 2, 'Unsigned |dz| CI L','Effects', 'Effect_Sizes');
                rows = push_mv_row(rows, [pfx 'abs_dz_ci_high'],sc_val, an_key, 'congruency', c_code, 'con_vs_incon', 'abs_dz_ci_high',max(abs(cl_e), abs(cu_e)), sprintf('%.3f', max(abs(cl_e), abs(cu_e))), 'dz', 2, 'Unsigned |dz| CI U','Effects', 'Effect_Sizes');
            end

            if m >= 9
                ft_i = find(strcmp(string(ft_tbl.Flavor), 'TrajNorm_noStandardization') & strcmp(string(ft_tbl.name), ft_map_names{m}), 1);
                if ~isempty(ft_i)
                    rows = push_mv_row(rows, [pfx 'clust_start_pct'], sc_val, an_key, 'congruency', c_code, 'cluster', 'clust_start_pct', ft_tbl.start_time(ft_i)*0.5, sprintf('%.1f', ft_tbl.start_time(ft_i)*0.5), '% path', 1, 'Cluster onset % path', 'Effects', 'fullTrajAnalysis');
                    rows = push_mv_row(rows, [pfx 'clust_end_pct'],   sc_val, an_key, 'congruency', c_code, 'cluster', 'clust_end_pct',   ft_tbl.end_time(ft_i)*0.5,   sprintf('%.1f', ft_tbl.end_time(ft_i)*0.5),   '% path', 1, 'Cluster offset % path', 'Effects', 'fullTrajAnalysis');
                    rows = push_mv_row(rows, [pfx 'clust_p'],         sc_val, an_key, 'congruency', c_code, 'cluster', 'clust_p',         ft_tbl.p_val(ft_i),          format_p_display(ft_tbl.p_val(ft_i)),       'p',      4, 'Cluster permutation p', 'Effects', 'fullTrajAnalysis');
                    rows = push_mv_row(rows, [pfx 'clust_t_star'],    sc_val, an_key, 'congruency', c_code, 'cluster', 'clust_t_star',    ft_tbl.('t*')(ft_i),         sprintf('%.3f', ft_tbl.('t*')(ft_i)),       't',      2, 'Peak sample t*', 'Effects', 'fullTrajAnalysis');
                end
            end

            nm_i = find(strcmp(string(norm_tbl.Flavor), f_lookup) & startsWith(string(norm_tbl.Variable), r_key), 1);
            if ~isempty(nm_i)
                rows = push_norm_rows(rows, norm_tbl, nm_i, pfx, sc_val, an_key, c_code);
            end

            if m >= 2
                w_pos = find(strcmp(string(win_tbl.Flavor), f_code) & strcmp(string(win_tbl.Comparison), [c_code '_minus_kb_rt']), 1);
                w_neg = find(strcmp(string(win_tbl.Flavor), f_code) & strcmp(string(win_tbl.Comparison), ['kb_rt_minus_' c_code]), 1);
                if ~isempty(w_pos)
                    d_es = num_val(win_tbl.Effect_Size_Diff(w_pos)); d_l = num_val(win_tbl.CI_Lower(w_pos)); d_u = num_val(win_tbl.CI_Upper(w_pos));
                elseif ~isempty(w_neg)
                    d_es = -num_val(win_tbl.Effect_Size_Diff(w_neg)); d_l = -num_val(win_tbl.CI_Upper(w_neg)); d_u = -num_val(win_tbl.CI_Lower(w_neg));
                else
                    d_es = NaN; d_l = NaN; d_u = NaN;
                end
                spfx = ['sens_' an_key '_' c_code '_vs_kb_rt_'];
                rows = push_mv_row(rows, [spfx 'delta_dz'], sc_val, an_key, 'sensitivity', c_code, 'vs_kb_rt', 'delta_dz', d_es, sprintf('%+.3f', d_es), 'Delta |dz|', 2, '|dz_measure| - |dz_kb_rt|', 'Effects', 'Effect_Comparisons_Within');
                rows = push_mv_row(rows, [spfx 'ci_low'],   sc_val, an_key, 'sensitivity', c_code, 'vs_kb_rt', 'ci_low',   d_l,  sprintf('%.3f', d_l),   'Delta |dz|', 2, 'Bootstrap CI L', 'Effects', 'Effect_Comparisons_Within');
                rows = push_mv_row(rows, [spfx 'ci_high'],  sc_val, an_key, 'sensitivity', c_code, 'vs_kb_rt', 'ci_high',  d_u,  sprintf('%.3f', d_u),   'Delta |dz|', 2, 'Bootstrap CI U', 'Effects', 'Effect_Comparisons_Within');
                ts_i = find(strcmp(string(t_sens.Node_Name), tree_sens_nodes{m}), 1);
                if ~isempty(ts_i)
                    rows = push_mv_row(rows, [spfx 'treebh_p'], sc_val, an_key, 'sensitivity', c_code, 'vs_kb_rt', 'p', num_val(t_sens.Uncorrected_p(ts_i)), format_p_display(num_val(t_sens.Uncorrected_p(ts_i))), 'p', 4, 'Sens p', 'Effects', 'TreeBH');
                    rows = push_mv_row(rows, [spfx 'treebh_q'], sc_val, an_key, 'sensitivity', c_code, 'vs_kb_rt', 'q', num_val(t_sens.Within_Family_FDR_q(ts_i)), format_p_display(num_val(t_sens.Within_Family_FDR_q(ts_i))), 'q', 4, 'Sens FDR q', 'Effects', 'TreeBH');
                end
                sa_r = sens_assump(strcmp(sens_assump.Flavor, f_code) & strcmp(sens_assump.Key, r_key), :);
                if ~isempty(sa_r)
                    rows = push_mv_row(rows, [spfx 'perm_p'],    sc_val, an_key, 'sensitivity', c_code, 'vs_kb_rt', 'perm_p',    num_val(sa_r.Perm_p(1)),    format_p_display(num_val(sa_r.Perm_p(1))), 'p', 4, 'Sign-flip perm p', 'Effects', 'sens_assump');
                    rows = push_mv_row(rows, [spfx 'delta_akp'], sc_val, an_key, 'sensitivity', c_code, 'vs_kb_rt', 'delta_akp', num_val(sa_r.Delta_AKP(1)), sprintf('%+.3f', num_val(sa_r.Delta_AKP(1))), 'Delta AKP', 2, '|AKP_m| - |AKP_kb|', 'Effects', 'sens_assump');
                end
            end
        end
    end

    % Temporal Full-Trajectory (Component 4 + noTrajNorm_noStandardization)
    c4 = TreeBH.Component4_Continuous_FDR;
    f3_raw = fst.noTrajNorm_noStandardization;
    f3_codes = {'traj','x_std','iep','head_angle'};
    f3_keys = {'Deviation From Center','Movement Variance (X-STD)','Implied End Point (IEP)','Heading Angle'};
    f3_c4   = {'Deviation_From_Center','Movement_Variation','Implied_End_Point','Heading_Angle'};
    f3_ft   = {'Deviation From center','Movement variation','iEP','Heading angle'};
    f3_u    = {'cm','cm','cm','deg'};
    for m = 1:4
        c_code = f3_codes{m}; r_key = f3_keys{m}; u_str = f3_u{m};
        scale_f = ternary_str_bool(m <= 3, 100.0, 1.0);
        pfx = ['temp_' c_code '_'];
        c4_i = find(strcmp(string(c4.Metric), f3_c4{m}), 1);
        ri   = find(startsWith(string(f3_raw.name), r_key), 1);
        if ~isempty(c4_i) && is_truthy(c4.Cluster_Detected(c4_i)) && ~isempty(ri)
            c_m = f3_raw.con_avg(ri)*scale_f; c_s = f3_raw.con_std(ri)*scale_f;
            i_m = f3_raw.incon_avg(ri)*scale_f; i_s = f3_raw.incon_std(ri)*scale_f;
            d_m = f3_raw.diff_avg(ri)*scale_f; ci_l = f3_raw.CI_low(ri)*scale_f; ci_h = f3_raw.CI_high(ri)*scale_f;
            rows = push_mv_row(rows, [pfx 'con_mean'],     'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'con_mean',     c_m, sprintf('%.3f', c_m), u_str, 2, 'Temp Con mean', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'con_sd'],       'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'con_sd',       c_s, sprintf('%.3f', c_s), u_str, 2, 'Temp Con SD', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'incon_mean'],   'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'incon_mean',   i_m, sprintf('%.3f', i_m), u_str, 2, 'Temp Incon mean', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'incon_sd'],     'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'incon_sd',     i_s, sprintf('%.3f', i_s), u_str, 2, 'Temp Incon SD', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'diff_mean'],    'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'diff_mean',    d_m, sprintf('%.3f', d_m), u_str, 2, 'Temp Con - Incon', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'abs_diff_mean'],'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'abs_diff_mean',abs(d_m), sprintf('%.3f', abs(d_m)), u_str, 2, 'Temp |Con - Incon|', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'ci_low'],       'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'ci_low',       ci_l, sprintf('%.3f', ci_l), u_str, 2, 'Temp CI L', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'ci_high'],      'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'ci_high',      ci_h, sprintf('%.3f', ci_h), u_str, 2, 'Temp CI U', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 't'],            'main', 'temp', 'congruency', c_code, 'con_vs_incon', 't',            f3_raw.tVal(ri), sprintf('%.3f', f3_raw.tVal(ri)), 't', 2, 'Window t', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'df'],           'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'df',           f3_raw.df(ri), sprintf('%d', round(f3_raw.df(ri))), 'df', 0, 'df', 'Effects', 'noTrajNorm_noStandardization');
            rows = push_mv_row(rows, [pfx 'clust_start_ms'],'main', 'temp', 'congruency', c_code, 'cluster', 'clust_start_ms', num_val(c4.Start_ms(c4_i)), sprintf('%d', round(num_val(c4.Start_ms(c4_i)))), 'ms', 0, 'Cluster start ms', 'Effects', 'Component4_Continuous_FDR');
            rows = push_mv_row(rows, [pfx 'clust_end_ms'],  'main', 'temp', 'congruency', c_code, 'cluster', 'clust_end_ms',   num_val(c4.End_ms(c4_i)),   sprintf('%d', round(num_val(c4.End_ms(c4_i)))),   'ms', 0, 'Cluster end ms',   'Effects', 'Component4_Continuous_FDR');
            rows = push_mv_row(rows, [pfx 'clust_p'],       'main', 'temp', 'congruency', c_code, 'cluster', 'clust_p',        num_val(c4.Cluster_p_raw(c4_i)), format_p_display(num_val(c4.Cluster_p_raw(c4_i))), 'p', 4, 'Cluster p', 'Effects', 'Component4_Continuous_FDR');
            rows = push_mv_row(rows, [pfx 'clust_q'],       'main', 'temp', 'congruency', c_code, 'cluster', 'clust_q',        num_val(c4.FDR_adj_p(c4_i)), format_p_display(num_val(c4.FDR_adj_p(c4_i))), 'q', 4, 'Cluster FDR q', 'Effects', 'Component4_Continuous_FDR');

            ef_i = find(strcmp(string(eff_tbl.Flavor), 'noTrajNorm_noStandardization') & strcmp(string(eff_tbl.Effect), c_code), 1);
            if ~isempty(ef_i)
                dz = num_val(eff_tbl.Cohens_dz(ef_i)); cl_e = num_val(eff_tbl.CI_Lower(ef_i)); cu_e = num_val(eff_tbl.CI_Upper(ef_i));
                rows = push_mv_row(rows, [pfx 'abs_dz'],        'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'abs_dz', abs(dz), sprintf('%.3f', abs(dz)), 'dz', 2, 'Window |dz|', 'Effects', 'Effect_Sizes');
                rows = push_mv_row(rows, [pfx 'abs_dz_ci_low'], 'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'abs_dz_ci_low', min(abs(cl_e), abs(cu_e)), sprintf('%.3f', min(abs(cl_e), abs(cu_e))), 'dz', 2, '|dz| CI L', 'Effects', 'Effect_Sizes');
                rows = push_mv_row(rows, [pfx 'abs_dz_ci_high'],'main', 'temp', 'congruency', c_code, 'con_vs_incon', 'abs_dz_ci_high',max(abs(cl_e), abs(cu_e)), sprintf('%.3f', max(abs(cl_e), abs(cu_e))), 'dz', 2, '|dz| CI U', 'Effects', 'Effect_Sizes');
            end
            ft_i = find(strcmp(string(ft_tbl.Flavor), 'noTrajNorm_noStandardization') & strcmp(string(ft_tbl.name), f3_ft{m}), 1);
            if ~isempty(ft_i)
                rows = push_mv_row(rows, [pfx 'clust_t_star'], 'main', 'temp', 'congruency', c_code, 'cluster', 'clust_t_star', ft_tbl.('t*')(ft_i), sprintf('%.3f', ft_tbl.('t*')(ft_i)), 't', 2, 'Peak sample t*', 'Effects', 'fullTrajAnalysis');
            end
            nm_i = find(strcmp(string(norm_tbl.Flavor), 'noTrajNorm_noStandardization') & startsWith(string(norm_tbl.Variable), r_key), 1);
            if ~isempty(nm_i)
                rows = push_norm_rows(rows, norm_tbl, nm_i, pfx, 'main', 'temp', c_code);
            end
        elseif ~isempty(c4_i)
            rows = push_mv_row(rows, [pfx 'clust_p'], 'main', 'temp', 'congruency', c_code, 'cluster', 'clust_p', 1.0, '1.0000', 'p', 4, 'No cluster detected', 'Effects', 'Component4_Continuous_FDR');
            rows = push_mv_row(rows, [pfx 'clust_q'], 'main', 'temp', 'congruency', c_code, 'cluster', 'clust_q', 1.0, '1.0000', 'q', 4, 'No cluster detected', 'Effects', 'Component4_Continuous_FDR');
        end
    end

    % 4. PAS Visibility, Objective Awareness & Dienes RttM
    ps_tbl = fst.primeAwarenessDist.PAS_Summary;
    pt_map = {'Reaching','Congruent','pas_reach_con'; 'Reaching','Incongruent','pas_reach_incon'; 'Reaching','Total (Marginal)','pas_reach_total'; ...
              'Keyboard','Congruent','pas_kb_con'; 'Keyboard','Incongruent','pas_kb_incon'; 'Keyboard','Total (Marginal)','pas_kb_total'; ...
              'Marginal by Congruency','Congruent Total','pas_marginal_con'; 'Marginal by Congruency','Incongruent Total','pas_marginal_incon'; ...
              'Grand Total','All Tasks & Conditions','pas_grand_total'};
    for k = 1:size(pt_map, 1)
        ri = find(strcmp(string(ps_tbl.Task), pt_map{k, 1}) & strcmp(string(ps_tbl.Condition), pt_map{k, 2}), 1);
        if isempty(ri), continue; end
        kp = pt_map{k, 3};
        for lv = 1:4
            rows = push_mv_row(rows, sprintf('%s_pas%d_pct', kp, lv), 'main', 'awareness', 'pas', kp, 'pas_distribution', sprintf('pas%d_pct', lv), ps_tbl.(sprintf('PAS_%d_Percent', lv))(ri), sprintf('%.2f', ps_tbl.(sprintf('PAS_%d_Percent', lv))(ri)), '%', 2, 'PAS %', 'Table_2_PAS_Visibility', 'PAS_Summary');
            rows = push_mv_row(rows, sprintf('%s_pas%d_cnt', kp, lv), 'main', 'awareness', 'pas', kp, 'pas_distribution', sprintf('pas%d_cnt', lv), ps_tbl.(sprintf('PAS_%d_Count', lv))(ri), sprintf('%d', round(ps_tbl.(sprintf('PAS_%d_Count', lv))(ri))), 'count', 0, 'PAS count', 'Table_2_PAS_Visibility', 'PAS_Summary');
        end
        rows = push_mv_row(rows, [kp '_mean'], 'main', 'awareness', 'pas', kp, 'pas_distribution', 'mean', ps_tbl.Mean_PAS_Score(ri), sprintf('%.3f', ps_tbl.Mean_PAS_Score(ri)), 'score', 2, 'Mean PAS', 'Table_2_PAS_Visibility', 'PAS_Summary');
        rows = push_mv_row(rows, [kp '_sd'],   'main', 'awareness', 'pas', kp, 'pas_distribution', 'sd',   ps_tbl.SD_PAS_Score(ri),   sprintf('%.3f', ps_tbl.SD_PAS_Score(ri)),   'score', 2, 'SD PAS',   'Table_2_PAS_Visibility', 'PAS_Summary');
    end
    past = fst.primeAwarenessDist.PAS_Statistical_Tests;
    ap_map = {'Main_Effect_Congruency (Incon - Con)', 'pas_anova_cong'; 'Main_Effect_Task (KB - Reach)', 'pas_anova_task'; 'Interaction_Task_x_Congruency', 'pas_anova_inter'};
    for k = 1:size(ap_map, 1)
        ri = find(strcmp(string(past.Analysis_Type), 'rm_ANOVA_Mean_PAS') & strcmp(string(past.Test_Contrast), ap_map{k, 1}), 1);
        if isempty(ri), continue; end
        kp = ap_map{k, 2};
        rows = push_mv_row(rows, [kp '_F'],     'main', 'awareness', 'pas_anova', kp, 'rm_anova', 'F',     past.Test_Statistic(ri), sprintf('%.3f', past.Test_Statistic(ri)), 'F', 2, 'rmANOVA F', 'Table_2_PAS_Visibility', 'PAS_Statistical_Tests');
        rows = push_mv_row(rows, [kp '_p'],     'main', 'awareness', 'pas_anova', kp, 'rm_anova', 'p',     past.P_Value(ri), format_p_display(past.P_Value(ri)), 'p', 4, 'rmANOVA p', 'Table_2_PAS_Visibility', 'PAS_Statistical_Tests');
        rows = push_mv_row(rows, [kp '_eta2p'], 'main', 'awareness', 'pas_anova', kp, 'rm_anova', 'eta2p', past.Effect_Size_Partial_Eta2(ri), sprintf('%.3f', past.Effect_Size_Partial_Eta2(ri)), 'eta2p', 3, 'partial eta^2', 'Table_2_PAS_Visibility', 'PAS_Statistical_Tests');
    end

    pps = fst.Prime_Performance_Stats;
    for ri = 1:height(pps)
        cond_k = char(string(pps.Trial_Type(ri)));
        if contains(lower(cond_k), 'incon'), c_tag = 'incon'; else, c_tag = 'con'; end
        for tk = {'reach', 'kb'}
            t_tag = tk{1};
            kp = ['obj_' t_tag '_' c_tag '_'];
            rows = push_mv_row(rows, [kp 'mean'],    'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'mean',    pps.([t_tag '_avg'])(ri),     sprintf('%.2f', pps.([t_tag '_avg'])(ri)),     '%', 2, 'Forced-choice accuracy %', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 'sd'],      'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'sd',      pps.([t_tag '_std'])(ri),     sprintf('%.2f', pps.([t_tag '_std'])(ri)),     '%', 2, 'SD accuracy %', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 't'],       'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 't',       pps.([t_tag '_tVal'])(ri),    sprintf('%.3f', pps.([t_tag '_tVal'])(ri)),    't', 2, 'One-sample t vs 50%', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 'df'],      'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'df',      pps.([t_tag '_df'])(ri),      sprintf('%d', round(pps.([t_tag '_df'])(ri))), 'df', 0, 'df', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 'p'],       'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'p',       pps.([t_tag '_pVal'])(ri),    format_p_display(pps.([t_tag '_pVal'])(ri)),   'p', 4, 'One-sample p', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 'ci_low'],  'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'ci_low',  pps.([t_tag '_CI_low'])(ri),  sprintf('%.2f', pps.([t_tag '_CI_low'])(ri)),  '%', 2, '95% CI L', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 'ci_high'], 'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'ci_high', pps.([t_tag '_CI_high'])(ri), sprintf('%.2f', pps.([t_tag '_CI_high'])(ri)), '%', 2, '95% CI U', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 'bf01'],    'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'bf01',    pps.([t_tag '_BF01'])(ri),    sprintf('%.2f', pps.([t_tag '_BF01'])(ri)),    'BF', 2, 'JZS BF01 (r=0.707)', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
            rows = push_mv_row(rows, [kp 'bf10'],    'main', 'awareness', 'objective_fc', [t_tag '_' c_tag], 'vs_chance_50', 'bf10',    pps.([t_tag '_BF10'])(ri),    sprintf('%.3f', pps.([t_tag '_BF10'])(ri)),    'BF', 3, 'JZS BF10 (r=0.707)', 'Objective_Prime_Awareness', 'Prime_Performance_Stats');
        end
    end

    for ri = 1:numel(rttm_stats.u)
        ru = rttm_stats.u{ri}; kp = ['rttm_u_' ru.tag '_'];
        rows = push_mv_row(rows, [kp 'obs_uc'],   'si', 'awareness', 'dienes_rttm', ru.tag, 'contamination_bound', 'obs_uc',   ru.u,        sprintf('%.4f', ru.u),        'proportion', 4, 'PAS=1 proportion', 'Dienes_RttM_Awareness', 'PAS_Summary');
        rows = push_mv_row(rows, [kp 'e_star'],   'si', 'awareness', 'dienes_rttm', ru.tag, 'contamination_bound', 'e_star',   ru.e_star,   sprintf('%.4f', ru.e_star),   'proportion', 4, 'Latent error bound', 'Dienes_RttM_Awareness', 'Dienes RttM');
        rows = push_mv_row(rows, [kp 'c_max'],    'si', 'awareness', 'dienes_rttm', ru.tag, 'contamination_bound', 'c_max',    ru.c_max,    sprintf('%.5f', ru.c_max),    'proportion', 5, 'Max contamination proportion', 'Dienes_RttM_Awareness', 'Dienes RttM');
        rows = push_mv_row(rows, [kp 'eff50_ms'], 'si', 'awareness', 'dienes_rttm', ru.tag, 'contamination_bound', 'eff50_ms', ru.eff50_ms, sprintf('%.3f', ru.eff50_ms), 'ms', 3, 'Max contaminated effect (50 ms conscious prior)', 'Dienes_RttM_Awareness', 'Dienes RttM');
    end
    for ri = 1:numel(rttm_stats.ms_tests)
        rm = rttm_stats.ms_tests{ri}; kp = ['rttm_' rm.code '_50ms_'];
        rows = push_mv_row(rows, [kp 'obs_eff'],       'si', 'awareness', 'dienes_rttm', rm.code, 'interval_vs_point_null', 'obs_eff',       rm.obs_eff,       sprintf('%.3f', rm.obs_eff),       'ms', 2, 'Observed effect (Incon - Con)', 'Dienes_RttM_Awareness', 'Dienes RttM');
        rows = push_mv_row(rows, [kp 'obs_se'],        'si', 'awareness', 'dienes_rttm', rm.code, 'interval_vs_point_null', 'obs_se',        rm.obs_se,        sprintf('%.3f', rm.obs_se),        'ms', 2, 'SE', 'Dienes_RttM_Awareness', 'Dienes RttM');
        rows = push_mv_row(rows, [kp 'eff_max'],       'si', 'awareness', 'dienes_rttm', rm.code, 'interval_vs_point_null', 'eff_max',       rm.eff_max,       sprintf('%.4f', rm.eff_max),       'ms', 4, 'Interval null upper bound', 'Dienes_RttM_Awareness', 'Dienes RttM');
        rows = push_mv_row(rows, [kp 'bf10_point'],    'si', 'awareness', 'dienes_rttm', rm.code, 'interval_vs_point_null', 'bf10_point',    rm.bf10_point,    sprintf('%.3g', rm.bf10_point),    'BF', 2, 'Point-null BF10 (HalfNormal SD=25)', 'Dienes_RttM_Awareness', 'Dienes RttM');
        rows = push_mv_row(rows, [kp 'bf10_interval'], 'si', 'awareness', 'dienes_rttm', rm.code, 'interval_vs_point_null', 'bf10_interval', rm.bf10_interval, sprintf('%.3g', rm.bf10_interval), 'BF', 2, 'RttM interval-null BF10', 'Dienes_RttM_Awareness', 'Dienes RttM');
        rows = push_mv_row(rows, [kp 'bf01_interval'], 'si', 'awareness', 'dienes_rttm', rm.code, 'interval_vs_point_null', 'bf01_interval', rm.bf01_interval, sprintf('%.3g', rm.bf01_interval), 'BF', 2, 'RttM interval-null BF01', 'Dienes_RttM_Awareness', 'Dienes RttM');
    end

    % 5. COM Correct vs Incorrect & Dwell-Time Sweep
    cm_sets = {'main', com_perf_stats.main, 'si'; 'pas1', com_perf_stats.pas1, 'si'};
    for ci = 1:size(cm_sets, 1)
        tag = cm_sets{ci, 1}; st = cm_sets{ci, 2}; sc_v = cm_sets{ci, 3}; ps = st.ps;
        kp = ['com_perf_' tag '_'];
        rows = push_mv_row(rows, [kp 'n'],         sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'n',         st.n,         sprintf('%d', st.n),            'participants', 0, 'minIncorr>=8 N', 'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'df'],        sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'df',        ps.df,        sprintf('%d', ps.df),           'df',           0, 'df', 'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'corr_mean'], sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'corr_mean', st.corr_mean, sprintf('%.2f', st.corr_mean),  'count',        2, 'Correct COM mean', 'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'corr_sd'],   sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'corr_sd',   st.corr_sd,   sprintf('%.2f', st.corr_sd),    'count',        2, 'Correct COM SD',   'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'inc_mean'],  sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'inc_mean',  st.inc_mean,  sprintf('%.2f', st.inc_mean),   'count',        2, 'Incorrect COM mean','COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'inc_sd'],    sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'inc_sd',    st.inc_sd,    sprintf('%.2f', st.inc_sd),     'count',        2, 'Incorrect COM SD',  'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'diff_mean'], sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'diff_mean', ps.diff_mean, sprintf('%.2f', ps.diff_mean),  'count',        2, 'Correct - Incorrect','COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'diff_sd'],   sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'diff_sd',   ps.sd_diff,   sprintf('%.2f', ps.sd_diff),    'count',        2, 'SD diff',          'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'ci_low'],    sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'ci_low',    ps.ci_low,    sprintf('%.2f', ps.ci_low),     'count',        2, '95% CI L',         'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'ci_high'],   sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'ci_high',   ps.ci_high,   sprintf('%.2f', ps.ci_high),    'count',        2, '95% CI U',         'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 't'],         sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 't',         ps.t,         sprintf('%.2f', ps.t),          't',            2, 'Paired t',         'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'p'],         sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'p',         ps.p,         format_p_display(ps.p),       'p',            4, 'Paired p',         'COM_Thresholding', 'f1_dir');
        rows = push_mv_row(rows, [kp 'dz'],        sc_v, 'prereg', 'com_perf', 'com_count', 'correct_vs_incorrect', 'dz',        ps.dz,        sprintf('%.2f', ps.dz),         'dz',           2, 'Cohen dz',         'COM_Thresholding', 'f1_dir');
    end
    rows = push_mv_row(rows, 'com_perf_main_downsamp_med_dz', 'si', 'prereg', 'com_perf', 'com_count', 'downsampling', 'median_dz', com_perf_stats.main.ds_med_dz, sprintf('%.3f', com_perf_stats.main.ds_med_dz), 'dz', 2, '10k downsampling median dz', 'COM_Thresholding', 'f1_dir');
    rows = push_mv_row(rows, 'com_perf_main_downsamp_mean_p', 'si', 'prereg', 'com_perf', 'com_count', 'downsampling', 'mean_p',   com_perf_stats.main.ds_mean_p, format_p_display(com_perf_stats.main.ds_mean_p), 'p', 4, '10k downsampling mean p', 'COM_Thresholding', 'f1_dir');

    com_sw = fst.Supp_COM_Threshold_Stats;
    for ri = 1:height(com_sw)
        th = lower(char(string(com_sw.Threshold(ri))));
        corr_k = lower(char(string(com_sw.Correctness(ri))));
        tok_s = regexp(th, '(\d+)\s*sample', 'tokens');
        tok_m = regexp(th, '(\d+)\s*ms', 'tokens');
        if ~isempty(tok_s)
            th_k = [tok_s{1}{1} 'samp'];
        elseif ~isempty(tok_m)
            th_k = [tok_m{1}{1} 'ms'];
        else
            th_k = sprintf('row%d', ri);
        end
        kp = ['com_thresh_' th_k '_' corr_k '_'];
        rows = push_mv_row(rows, [kp 'con_mean'], 'si', 'prereg', 'com_thresh', [th_k '_' corr_k], 'con_vs_incon', 'con_mean', com_sw.Congruent_Mean(ri), sprintf('%.3f', com_sw.Congruent_Mean(ri)), 'count', 2, th, 'COM_Thresholding', 'Supp_COM_Threshold_Stats');
        rows = push_mv_row(rows, [kp 'inc_mean'], 'si', 'prereg', 'com_thresh', [th_k '_' corr_k], 'con_vs_incon', 'inc_mean', com_sw.Incongruent_Mean(ri), sprintf('%.3f', com_sw.Incongruent_Mean(ri)), 'count', 2, th, 'COM_Thresholding', 'Supp_COM_Threshold_Stats');
        rows = push_mv_row(rows, [kp 'diff'],     'si', 'prereg', 'com_thresh', [th_k '_' corr_k], 'con_vs_incon', 'diff',     com_sw.Difference_Incon_minus_Con(ri), sprintf('%.3f', com_sw.Difference_Incon_minus_Con(ri)), 'count', 2, 'Incon - Con', 'COM_Thresholding', 'Supp_COM_Threshold_Stats');
        rows = push_mv_row(rows, [kp 't'],        'si', 'prereg', 'com_thresh', [th_k '_' corr_k], 'con_vs_incon', 't',        com_sw.t_statistic(ri), sprintf('%.3f', com_sw.t_statistic(ri)), 't', 2, 'Paired t', 'COM_Thresholding', 'Supp_COM_Threshold_Stats');
        rows = push_mv_row(rows, [kp 'df'],       'si', 'prereg', 'com_thresh', [th_k '_' corr_k], 'con_vs_incon', 'df',       com_sw.df(ri), sprintf('%d', round(com_sw.df(ri))), 'df', 0, 'df', 'COM_Thresholding', 'Supp_COM_Threshold_Stats');
        rows = push_mv_row(rows, [kp 'p'],        'si', 'prereg', 'com_thresh', [th_k '_' corr_k], 'con_vs_incon', 'p',        com_sw.p_value_uncorrected(ri), format_p_display(com_sw.p_value_uncorrected(ri)), 'p', 4, 'Uncorrected p', 'COM_Thresholding', 'Supp_COM_Threshold_Stats');
        rows = push_mv_row(rows, [kp 'dz'],       'si', 'prereg', 'com_thresh', [th_k '_' corr_k], 'con_vs_incon', 'dz',       com_sw.Cohens_dz(ri), sprintf('%.3f', com_sw.Cohens_dz(ri)), 'dz', 2, 'Cohen dz', 'COM_Thresholding', 'Supp_COM_Threshold_Stats');
    end

    % 6. Split-Half Reliability (24 rows -> unique metric x score_type)
    rel_tbl = fst.Split_Half_Reliability;
    for ri = 1:height(rel_tbl)
        mc = char(string(rel_tbl.Metric_Code(ri)));
        st = char(string(rel_tbl.Score_Type(ri)));
        if strcmp(st, 'Congruency_Diff'), st_k = 'diff';
        elseif strcmp(st, 'Congruent_Mean'), st_k = 'con';
        else, st_k = 'incon';
        end
        kp = ['rel_' mc '_' st_k '_'];
        rows = push_mv_row(rows, [kp 'pearson_r_sb'],    'si', 'prereg', 'reliability', [mc '_' st_k], 'split_half', 'pearson_r_sb',    rel_tbl.Pearson_r_SB_Mean(ri),    sprintf('%.3f', rel_tbl.Pearson_r_SB_Mean(ri)),    'r', 2, 'Spearman-Brown Pearson mean', 'Split_Half_Reliability', 'Split_Half_Reliability');
        rows = push_mv_row(rows, [kp 'pearson_ci_low'],  'si', 'prereg', 'reliability', [mc '_' st_k], 'split_half', 'pearson_ci_low',  rel_tbl.Pearson_CI_Lower(ri),     sprintf('%.3f', rel_tbl.Pearson_CI_Lower(ri)),     'r', 2, 'Pearson SB CI L', 'Split_Half_Reliability', 'Split_Half_Reliability');
        rows = push_mv_row(rows, [kp 'pearson_ci_high'], 'si', 'prereg', 'reliability', [mc '_' st_k], 'split_half', 'pearson_ci_high', rel_tbl.Pearson_CI_Upper(ri),     sprintf('%.3f', rel_tbl.Pearson_CI_Upper(ri)),     'r', 2, 'Pearson SB CI U', 'Split_Half_Reliability', 'Split_Half_Reliability');
        rows = push_mv_row(rows, [kp 'spearman_rho_sb'], 'si', 'prereg', 'reliability', [mc '_' st_k], 'split_half', 'spearman_rho_sb', rel_tbl.Spearman_rho_SB_Mean(ri), sprintf('%.3f', rel_tbl.Spearman_rho_SB_Mean(ri)), 'rho', 2, 'Spearman-Brown rho mean', 'Split_Half_Reliability', 'Split_Half_Reliability');
    end

    % 7. Without Long-Duration Exclusion (Sheet 10, from fst.SI_Reanalysis)
    if isfield(fst, 'SI_Reanalysis') && isstruct(fst.SI_Reanalysis)
        si = fst.SI_Reanalysis;
        t_sum = si.si_summary_tbl;
        for ri = 1:height(t_sum)
            vc = char(string(t_sum.Variable(ri)));
            un = char(string(t_sum.Units(ri)));
            kp = ['wolong_' vc '_'];
            rows = push_mv_row(rows, [kp 'con_mean'],   'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'con_mean',   t_sum.Congruent_Mean(ri),   sprintf('%.3f', t_sum.Congruent_Mean(ri)),   un, 2, 'N=31 Con mean', 'PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'con_sd'],     'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'con_sd',     t_sum.Congruent_SD(ri),     sprintf('%.3f', t_sum.Congruent_SD(ri)),     un, 2, 'N=31 Con SD',   'PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'incon_mean'], 'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'incon_mean', t_sum.Incongruent_Mean(ri), sprintf('%.3f', t_sum.Incongruent_Mean(ri)), un, 2, 'N=31 Incon mean','PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'incon_sd'],   'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'incon_sd',   t_sum.Incongruent_SD(ri),   sprintf('%.3f', t_sum.Incongruent_SD(ri)),   un, 2, 'N=31 Incon SD', 'PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'diff_mean'],  'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'diff_mean',  t_sum.Diff_Mean(ri),        sprintf('%.3f', t_sum.Diff_Mean(ri)),        un, 2, 'N=31 Incon - Con','PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 't'],          'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 't',          t_sum.t_stat(ri),           sprintf('%.3f', t_sum.t_stat(ri)),           't', 2, 'Paired t',      'PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'df'],         'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'df',         t_sum.df(ri),               sprintf('%d', round(t_sum.df(ri))),          'df', 0, 'df (N=31 -> 30)','PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'p'],          'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'p',          t_sum.p_val(ri),            format_p_display(t_sum.p_val(ri)),           'p', 4, 'Paired p',      'PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'dz'],         'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'dz',         t_sum.Cohen_dz(ri),         sprintf('%.3f', t_sum.Cohen_dz(ri)),         'dz', 2, 'Signed dz',     'PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
            rows = push_mv_row(rows, [kp 'abs_dz'],     'si', 'wo_long_dur', 'congruency', vc, 'con_vs_incon', 'abs_dz',     abs(t_sum.Cohen_dz(ri)),    sprintf('%.3f', abs(t_sum.Cohen_dz(ri))),    'dz', 2, 'Unsigned |dz|', 'PreReg_WO_Long_Dur_Excl', 'SI_Reanalysis_Summary');
        end

        t_eff4 = si.effects_tbl_f4;
        for ri = 1:height(t_eff4)
            ef = lower(char(string(t_eff4.Effect(ri))));
            rows = push_mv_row(rows, ['wolong_' ef '_boot_abs_dz'],    'si', 'wo_long_dur', 'congruency', ef, 'con_vs_incon', 'boot_abs_dz',    abs(num_val(t_eff4.Cohens_dz(ri))), sprintf('%.3f', abs(num_val(t_eff4.Cohens_dz(ri)))), 'dz', 2, 'Bootstrap |dz|', 'PreReg_WO_Long_Dur_Excl', 'Effect_Sizes_Summary');
            rows = push_mv_row(rows, ['wolong_' ef '_boot_ci_low'],    'si', 'wo_long_dur', 'congruency', ef, 'con_vs_incon', 'boot_ci_low',    min(abs(num_val(t_eff4.CI_Lower(ri))), abs(num_val(t_eff4.CI_Upper(ri)))), sprintf('%.3f', min(abs(num_val(t_eff4.CI_Lower(ri))), abs(num_val(t_eff4.CI_Upper(ri))))), 'dz', 2, '|dz| CI L', 'PreReg_WO_Long_Dur_Excl', 'Effect_Sizes_Summary');
            rows = push_mv_row(rows, ['wolong_' ef '_boot_ci_high'],   'si', 'wo_long_dur', 'congruency', ef, 'con_vs_incon', 'boot_ci_high',   max(abs(num_val(t_eff4.CI_Lower(ri))), abs(num_val(t_eff4.CI_Upper(ri)))), sprintf('%.3f', max(abs(num_val(t_eff4.CI_Lower(ri))), abs(num_val(t_eff4.CI_Upper(ri))))), 'dz', 2, '|dz| CI U', 'PreReg_WO_Long_Dur_Excl', 'Effect_Sizes_Summary');
        end

        t_kb4 = si.within_tbl_f4;
        for ri = 1:height(t_kb4)
            cmp = lower(char(string(t_kb4.Comparison(ri))));
            mc = regexprep(cmp, '_minus_kb_rt$', '');
            rows = push_mv_row(rows, ['wolong_sens_' mc '_vs_kb_rt_delta_dz'], 'si', 'wo_long_dur', 'sensitivity', mc, 'vs_kb_rt', 'delta_dz', num_val(t_kb4.Effect_Size_Diff(ri)), sprintf('%+.3f', num_val(t_kb4.Effect_Size_Diff(ri))), 'Delta |dz|', 2, '|dz| - KB', 'PreReg_WO_Long_Dur_Excl', 'Effect_Comparisons_vs_KB_RT');
            rows = push_mv_row(rows, ['wolong_sens_' mc '_vs_kb_rt_ci_low'],   'si', 'wo_long_dur', 'sensitivity', mc, 'vs_kb_rt', 'ci_low',   num_val(t_kb4.CI_Lower(ri)), sprintf('%.3f', num_val(t_kb4.CI_Lower(ri))),   'Delta |dz|', 2, 'CI L', 'PreReg_WO_Long_Dur_Excl', 'Effect_Comparisons_vs_KB_RT');
            rows = push_mv_row(rows, ['wolong_sens_' mc '_vs_kb_rt_ci_high'],  'si', 'wo_long_dur', 'sensitivity', mc, 'vs_kb_rt', 'ci_high',  num_val(t_kb4.CI_Upper(ri)), sprintf('%.3f', num_val(t_kb4.CI_Upper(ri))),  'Delta |dz|', 2, 'CI U', 'PreReg_WO_Long_Dur_Excl', 'Effect_Comparisons_vs_KB_RT');
            rows = push_mv_row(rows, ['wolong_sens_' mc '_vs_kb_rt_p'],        'si', 'wo_long_dur', 'sensitivity', mc, 'vs_kb_rt', 'p',        num_val(t_kb4.P_Value(ri)),  format_p_display(num_val(t_kb4.P_Value(ri))), 'p', 4, 'Paired bootstrap p', 'PreReg_WO_Long_Dur_Excl', 'Effect_Comparisons_vs_KB_RT');
        end

        t_dec = si.decomp_tbl;
        vn_dec = t_dec.Properties.VariableNames;
        if ismember('Variable', vn_dec) && ismember('Rescued_Slow_Pooled_Diff', vn_dec)
            for ri = 1:height(t_dec)
                mc = lower(regexprep(char(string(t_dec.Variable(ri))), '[^a-zA-Z0-9]+', '_'));
                du = char(string(t_dec.Units(ri)));
                rows = push_mv_row(rows, ['wolong_decomp_' mc '_slow_diff'],    'si', 'wo_long_dur', 'decomposition', mc, 'rescued_slow', 'slow_pooled_diff', num_val(t_dec.Rescued_Slow_Pooled_Diff(ri)),    sprintf('%.3f', num_val(t_dec.Rescued_Slow_Pooled_Diff(ri))),    du, 2, 'Rescued slow pooled diff', 'PreReg_WO_Long_Dur_Excl', 'WO_Long_Dur_Trial_Decomposition');
                rows = push_mv_row(rows, ['wolong_decomp_' mc '_n30_mean_diff'],'si', 'wo_long_dur', 'decomposition', mc, 'rescued_slow', 'n30_mean_diff',    num_val(t_dec.WO_Long_Dur_N30_Mean_Diff(ri)),   sprintf('%.3f', num_val(t_dec.WO_Long_Dur_N30_Mean_Diff(ri))),   du, 2, 'WO long dur N=30 diff', 'PreReg_WO_Long_Dur_Excl', 'WO_Long_Dur_Trial_Decomposition');
                rows = push_mv_row(rows, ['wolong_decomp_' mc '_pct_chg'],      'si', 'wo_long_dur', 'decomposition', mc, 'rescued_slow', 'pct_chg',          num_val(t_dec.Pct_Change_Mean_Diff_N30(ri)),    sprintf('%.2f', num_val(t_dec.Pct_Change_Mean_Diff_N30(ri))),    '%', 2, '% change in mean diff (N=30)', 'PreReg_WO_Long_Dur_Excl', 'WO_Long_Dur_Trial_Decomposition');
                rows = push_mv_row(rows, ['wolong_decomp_' mc '_n31_dz'],       'si', 'wo_long_dur', 'decomposition', mc, 'rescued_slow', 'n31_dz',           num_val(t_dec.WO_Long_Dur_N31_Cohens_dz(ri)),   sprintf('%.3f', num_val(t_dec.WO_Long_Dur_N31_Cohens_dz(ri))),   'dz', 2, 'WO long dur N=31 signed dz', 'PreReg_WO_Long_Dur_Excl', 'WO_Long_Dur_Trial_Decomposition');
            end
        end
    end

    % 8. Slow-Only Rescued Movements (Sheet 12)
    rows = push_mv_row(rows, 'slow_trials_con_total',   'si', 'slow_only', 'exclusions', 'slow_trials', 'slow_only', 'cnt_con',   slow_stats.n30_con_trials, sprintf('%d', slow_stats.n30_con_trials), 'count', 0, 'Rescued very-slow Con trials (N=30)', 'Slow_Only_Analysis', 'f1_dir');
    rows = push_mv_row(rows, 'slow_trials_incon_total', 'si', 'slow_only', 'exclusions', 'slow_trials', 'slow_only', 'cnt_incon', slow_stats.n30_inc_trials, sprintf('%d', slow_stats.n30_inc_trials), 'count', 0, 'Rescued very-slow Incon trials (N=30)', 'Slow_Only_Analysis', 'f1_dir');
    rows = push_mv_row(rows, 'slow_trials_total',       'si', 'slow_only', 'exclusions', 'slow_trials', 'slow_only', 'cnt_total', slow_stats.n30_tot_trials, sprintf('%d', slow_stats.n30_tot_trials), 'count', 0, 'Total rescued very-slow trials (N=30)', 'Slow_Only_Analysis', 'f1_dir');
    rows = push_mv_row(rows, 'slow_n25_lr_count',       'si', 'slow_only', 'sample',     'slow_lr',     'slow_only', 'n',         slow_stats.n25_count,      sprintf('%d', slow_stats.n25_count),      'participants', 0, 'L/R-balanced slow-only N', 'Slow_Only_Analysis', 'f1_dir');
    for di = 1:numel(slow_stats.disc)
        d = slow_stats.disc{di}; ps = d.ps;
        kp = sprintf('slow_%s_%s_', d.cohort, d.code);
        rows = push_mv_row(rows, [kp 'con_mean'],  'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 'con_mean',  d.con_mean,   sprintf('%.3f', d.con_mean),   d.unit, 2, 'Slow Con mean', 'Slow_Only_Analysis', 'f1_dir');
        rows = push_mv_row(rows, [kp 'incon_mean'],'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 'incon_mean',d.inc_mean,   sprintf('%.3f', d.inc_mean),   d.unit, 2, 'Slow Incon mean','Slow_Only_Analysis', 'f1_dir');
        rows = push_mv_row(rows, [kp 'diff_mean'], 'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 'diff_mean', ps.diff_mean, sprintf('%.3f', ps.diff_mean), d.unit, 2, 'Con - Incon', 'Slow_Only_Analysis', 'f1_dir');
        rows = push_mv_row(rows, [kp 't'],         'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 't',         ps.t,         sprintf('%.3f', ps.t),         't',    2, 'Paired t', 'Slow_Only_Analysis', 'f1_dir');
        rows = push_mv_row(rows, [kp 'df'],        'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 'df',        ps.df,        sprintf('%d', ps.df),          'df',   0, 'df', 'Slow_Only_Analysis', 'f1_dir');
        rows = push_mv_row(rows, [kp 'p'],         'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 'p',         ps.p,         format_p_display(ps.p),      'p',    4, 'Paired p', 'Slow_Only_Analysis', 'f1_dir');
        rows = push_mv_row(rows, [kp 'dz'],        'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 'dz',        ps.dz,        sprintf('%.3f', ps.dz),        'dz',   2, 'Signed dz', 'Slow_Only_Analysis', 'f1_dir');
        rows = push_mv_row(rows, [kp 'abs_dz'],    'si', 'slow_only', 'congruency', d.code, 'con_vs_incon', 'abs_dz',    abs(ps.dz),   sprintf('%.3f', abs(ps.dz)),   'dz',   2, 'Unsigned |dz|', 'Slow_Only_Analysis', 'f1_dir');
    end
    for ci = 1:numel(slow_stats.clust)
        c = slow_stats.clust{ci};
        kp = sprintf('slow_%s_%s_', c.cohort, c.code);
        rows = push_mv_row(rows, [kp 'clust_p'], 'si', 'slow_only', 'cluster', c.code, 'con_vs_incon', 'clust_p', c.clust_p, format_p_display(c.clust_p), 'p', 4, 'Slow cluster p', 'Slow_Only_Analysis', 'f1_dir');
        if c.detected == 1
            rows = push_mv_row(rows, [kp 'clust_start_pct'], 'si', 'slow_only', 'cluster', c.code, 'con_vs_incon', 'clust_start_pct', c.start_pct, sprintf('%.1f', c.start_pct), '% path', 1, 'Cluster start %', 'Slow_Only_Analysis', 'f1_dir');
            rows = push_mv_row(rows, [kp 'clust_end_pct'],   'si', 'slow_only', 'cluster', c.code, 'con_vs_incon', 'clust_end_pct',   c.end_pct,   sprintf('%.1f', c.end_pct),   '% path', 1, 'Cluster end %',   'Slow_Only_Analysis', 'f1_dir');
            rows = push_mv_row(rows, [kp 'clust_abs_dz'],    'si', 'slow_only', 'cluster', c.code, 'con_vs_incon', 'clust_abs_dz',    abs(c.ps.dz), sprintf('%.3f', abs(c.ps.dz)), 'dz', 2, 'Window |dz|', 'Slow_Only_Analysis', 'f1_dir');
        end
    end

    col_names = {'stat_key','scope','analysis','domain','measure','contrast','stat_name', ...
                 'raw_value','text_value','unit','decimals_hint','direction_note','review_sheet','source_mat_field'};
    tbl_out = cell2table(rows, 'VariableNames', col_names);

    % Verify zero duplicate stat_keys
    [u_keys, ~, ic] = unique(tbl_out.stat_key, 'stable');
    if numel(u_keys) ~= height(tbl_out)
        counts = accumarray(ic, 1);
        dups = u_keys(counts > 1);
        error('Duplicate stat_key(s) detected in Manuscript_Values: %s', strjoin(cellstr(dups), ', '));
    end
end

function rows = push_norm_rows(rows, norm_tbl, nm_i, pfx, sc_val, an_key, c_code)
    pairs = { ...
        'lilliefors_p', 'lilliefors_p', 'Lilliefors_p', 'p', 4; ...
        'jb_p',         'jb_p',         'JB_p',         'p', 4; ...
        'skewness',     'skewness',     'Skewness',     'skew', 2; ...
        'kurtosis',     'kurtosis',     'Kurtosis',     'kurt', 2; ...
        'perm_p',       'perm_p',       'Permutation_p','p', 4; ...
        'yuen_t',       'yuen_t',       'Yuen_t',       't', 2; ...
        'yuen_p',       'yuen_p',       'Yuen_p',       'p', 4; ...
        'akp_dep',      'akp_dep',      'AKP_Dependent','AKP', 2};
    for pi = 1:size(pairs, 1)
        fn = pairs{pi, 3};
        if ~ismember(fn, norm_tbl.Properties.VariableNames), continue; end
        val = num_val(norm_tbl.(fn)(nm_i));
        if isnan(val), continue; end
        if strcmp(pairs{pi, 4}, 'p'), txt = format_p_display(val); else, txt = sprintf('%.3f', val); end
        rows(end+1, :) = assign_row_cell([pfx 'norm_' pairs{pi, 1}], sc_val, an_key, 'assumptions', c_code, ...
            'con_vs_incon', pairs{pi, 2}, val, txt, pairs{pi, 4}, pairs{pi, 5}, ['Normality/Robust ' fn], 'Stats_Tests_Assumptions', 'Normality_and_Permutations_Table'); %#ok<AGROW>
    end
    akp_v = num_val(norm_tbl.AKP_Dependent(nm_i));
    if ~isnan(akp_v)
        rows(end+1, :) = assign_row_cell([pfx 'norm_abs_akp_dep'], sc_val, an_key, 'assumptions', c_code, ...
            'con_vs_incon', 'abs_akp_dep', abs(akp_v), sprintf('%.3f', abs(akp_v)), 'AKP', 2, 'Unsigned |AKP_dep|', 'Effects', 'Normality_and_Permutations_Table'); %#ok<AGROW>
    end
end

function rows_ref = push_mv_row(rows_ref, k, sc, an, dm, ms, ct, sn, rv, tv, un, dh, dn, rs, sf)
    rows_ref(end+1, :) = assign_row_cell(k, sc, an, dm, ms, ct, sn, rv, tv, un, dh, dn, rs, sf);
end

function r_cell = assign_row_cell(k, sc, an, dm, ms, ct, sn, rv, tv, un, dh, dn, rs, sf)
    r_cell = {char(k), char(sc), char(an), char(dm), char(ms), char(ct), char(sn), ...
              double(rv), char(tv), char(un), double(dh), char(dn), char(rs), char(sf)};
end

% =========================================================================
% BUILDER 16: Sheet 16 (_Metadata)
% =========================================================================
function tbl_out = build_sheet_metadata(xlsx_path, mv_tbl)
    meta_rows = { ...
        'Workbook_Path', xlsx_path; ...
        'Generated_Timestamp', datestr(now, 'yyyy-mm-dd HH:MM:SS'); ...
        'MATLAB_Version', version; ...
        'Manuscript_Values_Total_Keys', num2str(height(mv_tbl)); ...
        'Spatial_Units_Standard', 'All spatial length/deviation metrics (MAD, Distance Traveled, Deviance From Center, X-STD, IEP) scaled to cm; Reach Area and AUC in 10^2 cm^2 (100 cm^2); Heading Angle in deg; Latencies in ms'; ...
        'Robustness_ZScore_Note', 'Robustness analysis discrete measures (except Reach Area in 10^2 cm^2) are within-participant Z-scored; full-trajectory clusters use unstandardized TrajNorm coordinates in cm'; ...
        'Temporal_FullTraj_Note', 'chronological 0-340 ms (samples 1-34 at 100 Hz) un-warped trajectories; Heading Angle cluster dynamically recomputed with full-array SHA-256 cached permCluster'; ...
        'Sheet_Count', '16 (Sheets 1-14 review tables; Sheet 15 Manuscript_Values canonical numeric lookup; Sheet 16 _Metadata)'};
    tbl_out = cell2table(meta_rows, 'VariableNames', {'Property', 'Value'});
end

% =========================================================================
% SHARED STATISTICAL & FORMATTING HELPERS
% =========================================================================
function ps = calc_paired_stats(a, b)
    a = double(a(:)); b = double(b(:));
    valid = isfinite(a) & isfinite(b);
    a = a(valid); b = b(valid);
    d = a - b;
    n = numel(d);
    df = max(n - 1, 1);
    md = mean(d);
    sd = std(d);
    se = sd / sqrt(n);
    if sd == 0
        t_v = 0; p_v = 1.0; ci_l = md; ci_h = md; dz_v = 0;
    else
        [~, p_v, ci, st] = ttest(a, b);
        t_v = st.tstat; ci_l = ci(1); ci_h = ci(2); dz_v = md / sd;
    end
    ps = struct('n', n, 'df', df, 'diff_mean', md, 'sd_diff', sd, 'se', se, ...
                't', t_v, 'p', p_v, 'ci_low', ci_l, 'ci_high', ci_h, 'dz', dz_v);
end

function out = ternary_str_bool(cond, t_val, f_val)
    if cond, out = t_val; else, out = f_val; end
end

function v = ternary_str_num(tbl, col, default_v)
    if ~isempty(tbl) && ismember(col, tbl.Properties.VariableNames) && isfinite(tbl.(col)(1))
        v = tbl.(col)(1);
    else
        v = default_v;
    end
end

function pm_sub = filter_pm_by_good_subs(pm_tbl, good_subs)
    if isnumeric(pm_tbl.Sub_ID)
        sub_nums = double(pm_tbl.Sub_ID);
    else
        s_col = erase(string(pm_tbl.Sub_ID), 'Prtcp ');
        sub_nums = str2double(strtrim(s_col));
    end
    [tf, loc] = ismember(good_subs, sub_nums);
    pm_sub = pm_tbl(loc(tf), :);
end
