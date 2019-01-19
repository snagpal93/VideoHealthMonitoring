function hr = update_ppg(R, G, B, first, last, b, a)

    Fs = 20;
    
    p = chrom_method(R(first:last), G(first:last), B(first:last), a, b);
        
    % calcuate pulse rate from frequncy domain
    %[~,peak] = max(abs(fft(s_chrom)));
    % Fourier Transformation
    n = 512; % For FFT calculation
    Fs=20;  %Sampling frequency

    y = fft(p,n);   %fourier transform

    y = y(1:1+n/2); % Only half the values of concern
    freq = (0:n/2)* Fs/n;   
    [~,index] = max(y); %Find the index at which dominant frequency occurs

    hbs = freq(index);  %Use the index to find the dominant frequency

    hr = hbs*60; %Convert from Hz to hbm


end