%% PAIRS Demo Script
% Demonstrates PAIRS pitch shifting vs Raw PV and Std PV on a test signal.
% Run this from the matlab/ directory.
%
% Usage:
%   cd matlab
%   demo
%
% Authors: K. Siva Srinivas et al., Sathyabama IST, April 2026

clear; clc; close all;

fprintf('=== PAIRS Demo ===\n\n');

%% Load audio
% Replace with your own file path, or use MATLAB's built-in example:
[audio_file, audio_path] = uigetfile({'*.wav;*.flac;*.mp3', 'Audio Files'}, ...
    'Select a mono audio file (WAV/FLAC/MP3)');

if isequal(audio_file, 0)
    fprintf('No file selected. Using synthetic harmonic tone for demo.\n');
    fs   = 44100;
    t    = (0 : fs*2 - 1)' / fs;
    freq = 440;  % A4
    x    = 0.5 * (sin(2*pi*freq*t) + 0.4*sin(2*pi*2*freq*t) + ...
                  0.2*sin(2*pi*3*freq*t) + 0.1*sin(2*pi*4*freq*t));
else
    [x, fs] = audioread(fullfile(audio_path, audio_file));
    if size(x, 2) > 1
        x = mean(x, 2);   % to mono
    end
end

fprintf('Signal: %.2f s at %d Hz\n', length(x)/fs, fs);

%% Parameters
semitones = 4;   % pitch shift (change as desired)
L         = 2;   % upsampling factor

fprintf('Pitch shift: %+d semitones  |  L = %d\n\n', semitones, L);

%% Process
fprintf('Running Raw PV...\n');
tic; y_raw   = phase_vocoder(x, fs, semitones); t_raw = toc;

fprintf('Running PAIRS (L=%d)...\n', L);
tic; y_pairs = pairs_pitch_shift(x, fs, semitones, L); t_pairs = toc;

fprintf('\nTiming:\n');
fprintf('  Raw PV : %.3f s\n', t_raw);
fprintf('  PAIRS  : %.3f s  (overhead: %.1f%%)\n', t_pairs, ...
    (t_pairs - t_raw) / t_raw * 100);

%% Metrics
fprintf('\nComputing metrics...\n');

% Use a simple ideal reference: resample only (no vocoder)
% (For a true ideal, apply rational resampling; here we use PAIRS as proxy)
ref = resample(resample(x, round(length(x) * 2^(semitones/12)), length(x)), ...
               length(x), round(length(x) * 2^(semitones/12)));
ref = ref(1 : min(end, length(x)));
ref(end+1 : length(x)) = 0;

lsd_raw   = compute_lsd(ref, y_raw);
lsd_pairs = compute_lsd(ref, y_pairs);
tir       = compute_tir(x, y_raw, y_pairs, fs);
dcoh      = compute_phase_coherence(y_pairs, y_raw);

fprintf('\n--- Results ---\n');
fprintf('LSD (Raw PV)  : %.3f dB\n', lsd_raw);
fprintf('LSD (PAIRS)   : %.3f dB  (gain: %+.3f dB)\n', lsd_pairs, lsd_raw - lsd_pairs);
fprintf('TIR           : %.3f  (%s)\n', tir, tir_verdict(tir));
fprintf('Dcoh          : %+.4f  (%s)\n', dcoh, dcoh_verdict(dcoh));

%% Playback prompt
fprintf('\nPlayback order: Original → Raw PV → PAIRS\n');
fprintf('Press any key to start...\n');
pause;

fprintf('Playing: Original\n');
sound(x, fs);
pause(length(x)/fs + 0.5);

fprintf('Playing: Raw PV\n');
sound(y_raw, fs);
pause(length(y_raw)/fs + 0.5);

fprintf('Playing: PAIRS\n');
sound(y_pairs, fs);
pause(length(y_pairs)/fs + 0.5);

%% Save outputs
audiowrite('output_raw_pv.wav',   y_raw,   fs);
audiowrite('output_pairs.wav',    y_pairs, fs);
fprintf('\nOutputs saved: output_raw_pv.wav, output_pairs.wav\n');

%% Spectral plot
figure('Name', 'PAIRS vs Raw PV – Spectral Comparison', 'Color', 'w');
nfft = 1024;
win  = hann(nfft, 'periodic');
hop  = nfft / 2;

L_sig = min([length(x), length(y_raw), length(y_pairs)]);

subplot(3,1,1);
spectrogram(x(1:L_sig),      win, nfft-hop, nfft, fs, 'yaxis'); title('Original');      colorbar off;
subplot(3,1,2);
spectrogram(y_raw(1:L_sig),  win, nfft-hop, nfft, fs, 'yaxis'); title('Raw PV');        colorbar off;
subplot(3,1,3);
spectrogram(y_pairs(1:L_sig),win, nfft-hop, nfft, fs, 'yaxis'); title('PAIRS (L=2)');   colorbar off;

sgtitle(sprintf('Pitch Shift: %+d semitones', semitones));

fprintf('Done.\n');

% -------------------------------------------------------------------------
function s = tir_verdict(tir)
    if tir >= 1.05,     s = 'PAIRS clearly wins';
    elseif tir >= 0.90, s = 'Near-parity';
    else,               s = 'Std PV wins'; end
end

function s = dcoh_verdict(d)
    if d > 0.005,      s = 'PAIRS more coherent';
    elseif d > -0.005, s = 'Near-parity';
    else,              s = 'Std PV more coherent'; end
end
