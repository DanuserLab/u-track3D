function varargout = RenderFullMIPProcessGUI(varargin)
%RENDERFULLMIPPROCESSGUI MATLAB code file for RenderFullMIPProcessGUI.fig
%      RENDERFULLMIPPROCESSGUI, by itself, creates a new RENDERFULLMIPPROCESSGUI or raises the existing
%      singleton*.
%
%      H = RENDERFULLMIPPROCESSGUI returns the handle to a new RENDERFULLMIPPROCESSGUI or the handle to
%      the existing singleton*.
%
%      RENDERFULLMIPPROCESSGUI('Property','Value',...) creates a new RENDERFULLMIPPROCESSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to RenderFullMIPProcessGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      RENDERFULLMIPPROCESSGUI('CALLBACK') and RENDERFULLMIPPROCESSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in RENDERFULLMIPPROCESSGUI.M with the given input
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

% Edit the above text to modify the response to help RenderFullMIPProcessGUI

% Last Modified by GUIDE v2.5 25-Oct-2019 14:35:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RenderFullMIPProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @RenderFullMIPProcessGUI_OutputFcn, ...
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


% --- Executes just before RenderFullMIPProcessGUI is made visible.
function RenderFullMIPProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin) 
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

if isequal(userData.procConstr, @RenderDynROIMIPProcess)
  % Set up available Build Dyn ROI channels
  set(handles.listbox_availableDynROIChannels,'String',userData.MD.getChannelPaths(), ...
      'UserData',1:numel(userData.MD.channels_));

  DynROIChannelIndex = funParams.buildDynROIProcessChannel;

  if ~isempty(DynROIChannelIndex)
      DynROIChannelString = userData.MD.getChannelPaths(DynROIChannelIndex);
  else
      DynROIChannelString = {};
  end
  set(handles.listbox_selectedDynROIChannels,'String',DynROIChannelString,...
      'UserData',DynROIChannelIndex);


  %Setup Build Dyn ROI process list box
  DynROIProc =  cellfun(@(x) isa(x,'BuildDynROIProcess'),userData.MD.processes_);
  DynROIProcID=find(DynROIProc);
  DynROIProcNames = cellfun(@(x) x.getName(),userData.MD.processes_(DynROIProc),'Unif',false);
  DynROIProcString = vertcat('Choose later',DynROIProcNames(:));
  DynROIProcData=horzcat({[]},num2cell(DynROIProcID));
  DynROIProcValue = find(cellfun(@(x) isequal(x,funParams.processBuildDynROI),userData.MD.processes_(DynROIProc)));
  if isempty(DynROIProcValue)
      DynROIProcValue = 1; 
  else
      DynROIProcValue = DynROIProcValue+1; 
  end
  set(handles.popupmenu_BuildDynROIProcessIndex,'String',DynROIProcString,...
      'UserData',DynROIProcData,'Value',DynROIProcValue);

  % Update channels listboxes depending on the selected process
  popupmenu_BuildDynROIProcessIndex_Callback(hObject, eventdata, handles)
else
  uipanel_DynROIProc_posi = get(handles.uipanel_DynROIProc, 'Position');
  hgtDiff = uipanel_DynROIProc_posi(4) + 7;  
  delete(handles.uipanel_DynROIProc);
  set(handles.uipanel_1,'position', (get(handles.uipanel_1,'position') - [0 hgtDiff 0 0]))
  set(handles.uipanel_2,'position', (get(handles.uipanel_2,'position') - [0 hgtDiff 0 0]))
  set(handles.text_processName,'position', (get(handles.text_processName,'position') - [0 hgtDiff 0 0]));
  set(handles.axes_help,'position', (get(handles.axes_help,'position') - [0 hgtDiff 0 0]));
  set(handles.text_copyright,'position', (get(handles.text_copyright,'position') - [0 hgtDiff 0 0]));
  set(handles.figure1, 'Position', (get(handles.figure1,'position') - [0 -100 0 hgtDiff])); 
end


