{

this unit using for download file, dependent with decryptFile.dll in res folder (copy paste to your project folder / see demo project) 
adapted and modified from Projeto-TInject writen by mikelustosa
origininal source https://github.com/mikelustosa/Projeto-TInject/blob/master/Source/Model/uInjectDecryptFile.pas

}

unit wbot_decrypt_file;

interface

uses Classes, ExtCtrls, fphttpclient, Shellapi, UrlMon, Windows;

type
  TWbot_Decrypt_File = class(TComponent)
  private
    function DownLoadInternetFile(Source, Dest: string): Boolean;
    procedure DownloadFile(Source, Dest: string);
    function shell(program_path:  string):  string;
    function idUnique(id: string): string;
   public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function download(clientUrl, mediaKey, tipo, id: string) :string;
  end;

implementation

uses
  StrUtils, SysUtils, Forms;

{ TImagem }

constructor TWbot_Decrypt_File.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TWbot_Decrypt_File.Destroy;
begin
  inherited;
end;

procedure TWbot_Decrypt_File.DownloadFile(Source, Dest: String);
var
  IdHTTP1 : TFPHTTPClient;
  Stream  : TMemoryStream;
  Url, FileName: String;
begin
  IdHTTP1 := TFPHTTPClient.Create(nil);
  Stream  := TMemoryStream.Create;
  try
    IdHTTP1.Get(Source, Stream);
    Stream.SaveToFile(Dest);
  finally
    Stream.Free;
    IdHTTP1.Free;
  end;
end;

function TWbot_Decrypt_File.DownLoadInternetFile(Source, Dest: String): Boolean;
var ret:integer;
begin
  try
    ret:=URLDownloadToFile(nil, PChar(Source), PChar(Dest), 0, nil);
    if ret <> 0 then
    begin
      DownloadFile(Source, Dest) ;
      if FileExists(dest) then
        ret :=  0;
    end;

    Result := ret = 0
  except
    Result := False;
  end;
end;

function TWbot_Decrypt_File.idUnique(id: string): String;
var
  gID: TGuid;
begin
  CreateGUID(gID);
  result := copy(gID.ToString, 2, length(gID.ToString)  - 2);
end;

function TWbot_Decrypt_File.download(clientUrl, mediaKey, tipo, id: string): string;
var
  form, imagem, diretorio, arq:string;
begin
  Result    :=  '';
  diretorio := ExtractFilePath(ParamStr(0)) + 'download\';
  Sleep(1);

  if not DirectoryExists(diretorio) then
    CreateDir(diretorio);

  arq     :=  idUnique(id);
  imagem  :=  diretorio + arq;
  Sleep(1);

  if DownLoadInternetFile(clientUrl, imagem + '.enc') then
    if FileExists(imagem  + '.enc') then
    begin
        form  :=  format('--in %s.enc --out %s.%s --key %s',  [imagem,  imagem, tipo, mediakey]);
        shell(form);
        Sleep(10);
        Result:= imagem + '.' + tipo;
    end;
end;

function TWbot_Decrypt_File.Shell(program_path: string): string;
var
  s1: string;
begin
  s1 := ExtractFilePath(Application.ExeName)+'decryptFile.dll ';
  ShellExecute(0, nil, 'cmd.exe', PChar('/c '+ s1 + program_path ), PChar(s1 + program_path), SW_HIDE);
end;

end.
