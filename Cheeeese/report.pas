unit report;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  Graphics,
  IdExplicitTLSClientServerBase,
  IdMessage,
  IdMessageBuilder, // typhon/components/pl_indy
  SysUtils,
  helper;

procedure Report(Host, Username, Password: string; ImageStream: TStream);
procedure ReportDesktop(Host, Username, Password, HistoryPath: string);

procedure ReportDesktop(Config: TStrings);

implementation

procedure Report(Host, Username, Password: string; ImageStream: TStream);
var
  IdMessage: TIdMessage;
  iPos: Int32;
  Port: UInt16;
begin
  iPos := Pos(':', Host);
  if iPos > 0 then begin
    Port := StrToIntDef(RightStr(Host, Length(Host) - iPos), 25);
    Host := LeftStr(Host, iPos - 1);
  end else begin
    Port := 25;
  end;

  IdMessage := TIdMessage.Create;
  try
    IdMessage.From.Address := Username;
    IdMessage.From.Name := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
    IdMessage.ReplyTo.EMailAddresses := IdMessage.From.Address;
    IdMessage.Recipients.EMailAddresses := Username;
    IdMessage.Subject := FormatDateTime('[yyyy-mm-dd hh:nn] ', Now) + IdMessage.From.Name;

    with TIdMessageBuilderHtml.Create do
    try
      if ImageStream <> nil then begin
        Html.Add('<img src="cid:desktop" />');
        HtmlFiles.Add(ImageStream, 'image/png', 'desktop');
      end else begin
        IdMessage.Subject := '[FAILED] ' + IdMessage.Subject;
        Html.Add('<div>Failed to capture</div>');
      end;
      FillMessage(IdMessage);
    finally
      Free;
    end;

    Sendmail(Host, Port, TIdUseTLS(Port <> 25), Username, Password, IdMessage);
  finally
    IdMessage.Free;
  end;
end;

procedure ReportDesktop(Host, Username, Password, HistoryPath: string);
var
  ImageStream: TStream;
  Image: TPNGImage;
begin
  Image := TPNGImage.Create;
  try
    try
      if CopyDesktop(Image, MaxInt, MaxInt) then begin
        ImageStream := TMemoryStream.Create;
        try
          Image.SaveToStream(ImageStream);
          Report(Host, Username, Password, ImageStream);
        finally
          ImageStream.Free;
        end;
      end else begin
        Image.Assign(nil);
        Report(Host, Username, Password, nil);
      end;
    except
      SaveToFile(Image, HistoryPath + FormatDateTime('yyyymmdd_hhnnss', Now) + '.png');
    end;
  finally
    Image.Free;
  end;
end;

procedure ReportDesktop(Config: TStrings);
begin
  ReportDesktop(Config.Values['Host'], Config.Values['Username'], Config.Values['Password'], Config.Values['HistoryPath']);
end;

end.

