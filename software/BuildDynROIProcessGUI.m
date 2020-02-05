function varargout = BuildDynROIProcessGUI(varargin)
%BUILDDYNROIPROCESSGUI MATLAB code file for BuildDynROIProcessGUI.fig
%      BUILDDYNROIPROCESSGUI, by itself, creates a new BUILDDYNROIPROCESSGUI or raises the existing
%      singleton*.
%
%      H = BUILDDYNROIPROCESSGUI returns the handle to a new BUILDDYNROIPROCESSGUI or the handle to
%      the existing singleton*.
%
%      BUILDDYNROIPROCESSGUI('Property','Value',...) creates a new BUILDDYNROIPROCESSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to BuildDynROIProcessGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      BUILDDYNROIPROCESSGUI('CALLBACK') and BUILDDYNROIPROCESSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in BUILDDYNROIPROCESSGUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Copyright (C) 2020, Danuser Lab - UTSouthwestern 
%
% This file is part of NewUtrack3DPackage.
% 
% NewUtrack3DPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% NewUtrack3DPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with NewUtrack3DPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

% Edit the above text to modify the response to help BuildDynROIProcessGUI

% Last Modified by GUIDE v2.5 23-Sep-2019 16:06:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BuildDynROIProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @BuildDynROIProcessGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before BuildDynROIProcessGUI is made visible.
function BuildDynROIProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Parameters setup 
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;


% Set up available detection channels
set(handles.listbox_availableDetectChannels,'String',userData.MD.getChannelPaths(), ...
    'UserData',1:numel(userData.MD.channels_));

detectChannelIndex = funParams.detectionProcessChannel;

if ~isempty(detectChannelIndex)
    detectChannelString = userData.MD.getChannelPaths(detectChannelIndex);
else
    detectChannelString = {};
end
set(handles.listbox_selectedDetectChannels,'String',detectChannelString,...
    'UserData',detectChannelIndex);


%Setup detect process list box
detectProc =  cellfun(@(x) isa(x,'PointSourceDetectionProcess3D')&&~isa(x,'PointSourceDetectionProcess3DDynROI'),userData.MD.processes_);
detectProcID=find(detectProc);
detectProcNames = cellfun(@(x) x.getName(),userData.MD.processes_(detectProc),'Unif',false);
detectProcString = vertcat('Choose later',detectProcNames(:));
detectProcData=horzcat({[]},num2cell(detectProcID));
detectProcValue = find(cellfun(@(x) isequal(x,funParams.detectionProcess),userData.MD.processes_(detectProc)));
if isempty(detectProcValue)
    detectProcValue = 1; 
else
    detectProcValue = detectProcValue+1; 
end
set(handles.popupmenu_DetectProcessIndex,'String',detectProcString,...
    'UserData',detectProcData,'Value',detectProcValue);

% Update channels listboxes depending on the selected process
popupmenu_DetectProcessIndex_Callback(hObject, eventdata, handles)


% Set up available tracking channels
set(handles.listbox_availableTrackChannels,'String',userData.MD.getChannelPaths(), ...
    'UserData',1:numel(userData.MD.channels_));

trackChannelIndex = funParams.trackProcessChannel;

if ~isempty(trackChannelIndex)
    detectChannelString = userData.MD.getChannelPaths(trackChannelIndex);
else
    detectChannelString = {};
end
set(handles.listbox_selectedTrackChannels,'String',detectChannelString,...
    'UserData',trackChannelIndex);


%Setup tracking process list box
trackProc =  cellfun(@(x) isa(x,'TrackingProcess')&&~isa(x,'TrackingDynROIProcess'),userData.MD.processes_);
trackProcID=find(trackProc);
trackProcNames = cellfun(@(x) x.getName(),userData.MD.processes_(trackProc),'Unif',false);
trackProcString = vertcat('Choose later',trackProcNames(:));
trackProcData=horzcat({[]},num2cell(trackProcID));
trackProcValue = find(cellfun(@(x) isequal(x,funParams.trackProcess),userData.MD.processes_(trackProc)));
if isempty(trackProcValue)
    trackProcValue = 1; 
else
    trackProcValue = trackProcValue+1; 
