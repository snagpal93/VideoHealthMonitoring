%=========================%=========================
%=========================%=========================

%% VHM Final assingment

% Students:
% Michel van Lier 0961263

%=========================%=========================
%=========================%=========================

% tbs clear matlab
clear all
close all

%% Source selection input %%

prompt = 'Select input: webcam[w]/existing recording[v]: ';
str = input(prompt,'s');

while ((str~='w') && (str~='v'))
    disp('Wrong input selected, please slelect correct:')
    prompt = 'Select input: webcam[w]/existing recording[v]: ';
    str = input(prompt,'s');
end

disp(' ')
disp('You selected the correct input:')
if str == 'w'
    disp('- Webcam')
    % call here  webcam function
    Pt = webcam_ppg();
else
    disp('- Existing recording')
    % call here recording function
    Pt = video_ppg();
end

% evaluation of the framework
fw_evaluation(str, Pt, Fs, PR_reference);

