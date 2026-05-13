function dcoh = compute_phase_coherence(y_pairs, y_std, N, H)
% COMPUTE_PHASE_COHERENCE  Inter-frame phase coherence gain (Δcoh)
%
%   dcoh = compute_phase_coherence(y_pairs, y_std)
%   dcoh = compute_phase_coherence(y_pairs, y_std, N, H)
%
%   Inputs:
%     y_pairs - PAIRS output signal
%     y_std   - Std PV output signal
%     N       - FFT size (default: 2048)
%     H       - Hop size (default: 512)
%
%   Output:
%     dcoh  - Inter-frame phase coherence gain (PAIRS minus Std PV)
%             dcoh > 0  => PAIRS has more stable inter-frame phase progression
%             dcoh < 0  => Std PV is more phase-coherent
%
%   Formula:
%     coherence per frame = |E[exp(j * delta_phi)]| across frequency bins
%     delta_phi = inter-frame phase difference at each bin
%     Dcoh = mean_coh(PAIRS) - mean_coh(Std PV)
%
%   Authors: K. Siva Srinivas et al., Sathyabama IST, April 2026

    if nargin < 3, N = 2048; end
    if nargin < 4, H = 512;  end

    dcoh = mean_coherence(y_pairs, N, H) - mean_coherence(y_std, N, H);

end

% -------------------------------------------------------------------------
function mc = mean_coherence(sig, N, H)
% Compute mean inter-frame phase coherence for a signal.

    sig = sig(:);
    win = hann(N, 'periodic');

    % Pad
    sig = [zeros(N/2, 1); sig; zeros(N, 1)];
    num_frames = floor((length(sig) - N) / H);

    coh_vals = zeros(num_frames - 1, 1);

    phi_prev = zeros(N, 1);

    for m = 1 : num_frames
        idx   = (m-1)*H + (1:N);
        X     = fft(win .* sig(idx));
        phi   = angle(X);

        if m > 1
            delta_phi   = phi - phi_prev;
            % Circular mean magnitude (coherence) across bins
            coh_vals(m-1) = abs(mean(exp(1j * delta_phi)));
        end

        phi_prev = phi;
    end

    mc = mean(coh_vals);

end
