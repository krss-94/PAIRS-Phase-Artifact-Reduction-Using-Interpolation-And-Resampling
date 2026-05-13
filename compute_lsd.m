function lsd = compute_lsd(ref, est, nfft, hop)
% COMPUTE_LSD  Log Spectral Distance between reference and estimated signals
%
%   lsd = compute_lsd(ref, est)
%   lsd = compute_lsd(ref, est, nfft, hop)
%
%   Inputs:
%     ref   - Reference signal (ideal pitch-shifted output)
%     est   - Estimated signal (algorithm output)
%     nfft  - FFT size (default: 1024)
%     hop   - Hop size (default: nfft/2)
%
%   Output:
%     lsd   - Mean LSD in dB (lower = better spectral fidelity)
%
%   Formula:
%     LSD = (1/K) * sum_k [ 10*log10(S_ref[k] / S_est[k]) ]^2
%
%   Authors: K. Siva Srinivas et al., Sathyabama IST, April 2026

    if nargin < 3, nfft = 1024; end
    if nargin < 4, hop  = nfft / 2; end

    ref = ref(:);
    est = est(:);

    % Match lengths
    L = min(length(ref), length(est));
    ref = ref(1:L);
    est = est(1:L);

    win   = hann(nfft, 'periodic');
    S_ref = abs(spectrogram(ref, win, nfft - hop, nfft)).^2;
    S_est = abs(spectrogram(est, win, nfft - hop, nfft)).^2;

    % Floor to avoid log(0)
    S_ref = max(S_ref, 1e-12);
    S_est = max(S_est, 1e-12);

    lsd = mean(mean((10 * log10(S_ref ./ S_est)).^2));

end
