function [PBV, CHROM] = processRGB(R,G,B)
%PROCESSRGB Summary of this function goes here
%   Detailed explanation goes here
    Fs = 20;
    [b_BPF40220, a_BPF40220] = butter(9, ([40 220] /60)/(Fs/2),  'bandpass');
    [b_LPF30, a_LPF30] = butter(6, ([30]/60)/(Fs/2), 'low');

    x_lpf = filtfilt(b_LPF30,a_LPF30, R); 
    y_ACDC_R = (R - x_lpf)./x_lpf;
    x_lpf = filtfilt(b_LPF30,a_LPF30, G); 
    y_ACDC_G = (G - x_lpf)./x_lpf;
    x_lpf = filtfilt(b_LPF30,a_LPF30, B); 
    y_ACDC_B = (B - x_lpf)./x_lpf;


    Rn = filtfilt(b_BPF40220,a_BPF40220, y_ACDC_R); 
    Gn = filtfilt(b_BPF40220,a_BPF40220, y_ACDC_G); 
    Bn = filtfilt(b_BPF40220,a_BPF40220, y_ACDC_B); 
    
    Rc = filtfilt(b_BPF40220,a_BPF40220, Rn); 
    Gc = filtfilt(b_BPF40220,a_BPF40220, Gn); 
    Bc = filtfilt(b_BPF40220,a_BPF40220, Bn); 

    %%%%%%% Optimal projection axis %%%%%%%%%%%%%
    z = [Rc(:) Gc(:) Bc(:)];
    S = z'*z;    %%% The covariance matrix
    pbv = [0.15 0.87 0.47]/norm([0.15 0.87 0.47]);
    pbv=pbv';
    W = S\pbv;      %%% LMS solution S*W=q
    PBV = z*W/(pbv'*W);%%% Project data and correct amplitude
    
    Rc=1.00*Rn;
    Gc=0.66667*Gn;
    Bc=0.50*Bn;

    %%%%% chrominance signals
    X=(Rc-Gc); 
    Y=(Rc+Gc-2*Bc);


    %%%%% prefiltering X, Y to the relevant band (40-220BPM) 
    Xt = filtfilt(b_BPF40220,a_BPF40220, X); 		
    Yt = filtfilt(b_BPF40220,a_BPF40220, Y); 

    Nx=std(Xt);
    Ny=std(Yt);
    alpha_CHROM = Nx/Ny;
    CHROM=Xt- alpha_CHROM*Yt;
    
end