end
set(handles.popupmenu_TrackProcessIndex,'String',trackProcString,...
    'UserData',trackProcData,'Value',trackProcValue);

% Update channels listboxes depending on the selected process
popupmenu_TrackProcessIndex_Callback(hObject, eventdata, handles)

%Setup ROI type list box
set(handles.popupmenu_ROItypes, 'String', BuildDynROIProcess.getValidROITypes);
parVal = funParams.roiType;
valSel  = find(ismember(BuildDynROIProcess.getValidROITypes, parVal));
if isempty(valSel), valSel = 1; end
set(handles.popupmenu_ROItypes, 'Value', valSel);


set(handles.edit_fringe, 'String',num2str(funParams.fringe))
set(handles.edit_nSample, 'String',num2str(funParams.nSample))
    
% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = BuildDynROIProcessGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Delete figure
delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

% -------- Check user input --------
if isempty(get(handles.listbox_selectedChannels, 'String'))
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
else
    channelIndex = get(handles.listbox_selectedChannels, 'Userdata');
    funParams.ChannelIndex = channelIndex;
end

if isnan(str2double(get(handles.edit_fringe, 'String'))) ...
    || str2double(get(handles.edit_fringe, 'String')) < 0
  errordlg('Please provide a valid input for ''Fringe added in addition to box around all tracks: ''.','Setting Error','modal');
  return;
end

if isnan(str2double(get(handles.edit_nSample, 'String'))) ...
    || str2double(get(handles.edit_nSample, 'String')) < 0
  errordlg('Please provide a valid input for ''Number of tracks used for singleTracks, singleStaticTracks and randomSampling: ''.','Setting Error','modal');
  return;
end

% -------- Process Sanity check --------
% ( only check underlying data )
try
    userData.crtProc.sanityCheck;
catch ME
    errordlg([ME.message 'Please double check your data'],...
                'Setting Error','modal');
    return;
end

% Retrieve GUI-defined parameters:

%Get selected detect channels
detectChannelProps = get(handles.listbox_selectedDetectChannels, {'Userdata','String'});
funParams.detectionProcessChannel = detectChannelProps{1};
% Retrieve detect process
props=get(handles.popupmenu_DetectProcessIndex,{'UserData','Value'});
detectProcessIndex = props{1}{props{2}};
if ~isempty(detectProcessIndex)
  funParams.detectionProcess = userData.MD.processes_{detectProcessIndex};
else 
  funParams.detectionProcess = [];
end

%Get selected track channels
trackChannelProps = get(handles.listbox_selectedTrackChannels, {'Userdata','String'});
funParams.trackProcessChannel = trackChannelProps{1};
% Retrieve track process
props=get(handles.popupmenu_TrackProcessIndex,{'UserData','Value'});
trackProcessIndex = props{1}{props{2}};
if ~isempty(trackProcessIndex)
  funParams.trackProcess = userData.MD.processes_{trackProcessIndex};
else 
  funParams.trackProcess = [];
end


funParams.fringe = str2double(get(handles.edit_fringe, 'String'));
funParams.nSample = str2double(get(handles.edit_nSample, 'String'));

selType = get(handles.popupmenu_ROItypes, 'Value'); 
funParams.roiType = BuildDynROIProcess.getValidROITypes{selType};


% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);


% --- Executes on button press in checkbox_applytoall.
function checkbox_applytoall_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_applytoall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_applytoall


% --- Executes on selection change in listbox_availableTrackChannels.
function listbox_availableTrackChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_availableTrackChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_availableTrackChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_availableTrackChannels


% --- Executes during object creation, after setting all properties.
function listbox_availableTrackChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_availableTrackChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_track_all.
function checkbox_track_all_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_track_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_track_all
contents1 = get(handles.listbox_availableTrackChannels, 'String');

chanIndex1 = get(handles.listbox_availableTrackChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedTrackChannels, 'Userdata');

% Return if listbox1 is empty
if isempty(contents1)
    return;
end

switch get(hObject,'Value')
    case 1
        set(handles.listbox_selectedTrackChannels, 'String', contents1);
        chanIndex2 = chanIndex1;
    case 0
        set(handles.listbox_selectedTrackChannels, 'String', {}, 'Value',1);
        chanIndex2 = [ ];
