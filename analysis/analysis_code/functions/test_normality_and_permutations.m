function [norm_perm_struct, norm_perm_table] = test_normality_and_permutations(rawAggData, good_subs)
% TEST_NORMALITY_AND_PERMUTATIONS
% Evaluates normality, 1.5*IQR outliers, Yuen's robust t-test / AKP effect size,
% and paired sign-flip permutation tests for all discrete DVs across all flavors.
% Strictly includes only participants in good_subs.

    flavors = fieldnames(rawAggData);
    dv_names = {'kb_rt', 'ra', 'tot_dist', 'auc', 'mad', 'react', 'mt', 'com', 'rt'};
    dv_labels = {'Keyboard RT', 'Reach Area', 'Total Distance', 'AUC', 'MAD', 'Reach Onset', 'Movement Duration', 'Changes of Mind', 'Reach RT'};

    all_rows = {};
    norm_perm_struct = struct();

    % Normalization constant for 20% trimmed AKP effect size
    tr = 0.20;
    z_tr = norminv(1 - tr);
    akp_cterm = sqrt((erf(z_tr / sqrt(2)) - 2 * z_tr * normpdf(z_tr)) + 2 * (norminv(tr)^2) * tr);

    for iFlav = 1:length(flavors)
        flav = flavors{iFlav};
        flav_data = rawAggData.(flav);
        norm_perm_struct.(flav) = struct();

        for iDV = 1:length(dv_names)
            dv = dv_names{iDV};
            label = dv_labels{iDV};

            % Extract con and incon for good_subs
            con_vec = [];
            incon_vec = [];

            if strcmp(dv, 'kb_rt')
                if isfield(flav_data, 'keyboard') && isfield(flav_data.keyboard, 'rt')
                    con_vec = flav_data.keyboard.rt.con(good_subs);
                    incon_vec = flav_data.keyboard.rt.incon(good_subs);
                    if ~contains(flav, 'Standardization') && mean(con_vec, 'omitnan') < 10
                        con_vec = con_vec * 1000;
                        incon_vec = incon_vec * 1000;
                    end
                end
            else
                if isfield(flav_data, 'reach') && isfield(flav_data.reach, dv)
                    con_vec = flav_data.reach.(dv).con(good_subs);
                    incon_vec = flav_data.reach.(dv).incon(good_subs);
                    if size(con_vec, 1) > 1
                        con_vec = con_vec(1, :);
                        incon_vec = incon_vec(1, :);
                    end
                    if strcmp(dv, 'ra') && ~contains(flav, 'Standardization') && ~contains(flav, 'TrajNorm')
                        if mean(con_vec, 'omitnan') < 0.5
                            con_vec = con_vec * 10000;
                            incon_vec = incon_vec * 10000;
                        end
                    end
                end
            end

            if isempty(con_vec) || isempty(incon_vec) || all(isnan(con_vec)) || all(isnan(incon_vec))
                continue;
            end

            % Clean paired vectors
            valid_idx = ~isnan(con_vec) & ~isnan(incon_vec);
            x = con_vec(valid_idx);
            y = incon_vec(valid_idx);
            n = length(x);
            diff_vec = y - x;

            if n < 5
                continue;
            end

            % --- 1. Parametric Statistics ---
            mean_diff = mean(diff_vec);
            sd_diff = std(diff_vec);
            [~, p_param, ci_param, stats_param] = ttest(y, x);
            t_stat = stats_param.tstat;
            df_param = stats_param.df;
            cohens_dz = t_stat / sqrt(n);

            % --- 2. Normality Testing ---
            [h_lillie, p_lillie, stat_lillie] = lillietest(diff_vec);
            is_normal_lillie = (h_lillie == 0);

            [h_jb, p_jb, stat_jb] = jbtest(diff_vec);
            is_normal_jb = (h_jb == 0);

            skew_val = skewness(diff_vec);
            kurt_val = kurtosis(diff_vec);

            % Overall normality flag: Normal if Lilliefors p >= 0.05 and JB p >= 0.05
            is_normal = is_normal_lillie && is_normal_jb;

            % --- 3. Outlier Detection (1.5 * IQR) ---
            q1 = prctile(diff_vec, 25);
            q3 = prctile(diff_vec, 75);
            iqr_val = q3 - q1;
            lower_fence = q1 - 1.5 * iqr_val;
            upper_fence = q3 + 1.5 * iqr_val;
            outlier_mask = (diff_vec < lower_fence) | (diff_vec > upper_fence);
            n_outliers = sum(outlier_mask);
            has_outliers = (n_outliers > 0);

            % --- 4. Yuen's Robust Paired Test & AKP Effect Size ---
            g = floor(tr * n);
            h = n - 2 * g;

            % Winsorize x and y while strictly preserving participant pairing
            sort_x = sort(x);
            xbot = sort_x(g + 1);
            xtop = sort_x(end - g);
            win_x = x;
            win_x(win_x <= xbot) = xbot;
            win_x(win_x >= xtop) = xtop;

            sort_y = sort(y);
            ybot = sort_y(g + 1);
            ytop = sort_y(end - g);
            win_y = y;
            win_y(win_y <= ybot) = ybot;
            win_y(win_y >= ytop) = ytop;

            s1sq = var(win_x);
            s2sq = var(win_y);
            cov_xy_mat = cov(win_x, win_y);
            cov_val = cov_xy_mat(1, 2);

            se_yuen = sqrt(((n - 1) * s1sq + (n - 1) * s2sq - 2 * (n - 1) * cov_val) / (h * (h - 1)));
            mean_x_tr = trimmean(x, 2 * tr * 100);
            mean_y_tr = trimmean(y, 2 * tr * 100);
            diff_trimmed = mean_y_tr - mean_x_tr;
            t_yuen = diff_trimmed / se_yuen;
            df_yuen = h - 1;
            p_yuen = 2 * (1 - tcdf(abs(t_yuen), df_yuen));
            crit_t = tinv(1 - 0.05 / 2, df_yuen);
            ci_yuen = [diff_trimmed - crit_t * se_yuen, diff_trimmed + crit_t * se_yuen];

            sp_win = sqrt(((n - 1) * s1sq + (n - 1) * s2sq) / (2 * n - 2));
            akp_effect = akp_cterm * diff_trimmed / sp_win;

            % Bootstrap CI for Independent AKP effect size (2000 reps)
            nboot_akp = 2000;
            akp_boot = zeros(nboot_akp, 1);
            rng(42); % Reproducibility
            for b = 1:nboot_akp
                b_idx = randi(n, [n, 1]);
                bx = x(b_idx);
                by = y(b_idx);
                b_sort_x = sort(bx);
                bxbot = b_sort_x(g + 1);
                bxtop = b_sort_x(end - g);
                b_win_x = bx;
                b_win_x(b_win_x <= bxbot) = bxbot;
                b_win_x(b_win_x >= bxtop) = bxtop;

                b_sort_y = sort(by);
                bybot = b_sort_y(g + 1);
                bytop = b_sort_y(end - g);
                b_win_y = by;
                b_win_y(b_win_y <= bybot) = bybot;
                b_win_y(b_win_y >= bytop) = bytop;

                b_s1sq = var(b_win_x);
                b_s2sq = var(b_win_y);
                b_sp = sqrt(((n - 1) * b_s1sq + (n - 1) * b_s2sq) / (2 * n - 2));
                if b_sp > 0
                    akp_boot(b) = akp_cterm * (trimmean(by, 2 * tr * 100) - trimmean(bx, 2 * tr * 100)) / b_sp;
                else
                    akp_boot(b) = NaN;
                end
            end
            akp_ci = [prctile(akp_boot, 2.5), prctile(akp_boot, 97.5)];

            % --- 4b. Dependent AKP Effect Size (WRS2 dep.effect / D.akp.effect, dz-scale) ---
            [dep_akp_effect, dep_akp_ci] = calc_dependent_akp(y, x, tr, 2000, 42);

            % --- 5. Paired Sign-Flip Permutation t-Test (10,000 iterations) ---
            % Run ONLY if non-normal or if outliers exist
            nperm = 10000;
            if ~is_normal || has_outliers
                rng(42); % Reproducibility
                signs = (rand(nperm, n) > 0.5) * 2 - 1; % Matrix of +/- 1
                perm_diffs = signs .* repmat(diff_vec(:)', nperm, 1);
                perm_means = mean(perm_diffs, 2);
                perm_sds = std(perm_diffs, 0, 2);
                perm_tstats = perm_means ./ (perm_sds / sqrt(n));

                p_perm = (1 + sum(abs(perm_tstats) >= abs(t_stat))) / (1 + nperm);

                % Permutation bootstrap CI for mean difference
                ci_perm = [prctile(perm_means, 2.5), prctile(perm_means, 97.5)];
                p_perm_str = sprintf('%.4f', p_perm);
                ci_perm_str = sprintf('[%.3f, %.3f]', ci_perm(1), ci_perm(2));
            else
                p_perm = NaN;
                ci_perm = [NaN, NaN];
                p_perm_str = 'N/A (Normal)';
                ci_perm_str = 'N/A (Normal)';
            end

            % --- 6. Formatted Statistical Summary ---
            if has_outliers
                formatted_report = sprintf('Robust Yuen t(%d)=%.2f (p=%.4f), AKP_dep=%.2f', df_yuen, t_yuen, p_yuen, dep_akp_effect);
            elseif ~is_normal
                formatted_report = sprintf('Permutation t: p_perm=%.4f', p_perm);
            else
                formatted_report = sprintf('Parametric t(%d)=%.2f (p=%.4f), dz=%.2f', df_param, t_stat, p_param, cohens_dz);
            end

            % Save into struct
            res = struct();
            res.N = n;
            res.mean_diff = mean_diff;
            res.sd_diff = sd_diff;
            res.t_param = t_stat;
            res.df_param = df_param;
            res.p_param = p_param;
            res.ci_param = ci_param;
            res.cohens_dz = cohens_dz;
            res.lilliefors_stat = stat_lillie;
            res.lilliefors_p = p_lillie;
            res.is_normal_lillie = is_normal_lillie;
            res.jb_stat = stat_jb;
            res.jb_p = p_jb;
            res.skewness = skew_val;
            res.kurtosis = kurt_val;
            res.is_normal = is_normal;
            res.n_outliers = n_outliers;
            res.has_outliers = has_outliers;
            res.t_yuen = t_yuen;
            res.df_yuen = df_yuen;
            res.p_yuen = p_yuen;
            res.ci_yuen = ci_yuen;
            res.akp_effect = akp_effect;
            res.akp_ci = akp_ci;
            res.dep_akp_effect = dep_akp_effect;
            res.dep_akp_ci = dep_akp_ci;
            res.p_perm = p_perm;
            res.ci_perm = ci_perm;
            res.formatted_report = formatted_report;

            norm_perm_struct.(flav).(dv) = res;

            % Add row for master table
            all_rows = [all_rows; { ...
                string(flav), ...
                string(label), ...
                n, ...
                round(mean_diff, 4), ...
                round(sd_diff, 4), ...
                round(t_stat, 3), ...
                round(p_param, 4), ...
                sprintf('[%.3f, %.3f]', ci_param(1), ci_param(2)), ...
                round(cohens_dz, 3), ...
                round(p_lillie, 4), ...
                round(p_jb, 4), ...
                round(skew_val, 2), ...
                round(kurt_val, 2), ...
                string(ternary(is_normal, 'Yes', 'No')), ...
                n_outliers, ...
                string(ternary(has_outliers, 'Yes', 'No')), ...
                round(t_yuen, 3), ...
                round(p_yuen, 4), ...
                sprintf('[%.3f, %.3f]', ci_yuen(1), ci_yuen(2)), ...
                round(akp_effect, 3), ...
                sprintf('[%.3f, %.3f]', akp_ci(1), akp_ci(2)), ...
                round(dep_akp_effect, 3), ...
                sprintf('[%.3f, %.3f]', dep_akp_ci(1), dep_akp_ci(2)), ...
                string(p_perm_str), ...
                string(ci_perm_str), ...
                string(formatted_report) ...
            }];
        end
    end

    varNames = { ...
        'Flavor', 'Variable', 'N', 'Mean_Diff', 'SD_Diff', ...
        't_param', 'p_param', 'CI_param', 'Cohens_dz', ...
        'Lilliefors_p', 'JB_p', 'Skewness', 'Kurtosis', 'Is_Normal', ...
        'Outliers_1_5IQR', 'Has_Outliers', ...
        'Yuen_t', 'Yuen_p', 'Yuen_CI', ...
        'AKP_Independent', 'AKP_Independent_CI', ...
        'AKP_Dependent', 'AKP_Dependent_CI', ...
        'Permutation_p', 'Permutation_CI', 'Formatted_Report' ...
    };

    norm_perm_table = cell2table(all_rows, 'VariableNames', varNames);
end

function val = ternary(cond, trueVal, falseVal)
    if cond
        val = trueVal;
    else
        val = falseVal;
    end
end
