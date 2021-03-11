unit _fmmain;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  ExtCtrls,
  Forms,
  SysUtils,
  report;

type

  { TfmMain }

  TfmMain = class(TForm)
    TmReport: TTimer;
    procedure TmReportTimer(Sender: TObject);
  private
  public
  end;

var
  fmMain: TfmMain;

implementation

{$R *.frm}

function LoadConfigFromFile(Config: TStrings; FileName: string): Boolean;
begin
  if not FileExists(FileName) then Exit(False);

  Config.LoadFromFile(FileName);

  if Length(Config.Values['Host']) = 0 then Exit(False);
  if Length(Config.Values['Username']) = 0 then Exit(False);
  if Length(Config.Values['Password']) = 0 then Exit(False);

  Config.Values['HistoryPath'] := ExtractFilePath(ParamStr(0)) + 'history\';

  Result := True;
end;

{ TfmMain }

procedure TfmMain.TmReportTimer(Sender: TObject);
var
  Timer: TTimer;
  Config: TStrings;
begin
  if not (Sender is TTimer) then Exit;

  Timer := Sender as TTimer;
  if not Timer.Enabled then Exit;

  Timer.Enabled := False;
  try
    Config := TStringList.Create;
    try
      if not LoadConfigFromFile(Config, ChangeFileExt(ParamStr(0), '.config')) then Exit;

      Timer.Interval := StrToIntDef(Config.Values['Interval'], 600000);
      ReportDesktop(Config);
    finally
      Config.Free;
    end;
  finally
    Timer.Enabled := True;
  end;
end;

end.

