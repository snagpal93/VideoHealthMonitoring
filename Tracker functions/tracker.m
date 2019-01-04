function [rect,trackermodel] = tracker(img,TrackerInit,rect_prev,trackermodel,TrackFirstRun)
%TRACKER Kernelized/Dual Correlation Filter (KCF/DCF) tracking.
%   This function implements the pipeline for tracking with the KCF (by
%   choosing a non-linear kernel) and DCF (by choosing a linear kernel).
%
%   Parameters:
%     POS and TARGET_SZ are the initial position and size of the target
%      (both in format [rows, columns]).
%     PADDING is the additional tracked region, for context, relative to 
%      the target size.
%     KERNEL is a struct describing the kernel. The field TYPE must be one
%      of 'gaussian', 'polynomial' or 'linear'. The optional fields SIGMA,
%      POLY_A and POLY_B are the parameters for the Gaussian and Polynomial
%      kernels.
%     OUTPUT_SIGMA_FACTOR is the spatial bandwidth of the regression
%      target, relative to the target size.
%     INTERP_FACTOR is the adaptation rate of the tracker.
%     CELL_SIZE is the number of pixels per cell (must be 1 if using raw
%      pixels).
%     FEATURES is a struct describing the used features (see GET_FEATURES).
%     SHOW_VISUALIZATION will show an interactive video if set to true.

    pos = [rect_prev(2) rect_prev(1)];
    target_sz = [rect_prev(4) rect_prev(3)];

    x=rect_prev(1); y=rect_prev(2); w=rect_prev(3); h=rect_prev(4);  

	%if the target is large, lower the resolution, we don't need that much
	%detail
	resize_image = 0;%(sqrt(prod(target_sz)) >= 100);  %diagonal size >= threshold
	if resize_image,
		pos = floor(pos / 2);
		target_sz = floor(target_sz / 2);
    end

	%window size, taking padding into account
	window_sz = floor(target_sz * (1 + TrackerInit.padding));
	
	%create regression labels, gaussian shaped, with a bandwidth
	%proportional to target size
	output_sigma = sqrt(prod(target_sz)) * TrackerInit.output_sigma_factor / TrackerInit.cell_size;
	yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / TrackerInit.cell_size)));

	%store pre-computed cosine window
	cos_window = hann(size(yf,1)) * hann(size(yf,2))';	
	
	%note: variables ending with 'f' are in the Fourier domain.

    img_rgb = img;
        
    if size(img,3) > 1,
        %im = rgb2gray(im); %original

         % optional if #channel >3
        img = rgb2gray(img_rgb);
    end
    if resize_image,
        img = imresize(img, 0.5);
    end	

    if TrackFirstRun == false
        %obtain a subwindow for detection at the position from last
        %frame, and convert to Fourier domain (its size is unchanged)
        patch = get_subwindow(img, pos, window_sz);
        zf = fft2(get_features(patch, TrackerInit.features, TrackerInit.cell_size, cos_window));

        %calculate response of the classifier at all shifts
        switch TrackerInit.kernel.type
        case 'gaussian',
            kzf = gaussian_correlation(zf, trackermodel.model_xf, TrackerInit.kernel.sigma);
        case 'polynomial',
            kzf = polynomial_correlation(zf, trackermodel.model_xf, TrackerInit.kernel.poly_a, TrackerInit.kernel.poly_b);
        case 'linear',
            kzf = linear_correlation(zf, trackermodel.model_xf);
        end
        response = real(ifft2(trackermodel.model_alphaf .* kzf));  %equation for fast detection

        %target location is at the maximum response. we must take into
        %account the fact that, if the target doesn't move, the peak
        %will appear at the top-left corner, not at the center (this is
        %discussed in the paper). the responses wrap around cyclically.
        [vert_delta, horiz_delta] = find(response == max(response(:)), 1);
        if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis
            vert_delta = vert_delta - size(zf,1);
        end
        if horiz_delta > size(zf,2) / 2,  %same for horizontal axis
            horiz_delta = horiz_delta - size(zf,2);
        end
        pos = pos + TrackerInit.cell_size * [vert_delta - 1, horiz_delta - 1];

        if pos(1)<1
            pos(1)=1;
        elseif pos(2)<1
            pos(2)=1;                
        end
    end

    %obtain a subwindow for training at newly estimated target position
    patch = get_subwindow(img, pos, window_sz);
    xf = fft2(get_features(patch, TrackerInit.features, TrackerInit.cell_size, cos_window));

    %Kernel Ridge Regression, calculate alphas (in Fourier domain)
    switch TrackerInit.kernel.type
    case 'gaussian',
        kf = gaussian_correlation(xf, xf, TrackerInit.kernel.sigma);
    case 'polynomial',
        kf = polynomial_correlation(xf, xf, TrackerInit.kernel.poly_a, TrackerInit.kernel.poly_b);
    case 'linear',
        kf = linear_correlation(xf, xf);
    end
    alphaf = yf ./ (kf + TrackerInit.lambda);   %equation for fast training

    if TrackFirstRun == true %first frame, train with a single image
        trackermodel.model_alphaf = alphaf;
        trackermodel.model_xf = xf;
    else
        %subsequent frames, interpolate model
        trackermodel.model_alphaf = (1 - TrackerInit.interp_factor) * trackermodel.model_alphaf + TrackerInit.interp_factor * alphaf;
        trackermodel.model_xf = (1 - TrackerInit.interp_factor) * trackermodel.model_xf + TrackerInit.interp_factor * xf;
    end          

    x=pos(2); y=pos(1);
    rect = [x,y,w,h];  
end