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
else
    disp('- Existing recording')
    % call here recording function
end

%% Webcam get picture data

%% INIT WEBCAM stuff
% Identifying Available Webcams
camList = webcamlist;

% Connect to the webcam.
cam = webcam(1);

% webcam settings
%cam.Resolution = '320x240';
%cam.Exposure = -4;
%cam.Gain = 253;
%cam.Saturation = 32;
%cam.WhiteBalance = 8240;
%cam.WhiteBalanceMode = 'manual';
%cam.ExposureMode = 'manual'; 
%cam.Sharpness = 48;
%cam.Brightness = 128;
%cam.BacklightCompensation = 1;
%cam.Contrast = 32;
%preview(cam)

% INIT Face detection with Viola-Jones algorithm
% Create a cascade detector object.
faceDetector  = vision.CascadeObjectDetector();
eyeDetector   = vision.CascadeObjectDetector('EyePairBig', 'UseROI', true);
noseDetector = vision.CascadeObjectDetector('Nose', 'UseROI', true);
% bad performance, so dont use
%mouthDetector = vision.CascadeObjectDetector('Mouth', 'UseROI', true); 

%% INIT face tracking fucntion
face_found = false;
while face_found == false
    % get first shot to get face and make init ROI for the tracker
    [img, ~] = snapshot(cam);
    
    img = imresize(img, 0.5);

    % get first ROI to init tracker
    rect_prev = step(faceDetector, img);
    
    % Visualize bounding box in the frame
    img_ann = insertObjectAnnotation(img,'rectangle',rect_prev,'ROI'); 
    
    if isempty(rect_prev)
        % if no face found add message
        text_str = ['No face found, please allign on webcam, or add more light!'];
        position = [0 0];
        box_color = {'red'};
    else
        % face is found, start with tracking
        face_found = true;
        text_str = ['Face found!, going to start measurment'];
        position = [rect_prev(1) (rect_prev(2)-(60/0.5))];
        box_color = {'green'};
    end
    
    % show img with warning msg
    img_text = insertText(img_ann,position,text_str,'FontSize',18,'BoxColor', box_color,'BoxOpacity',0.4,'TextColor','white');
    imshow(img_text)
    
end


% init tacker
TrackInitFlag = false;

if TrackInitFlag == false
    % Initialize tracker
    TrackFirstRun = true;
    trackermodel.model_alphaf = 0;
    trackermodel.model_xf = 0;

    [TrackerInit, TrackInitFlag] = InitTracker; % TrackInitFlag set to true 
    [rect, trackermodel] = tracker(img, TrackerInit, rect_prev, trackermodel, TrackFirstRun); 
    TrackFirstRun = false;
end

% TrackInitFlag; flag to indicate if tracker is initialized
% TrackerInit; struct with tracker parameters
% rect; bounding box coordinates current frame
% img; RGB input image
% rect_prev; bounding box coordinates previous frame
% trackermodel; struct of tracker model, updated at each iteration
% TrackFirstRun; flag to indicate if the tracker is executed for the first time, necessary for the trackermodel

% Display rPPG bmp settings
bpm_str = ['BMP: 0'];
position = [0 0];
box_color = {'blue'};


%% Do here the detection loop

i = 1;
while true
    % get camera frame
    [img,timestamp(i)] = snapshot(cam);
    img = imresize(img, 0.5);
    [rect,trackermodel] = tracker(img, TrackerInit, rect_prev, trackermodel, TrackFirstRun); 
    
    img_ann = insertObjectAnnotation(img,'rectangle',rect,'Face found');
    
    BB_eye  = eyeDetector(img, rect);
    BB_nose = noseDetector(img, rect);
    
    % Visualize bounding box in the frame
    img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_eye,'Eyes found');
    img_ann = insertObjectAnnotation(img_ann,'rectangle',BB_nose,'Nose found');
    
    % show bpm in img
    img_bmp = insertText(img_ann, position, bpm_str, 'FontSize',24, 'BoxColor', box_color, 'BoxOpacity' ,0.4 ,'TextColor','white');
    
    if ~(isempty(BB_eye))
        x = BB_eye(1) + BB_eye(3)/2;
        y1 = BB_eye(2) - (BB_eye(4)/1.5);
        y2 = BB_eye(2) + (BB_eye(4)*1.5);
        img_bmp = insertShape(img_bmp,'Line',[x y1 x y2],'LineWidth',2,'Color','blue');
        
        img_bmp = insertObjectAnnotation(img_bmp,'rectangle',[x-30 y1-30 60 30],'meas', 'LineWidth',2,'Color','green');
    end
    
    imshow(img_bmp)
    
end

%% [optional] Skin classifier


%% Resampling webcam frames
%vq = interp1(x,v,xq)
% returns interpolated values of a 1-D function at specific query points using linear ...
%    interpolation. Vector x contains the sample points, and v contains the corresponding values, ...
%    v(x). Vector xq contains the coordinates of the query points.

% Clean Up
clear cam