program wbotdemo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, 
  //WBot
  WBot_Config,
  umain
  { you can add units after this };

{$R *.res}

begin
  
    try
    if (CreateGlobalCEFApp) then
    begin
      RequireDerivedFormResource:=True;
	  Application.Scaled:=True;
      Application.Initialize;
      Application.CreateForm(TForm1, Form1);
      Application.Run;
    end;
  finally
    DestroyGlobalCEFApp;
  end;
  
end.

