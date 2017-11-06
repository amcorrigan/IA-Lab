function varargout = AboutWound(varargin)
% ABOUTWOUND MATLAB code for AboutWound.fig
%      ABOUTWOUND, by itself, creates a new ABOUTWOUND or raises the existing
%      singleton*.
%
%      H = ABOUTWOUND returns the handle to a new ABOUTWOUND or the handle to
%      the existing singleton*.
%
%      ABOUTWOUND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ABOUTWOUND.M with the given input arguments.
%
%      ABOUTWOUND('Property','Value',...) creates a new ABOUTWOUND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AboutWound_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AboutWound_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AboutWound

% Last Modified by GUIDE v2.5 12-Dec-2016 10:16:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AboutWound_OpeningFcn, ...
                   'gui_OutputFcn',  @AboutWound_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before AboutWound is made visible.
function AboutWound_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AboutWound (see VARARGIN)

    anImage = imread('pellet.png');
    imshow(anImage, [], 'Parent', handles.axes1, 'InitialMagnification', 'fit');
    
    set(handles.axes1,'xcolor','w','ycolor','w','xtick',[],'ytick',[]);
    set(handles.figure1,'Name','About Pellet Explorer')
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes YEAbout wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = AboutWound_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout = cell(nargout,1);
end