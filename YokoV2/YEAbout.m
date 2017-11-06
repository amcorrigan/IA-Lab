function varargout = YEAbout(varargin)
% YEABOUT MATLAB code for YEAbout.fig
%      YEABOUT, by itself, creates a new YEABOUT or raises the existing
%      singleton*.
%
%      H = YEABOUT returns the handle to a new YEABOUT or the handle to
%      the existing singleton*.
%
%      YEABOUT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in YEABOUT.M with the given input arguments.
%
%      YEABOUT('Property','Value',...) creates a new YEABOUT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before YEAbout_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to YEAbout_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help YEAbout

% Last Modified by GUIDE v2.5 14-Oct-2016 13:34:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @YEAbout_OpeningFcn, ...
                   'gui_OutputFcn',  @YEAbout_OutputFcn, ...
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

% --- Executes just before YEAbout is made visible.
function YEAbout_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to YEAbout (see VARARGIN)

    %_______________________________________________
    %   change Yinhai Icon
% %     jFrame = get(hObject,'JavaFrame');
% %     jIcon = javax.swing.ImageIcon('\\UK-Image-01\IAGroup\SB\2016\Yoko\Source Code\Artworks\icon_48.png');
% %     jFrame.setFigureIcon(jIcon);
    % commented this out until any conflict with the licensing agreement is
    % clarified
    
    % this isn't necessary, everything is stored in handles
%     hAxes = findobj('Tag', 'AxesAbout');

%     anImage = imread('\\UK-Image-01\IAGroup\SB\2016\Yoko\Source Code\Artworks\panel.png');
    anImage = imread('IALab.png');
    imshow(anImage, [], 'Parent', handles.AxesAbout, 'InitialMagnification', 'fit');
    
    set(handles.AxesAbout,'xcolor','w','ycolor','w','xtick',[],'ytick',[]);
    set(handles.figure1,'Name','About IALab')
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes YEAbout wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
    
end

% --- Outputs from this function are returned to the command line.
function varargout = YEAbout_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout = cell(nargout,1);
end
