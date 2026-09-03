function plot_and_save_qq_plots(rawAggData, good_subs, baseFigsFldr)
% PLOT_AND_SAVE_QQ_PLOTS
% Generates individual and composite QQ-plots of model residuals (Congruent - Incongruent)
% with 95% confidence envelopes matching the R / Supplementary Figure 2 convention.

    if nargin < 3 || isempty(baseFigsFldr)
        baseFigsFldr = '../figures';
    end

    flavors = fieldnames(rawAggData);
    dv_names = {'kb_rt', 'ra', 'tot_dist', 'auc', 'mad', 'react', 'mt', 'com', 'rt'};
    dv_labels = {'Keyboard RT', 'Reach Area', 'Total Distance', 'AUC', 'MAD', 'Reaching Onset', 'Reaching Duration', 'COM', 'Reach RT'};

    for iFlav = 1:length(flavors)
        flav = flavors{iFlav};
        flav_data = rawAggData.(flav);

        qq_fldr = fullfile(baseFigsFldr, flav, 'QQ_plots');
        if ~exist(qq_fldr, 'dir'), mkdir(qq_fldr); end

        % Master 3x3 composite figure
        f_comp = figure('Name', sprintf('QQ Plots - %s', flav), 'Position', [50, 50, 1200, 1000], 'Visible', 'off', 'Color', 'w');

        for iDV = 1:length(dv_names)
            dv = dv_names{iDV};
            label = dv_labels{iDV};

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

            if isempty(con_vec) || isempty(incon_vec)
                continue;
            end

            valid_idx = ~isnan(con_vec) & ~isnan(incon_vec);
            % Congruent - Incongruent convention matching R lm(differ ~ 1)
            diff_vec = con_vec(valid_idx) - incon_vec(valid_idx);
            res_vec = diff_vec - mean(diff_vec); % Residuals from intercept model
            n = length(res_vec);

            if n < 5
                continue;
            end

            % --- Generate Individual QQ-Plot ---
            f_single = figure('Name', sprintf('QQ - %s', label), 'Position', [100, 100, 550, 450], 'Visible', 'off', 'Color', 'w');
            ax_single = gca;
            render_single_qq_r_style(ax_single, res_vec, label);

            % Save individual figure
            saveas(f_single, fullfile(qq_fldr, sprintf('%s_qqplot.fig', dv)));
            saveas(f_single, fullfile(qq_fldr, sprintf('%s_qqplot.png', dv)));
            close(f_single);

            % --- Render to 3x3 Composite Figure ---
            figure(f_comp);
            ax_comp = subplot(3, 3, iDV);
            render_single_qq_r_style(ax_comp, res_vec, label);
        end

        % Save composite figure
        figure(f_comp);
        sgtitle(sprintf('QQ-Plots of Residuals (%s)', strrep(flav, '_', '\_')), 'FontWeight', 'bold', 'FontSize', 14);
        saveas(f_comp, fullfile(qq_fldr, 'all_variables_qq_plots.fig'));
        saveas(f_comp, fullfile(qq_fldr, 'all_variables_qq_plots.png'));
        close(f_comp);
    end
    fprintf('Successfully generated and saved all R-convention QQ-plots in QQ_plots subfolders.\n');
end

function render_single_qq_r_style(ax, res_vec, label)
    n = length(res_vec);
    y = sort(res_vec(:));
    
    % Sample stats
    mu_y = mean(y); % 0 by construction
    sigma_y = std(y);

    % Theoretical quantiles scaled to the sample SD (matching qqplotr / ggplot2)
    p_vals = ((1:n)' - 0.5) / n;
    z_theo = norminv(p_vals);
    x_theo = mu_y + sigma_y * z_theo;

    % Theoretical reference line through origin with slope = 1 for scaled theoretical quantiles
    line_y = x_theo;

    % Pointwise 95% Confidence Band for sample quantiles
    % SE of order statistic: sigma * sqrt(p*(1-p)/n) / phi(z_p)
    phi_z = normpdf(z_theo);
    se_band = (sigma_y ./ phi_z) .* sqrt(p_vals .* (1 - p_vals) / n);
    upper_band = line_y + 1.96 * se_band;
    lower_band = line_y - 1.96 * se_band;

    hold(ax, 'on');

    % 1. Shaded Confidence Envelope
    fill_x = [x_theo; flipud(x_theo)];
    fill_y = [upper_band; flipud(lower_band)];
    fill(ax, fill_x, fill_y, [0.75, 0.75, 0.75], 'EdgeColor', 'none', 'FaceAlpha', 0.6);

    % 2. Reference Line
    plot(ax, x_theo, line_y, 'k-', 'LineWidth', 1.5);

    % 3. Observed Quantiles (Points)
    scatter(ax, x_theo, y, 35, 'k', 'filled');

    hold(ax, 'off');

    % Axis formatting matching R's theme_classic
    box(ax, 'off');
    set(ax, 'TickDir', 'out', 'LineWidth', 1, 'FontSize', 10);
    xlabel(ax, 'Theoretical Quantiles', 'FontSize', 10);
    ylabel(ax, 'Sample Quantiles', 'FontSize', 10);
    title(ax, label, 'FontWeight', 'normal', 'FontSize', 12);
end
