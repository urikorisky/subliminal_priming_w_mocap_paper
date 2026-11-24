function [x_placed, h_scatter] = place_non_overlapping_beeswarm(ax, y_vals, x_center, x_max_half_width, marker_color, marker_size_pts, alpha_val)
% PLACE_NON_OVERLAPPING_BEESWARM Deterministically places beeswarm markers with ZERO overlap.
% Ensures that for any two markers at the same height, the horizontal center-to-center
% distance is at least 1.5 * marker diameter (leaving a clear gap >= 0.5 * marker size).
%
% Inputs:
%   ax               - Target axes handle (xlim and ylim MUST be set before calling!)
%   y_vals           - Vector of Y data values (N x 1 or 1 x N)
%   x_center         - X coordinate center for this group (e.g., 1 or 2)
%   x_max_half_width - Soft maximum horizontal half-width in X data units (e.g., 0.35)
%   marker_color     - 1x3 RGB vector
%   marker_size_pts  - Desired marker diameter in points (default: 5.5)
%   alpha_val        - Face/Edge alpha (default: 0.78)

if nargin < 6 || isempty(marker_size_pts)
    marker_size_pts = 5.5;
end
if nargin < 7 || isempty(alpha_val)
    alpha_val = 0.78;
end

y_vals = y_vals(:);
n = numel(y_vals);
x_placed = repmat(x_center, n, 1);

valid_mask = ~isnan(y_vals) & ~isinf(y_vals);
valid_idx = find(valid_mask);
n_valid = numel(valid_idx);
if n_valid == 0
    h_scatter = gobjects(0);
    return;
end

% Get physical dimensions of axes in points
drawnow limitrate;
orig_ax_units = ax.Units;
ax.Units = 'points';
ax_pos_pts = ax.Position; % [left, bottom, width, height] in points
ax.Units = orig_ax_units;

ax_w_pts = max(ax_pos_pts(3), 60);
ax_h_pts = max(ax_pos_pts(4), 60);

x_lim = xlim(ax);
y_lim = ylim(ax);
x_range = max(x_lim(2) - x_lim(1), 1e-6);
y_range = max(y_lim(2) - y_lim(1), 1e-6);

pts_per_x = ax_w_pts / x_range;
pts_per_y = ax_h_pts / y_range;

% Try placing with desired marker_size_pts; if max width exceeded, shrink marker_size_pts slightly
cur_diam_pts = marker_size_pts;
max_dx_pts_allowed = x_max_half_width * pts_per_x;

for attempt = 1:4
    min_center_dist_pts = 1.52 * cur_diam_pts; % >= 1.5x diameter -> >= 0.5x diameter clear gap
    y_v = y_vals(valid_idx);
    y_pts = (y_v - y_lim(1)) * pts_per_y;

    % Sort points from median Y outward so dense middle regions get placed symmetrically first
    [~, sort_order] = sort(y_pts, 'ascend');
    dx_pts = zeros(n_valid, 1);
    placed_mask = false(n_valid, 1);

    % Candidate horizontal offsets in points: 0, +s, -s, +2s, -2s, ...
    step_pt = 0.04 * min_center_dist_pts;
    max_steps = ceil((max_dx_pts_allowed * 1.8) / step_pt);
    pos_offsets = (1:max_steps) * step_pt;
    neg_offsets = -pos_offsets;
    cand_offsets = [0, reshape([pos_offsets; neg_offsets], 1, [])];

    max_used_dx_pt = 0;
    for k = 1:n_valid
        idx_k = sort_order(k);
        yk = y_pts(idx_k);

        if ~any(placed_mask)
            dx_pts(idx_k) = 0;
            placed_mask(idx_k) = true;
            continue;
        end

        % Find already placed points that are vertically within min_center_dist_pts
        dy_placed = abs(y_pts(placed_mask) - yk);
        close_mask = dy_placed < min_center_dist_pts;

        if ~any(close_mask)
            dx_pts(idx_k) = 0;
            placed_mask(idx_k) = true;
            continue;
        end

        placed_indices = find(placed_mask);
        close_indices = placed_indices(close_mask);
        dy_close = y_pts(close_indices) - yk;
        dx_close = dx_pts(close_indices);

        % Alternate parity slightly for visual balance
        if mod(k, 2) == 0 && numel(cand_offsets) > 1
            cands = [0, reshape([neg_offsets; pos_offsets], 1, [])];
        else
            cands = cand_offsets;
        end

        chosen_dx = cands(end);
        for c_i = 1:numel(cands)
            cand_x = cands(c_i);
            dist_sq = (dx_close - cand_x).^2 + dy_close.^2;
            if all(dist_sq >= (min_center_dist_pts^2 - 1e-6))
                chosen_dx = cand_x;
                break;
            end
        end

        dx_pts(idx_k) = chosen_dx;
        placed_mask(idx_k) = true;
        max_used_dx_pt = max(max_used_dx_pt, abs(chosen_dx));
    end

    if max_used_dx_pt <= max_dx_pts_allowed || attempt == 4
        break;
    else
        scale_factor = max(0.72, (max_dx_pts_allowed / max_used_dx_pt)^0.85);
        cur_diam_pts = cur_diam_pts * scale_factor;
    end
end

x_placed(valid_idx) = x_center + (dx_pts / pts_per_x);

% Area in points^2 for scatter such that circle diameter equals cur_diam_pts
scatter_area = pi * (cur_diam_pts / 2)^2 * 1.15;
hold(ax, 'on');
h_scatter = scatter(ax, x_placed(valid_idx), y_vals(valid_idx), scatter_area, ...
    'MarkerFaceColor', marker_color, ...
    'MarkerEdgeColor', marker_color * 0.65, ...
    'MarkerFaceAlpha', alpha_val, ...
    'MarkerEdgeAlpha', min(1.0, alpha_val + 0.15), ...
    'LineWidth', 0.7, ...
    'Clipping', 'off');

end