end
set(handles.listbox_selectedTrackChannels, 'UserData', chanIndex2);


% --- Executes on button press in pushbutton_track_select.
function pushbutton_track_select_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_track_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents1 = get(handles.listbox_availableTrackChannels, 'String');
contents2 = get(handles.listbox_selectedTrackChannels, 'String');
id = get(handles.listbox_availableTrackChannels, 'Value');

% If channel has already been added, return;
chanIndex1 = get(handles.listbox_availableTrackChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedTrackChannels, 'Userdata');

for i = id

        contents2{end+1} = contents1{i};
        
        chanIndex2 = cat(2, chanIndex2, chanIndex1(i));

end

set(handles.listbox_selectedTrackChannels, 'String', contents2, 'Userdata', chanIndex2);


% --- Executes on button press in pushbutton_track_delete.
function pushbutton_track_delete_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_track_delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call back function of 'delete' button
contents = get(handles.listbox_selectedTrackChannels,'String');
id = get(handles.listbox_selectedTrackChannels,'Value');

% Return if list is empty
if isempty(contents) || isempty(id)
    return;
end

% Delete selected item
contents(id) = [ ];

% Delete userdata
chanIndex2 = get(handles.listbox_selectedTrackChannels, 'Userdata');
chanIndex2(id) = [ ];
set(handles.listbox_selectedTrackChannels, 'Userdata', chanIndex2);

% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (id >length(contents) && id>1)
    set(handles.listbox_selectedTrackChannels,'Value',length(contents));
end
% Refresh listbox
set(handles.listbox_selectedTrackChannels,'String',contents);


% --- Executes on selection change in listbox_selectedTrackChannels.
function listbox_selectedTrackChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_selectedTrackChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_selectedTrackChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_selectedTrackChannels


% --- Executes during object creation, after setting all properties.
function listbox_selectedTrackChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_selectedTrackChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_track_up.
function pushbutton_track_up_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_track_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call back of 'Up' button

id = get(handles.listbox_selectedTrackChannels,'Value');
contents = get(handles.listbox_selectedTrackChannels,'String');


% Return if list is empty
if isempty(contents) || isempty(id) || id == 1
    return;
end

temp = contents{id};
contents{id} = contents{id-1};
contents{id-1} = temp;

chanIndex = get(handles.listbox_selectedTrackChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id-1);
chanIndex(id-1) = temp;

set(handles.listbox_selectedTrackChannels, 'String', contents, 'Userdata', chanIndex);
set(handles.listbox_selectedTrackChannels, 'value', id-1);


% --- Executes on button press in pushbutton_track_down.
function pushbutton_track_down_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_track_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

