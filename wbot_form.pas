{
 _    _  _         _____
| |  | || |       |_   _|   /|
| |  | || |___  ___ | |    / |__
| |/\| ||  _  |/ _ \| |   /_   /
| /  \ || (_) | (_) | |     | /
|__/\__||_____|\___/|_|     |/

}
unit WBot_Form;

{$i wbot.inc}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  LResources,
  // CEF
  uCEFWindowParent, uCEFChromium, uCEFTypes, uCEFInterfaces, uCEFApplication,
  // WBot
  WBot_Const, WBot_Utils, WBot_Model;

type

  { TWBotForm }

  TWBotForm = class(TForm)
    ChromiumWindow: TCEFWindowParent;
    Chromium: TChromium;
    QrCodeImg: TImage;
    StatusBar: TStatusBar;
    TimerConnect: TTimer;
    TimerMonitoring: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);  
    procedure FormShow(Sender: TObject);  
    procedure OnTimerConnect(Sender: TObject);
    procedure OnTimerMonitoring(Sender: TObject);
    procedure ChromiumConsoleMessage(Sender: TObject;
      const {%H-}ABrowser: ICefBrowser; {%H-}ALevel: TCefLogSeverity;
      const AMessage, {%H-}ASource: ustring; {%H-}ALine: Integer;
      out {%H-}AResult: Boolean);
    procedure ChromiumTitleChange(Sender: TObject;
      const {%H-}ABrowser: ICefBrowser; const {%H-}ATitle: ustring);
  private
    FAuthenticated: boolean;
    FConected: boolean;
    FBrowser: Boolean;
    FStep: NativeInt;
    FZoom: NativeInt;
    FLastQrCode: string; 
    FMonitorBattery: boolean;
    FMonitorUnreadMsgs: boolean;
    FOnError: TErrorEvent;
    FOnNotification: TNotificationEvent;
  private
    procedure SetZoom(const AValue: NativeInt);
  protected
    procedure CheckCEFApp;
    procedure InternalNotification(const AAction: TActionType;
      const AData: string = '');
    procedure InternalError(const AError: string;
      const AAdditionalInformation: string);
    procedure ExecuteScript(const AScript: string;
      const ADirect: boolean = False);
  protected
    procedure ProcessQrCode(const AData: string);  
    procedure Logout;
  public   
    procedure Connect;
    procedure Disconnect(const ALogout: boolean = False);
  public
    procedure GetQrCode;
    procedure GetBatteryLevel; 
    procedure GetUnreadMessages;  
    procedure GetAllContacts; 
    procedure GetAllGroups;
    procedure ReadMsg(const ANumber: String);
    procedure SendContact(const ANumber, AContact: string);
    procedure SendMsg(const ANumber, AMsg: string);
    procedure SendMsgBase64(const ANumber, AMsg, AFileName, ACaption: string);
  public
    property Conected: boolean read FConected;
    property Authenticated: boolean read FAuthenticated;
    property Browser: Boolean read FBrowser write FBrowser;
    property MonitorBattery: boolean
      read FMonitorBattery write FMonitorBattery;
    property MonitorUnreadMsgs: boolean
      read FMonitorUnreadMsgs write FMonitorUnreadMsgs;   
    property OnError: TErrorEvent read FOnError write FOnError;
    property OnNotification: TNotificationEvent
      read FOnNotification write FOnNotification;
  end;

var
  WBotForm: TWBotForm;

implementation

uses 

{$IF FPC_FullVersion >= 30200}
opensslsockets,
{$IFEND}
fphttpclient;

{$R *.lfm}

{ TWBotForm }

function Download(URL: String; AStream: TStream; out AErrMsg: String): Boolean;
begin
  AErrMsg := '';
  with TFpHttpClient.Create(nil) do
    try
      try
        AllowRedirect := true;
        Get(URL, AStream);
        AStream.Position := 0;
        Result := true;
      except
        on E:EHTTPClient do begin
          AErrMsg := E.Message;
          Result := false;
        end;
      end;
    finally
      Free;
    end;
end;

function StreamToString(const AStream: TStream): String;
begin
  Result := '';
  with TStringStream.Create() do
  try
    LoadFromStream(AStream);
    Result := DataString;
  finally
    Free;
  end;
end;

procedure TWBotForm.FormCreate(Sender: TObject);
begin
  Chromium.DefaultUrl := WBOT_WHATSAPP;
  FConected := False;
  FAuthenticated := False;
  FBrowser := True;
  FStep := 0;
  FZoom := 1;
  FLastQrCode := EmptyStr;
  FMonitorBattery := True;
  FMonitorUnreadMsgs := True;
  FOnError := nil;
  FOnNotification:= nil;
end;

procedure TWBotForm.FormDestroy(Sender: TObject);
begin
  InternalNotification(atDestroy);
end;          

