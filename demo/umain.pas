unit umain;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
ExtCtrls, StrUtils, WBot_Core, WBot_Model, WBot_Utils, wbot_decrypt_file;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ContactListBox: TListBox;
    GroupListBox: TListBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    LStatus: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Memo3: TMemo;
    WBot1: TWBot;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ContactListBoxDblClick(Sender: TObject);
    procedure GroupListBoxDblClick(Sender: TObject);
    procedure WBot1Connected(Sender: TObject);
    procedure WBot1Disconnected(Sender: TObject);
    procedure WBot1RequestChat(const ASender: TObject;
      const AChats: TResponseChat);
    procedure WBot1RequestContact(const ASender: TObject;
      const AContacts: TResponseContact);
    procedure WBot1RequestGroups(const ASender: TObject;
      const AGroups: TResponseGroups);
  private

    procedure AutoRespon(AFoneId, AMsg: String);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

function ExtractBetween(const AValue, ADelimiterA, ADelimiterB: string): string;
var
  VPositonA: NativeInt;
  VPositonB: NativeInt;
begin
  Result := EmptyStr;
  VPositonA := Pos(ADelimiterA, AValue);
  if (VPositonA > 0) then
  begin
    VPositonA := VPositonA + Length(ADelimiterA);
    VPositonB := PosEx(ADelimiterB, AValue, VPositonA);
    if (VPositonB > 0) then
    begin
      Result := Copy(AValue, VPositonA, VPositonB-VPositonA);
    end;
  end;
end;

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
    if (WBot1.Conected) then
  begin
    WBot1.Disconnect;
  end
  else
  begin
    WBot1.Browser := True;
    WBot1.Connect;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
    if WBot1.Conected then
  begin
    WBot1.GetAllContacts;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
    if WBot1.Conected then
  begin
    WBot1.GetAllGroups;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
    if WBot1.Conected then
  begin
    WBot1.SendMsg(Edit3.Text, NormalizeString(Memo2.Text));
  end;
end;

procedure TForm1.ContactListBoxDblClick(Sender: TObject);
begin
  Edit3.Text:= ExtractBetween(ContactListBox.GetSelectedText, '(', ')');
end;

procedure TForm1.GroupListBoxDblClick(Sender: TObject);
var
  VText: string;
  VIndex: NativeInt;
begin
  VText := GroupListBox.GetSelectedText;
  VIndex := Pos('@g.us', VText);
  if (VIndex > 0) then
  begin
    Edit3.Text := Copy(VText, 0, Pos('@g.us', VText) + 5);
  end;
end;

procedure TForm1.WBot1Connected(Sender: TObject);
begin
  LStatus.Color:=clGreen;
  LStatus.Caption:='Connected';
end;

procedure TForm1.WBot1Disconnected(Sender: TObject);
begin
  LStatus.Color:=clRed;
  LStatus.Caption:='Disconnected';
end;

procedure TForm1.WBot1RequestChat(const ASender: TObject;
  const AChats: TResponseChat);
var
  VChat: TChat;
  VMsg: TMessage;
  WbotDecrypt: TWbot_Decrypt_File;
begin
  for VChat in AChats.Result do
  begin
    if (Assigned(VChat)) and (not(VChat.IsGroup)) then
    //if (Assigned(VChat)) then
    begin
      for VMsg in VChat.Messages do
      begin
        if (Assigned(VMsg)) and (not(VMsg.Sender.IsMe)) then
        begin
          Edit1.Text:=VChat.Contact.Id;
          Edit2.Text:=VChat.Contact.Name;
          Memo1.Text:=VMsg.Content;
          // Auto Respon
          if (CheckBox1.Checked=True) then
          begin
            AutoRespon(Edit1.Text, Memo1.Text);
          end;
          // End Auto Respon
          // Download File
          case AnsiIndexStr(UpperCase(VMsg.&type), ['PTT', 'IMAGE', 'VIDEO', 'AUDIO', 'DOCUMENT']) of
              0: begin WbotDecrypt.download(VMsg.deprecatedMms3Url, VMsg.mediaKey, 'mp3', VMsg.Id); end;
              1: begin WbotDecrypt.download(VMsg.deprecatedMms3Url, VMsg.mediaKey, 'jpg', VMsg.id); end;
              2: begin WbotDecrypt.download(VMsg.deprecatedMms3Url, VMsg.mediaKey, 'mp4', VMsg.id); end;
              3: begin WbotDecrypt.download(VMsg.deprecatedMms3Url, VMsg.mediaKey, 'mp3', VMsg.id); end;
              4: begin WbotDecrypt.download(VMsg.deprecatedMms3Url, VMsg.mediaKey, 'pdf', VMsg.id); end;
            end;
          // End Download File
          WBot1.ReadMsg(VChat.Contact.Id);
        end;
      end;
    end;
  end;

end;

procedure TForm1.WBot1RequestContact(const ASender: TObject;
  const AContacts: TResponseContact);
Var
  VContact: TContact;
begin
  for VContact in AContacts.Result do
  begin
    if (Assigned(VContact)) then
    begin
      ContactListBox.Items.Add(VContact.Name + ' (' + VContact.Id +')');
    end;
  end;
end;

procedure TForm1.WBot1RequestGroups(const ASender: TObject;
  const AGroups: TResponseGroups);
begin
  GroupListBox.Items.Assign(AGroups.Result);
end;

procedure TForm1.AutoRespon(AFoneId, AMsg: String);
begin
  WBot1.ReadMsg(AFoneId);
  // Send Auto Respon Message if Sender say Hello
  if (AMsg='Hello') then
  begin
    WBot1.SendMsg(AFoneId, NormalizeString(Memo3.Text));
  end;

end;

end.

