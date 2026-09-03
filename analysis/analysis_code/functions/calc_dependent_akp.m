function [dval, ci, boot_dist] = calc_dependent_akp(x, y, tr, nboot, seed)
% CALC_DEPENDENT_AKP
% Computes the robust Algina-Keselman-Penfield (AKP) effect size for paired /
% dependent samples matching WRS2's D.akp.effect / dep.effect (Mair & Wilcox, 2020).
%
% Usage:
%   dval = calc_dependent_akp(incon, con)
%   dval = calc_dependent_akp(diff_scores)
%   [dval, ci, boot_dist] = calc_dependent_akp(incon, con, 0.2, 2000, 42)
%
% Under normality, the scaling factor c = 0.6418 ensures that:
%   dval = Cohen's dz

    if nargin < 3 || isempty(tr)
        tr = 0.20;
    end
    if nargin < 4 || isempty(nboot)
        nboot = 0; % Do not bootstrap by default unless requested
    end
    if nargin < 5 || isempty(seed)
        seed = 42;
    end

    if nargin >= 2 && ~isempty(y)
        d = x(:) - y(:);
    else
        d = x(:);
    end

    d = d(~isnan(d));
    n = length(d);

    if n < 5
        dval = NaN; ci = [NaN, NaN]; boot_dist = [];
        return;
    end

    % 1. Scaling Constant c (Algina, Keselman & Penfield, 2005)
    if tr > 0
        z_tr = norminv(1 - tr);
        phi_z = normpdf(z_tr);
        cterm = sqrt((erf(z_tr / sqrt(2)) - 2 * z_tr * phi_z) + 2 * (z_tr^2) * tr);
    else
        cterm = 1.0;
    end

    % 2. Dependent AKP Point Estimate
    dval = compute_single_dakp(d, tr, cterm);

    % 3. Optional Bootstrap Confidence Interval
    if nboot > 0
        rng(seed);
        boot_dist = zeros(nboot, 1);
        for b = 1:nboot
            b_idx = randi(n, [n, 1]);
            b_d = d(b_idx);
            boot_dist(b) = compute_single_dakp(b_d, tr, cterm);
        end
        ci = [prctile(boot_dist, 2.5), prctile(boot_dist, 97.5)];
    else
        ci = [NaN, NaN];
        boot_dist = [];
    end
end

function dval = compute_single_dakp(d, tr, cterm)
    n = length(d);
    g = floor(tr * n);
    sort_d = sort(d);
    
    % Winsorize the difference scores
    win_d = d;
    win_d(win_d <= sort_d(g + 1)) = sort_d(g + 1);
    win_d(win_d >= sort_d(end - g)) = sort_d(end - g);
    
    s_win = std(win_d);
    tmean_d = trimmean(d, 2 * tr * 100);
    
    if s_win > 0
        dval = cterm * tmean_d / s_win;
    else
        dval = NaN;
    end
end
