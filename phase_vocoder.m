function y = phase_vocoder(x, fs, semitones)
% PHASE_VOCODER  STFT-based pitch shifter with spectral peak locking
%
%   y = phase_vocoder(x, fs, semitones)
%
%   Inputs:
%     x         - Input audio signal (mono column vector)
%     fs        - Sample rate in Hz
%     semitones - Pitch shift in semitones
%
%   Output:
%     y         - Pitch-shifted output signal (same length as x)
%
%   Parameters:
%     N  = 2048  (FFT size)
%     H  = 512   (analysis hop size; synthesis hop Hs = round(H * ratio))
%     Window: periodic Hann
%
%   Spectral peak locking propagates the instantaneous frequency of each
%   detected peak to surrounding bins (±5 bins), reducing inter-bin phase
%   incoherence and the "phasiness" artifact.
%
%   Authors: K. Siva Srinivas et al., Sathyabama IST, April 2026

    x = x(:);
    N  = 2048;
    Ha = 512;                         % analysis hop
    ratio = 2^(semitones / 12);       % pitch shift ratio
    Hs = round(Ha * ratio);           % synthesis hop

    win = hann(N, 'periodic');

    % --- Frame the signal ---
    % Pad so every frame is full
    pad_len = N + ceil((length(x) - N) / Ha) * Ha - length(x) + Ha;
    x_pad   = [zeros(N/2, 1); x; zeros(pad_len + N/2, 1)];

    num_frames = floor((length(x_pad) - N) / Ha) + 1;

    % Output buffer (overlap-add)
    out_len = Hs * (num_frames + 1) + N;
    y_buf   = zeros(out_len, 1);

    phi_syn = zeros(N, 1);   % accumulated synthesis phase
    phi_prev = zeros(N, 1);  % previous frame analysis phase

    omega_ref = 2 * pi * Ha / N * (0 : N-1)';  % expected phase advance per bin

    for m = 1 : num_frames
        % Extract and window frame
        idx   = (m-1)*Ha + (1:N);
        frame = win .* x_pad(idx);

        % Analysis FFT
        X = fft(frame);

        % --- Instantaneous frequency estimation ---
        delta_phi = angle(X) - phi_prev;
        phi_prev  = angle(X);

        % Wrap to [-pi, pi]
        delta_phi = delta_phi - omega_ref;
        delta_phi = delta_phi - 2*pi * round(delta_phi / (2*pi));

        freq_dev = (omega_ref + delta_phi) / Ha;   % true inst. freq (rad/sample)

        % --- Spectral peak locking ---
        mag = abs(X);
        [~, peak_idx] = findpeaks(mag(1:N/2), 'MinPeakProminence', max(mag)*0.05);

        for p = 1 : length(peak_idx)
            k  = peak_idx(p);
            lo = max(1,   k - 5);
            hi = min(N/2, k + 5);
            freq_dev(lo:hi) = freq_dev(k);
            % Mirror for negative frequencies
            k_m  = N - k + 2;
            lo_m = max(N/2+1, k_m - 5);
            hi_m = min(N,     k_m + 5);
            if k_m >= 1 && k_m <= N
                freq_dev(lo_m:hi_m) = -freq_dev(k);
            end
        end

        % --- Accumulate synthesis phase ---
        phi_syn = phi_syn + Hs * freq_dev;

        % --- Reconstruct frame ---
        Y_frame = mag .* exp(1j * phi_syn);
        y_frame = real(ifft(Y_frame, 'symmetric'));
        y_frame = win .* y_frame;

        % --- Overlap-add into output buffer ---
        out_idx = (m-1)*Hs + (1:N);
        y_buf(out_idx) = y_buf(out_idx) + y_frame;
    end

    % --- Trim and normalise ---
    y = y_buf(N/2 + 1 : N/2 + length(x));

    % Normalise to prevent clipping while preserving relative level
    peak = max(abs(y));
    if peak > 0.99
        y = y * (0.99 / peak);
    end

end
