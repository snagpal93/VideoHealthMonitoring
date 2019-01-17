function peak = update_ppg(s_chrom)

    Fs = 20;
        
    % calcuate pulse rate from frequncy domain
    [~,peak] = max(abs(fft(s_chrom, 60*Fs)));

end