id = get(handles.listbox_selectedTrackChannels,'Value');
contents = get(handles.listbox_selectedTrackChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == length(contents)
    return;
end

temp = contents{id};
contents{id} = contents{id+1};
contents{id+1} = temp;

chanIndex = get(handles.listbox_selectedTrackChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id+1);
chanIndex(id+1) = temp;

set(handles.listbox_selectedTrackChannels, 'string', contents, 'Userdata',chanIndex);
set(handles.listbox_selectedTrackChannels, 'value', id+1);


% --- Executes on selection change in popupmenu_TrackProcessIndex.
function popupmenu_TrackProcessIndex_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_TrackProcessIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_TrackProcessIndex contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_TrackProcessIndex

% Retrieve selected process ID
props= get(handles.popupmenu_TrackProcessIndex,{'UserData','Value'});
procID = props{1}{props{2}};

% Read process and check available channels
userData = get(handles.figure1, 'UserData');
if(isempty(userData)), userData = struct(); end;

if isempty(procID)
    allChannelIndex=1:numel(userData.MD.channels_);
else
    allChannelIndex = find(userData.MD.processes_{procID}.checkChannelOutput);
end

% Set up available channels listbox
if ~isempty(allChannelIndex)
    if isempty(procID)
        channelString = userData.MD.getChannelPaths(allChannelIndex);
    else
        channelString = userData.MD.processes_{procID}.outFilePaths_(1,allChannelIndex);
    end
else
    channelString = {};
end
set(handles.listbox_availableTrackChannels,'String',channelString,'UserData',allChannelIndex);

% Set up selected channels listbox
channelIndex = get(handles.listbox_selectedTrackChannels, 'UserData');
channelIndex(~ismember(channelIndex,allChannelIndex)) = [];%So that indices may repeat, and handles empty better than intersect
if ~isempty(channelIndex)
    if isempty(procID)
        channelString = userData.MD.getChannelPaths(channelIndex);
    else
        channelString = userData.MD.processes_{procID}.outFilePaths_(1,channelIndex);
    end
else
    channelString = {};
    channelIndex = [];%Because the intersect command returns a 0x1 instead of 0x0 which causes concatenation errors
end
set(handles.listbox_selectedTrackChannels,'String',channelString,'UserData',channelIndex);


% --- Executes during object creation, after setting all properties.
function popupmenu_TrackProcessIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_TrackProcessIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_availableDetectChannels.
function listbox_availableDetectChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_availableDetectChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_availableDetectChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_availableDetectChannels


% --- Executes during object creation, after setting all properties.
function listbox_availableDetectChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_availableDetectChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_detect_all.
function checkbox_detect_all_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_detect_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_detect_all
contents1 = get(handles.listbox_availableDetectChannels, 'String');

chanIndex1 = get(handles.listbox_availableDetectChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedDetectChannels, 'Userdata');

% Return if listbox1 is empty
if isempty(contents1)
    return;
end

switch get(hObject,'Value')
    case 1
        set(handles.listbox_selectedDetectChannels, 'String', contents1);
        chanIndex2 = chanIndex1;
    case 0
        set(handles.listbox_selectedDetectChannels, 'String', {}, 'Value',1);
        chanIndex2 = [ ];
end
set(handles.listbox_selectedDetectChannels, 'UserData', chanIndex2);


% --- Executes on button press in pushbutton_detect_select.
function pushbutton_detect_select_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_detect_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents1 = get(handles.listbox_availableDetectChannels, 'String');
contents2 = get(handles.listbox_selectedDetectChannels, 'String');
id = get(handles.listbox_availableDetectChannels, 'Value');

% If channel has already been added, return;
chanIndex1 = get(handles.listbox_availableDetectChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedDetectChannels, 'Userdata');

for i = id

        contents2{end+1} = contents1{i};
        
        chanIndex2 = cat(2, chanIndex2, chanIndex1(i));

end

set(handles.listbox_selectedDetectChannels, 'String', contents2, 'Userdata', chanIndex2);


% --- Executes on button press in pushbutton_detect_delete.
function pushbutton_detect_delete_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_detect_delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call back function of 'delete' button
contents = get(handles.listbox_selectedDetectChannels,'String');
id = get(handles.listbox_selectedDetectChannels,'Value');

% Return if list is empty
if isempty(contents) || isempty(id)
    return;
end

% Delete selected item
contents(id) = [ ];

% Delete userdata
chanIndex2 = get(handles.listbox_selectedDetectChannels, 'Userdata');
chanIndex2(id) = [ ];
set(handles.listbox_selectedDetectChannels, 'Userdata', chanIndex2);

% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (id >length(contents) && id>1)
    set(handles.listbox_selectedDetectChannels,'Value',length(contents));
end
% Refresh listbox
set(handles.listbox_selectedDetectChannels,'String',contents);


% --- Executes on selection change in listbox_selectedDetectChannels.
function listbox_selectedDetectChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_selectedDetectChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_selectedDetectChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_selectedDetectChannels


% --- Executes during object creation, after setting all properties.
function listbox_selectedDetectChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_selectedDetectChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_detect_up.
function pushbutton_detect_up_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_detect_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call back of 'Up' button

id = get(handles.listbox_selectedDetectChannels,'Value');
contents = get(handles.listbox_selectedDetectChannels,'String');


% Return if list is empty
if isempty(contents) || isempty(id) || id == 1
    return;
end

temp = contents{id};
contents{id} = contents{id-1};
contents{id-1} = temp;

chanIndex = get(handles.listbox_selectedDetectChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id-1);
chanIndex(id-1) = temp;

set(handles.listbox_selectedDetectChannels, 'String', contents, 'Userdata', chanIndex);
set(handles.listbox_selectedDetectChannels, 'value', id-1);


% --- Executes on button press in pushbutton_detect_down.
function pushbutton_detect_down_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_detect_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

id = get(handles.listbox_selectedDetectChannels,'Value');
contents = get(handles.listbox_selectedDetectChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == length(contents)
    return;
end

temp = contents{id};
contents{id} = contents{id+1};
contents{id+1} = temp;

chanIndex = get(handles.listbox_selectedDetectChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id+1);
chanIndex(id+1) = temp;

set(handles.listbox_selectedDetectChannels, 'string', contents, 'Userdata',chanIndex);
set(handles.listbox_selectedDetectChannels, 'value', id+1);


% --- Executes on selection change in popupmenu_DetectProcessIndex.
function popupmenu_DetectProcessIndex_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_DetectProcessIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_DetectProcessIndex contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_DetectProcessIndex

% Retrieve selected process ID
props= get(handles.popupmenu_DetectProcessIndex,{'UserData','Value'});
procID = props{1}{props{2}};

% Read process and check available channels
userData = get(handles.figure1, 'UserData');
if(isempty(userData)), userData = struct(); end;

if isempty(procID)
    allChannelIndex=1:numel(userData.MD.channels_);
else
    allChannelIndex = find(userData.MD.processes_{procID}.checkChannelOutput);
end

% Set up available channels listbox
if ~isempty(allChannelIndex)
    if isempty(procID)
        channelString = userData.MD.getChannelPaths(allChannelIndex);
    else
        channelString = userData.MD.processes_{procID}.outFilePaths_(1,allChannelIndex);
    end
else
    channelString = {};
end
set(handles.listbox_availableDetectChannels,'String',channelString,'UserData',allChannelIndex);

% Set up selected channels listbox
channelIndex = get(handles.listbox_selectedDetectChannels, 'UserData');
channelIndex(~ismember(channelIndex,allChannelIndex)) = [];%So that indices may repeat, and handles empty better than intersect
if ~isempty(channelIndex)
    if isempty(procID)
        channelString = userData.MD.getChannelPaths(channelIndex);
    else
        channelString = userData.MD.processes_{procID}.outFilePaths_(1,channelIndex);
    end
else
    channelString = {};
    channelIndex = [];%Because the intersect command returns a 0x1 instead of 0x0 which causes concatenation errors
end
set(handles.listbox_selectedDetectChannels,'String',channelString,'UserData',channelIndex);


% --- Executes during object creation, after setting all properties.
function popupmenu_DetectProcessIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_DetectProcessIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_ROItypes.
function popupmenu_ROItypes_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_ROItypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_ROItypes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_ROItypes


% --- Executes during object creation, after setting all properties.
function popupmenu_ROItypes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_ROItypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_nSample_Callback(hObject, eventdata, handles)
% hObject    handle to edit_nSample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_nSample as text
%        str2double(get(hObject,'String')) returns contents of edit_nSample as a double


% --- Executes during object creation, after setting all properties.
function edit_nSample_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_nSample (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_fringe_Callback(hObject, eventdata, handles)
% hObject    handle to edit_fringe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_fringe as text
%        str2double(get(hObject,'String')) returns contents of edit_fringe as a double


% --- Executes during object creation, after setting all properties.
function edit_fringe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_fringe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_availableChannels.
function listbox_availableChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_availableChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_availableChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_availableChannels


% --- Executes during object creation, after setting all properties.
function listbox_availableChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_availableChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_all.
function checkbox_all_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_all


% --- Executes on button press in pushbutton_select.
function pushbutton_select_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton_delete.
function pushbutton_delete_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in listbox_selectedChannels.
function listbox_selectedChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_selectedChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_selectedChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_selectedChannels


% --- Executes during object creation, after setting all properties.
function listbox_selectedChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_selectedChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% functions Add by user:
% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
% Key: name of the key that was pressed, in lower case
% Character: character interpretation of the key(s) that was pressed
% Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_done (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
% Key: name of the key that was pressed, in lower case
% Character: character interpretation of the key(s) that was pressed
% Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end