function y = pairs_pitch_shift(x, fs, semitones, L)
% PAIRS_PITCH_SHIFT  Phase Artifact Reduction Using Interpolation And Re-Sampling
%
%   y = pairs_pitch_shift(x, fs, semitones)
%   y = pairs_pitch_shift(x, fs, semitones, L)
%
%   Inputs:
%     x         - Input audio signal (mono column vector)
%     fs        - Sample rate in Hz (e.g. 44100)
%     semitones - Pitch shift in semitones (positive = up, negative = down)
%     L         - Upsampling factor (default: 2)
%
%   Output:
%     y         - Pitch-shifted output signal at original sample rate fs
%
%   Algorithm (4 stages):
%     1. Upsample x by L using polyphase FIR interpolation
%     2. Run phase vocoder at elevated rate L*fs
%     3. Apply 64th-order FIR anti-aliasing LPF (cutoff pi/L)
%     4. Downsample by L to restore original fs
%
%   The phase vocoder is NOT modified. PAIRS is a transparent wrapper.
%   The Noble Identity does not apply (PV is nonlinear), so the PV MUST
%   execute at the elevated rate for the sacrificial-band mechanism to work.
%
%   References:
%     Vaidyanathan, P.P., "Multirate Systems and Filter Banks," Prentice-Hall, 1993.
%
%   Authors: K. Siva Srinivas, K. Keshav, K. Lokesh, S. Kishore Vikhram,
%            Lakshmi Srinivasan K, S. Karthikeyan
%   Institution: Dept. of ECE, Sathyabama Institute of Science and Technology
%   Date: April 2026

    if nargin < 4
        L = 2;
    end

    % Ensure column vector
    x = x(:);

    % --- Stage 1: Upsample by L ---
    % resample() uses a polyphase Kaiser FIR internally (MATLAB default beta~8)
    x_up = resample(x, L, 1);
    fs_up = L * fs;

    % --- Stage 2: Phase Vocoder at elevated rate ---
    y_up = phase_vocoder(x_up, fs_up, semitones);

    % --- Stage 3: Anti-alias LPF (mandatory pre-decimation filter) ---
    % Normalised cutoff = 1/L (i.e. pi/L in rad/sample).
    % This removes all energy above original Nyquist, including sacrificial-band IMD.
    lpf = fir1(64, 1/L);
    y_filt = filtfilt(lpf, 1, y_up);

    % --- Stage 4: Downsample by L ---
    y = resample(y_filt, 1, L);

end
