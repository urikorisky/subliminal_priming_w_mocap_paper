function figHandle = plot_jzs_bayesian_hierarchy(outFigFolder, procDataFolder)
%PLOT_JZS_BAYESIAN_HIERARCHY Minimal hierarchical graphical model and inference
% summary for the two-sided one-sample JZS Bayes Factor (Rouder et al., 2009)
% testing objective prime awareness (PAS = 1) against chance (50%) across both
% Incongruent and Congruent trials, split by response modality.
%
% Saves high-resolution .png (300 DPI), .pdf, .svg, and .fig outputs.

    if nargin < 1 || isempty(outFigFolder)
        outFigFolder = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'figures');
    end
    if ~exist(outFigFolder, 'dir'), mkdir(outFigFolder); end

    if nargin < 2 || isempty(procDataFolder)
        procDataFolder = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'processed_data', 'nonStandardized_TrajNorm');
    end

    % ---------------------------------------------------------------------
    % Load empirical PAS = 1 2AFC recognition accuracy (%) across N = 30
    % ---------------------------------------------------------------------
    good_subs_file = fullfile(procDataFolder, 'good_subs_day2_target_x_to_subs_47_49-85_87-90.mat');
    avg_each_file  = fullfile(procDataFolder, 'avg_each_day2_target_x_to_subs_47_49-85_87-90.mat');

    if ~exist(good_subs_file, 'file') || ~exist(avg_each_file, 'file')
        error('plot_jzs_bayesian_hierarchy:MissingData', ...
            'Could not find processed awareness files in %s', procDataFolder);
    end

    gs   = load(good_subs_file);
    subs = gs.good_subs;
    ae   = load(avg_each_file);

    data_incon_reach = ae.reach_avg_each.fc_prime.incon(subs) * 100;
    data_incon_kb    = ae.keyboard_avg_each.fc_prime.incon(subs) * 100;
    data_con_reach   = ae.reach_avg_each.fc_prime.con(subs) * 100;
    data_con_kb      = ae.keyboard_avg_each.fc_prime.con(subs) * 100;

    r = sqrt(2) / 2;
    [~, ~, det_ir] = compute_jzs_bayes_factor(data_incon_reach, 50, r);
    [~, ~, det_ik] = compute_jzs_bayes_factor(data_incon_kb,    50, r);
    [~, ~, det_cr] = compute_jzs_bayes_factor(data_con_reach,   50, r);
    [~, ~, det_ck] = compute_jzs_bayes_factor(data_con_kb,      50, r);

    N  = det_ir.data.N;
    df = det_ir.data.df;

    % ---------------------------------------------------------------------
    % Initialize clean minimalist figure
    % ---------------------------------------------------------------------
    figHandle = figure('Name', 'JZS Bayesian Model Hierarchy', ...
        'Color', [1 1 1], 'Position', [60 60 1380 860], 'MenuBar', 'figure');

    annotation(figHandle, 'textbox', [0.05, 0.935, 0.90, 0.045], ...
        'String', 'JZS Hierarchical Bayesian Model for Objective Prime Awareness (PAS = 1)', ...
        'FontSize', 14.5, 'FontWeight', 'bold', 'FontName', 'Arial', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'EdgeColor', 'none', 'Color', [0.12 0.12 0.12]);

    % Palette
    col_hyper    = [0.46 0.24 0.62]; % Purple: g
    col_nuisance = [0.82 0.44 0.12]; % Amber: sigma^2
    col_effect   = [0.14 0.54 0.30]; % Green: delta (H1)
    col_mean     = [0.15 0.45 0.74]; % Blue: mu (H1)
    col_data     = [0.76 0.20 0.20]; % Red: y_i
    col_null     = [0.28 0.28 0.28]; % Dark gray: H0
    col_arrow    = [0.35 0.35 0.35];

    % Node positions (generous spacing so arrows never touch labels)
    w       = 0.22;
    h       = 0.185;
    x_left  = 0.075;
    x_mid   = 0.390;
    x_right = 0.705;
    y_top   = 0.675;
    y_mid   = 0.485;
    y_low   = 0.305;

    % =====================================================================
    % NODE 1: Latent Variance Factor g
    % =====================================================================
    ax1 = axes('Parent', figHandle, 'Position', [x_left, y_top, w, h]);
    g_vals = linspace(0.005, 3.2, 400);
    p_g = (2 * pi)^(-0.5) .* g_vals.^(-1.5) .* exp(-1 ./ (2 .* g_vals));
    fill(ax1, [g_vals, fliplr(g_vals)], [p_g, zeros(size(p_g))], col_hyper, ...
        'FaceAlpha', 0.16, 'EdgeColor', 'none');
    hold(ax1, 'on');
    plot(ax1, g_vals, p_g, '-', 'Color', col_hyper, 'LineWidth', 2.1);
    style_minimal_dist_axes(ax1, [0 3.2], [0 0.52], [0 1 2 3], {'0', '1', '2', '3'}, 'g', 'Density');
    title(ax1, {'\bfLatent Variance Factor', '\rmg \sim Inv-Gamma(1/2, 1/2)'}, ...
        'FontSize', 10, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);

    % =====================================================================
    % NODE 2: Population Variance \sigma^2
    % =====================================================================
    ax2 = axes('Parent', figHandle, 'Position', [x_right, y_top, w, h]);
    sig2_vals = linspace(0.001, 4.0, 800);
    p_sig2 = 1 ./ sig2_vals;
    fill(ax2, [sig2_vals, fliplr(sig2_vals)], [min(p_sig2, 4.8), zeros(size(p_sig2))], col_nuisance, ...
        'FaceAlpha', 0.16, 'EdgeColor', 'none');
    hold(ax2, 'on');
    p_sig2_line = p_sig2;
    p_sig2_line(p_sig2_line > 4.82) = NaN;
    plot(ax2, sig2_vals, p_sig2_line, '-', 'Color', col_nuisance, 'LineWidth', 2.1);
    style_minimal_dist_axes(ax2, [0 4.0], [0 4.8], [0 1 2 3 4], {'0', '1', '2', '3', '4'}, '\sigma^2', 'Density');
    title(ax2, {'\bfPopulation Variance', '\rmp(\sigma^2) \propto 1/\sigma^2'}, ...
        'FontSize', 10, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);

    % =====================================================================
    % NODE 3: Standardized Effect Size \delta
    % =====================================================================
    ax3 = axes('Parent', figHandle, 'Position', [x_left, y_low, w, h]);
    delta_vals = linspace(-2.5, 2.5, 400);
    p_cauchy = 1 ./ (pi * r * (1 + (delta_vals ./ r).^2));
    fill(ax3, [delta_vals, fliplr(delta_vals)], [p_cauchy, zeros(size(p_cauchy))], col_effect, ...
        'FaceAlpha', 0.16, 'EdgeColor', 'none');
    hold(ax3, 'on');
    plot(ax3, delta_vals, p_cauchy, '-', 'Color', col_effect, 'LineWidth', 2.1);
    plot(ax3, [0 0], [0 0.60], '-', 'Color', col_null, 'LineWidth', 2.2);
    plot(ax3, 0, 0.60, 'o', 'Color', col_null, 'MarkerFaceColor', col_null, 'MarkerSize', 5);
    style_minimal_dist_axes(ax3, [-2.5 2.5], [0 0.68], [-2 -1 0 1 2], {'-2', '-1', '0', '1', '2'}, '\delta', 'Density');
    title(ax3, {'\bfStandardized Effect Size', ...
        '\rm\color[rgb]{0.28,0.28,0.28}H_0: \delta = 0   \color[rgb]{0.55,0.55,0.55}|   \color[rgb]{0.14,0.54,0.30}H_1: \delta \sim Cauchy(0, r)'}, ...
        'FontSize', 10, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);

    % =====================================================================
    % NODE 4: Population Mean \mu
    % =====================================================================
    ax4 = axes('Parent', figHandle, 'Position', [x_mid, y_mid, w, h]);
    mu_vals = linspace(35, 65, 400);
    p_mu = normpdf(mu_vals, 50, 3.2);
    fill(ax4, [mu_vals, fliplr(mu_vals)], [p_mu, zeros(size(p_mu))], col_mean, ...
        'FaceAlpha', 0.16, 'EdgeColor', 'none');
    hold(ax4, 'on');
    plot(ax4, mu_vals, p_mu, '-', 'Color', col_mean, 'LineWidth', 2.1);
    plot(ax4, [50 50], [0 max(p_mu)*1.12], '--', 'Color', col_null, 'LineWidth', 1.8);
    style_minimal_dist_axes(ax4, [35 65], [0 max(p_mu)*1.18], [35 50 65], {'35', '50', '65'}, '\mu (% Correct)', 'Density');
    title(ax4, {'\bfPopulation Mean', ...
        '\rm\color[rgb]{0.28,0.28,0.28}H_0: \mu = 50   \color[rgb]{0.55,0.55,0.55}|   \color[rgb]{0.15,0.45,0.74}H_1: \mu | \sigma^2, g \sim Normal(50, g r^2 \sigma^2)'}, ...
        'FontSize', 10, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);

    % =====================================================================
    % NODE 5: Observed Data y_i
    % =====================================================================
    ax5 = axes('Parent', figHandle, 'Position', [x_right, y_low, w, h]);
    y_vals = linspace(0, 100, 400);
    p_y = normpdf(y_vals, 50, 13);
    fill(ax5, [y_vals, fliplr(y_vals)], [p_y, zeros(size(p_y))], col_data, ...
        'FaceAlpha', 0.16, 'EdgeColor', 'none');
    hold(ax5, 'on');
    plot(ax5, y_vals, p_y, '-', 'Color', col_data, 'LineWidth', 2.1);
    style_minimal_dist_axes(ax5, [0 100], [0 max(p_y)*1.15], [0 50 100], {'0', '50', '100'}, 'y_i (% Correct)', 'Density');
    title(ax5, {'\bfObserved Data', '\rmy_i | \mu, \sigma^2 \sim Normal(\mu, \sigma^2)'}, ...
        'FontSize', 10, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);

    % =====================================================================
    % MINIMAL UNLABELED DIRECTED ARROWS (DAG + Inference Link)
    % =====================================================================
    % g -> delta (left column, vertical)
    annotation(figHandle, 'arrow', [x_left + w/2, x_left + w/2], [y_top - 0.052, y_low + h + 0.058], ...
        'Color', col_arrow, 'LineWidth', 1.8, 'HeadWidth', 8, 'HeadLength', 8);

    % sigma^2 -> y_i (right column, vertical)
    annotation(figHandle, 'arrow', [x_right + w/2, x_right + w/2], [y_top - 0.052, y_low + h + 0.058], ...
        'Color', col_arrow, 'LineWidth', 1.8, 'HeadWidth', 8, 'HeadLength', 8);

    % delta -> mu (diagonal up-right, clearing mu's Y-label)
    annotation(figHandle, 'arrow', [x_left + w + 0.012, x_mid - 0.032], [y_low + 0.62*h, y_mid + 0.35*h], ...
        'Color', col_arrow, 'LineWidth', 1.8, 'HeadWidth', 8, 'HeadLength', 8);

    % sigma^2 -> mu (diagonal down-left, clearing sigma^2's Y-label)
    annotation(figHandle, 'arrow', [x_right - 0.032, x_mid + w + 0.012], [y_top + 0.35*h, y_mid + 0.68*h], ...
        'Color', col_arrow, 'LineWidth', 1.8, 'HeadWidth', 8, 'HeadLength', 8);

    % mu -> y_i (diagonal down-right, clearing y_i's Y-label)
    annotation(figHandle, 'arrow', [x_mid + w + 0.012, x_right - 0.032], [y_mid + 0.32*h, y_low + 0.65*h], ...
        'Color', col_arrow, 'LineWidth', 1.8, 'HeadWidth', 8, 'HeadLength', 8);

    % y_i -> Bayes Factor Inference box (vertical down)
    annotation(figHandle, 'arrow', [x_right + w/2, x_right + w/2], [y_low - 0.055, 0.205], ...
        'Color', col_arrow, 'LineWidth', 1.8, 'HeadWidth', 8, 'HeadLength', 8);

    % =====================================================================
    % BOTTOM PANEL: Inference Process (Formula + Congruent & Incongruent)
    % =====================================================================
    ax_bot = axes('Parent', figHandle, 'Position', [x_left, 0.030, (x_right + w) - x_left, 0.168]);
    set(ax_bot, 'Color', [0.985 0.985 0.985], 'Box', 'on', 'XTick', [], 'YTick', [], ...
        'LineWidth', 1.1, 'XColor', [0.78 0.78 0.78], 'YColor', [0.78 0.78 0.78]);
    hold(ax_bot, 'on');
    xlim(ax_bot, [0 1]); ylim(ax_bot, [0 1]);

    % Left side: Minimal marginal likelihood equations
    text(ax_bot, 0.020, 0.84, sprintf('\\bfBayes Factor Inference  (r = \\surd2 / 2 \\approx 0.707,  N = %d,  \\nu = %d)', N, df), ...
        'FontSize', 10, 'FontName', 'Arial', 'Color', [0.12 0.12 0.12]);
    text(ax_bot, 0.020, 0.61, 't = (M - 50) / (SD / \surdN),      m_0(t) = (1 + t^2/\nu)^{-(\nu+1)/2}', ...
        'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.20 0.20 0.20]);
    text(ax_bot, 0.020, 0.36, 'm_1(t) = \int_0^\infty (1 + N g r^2)^{-1/2} [1 + t^2 / (\nu(1 + N g r^2))]^{-(\nu+1)/2} p(g) dg', ...
        'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.20 0.20 0.20]);
    text(ax_bot, 0.020, 0.13, '\bfBF_{01} = m_0(t) / m_1(t)', ...
        'FontSize', 10, 'FontName', 'Arial', 'Color', [0.12 0.12 0.12]);

    % Vertical separator
    plot(ax_bot, [0.465 0.465], [0.08 0.92], '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 1.0);

    % Right side: Clean 4-row inference table (Incongruent & Congruent x Modality)
    xc_cond = 0.485;
    xc_mod  = 0.595;
    xc_msd  = 0.720;
    xc_t    = 0.815;
    xc_m0   = 0.875;
    xc_m1   = 0.928;
    xc_bf   = 0.978;

    y_hdr = 0.85;
    text(ax_bot, xc_cond, y_hdr, '\bfTrials',      'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);
    text(ax_bot, xc_mod,  y_hdr, '\bfModality',    'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);
    text(ax_bot, xc_msd,  y_hdr, '\bfM \pm SD (%)','FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15], 'HorizontalAlignment', 'center');
    text(ax_bot, xc_t,    y_hdr, sprintf('\\bft(%d)', df), 'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15], 'HorizontalAlignment', 'center');
    text(ax_bot, xc_m0,   y_hdr, '\bfm_0',         'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15], 'HorizontalAlignment', 'center');
    text(ax_bot, xc_m1,   y_hdr, '\bfm_1',         'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15], 'HorizontalAlignment', 'center');
    text(ax_bot, xc_bf,   y_hdr, '\bfBF_{01}',     'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15], 'HorizontalAlignment', 'right');

    plot(ax_bot, [0.482 0.985], [0.74 0.74], '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.9);

    rows = {
        'Incongruent', 'Reaching',  det_ir, 0.61;
        'Incongruent', 'Key Press', det_ik, 0.44;
        'Congruent',   'Reaching',  det_cr, 0.25;
        'Congruent',   'Key Press', det_ck, 0.09
    };

    plot(ax_bot, [0.482 0.985], [0.35 0.35], ':', 'Color', [0.82 0.82 0.82], 'LineWidth', 0.8);

    for iR = 1:size(rows, 1)
        cond_lbl = rows{iR, 1};
        mod_lbl  = rows{iR, 2};
        d        = rows{iR, 3};
        yy       = rows{iR, 4};

        text(ax_bot, xc_cond, yy, cond_lbl, 'FontSize', 9.2, 'FontName', 'Arial', 'Color', [0.18 0.18 0.18]);
        text(ax_bot, xc_mod,  yy, mod_lbl,  'FontSize', 9.2, 'FontName', 'Arial', 'Color', [0.18 0.18 0.18]);
        text(ax_bot, xc_msd,  yy, sprintf('%.1f \\pm %.1f', d.data.mean, d.data.std), ...
            'FontSize', 9.2, 'FontName', 'Arial', 'Color', [0.18 0.18 0.18], 'HorizontalAlignment', 'center');
        text(ax_bot, xc_t,    yy, sprintf('%.2f', d.data.t), ...
            'FontSize', 9.2, 'FontName', 'Arial', 'Color', [0.18 0.18 0.18], 'HorizontalAlignment', 'center');
        text(ax_bot, xc_m0,   yy, sprintf('%.3f', d.sub_variables.m0), ...
            'FontSize', 9.2, 'FontName', 'Arial', 'Color', [0.18 0.18 0.18], 'HorizontalAlignment', 'center');
        text(ax_bot, xc_m1,   yy, sprintf('%.3f', d.sub_variables.m1), ...
            'FontSize', 9.2, 'FontName', 'Arial', 'Color', [0.18 0.18 0.18], 'HorizontalAlignment', 'center');
        text(ax_bot, xc_bf,   yy, sprintf('\\bf%.2f', d.sub_variables.bf01), ...
            'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.10 0.42 0.20], 'HorizontalAlignment', 'right');
    end

    % ---------------------------------------------------------------------
    % Export high-resolution outputs (.png, .pdf, .svg, .fig)
    % ---------------------------------------------------------------------
    out_png = fullfile(outFigFolder, 'Fig_JZS_Bayesian_Model_Hierarchy.png');
    out_pdf = fullfile(outFigFolder, 'Fig_JZS_Bayesian_Model_Hierarchy.pdf');
    out_svg = fullfile(outFigFolder, 'Fig_JZS_Bayesian_Model_Hierarchy.svg');
    out_fig = fullfile(outFigFolder, 'Fig_JZS_Bayesian_Model_Hierarchy.fig');

    exportgraphics(figHandle, out_png, 'Resolution', 300);
    exportgraphics(figHandle, out_pdf, 'ContentType', 'vector');
    try
        exportgraphics(figHandle, out_svg, 'ContentType', 'vector');
    catch
    end
    savefig(figHandle, out_fig);
    fprintf('Saved JZS Bayesian Model Hierarchy figure to:\n  %s\n  %s\n  %s\n', out_png, out_pdf, out_fig);
end

function style_minimal_dist_axes(ax, x_lims, y_lims, x_ticks, x_tick_labels, x_lbl, y_lbl)
    set(ax, ...
        'Color', [1 1 1], ...
        'Box', 'off', ...
        'LineWidth', 1.1, ...
        'FontSize', 9.5, ...
        'FontName', 'Arial', ...
        'TickDir', 'out', ...
        'XLim', x_lims, ...
        'YLim', y_lims, ...
        'XTick', x_ticks, ...
        'XTickLabel', x_tick_labels, ...
        'YTick', [], ...
        'XColor', [0.22 0.22 0.22], ...
        'YColor', [0.22 0.22 0.22]);
    grid(ax, 'off');
    xlabel(ax, x_lbl, 'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);
    ylabel(ax, y_lbl, 'FontSize', 9.5, 'FontName', 'Arial', 'Color', [0.15 0.15 0.15]);
end
