function [Ri, Gi, Bi] = webcam_interpl(R, G, B, w_timestamp, first, last, update_Fs, x)

    resample = w_timestamp(first):update_Fs:w_timestamp(last);

    % interpolate all the colors
    Ri = interp1(w_timestamp(first:last), R(first:last), resample(1:x));
    Gi = interp1(w_timestamp(first:last), G(first:last), resample(1:x));
    Bi = interp1(w_timestamp(first:last), B(first:last), resample(1:x));
    
    % maybe use better mode, e.g. spline, or use detrend after?

end