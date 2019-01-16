function fw_evaluation(source_input, Pt, Fs, PR_reference)

    % Sliding window SNR settings
    window_size = 300;

    % Calc SNR for eacht segment
    for i = window_size:length(Pt)
        SNRt(i) = CalcSNR(Pt(i-(window_size-1):i),Fs); % Pt = pulse segment, Fs = (re)sampling frequency [Hz]
    end
    
    % Spectrogram calculation of the extracted pulse signal
    P_F = spec(Pt,Fs); % P = pulse signal, Fs = frame rate (re)sampling frequency [Hz]
    
    
    % Visualize SNR
    if source_input == 'v'
        subplot(1,3,1);
    else
        subplot(1,2,1);
    end
    plot(SNRt); 
    xlabel('Frame'); ylabel('Pulse rate [bpm]'); title('SNR');
    
    % Insert mean SNR in plot
    annotation('textbox',...
    [0.7 0.6 0.3 0.3],...
    'String',{'Mean SNR: ' num2str(mean(SNRt))},...  % calc and print mean SNR from signal
    'FitBoxToText','on',...
    'FontSize',14,...
    'BackgroundColor',[0.9 0.9 0.9],...
    'Color','red');

    
    % Visualize spectrogram
    if source_input == 'v'
        subplot(1,3,2);
    else
        subplot(1,2,2);
    end
    imagesc(P_F(1:300,:)); % only visualize relevant frequencies [bpm]
    colormap('jet'); set(gca,'YDir','normal'); xlabel('Frame'); ylabel('Pulse rate [bpm]'); title('Spectrogram'); sgtitle('Framework Perfromace Evaluation')
    
    
    % Visualize Bland-Altman analysis
    if source_input == 'v'
        % Perform Bland-Altman analysis on pulse rates extracted from the camera and the reference sensor (more details can be found in the `ba' function file):
        ba(subplot(1,3,3), Pt, PR_reference, 'XName', 'rPPG', 'YName', 'Reference', 'PlotMeanDifference', true, 'PlotStatistics','basic');
    end
end
