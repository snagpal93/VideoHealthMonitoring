function fw_eval_vid(pbv, chr, Fs, PR_reference)

    % Sliding window SNR settings
    window_size = 300;

    % Calc SNR for eacht segment
    for i = window_size:length(pbv)
        pbv_snr(i) = CalcSNR(pbv(i-(window_size-1):i),Fs); % Pt = pulse segment, Fs = (re)sampling frequency [Hz]
        chr_snr(i) = CalcSNR(chr(i-(window_size-1):i),Fs); % Pt = pulse segment, Fs = (re)sampling frequency [Hz]
        SNRt(i) = max(pbv_snr(i),chr_snr(i));
        
        if (pbv_snr(i) > chr_snr(i))
            hr_mer(i) = calcHR300(pbv(i-(window_size-1):i));
        else
            hr_mer(i) = calcHR300(chr(i-(window_size-1):i));
        end
    end
    
    % Spectrogram calculation of the extracted pulse signal
    %P_F = spec(Pt,Fs); % P = pulse signal, Fs = frame rate (re)sampling frequency [Hz]
    
    x = (1:length(pbv))/20;
    % Visualize SNR
    subplot(1,3,1);


    plot(x,pbv_snr,x,chr_snr,x,SNRt); 
    
    legend({'pbv','çhr','SNRt'},'Location','southwest')
    
    xlabel('Frame'); ylabel('Pulse rate [bpm]'); title('SNR');
    
    % Insert mean SNR in plot
    annotation('textbox',...
    [0.7 0.6 0.3 0.3],...
    'String',{'Mean SNR: ' num2str(mean(SNRt))},...  % calc and print mean SNR from signal
    'FitBoxToText','on',...
    'FontSize',14,...
    'BackgroundColor',[0.9 0.9 0.9],...
    'Color','red');

    subplot(1,3,2);

    hr = hr_mer(301:length(hr_mer));
    plot(hr);
    
    [~,hr_ref] = max(spec(PR_reference,20));
    
    hold on
    
    plot(hr_ref)
   
    

end


