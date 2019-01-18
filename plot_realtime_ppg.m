function plot_realtime_ppg(ppg, sec)

    sec = sec - 1;
    if sec < 16
        plot(ppg)
    else
        plot(ppg((sec-15:sec)))
    end
    xlabel('Last seconds'); ylabel('Pulse rate [bpm]'); title('Real-time measured heart beat');

end 