procedure TWBotForm.FormShow(Sender: TObject);
begin
  Caption := WBOT_NAME + ' - ' + WBOT_VERSION;
  StatusBar.SimpleText := EmptyStr;
  ChromiumWindow.Visible := False;
  QrCodeImg.Visible := False;
  if (FBrowser) then
  begin                      
    ChromiumWindow.Visible := True;
  end
  else
  begin                            
    QrCodeImg.Visible := True;
    StatusBar.SimpleText := QRCODE_LOADING;
  end;
end;

procedure TWBotForm.OnTimerConnect(Sender: TObject);
var
  VStatus: boolean;
  VScript: string;
  Stream: TMemoryStream;
  Err: String;
  URL : String = 'https://raw.githubusercontent.com/mikelustosa/Projeto-TInject/master/Source/JS/js.abr';  
begin
  TimerConnect.Enabled := False;
  VStatus := True;
  try
    if (FAuthenticated) then
    begin
	  Stream := TMemoryStream.Create;
	  try
		if not Download(URL, Stream, Err) then
		  ShowMessage('Error: ' + Err);

		Stream.Position := 0;
		VScript := StreamToString(Stream);
	  finally
		Stream.Free;
	  end;                         
      ExecuteScript(VScript, True);
      Sleep(50);
      if (Not(FBrowser)) then
      begin
        Hide;
      end;
      VStatus := False;
      InternalNotification(atInitialized);
    end
    else
    begin
      GetQrCode;
    end;
  finally
    TimerConnect.Enabled := VStatus;
  end;
end;

procedure TWBotForm.OnTimerMonitoring(Sender: TObject);
begin
  TimerMonitoring.Enabled := False;
  try
    if (FAuthenticated) then
    begin
      if (FMonitorBattery) then
      begin
        GetBatteryLevel;
      end;
      if (FMonitorUnreadMsgs) then
      begin
        GetUnreadMessages;
      end;
    end;
  finally
    TimerMonitoring.Enabled := True;
  end;
end;

procedure TWBotForm.ChromiumConsoleMessage(Sender: TObject;
  const ABrowser: ICefBrowser; ALevel: TCefLogSeverity;
  const AMessage, ASource: ustring; ALine: Integer; out AResult: Boolean);
var
  VConsole: TResponseConsole;
  VAction: TActionType;
begin
  {$IfDef wbot_debug}  
  WriteLn(AMessage);
  {$EndIf}
  // Check JSON
  if (Copy(TrimLeft(AMessage), 1, 2) <> '{"') then
  begin
    Exit;
  end;
  VConsole := TResponseConsole.Create;
  try  
    VConsole.LoadJSON(string(AMessage));
    VAction := VConsole.ActionType;
    // Redirect
    case VAction of
      atNone:
      begin
        InternalError(EXCEPT_JS_UNKNOWN, string(AMessage));
      end;  
      atGetQrCode:
      begin
        ProcessQrCode(VConsole.SaveJSON);
        InternalNotification(VAction);
      end;
      else
      begin
        InternalNotification(VAction, VConsole.Result);
      end;
    end;
  finally
    FreeAndNil(VConsole);
  end;
end;

procedure TWBotForm.ChromiumTitleChange(Sender: TObject;
  const ABrowser: ICefBrowser; const ATitle: ustring);
begin
  Inc(FStep);
  if (FStep > 3) and (FStep < 10) and (not(FAuthenticated)) then
  begin
    // Established connection   
    FAuthenticated := True;
    InternalNotification(atConnected);
  end;
  if (FStep <= 3) then
  begin
    SetZoom(-2);
  end;
end;    

procedure TWBotForm.SetZoom(const AValue: NativeInt);
var
  VIndex: NativeInt;
  VZoom: NativeInt;
begin
  if (FZoom <> AValue) then
  begin
    FZoom := AValue;
    Chromium.ResetZoomStep;
    VZoom := (FZoom * (-1));
    for VIndex := 0 to (VZoom - 1) do
    begin
      Chromium.DecZoomStep;
    end;
  end;
end;

procedure TWBotForm.InternalNotification(const AAction: TActionType;
  const AData: string);
begin
  if (Assigned(FOnNotification)) then
  begin
    FOnNotification(Self, AAction, AData);
  end;
end;

procedure TWBotForm.InternalError(const AError: string;
  const AAdditionalInformation: string);
begin
  if (Assigned(FOnError)) then
  begin
    FOnError(Self, AError, AAdditionalInformation);
  end;
end;

procedure TWBotForm.ExecuteScript(const AScript: string;
  const ADirect: boolean);
begin
  CheckCEFApp;  
  if (not (FConected)) and (not (ADirect))  then
  begin
    raise EWBot.Create(EXCEPT_CEF_CONNECT);
  end;
  Chromium.Browser.MainFrame.ExecuteJavaScript(UnicodeString(AScript),
    UnicodeString('about:blank'), 0);
end;

procedure TWBotForm.ProcessQrCode(const AData: string);
var
  VQrCode: TResponseQrCode;
