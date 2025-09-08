%% ------------------------------------------------------------------------
% Ultrasonic Sweep Live Monitor (Polar Plot)
%
% Description:
%   - Listens to serial data from an Arduino-based ultrasonic scanner.
%   - Expected line format per sweep step:
%       mode, angle, r1, r2, ..., r10, mean
%     where:
%       * mode       : acquisition mode identifier (e.g., 1 = full sweep, 2 = sparse)
%       * angle      : servo angle in degrees [30..150] at 10° increments
%       * r1..r10    : raw single-shot distance readings (meters) at that angle
%       * mean       : pre-computed mean/smoothed value (meters) for that angle
%   - Plots raw readings as colored dots and the mean as a black “x”
%     on a 0–180° polar plot.
%   - After all expected angles for the current mode are received, the figure
%     is refreshed for the next sweep.
%
% Notes:
%   - Distances are in meters and compared against r_max for out-of-range checks.
%   - This script assumes the Arduino already applies calibration where needed.
% -------------------------------------------------------------------------

clear
close all
clc

%% ----------------------------- USER SETTINGS -----------------------------
device = serialport("/dev/cu.usbserial-10",9600);
flush(device,"input");

%% ------------------------------- PARAMETERS ------------------------------
start_angle      = 30;         % sweep start (degrees)
end_angle        = 150;        % sweep end (degrees)
increment_angle  = 10;         % step size (degrees)
angles_deg       = start_angle:increment_angle:end_angle;
N                = numel(angles_deg);
r_max            = 3;          % radial limit for plotting (meters)

%% ------------------------------ FIGURE CONFIG ----------------------------
C  = lines(N);
ax = polaraxes;
hold(ax,'on');
ax.ThetaLim          = [0 180];
ax.ThetaZeroLocation = 'right';
ax.ThetaDir          = 'counterclockwise';
rlim([0 r_max]);

% Marker sizes
sz_read = 70;    % raw reading marker size
sz_mean = 160;   % mean marker size

%% --------------------------- LEGENDS & LABELS ----------------------------
% Create per-angle legend anchors (for raw readings)
hLegRead = gobjects(N,1);
for i = 1:N
    hLegRead(i) = polarscatter(ax, NaN, NaN, sz_read, 'filled', ...
        'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none', ...
        'MarkerFaceColor', C(i,:), ...
        'DisplayName', sprintf('%d°', angles_deg(i)));
end

% Legend anchor for the mean marker
hLegMean = polarscatter(ax, NaN, NaN, sz_mean, 'x', ...
    'MarkerEdgeColor','k', 'LineWidth', 1.2, ...
    'DisplayName','Mean');

legend(ax, [hLegRead; hLegMean], ...
    'Location','southoutside', 'NumColumns', 4, 'AutoUpdate','off');

title(ax,'Ultrasonic Sweep Monitor');
ax.ThetaAxis.Label.String = 'Angle (deg)';
ax.RAxis.Label.String     = 'Range (m)';

%% --------------------------- DATA BUFFERS/STATE --------------------------
data = NaN(N,11);     % per-angle buffer: [r1..r10 mean]
got  = false(1,N);    % flags for which angles have arrived in this sweep

%% --------------------------------- MAIN LOOP -----------------------------
while true

    % -------- Parse one serial line --------
    s    = readline(device);                         % raw text line
    nums = str2double(split(strtrim(s),','))';       % numeric row vector

    % Guard against malformed lines
    if numel(nums) < 13
        % Skip if the line doesn't have the expected fields
        continue
    end

    mode = nums(1);                                  % acquisition mode (int)
    deg  = nums(2);                                  % angle (degrees)
    vals = nums(3:13);                               % [r1..r10 mean] (meters)

    % Map angle to index in angles_deg
    idx = angleToIndex(deg, start_angle, increment_angle);
    if idx < 1 || idx > N
        % Skip if angle is out of configured sweep bounds
        continue
    end

    % Update buffers
    data(idx,:) = vals;
    th    = deg2rad(angles_deg(idx));
    reads = vals(1:10);
    mu    = vals(11);

    fprintf("Current mode: MODE %d\n", mode);

    % -------- Basic validity check & warning --------
    % Shows a single (non-stacking) warning dialog if any value is NaN or > r_max
    for k = 1:11
        if isnan(vals(k)) || vals(k) > r_max
            delete(findall(0,'Type','figure','Tag','Msgbox')); % prevent stacking dialogs
            warndlg('Invalid reading detected (NaN or out of range).', 'Sensor Warning');
            break
        end
    end

    % -------- Plot raw and mean points at this angle --------
    polarscatter(ax, repmat(th,1,10), reads, sz_read, repmat(C(idx,:),10,1), ...
        'filled', 'MarkerFaceAlpha', 0.75, 'MarkerEdgeColor', 'none');
    polarscatter(ax, th, mu, sz_mean, 'x', 'MarkerEdgeColor','k', 'LineWidth', 1.2);

    got(idx) = true;

    % -------- If sweep complete for the current mode, reset for next pass --------
    % MODE 1: full sweep (all angles)
    % MODE 2: sparse sweep (indices 1,3,5,7,9,11)
    if (mode == 1 && all(got)) || (mode == 2 && all(got([1,3,5,7,9,11])))
        drawnow;
        pause(0.5);  % brief pause for visual clarity

        % Reset buffers/flags
        data(:) = NaN;
        got(:)  = false;

        % Keep only legend anchors; delete previously plotted points
        to_keep = [hLegRead(:); hLegMean];
        kids    = allchild(ax);
        delete(setdiff(kids, to_keep));

        % Re-assert radial limit (in case axes auto-scaled)
        rlim(ax, [0 r_max]);
    end

end

%% ------------------------------- HELPERS ---------------------------------
function idx = angleToIndex(angle, startAngle, incrementAngle)
    % Convert an absolute angle to a 1-based index into the configured angle vector.
    % Example: start=30, step=10 -> angle=30 -> idx=1, angle=40 -> idx=2, ...
    idx = int32((angle - startAngle) ./ incrementAngle) + 1;
end
