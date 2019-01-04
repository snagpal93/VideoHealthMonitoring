function SNR = CalcSNR(HB,Fs)

dim = size(HB);

if dim(2) > dim(1)
    HB = HB';
end

if size(HB,1) ~= 300
    display('Error: the pulse segments should contain 300 samples (15s @20Hz)')
    return;
end    

FFT_sig = abs(fft(HB.*hann(length(HB)),60*Fs));
% calculate SNR

idx_f = 40:240;
[~,freq_bin] = max(FFT_sig(idx_f));
freq_bin = idx_f(freq_bin);

harmonic = [];
n_harmonic = 3;
margin = 6;
for nh = 1 : n_harmonic
    bin_width = -margin*nh:margin*nh;
    for bw = 1 : length(bin_width)
        harmonic = cat(2,harmonic,nh*freq_bin+bin_width(bw));
    end
end

harmonic = harmonic(harmonic>0);
MaskSNR = zeros(size(FFT_sig));
MaskSNR(harmonic) = 1;
MaskSNR = MaskSNR(1:length(FFT_sig));

FFT_sig_temp = FFT_sig(idx_f);
FFT_sig_temp = FFT_sig_temp/norm(FFT_sig_temp);
MaskSNR_temp = MaskSNR(idx_f);

A_sigv = MaskSNR_temp.*FFT_sig_temp;
A_noisev = (~MaskSNR_temp).*FFT_sig_temp;

SNR = 10*log10(sum(A_sigv.^2)/sum(A_noisev.^2));