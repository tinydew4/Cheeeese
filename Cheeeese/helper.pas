unit helper;

{$mode objfpc}{$H+}

interface

uses
  DwmApi,
  Forms,
  Graphics,
  IdExplicitTLSClientServerBase,
  IdMessage,
  IdSMTP,
  IdSSLOpenSSL,
  JwaWinGDI,
  SysUtils,
  Windows;

function ScaleXTo(const SizeX, ToDPI: Integer): Integer;
function ScaleYTo(const SizeY, ToDPI: Integer): Integer;
function GetWindowRect(Handle: HWND; var lpRect: TRect): Boolean;
function CopyDesktop(Image: TPNGImage; MaxWidth, MaxHeight: Int32): Boolean;
procedure SaveToFile(Image: TPNGImage; FileName: string);
function MakeSMTP(AHost: string; APort: UInt16; AUseTLS: TIdUseTLS; AUsername, APassword: string): TIdSMTP;
function Sendmail(AHost: string; APort: UInt16; AUseTLS: TIdUseTLS; AUsername, APassword: string; Message: TIdMessage): Boolean;

implementation

function ScaleXTo(const SizeX, ToDPI: Integer): Integer;
begin
  Result := MulDiv(SizeX, ToDPI, ScreenInfo.PixelsPerInchX * 100 div 96);
end;

function ScaleYTo(const SizeY, ToDPI: Integer): Integer;
begin
  Result := MulDiv(SizeY, ToDPI, ScreenInfo.PixelsPerInchY * 100 div 96);
end;

function GetWindowRect(Handle: HWND; var lpRect: TRect): Boolean;
begin
  Result := (DwmGetWindowAttribute(Handle, DWMWA_EXTENDED_FRAME_BOUNDS, @lpRect, SizeOf(lpRect)) = S_OK);
  if not Result then begin
    Result := Windows.GetWindowRect(Handle, lpRect);
  end;
end;

function CopyDesktop(Image: TPNGImage; MaxWidth, MaxHeight: Int32): Boolean;
var
  hSubject: HWND;
  hSubjectDC: HDC;
begin
  if Image = nil then Exit(False);

  hSubject := GetDesktopWindow;

  Image.Width := Min(ScaleXTo(Screen.DesktopWidth, 100), MaxWidth);
  Image.Height := Min(ScaleYTo(Screen.DesktopHeight, 100), MaxHeight);
  Image.Canvas.FillRect(0, 0, Image.Width, Image.Height);

  hSubjectDC := GetDC(hSubject);
  try
    BitBlt(Image.Canvas.Handle, 0, 0, Image.Width, Image.Height,
      hSubjectDC, ScaleXTo(Screen.DesktopLeft, 100), ScaleYTo(Screen.DesktopTop, 100), SRCCOPY or CAPTUREBLT);
    Result := True;
  finally
    ReleaseDC(hSubject, hSubjectDC);
  end;
end;

procedure SaveToFile(Image: TPNGImage; FileName: string);
begin
  ForceDirectories(ExtractFilePath(FileName));
  if Image <> nil then begin
    Image.SaveToFile(FileName);
  end else begin
    FileClose(FileCreate(FileName));
  end;
end;

function MakeSMTP(AHost: string; APort: UInt16; AUseTLS: TIdUseTLS; AUsername, APassword: string): TIdSMTP;
begin
  Result := TIdSMTP.Create(nil);
  try
    if AUseTLS <> utNoTLSSupport then begin
      Result.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(Result);
    end;
    Result.Host := AHost;
    Result.Port := APort;
    Result.UseTLS := AUseTLS;
    Result.Username := AUsername;
    Result.Password := APassword;
  except
    FreeAndNil(Result);
  end;
end;

function Sendmail(AHost: string; APort: UInt16; AUseTLS: TIdUseTLS; AUsername, APassword: string; Message: TIdMessage): Boolean;
begin
  Result := False;
  with MakeSMTP(AHost, APort, AUseTLS, AUsername, APassword) do
  try
    Connect;
    Send(Message);
    Result := True;
  finally
    Free;
  end;
end;

initialization
  InitDwmLibrary;

end.