set(handles.edit_renderFramesFrom, 'String',num2str(funParams.renderFrames(1)))
set(handles.edit_renderFramesTo, 'String',num2str(funParams.renderFrames(end)))
    
% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = RenderFullMIPProcessGUI_OutputFcn(hObject, eventdata, handles) 
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

if isnan(str2double(get(handles.edit_renderFramesFrom, 'String'))) ...
    || isnan(str2double(get(handles.edit_renderFramesTo, 'String'))) ...
    || str2double(get(handles.edit_renderFramesFrom, 'String')) < 0 ...
    || str2double(get(handles.edit_renderFramesTo, 'String')) < 0 ...
    || str2double(get(handles.edit_renderFramesFrom, 'String')) > str2double(get(handles.edit_renderFramesTo, 'String'))
  errordlg('Please provide a valid input for ''The frames to be renderered ''.','Setting Error','modal');
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

if isequal(userData.procConstr, @RenderDynROIMIPProcess)
  %Get selected DynROI channels
  DynROIChannelProps = get(handles.listbox_selectedDynROIChannels, {'Userdata','String'});
  funParams.buildDynROIProcessChannel = DynROIChannelProps{1};
  % Retrieve Build Dyn ROI process
  props=get(handles.popupmenu_BuildDynROIProcessIndex,{'UserData','Value'});
  DynROIProcessIndex = props{1}{props{2}};
  if ~isempty(DynROIProcessIndex)
    funParams.processBuildDynROI = userData.MD.processes_{DynROIProcessIndex};
  else 
    funParams.processBuildDynROI = [];
  end
end

renderFramesFrom = str2double(get(handles.edit_renderFramesFrom, 'String'));
renderFramesTo = str2double(get(handles.edit_renderFramesTo, 'String'));
funParams.renderFrames = renderFramesFrom : renderFramesTo;

% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);



% --- Executes on button press in checkbox_applytoall.
function checkbox_applytoall_Callback(hObject, eventdata, handles) 
% hObject    handle to checkbox_applytoall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_applytoall



function edit_renderFramesTo_Callback(hObject, eventdata, handles)
% hObject    handle to edit_renderFramesTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_renderFramesTo as text
%        str2double(get(hObject,'String')) returns contents of edit_renderFramesTo as a double


% --- Executes during object creation, after setting all properties.
function edit_renderFramesTo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_renderFramesTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_renderFramesFrom_Callback(hObject, eventdata, handles)
% hObject    handle to edit_renderFramesFrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_renderFramesFrom as text
%        str2double(get(hObject,'String')) returns contents of edit_renderFramesFrom as a double


