function peak = update_ppg(R, G, B, first, last, b, a)
    
    Fs = 20;

    %here we need to know the pixel colors already
    s_chrom = chrom_method(R(first:last), G(first:last), B(first:last), a, b);
        
    % calcuate pulse rate from frequncy domain
    [~,peak] = max(abs(fft(s_chrom, 60*Fs)));

end