begin
  if (FLastQrCode <> AData) then
  begin                  
    FLastQrCode := AData;
    VQrCode := TResponseQrCode.Create;
    try
      VQrCode.LoadJSON(FLastQrCode);
      QrCodeImg.Picture.Assign(VQrCode.Result.QrCodeImage);
      if (Assigned(QrCodeImg.Picture.Graphic))  and
        (not(QrCodeImg.Picture.Graphic.Empty)) then
      begin
        StatusBar.SimpleText := QRCODE_SUCCESS;
      end;
    finally
      FreeAndNil(VQrCode);
    end;
  end;
end;   

procedure TWBotForm.Logout;
begin
  ExecuteScript(CMD_LOGOUT);
end;

procedure TWBotForm.CheckCEFApp;
begin
  if (not(Assigned(GlobalCEFApp))) or
    (GlobalCEFApp.Status <> asInitialized) then
  begin
    raise EWBot.Create(EXCEPT_CEF_APP);
  end;
end;

procedure TWBotForm.Connect;
var
  VStart: NativeUInt;
begin
  CheckCEFApp;
  try
    if (not(FConected)) then
    begin
      InternalNotification(atConnecting);
      VStart := GetTickCount64;
      FConected := Chromium.CreateBrowser(ChromiumWindow);
      repeat
        FConected := (Chromium.Initialized);
        if (not (FConected)) then
        begin
          Sleep(10);
          Application.ProcessMessages;
          if ((GetTickCount64 - VStart) > 20000) then
          begin
            Break;
          end;
        end;
      until FConected;
    end;
  finally                                
    TimerConnect.Enabled := FConected;
    TimerMonitoring.Enabled := FConected;
    if (FConected) then
    begin
      Chromium.OnConsoleMessage := @ChromiumConsoleMessage;
      Chromium.OnTitleChange := @ChromiumTitleChange;
      Chromium.Reload;
      Show;
    end
    else
    begin
      InternalNotification(atDisconnected);
      raise EWBot.Create(EXCEPT_CEF_CONNECT);
    end;
  end;
end;

procedure TWBotForm.Disconnect(const ALogout: boolean);
begin
  if (not(FConected)) then
  begin
    Exit;
  end;
  try
    if (ALogout) then
    begin
      Logout;
      Sleep(50);
    end;
    TimerConnect.Enabled := False;
    TimerMonitoring.Enabled := False;
    Chromium.StopLoad;
    //Chromium.CloseBrowser(True);
    Sleep(600);
    FStep := 0;     
    FLastQrCode := EmptyStr; 
    FAuthenticated:= False;
    FConected := False;     
    Hide;
    InternalNotification(atDisconnected);
  except
  end;
end;

procedure TWBotForm.GetQrCode;
begin
  if (not(FBrowser)) then
  begin
    ExecuteScript(CMD_GET_QRCODE);
  end;
end;

procedure TWBotForm.GetBatteryLevel;
begin                                  
  ExecuteScript(CMD_GET_BATTERY_LEVEL);
end;

procedure TWBotForm.GetUnreadMessages;
begin
  ExecuteScript(CMD_GET_UNREAD_MESSAGES);
end;

procedure TWBotForm.GetAllContacts;
begin
  ExecuteScript(CMD_GET_ALL_CONTACTS);
end;

procedure TWBotForm.GetAllGroups;
begin
  ExecuteScript(CMD_GET_ALL_GROUPS);
end;

procedure TWBotForm.ReadMsg(const ANumber: String);
var
  VScript: string;
begin
  VScript := CMD_READ_MSG;
  VScript := ReplaceVAR(VScript, '<#PHONE#>', ANumber);
  ExecuteScript(VScript);
end;

procedure TWBotForm.SendContact(const ANumber, AContact: string);
var
  VScript: string;
begin
  VScript := CMD_SEND_CONTACT;
  VScript := ReplaceVAR(VScript, '<#PHONE#>', ANumber);
  VScript := ReplaceVAR(VScript, '<#CONTACT#>', AContact);
  ExecuteScript(VScript);
end;

procedure TWBotForm.SendMsg(const ANumber, AMsg: string);
var
  VScript: string;
begin
  VScript := CMD_SEND_MSG;
  VScript := ReplaceVAR(VScript, '<#PHONE#>', ANumber);
  VScript := ReplaceVAR(VScript, '<#MSG#>', AMsg);
  ExecuteScript(VScript);
end;

procedure TWBotForm.SendMsgBase64(const ANumber, AMsg, AFileName,
  ACaption: string);    
var
  VScript: string;
begin
  VScript := CMD_SEND_MSG_BASE64; 
  VScript := ReplaceVAR(VScript, '<#PHONE#>', ANumber);
  VScript := ReplaceVAR(VScript, '<#MSG#>', AMsg); 
  VScript := ReplaceVAR(VScript, '<#FILENAME#>', AFileName);
  VScript := ReplaceVAR(VScript, '<#CAPTION#>', ACaption);
  ExecuteScript(VScript);
end;

end.
