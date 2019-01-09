function s_ppg = update_ppg(R, G, B, first, last)
    
    Fs = 20;

    %here we need to know the pixel colors already
    s_chrom = chrom_method(R(first:last), G(first:last), B(first:last), a_BPF40220, b_BPF40220);
        
    % calcuate pulse rate from frequncy domain
    [~,peak] = max(abs(fft(hanning(s_chrom),60*Fs)));

end