% --- Executes during object creation, after setting all properties.
function edit_renderFramesFrom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_renderFramesFrom (see GCBO)
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
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_done (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on selection change in listbox_availableDynROIChannels.
function listbox_availableDynROIChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_availableDynROIChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_availableDynROIChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_availableDynROIChannels


% --- Executes during object creation, after setting all properties.
function listbox_availableDynROIChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_availableDynROIChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_DynROI_all.
function checkbox_DynROI_all_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_DynROI_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_DynROI_all
contents1 = get(handles.listbox_availableDynROIChannels, 'String');

chanIndex1 = get(handles.listbox_availableDynROIChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedDynROIChannels, 'Userdata');

% Return if listbox1 is empty
if isempty(contents1)
    return;
end

switch get(hObject,'Value')
    case 1
        set(handles.listbox_selectedDynROIChannels, 'String', contents1);
        chanIndex2 = chanIndex1;
    case 0
        set(handles.listbox_selectedDynROIChannels, 'String', {}, 'Value',1);
        chanIndex2 = [ ];
end
set(handles.listbox_selectedDynROIChannels, 'UserData', chanIndex2);

% --- Executes on button press in pushbutton_DynROI_select.
function pushbutton_DynROI_select_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_DynROI_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents1 = get(handles.listbox_availableDynROIChannels, 'String');
contents2 = get(handles.listbox_selectedDynROIChannels, 'String');
id = get(handles.listbox_availableDynROIChannels, 'Value');

% If channel has already been added, return;
chanIndex1 = get(handles.listbox_availableDynROIChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedDynROIChannels, 'Userdata');

for i = id

        contents2{end+1} = contents1{i};
        
        chanIndex2 = cat(2, chanIndex2, chanIndex1(i));

end

set(handles.listbox_selectedDynROIChannels, 'String', contents2, 'Userdata', chanIndex2);


% --- Executes on button press in pushbutton_DynROI_delete.
function pushbutton_DynROI_delete_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_DynROI_delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call back function of 'delete' button
contents = get(handles.listbox_selectedDynROIChannels,'String');
id = get(handles.listbox_selectedDynROIChannels,'Value');

% Return if list is empty
if isempty(contents) || isempty(id)
    return;
end

% Delete selected item
contents(id) = [ ];

% Delete userdata
chanIndex2 = get(handles.listbox_selectedDynROIChannels, 'Userdata');
chanIndex2(id) = [ ];
set(handles.listbox_selectedDynROIChannels, 'Userdata', chanIndex2);

% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (id >length(contents) && id>1)
    set(handles.listbox_selectedDynROIChannels,'Value',length(contents));
end
% Refresh listbox
set(handles.listbox_selectedDynROIChannels,'String',contents);


% --- Executes on selection change in listbox_selectedDynROIChannels.
function listbox_selectedDynROIChannels_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_selectedDynROIChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_selectedDynROIChannels contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_selectedDynROIChannels


% --- Executes during object creation, after setting all properties.
function listbox_selectedDynROIChannels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_selectedDynROIChannels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_DynROI_up.
function pushbutton_DynROI_up_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_DynROI_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call back of 'Up' button

id = get(handles.listbox_selectedDynROIChannels,'Value');
contents = get(handles.listbox_selectedDynROIChannels,'String');


% Return if list is empty
if isempty(contents) || isempty(id) || id == 1
    return;
end

temp = contents{id};
contents{id} = contents{id-1};
contents{id-1} = temp;

chanIndex = get(handles.listbox_selectedDynROIChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id-1);
chanIndex(id-1) = temp;

set(handles.listbox_selectedDynROIChannels, 'String', contents, 'Userdata', chanIndex);
set(handles.listbox_selectedDynROIChannels, 'value', id-1);


% --- Executes on button press in pushbutton_DynROI_down.
function pushbutton_DynROI_down_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_DynROI_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

id = get(handles.listbox_selectedDynROIChannels,'Value');
contents = get(handles.listbox_selectedDynROIChannels,'String');

% Return if list is empty
if isempty(contents) || isempty(id) || id == length(contents)
    return;
end

temp = contents{id};
contents{id} = contents{id+1};
contents{id+1} = temp;

chanIndex = get(handles.listbox_selectedDynROIChannels, 'Userdata');
temp = chanIndex(id);
chanIndex(id) = chanIndex(id+1);
chanIndex(id+1) = temp;

set(handles.listbox_selectedDynROIChannels, 'string', contents, 'Userdata',chanIndex);
set(handles.listbox_selectedDynROIChannels, 'value', id+1);


% --- Executes on selection change in popupmenu_BuildDynROIProcessIndex.
function popupmenu_BuildDynROIProcessIndex_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_BuildDynROIProcessIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_BuildDynROIProcessIndex contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_BuildDynROIProcessIndex

% Retrieve selected process ID
props= get(handles.popupmenu_BuildDynROIProcessIndex,{'UserData','Value'});
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
set(handles.listbox_availableDynROIChannels,'String',channelString,'UserData',allChannelIndex);

% Set up selected channels listbox
channelIndex = get(handles.listbox_selectedDynROIChannels, 'UserData');
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
set(handles.listbox_selectedDynROIChannels,'String',channelString,'UserData',channelIndex);


% --- Executes during object creation, after setting all properties.
function popupmenu_BuildDynROIProcessIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_BuildDynROIProcessIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
