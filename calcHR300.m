function [hr] = calcHR300(ppg)
%CALCHR300 Summary of this function goes here
% Function to detect dominant frequency in hbm from a PPG signal of 15s = 300 frames at 20 fps 
%   Detailed explanation goes here

dimPPG = size(ppg);

if dimPPG(1) < dimPPG(2)
    ppg = ppg';
end

dimPPG = size(ppg);

if (dimPPG(1) ~=300) display('Invalid input: data should by of dimension 1x300'); end    

%p = ppg;
p = ppg - mean(ppg);
n = 512; % For FFT calculation
Fs=20;  %Sampling frequency

y = fft(p,n);   %fourier transform

y = y(1:1+n/2); % Only half the values of concern
freq = (0:n/2)* Fs/n;   
[~,index] = max(y); %Find the index at which dominant frequency occurs

hbs = freq(index);  %Use the index to find the dominant frequency

hr = hbs*60; %Convert from Hz to hbm

end

