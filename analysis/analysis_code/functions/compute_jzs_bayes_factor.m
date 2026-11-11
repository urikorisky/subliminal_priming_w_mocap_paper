function [bf01, bf10, model_details] = compute_jzs_bayes_factor(sample_data, chance_level, r_scale)
%COMPUTE_JZS_BAYES_FACTOR Two-sided JZS (Jeffreys-Zellner-Siow) Bayes Factor
% for a one-sample t-test against a reference/chance level (Rouder et al., 2009).
%
% Hypotheses:
%   H0: mu = chance_level (Performance is at chance / no awareness)
%   H1: mu ~= chance_level (Performance differs from chance / two-sided Cauchy prior on delta)
%
% =========================================================================
% HIERARCHICAL BAYESIAN MODEL SPECIFICATION & PRIORS
% =========================================================================
% 1. Nuisance Parameter: Population Variance (sigma^2)
%    - Prior: Jeffreys' uninformative scale-invariant prior:
%      p(sigma^2) \propto 1 / sigma^2
%    - Parameters: None (standard improper reference prior, shared under H0 & H1).
%
% 2. Latent Scale-Mixture Variance Factor (g)
%    - Prior: Inverse-Gamma distribution (Zellner & Siow, 1980):
%      g ~ Inverse-Gamma(alpha = 1/2, beta = 1/2)
%    - Prior Density: p(g) = (2 * pi)^(-1/2) * g^(-3/2) * exp(-1 / (2 * g))
%    - Parameters: shape alpha = 0.5, scale beta = 0.5.
%
% 3. Standardized Effect Size: delta = (mu - chance_level) / sigma
%    - Under H0: Point mass at 0:
%      p(delta | H0) = Dirac_delta(delta)  [delta_0 = 0]
%    - Under H1: Cauchy prior centered at 0 with scale r:
%      delta ~ Cauchy(location = 0, scale = r_scale)
%      Hierarchical representation (scale mixture of normals):
%      delta | g ~ Normal(0, g * r_scale^2)
%      Parameters: location = 0, scale r_scale = sqrt(2)/2 approx 0.7071.
%
% 4. Population Mean: mu
%    - Under H0: mu = chance_level (deterministic)
%    - Under H1: mu = chance_level + delta * sigma
%      Conditional on sigma^2 and g:
%      mu | sigma^2, g ~ Normal(chance_level, g * r_scale^2 * sigma^2)
%
% 5. Observed Data: y_i (i = 1, ..., N)
%    - Likelihood: y_i | mu, sigma^2 ~ i.i.d. Normal(mu, sigma^2)
%
% =========================================================================
% FORMULA DECOMPOSITION INTO SUB-VARIABLES (Rouder et al., 2009, Eq. 1)
% =========================================================================
% - Sample statistics:
%     N: sample size
%     df = N - 1: degrees of freedom
%     t = (mean(y) - chance_level) / (std(y) / sqrt(N)): sample t-statistic
%
% - Sub-variable 1: Marginal likelihood under H0:
%     m0 = (1 + t^2 / df)^(-(df + 1) / 2)
%
% - Sub-variable 2: Prior variance of effect size given g:
%     V_delta(g) = g * r_scale^2
%
% - Sub-variable 3: Shrinkage / sample-size penalty factor:
%     S(g) = (1 + N * V_delta(g))^(-1/2)
%
% - Sub-variable 4: Modulated t-statistic term:
%     T(g) = [1 + t^2 / (df * (1 + N * V_delta(g)))]^(-(df + 1) / 2)
%
% - Sub-variable 5: Conditional marginal likelihood under H1 given g:
%     m1_given_g(g) = S(g) * T(g)
%
% - Sub-variable 6: Prior density on g:
%     p_g(g) = (2 * pi)^(-1/2) * g^(-3/2) * exp(-1 / (2 * g))
%
% - Sub-variable 7: Full marginal likelihood under H1 (integrated over g):
%     m1 = \int_0^\infty m1_given_g(g) * p_g(g) dg
%
% - Bayes Factors:
%     BF01 = m0 / m1  (evidence favoring H0 over H1)
%     BF10 = m1 / m0  (evidence favoring H1 over H0)
% =========================================================================

    if nargin < 2 || isempty(chance_level)
        chance_level = 50;
    end
    if nargin < 3 || isempty(r_scale)
        r_scale = sqrt(2) / 2; % 0.7071 (Rouder's default medium prior scale)
    end

    valid_data = sample_data(~isnan(sample_data));
    N = length(valid_data);
    if N < 2
        bf01 = NaN;
        bf10 = NaN;
        model_details = struct();
        return;
    end

    % Sample statistics:
    y_mean = mean(valid_data);
    y_std  = std(valid_data);
    df     = N - 1;
    [~, ~, ~, stats] = ttest(valid_data, chance_level);
    t = stats.tstat;

    % ---------------------------------------------------------------------
    % Sub-variable 1: Marginal likelihood under H0
    % ---------------------------------------------------------------------
    m0 = (1 + t^2 / df)^(-(df + 1) / 2);

    % ---------------------------------------------------------------------
    % Sub-variables for H1 conditional on g
    % ---------------------------------------------------------------------
    % Prior variance on effect size given g:
    V_delta = @(g) g .* (r_scale^2);

    % Shrinkage / sample-size penalty:
    S = @(g) (1 + N .* V_delta(g)).^(-0.5);

    % Modulated t-statistic term:
    T = @(g) (1 + t.^2 ./ (df .* (1 + N .* V_delta(g)))).^(-(df + 1) / 2);

    % Conditional marginal likelihood m1(D | g):
    m1_given_g = @(g) S(g) .* T(g);

    % Prior density on latent scale mixture g ~ Inv-Gamma(1/2, 1/2):
    p_g = @(g) (2 * pi).^(-0.5) .* g.^(-1.5) .* exp(-1 ./ (2 .* g));

    % Integrand for H1 marginal likelihood:
    integrand = @(g) m1_given_g(g) .* p_g(g);

    % ---------------------------------------------------------------------
    % Sub-variable 7: Full marginal likelihood under H1
    % ---------------------------------------------------------------------
    m1 = integral(integrand, 0, Inf);

    % ---------------------------------------------------------------------
    % Final Bayes Factors
    % ---------------------------------------------------------------------
    bf10 = m1 / m0;
    bf01 = m0 / m1;

    % ---------------------------------------------------------------------
    % Structured model details and prior specifications
    % ---------------------------------------------------------------------
    if nargout >= 3
        model_details = struct();
        
        % Data summary:
        model_details.data.N            = N;
        model_details.data.df           = df;
        model_details.data.mean         = y_mean;
        model_details.data.std          = y_std;
        model_details.data.t            = t;
        model_details.data.chance_level = chance_level;

        % Prior distributions and parameters:
        model_details.priors.sigma2.name        = 'Jeffreys improper prior';
        model_details.priors.sigma2.formula     = 'p(sigma^2) \propto 1 / sigma^2';
        model_details.priors.sigma2.parameters  = 'Scale-invariant uninformative';

        model_details.priors.g.name             = 'Inverse-Gamma';
        model_details.priors.g.alpha            = 0.5;
        model_details.priors.g.beta             = 0.5;
        model_details.priors.g.formula          = 'p(g) = (2*pi)^(-0.5) * g^(-1.5) * exp(-1/(2*g))';

        model_details.priors.delta_H0.name      = 'Point mass at zero';
        model_details.priors.delta_H0.delta_0   = 0;

        model_details.priors.delta_H1.name      = 'Cauchy';
        model_details.priors.delta_H1.location  = 0;
        model_details.priors.delta_H1.scale     = r_scale;
        model_details.priors.delta_H1.mixture   = 'delta | g ~ Normal(0, g * r^2)';

        model_details.priors.mu_H1.name         = 'Conditional Normal';
        model_details.priors.mu_H1.mean         = chance_level;
        model_details.priors.mu_H1.variance     = 'g * r^2 * sigma^2';

        % Likelihood:
        model_details.likelihood.name           = 'Normal';
        model_details.likelihood.mean           = 'mu';
        model_details.likelihood.variance       = 'sigma^2';

        % Evaluated formula sub-variables:
        model_details.sub_variables.m0          = m0;
        model_details.sub_variables.m1          = m1;
        model_details.sub_variables.bf01        = bf01;
        model_details.sub_variables.bf10        = bf10;
        model_details.sub_variables.V_delta_func= V_delta;
        model_details.sub_variables.S_func      = S;
        model_details.sub_variables.T_func      = T;
        model_details.sub_variables.m1_given_g  = m1_given_g;
        model_details.sub_variables.p_g_func    = p_g;
    end
end
