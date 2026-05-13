function tir = compute_tir(x_orig, y_std, y_pairs, fs)
% COMPUTE_TIR  Transient Integrity Ratio
%
%   tir = compute_tir(x_orig, y_std, y_pairs, fs)
%
%   Measures how well PAIRS preserves the signal transient relative to
%   standard phase vocoder (Std PV) output.
%
%   Inputs:
%     x_orig  - Original (unshifted) reference signal
%     y_std   - Std PV output
%     y_pairs - PAIRS output
%     fs      - Sample rate in Hz
%
%   Output:
%     tir > 1.0 => PAIRS preserves transient better than Std PV
%     tir < 1.0 => Std PV performs better
%     tir = 1.0 => Equal performance
%
%   Formula:
%     TIR = RMS_err(Std PV) / RMS_err(PAIRS)
%     where RMS_err is computed within ±25 ms of the detected signal peak
%
%   NOTE: TIR is unreliable for soft-attack signals (flute, sustained vocal)
%   where no sharp onset falls within the ±25 ms window.
%
%   Authors: K. Siva Srinivas et al., Sathyabama IST, April 2026

    x_orig  = x_orig(:);
    y_std   = y_std(:);
    y_pairs = y_pairs(:);

    % Match lengths to x_orig
    L = length(x_orig);
    y_std   = y_std(1 : min(end, L));
    y_pairs = y_pairs(1 : min(end, L));

    % Pad shorter outputs if needed
    if length(y_std)   < L, y_std   = [y_std;   zeros(L - length(y_std),   1)]; end
    if length(y_pairs) < L, y_pairs = [y_pairs; zeros(L - length(y_pairs), 1)]; end

    % Detect transient peak
    [~, peak_idx] = max(abs(x_orig));

    % ±25 ms window
    win_samp = round(0.025 * fs);
    lo = max(1, peak_idx - win_samp);
    hi = min(L, peak_idx + win_samp);
    idx = lo : hi;

    err_std   = rms(y_std(idx)   - x_orig(idx));
    err_pairs = rms(y_pairs(idx) - x_orig(idx));

    tir = err_std / max(err_pairs, 1e-12);

end
