unit SpinFloat;

interface
uses Windows, Classes, StdCtrls, ExtCtrls, Controls, Messages, SysUtils,
  Forms, Graphics, Menus, Buttons, Spin, dutils;

type
  TSpinFloatEdit = class(TCustomEdit)
  private
    FMinValue: Double;
    FMaxValue: Double;
    FValue : double;
    FIncrement: Double;
    FDecimals : Longint;
    FButton: TSpinButton;
    FEditorEnabled: Boolean;
    function GetMinHeight: Integer;
    function GetValue: Double;
    function CheckValue (NewValue: Double): Double;
    procedure SetValue (NewValue: Double);
    Procedure SetDecimals(NewValue : LongInt);
    procedure SetMinValue(NewValue : double);
    procedure SetMaxValue(NewValue : double);
    procedure SetEditRect;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure CMExit(var Message: TCMExit);   message CM_EXIT;
    procedure CMEnter(var Message: TCMGotFocus); message CM_ENTER;
    procedure WMPaste(var Message: TWMPaste);   message WM_PASTE;
    procedure WMCut(var Message: TWMCut);   message WM_CUT;
  protected
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function IsValidChar(Key: Char): Boolean; virtual;
    function IsValidKey(Key : word) : boolean; virtual;
    procedure UpClick (Sender: TObject); virtual;
    procedure DownClick (Sender: TObject); virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    Procedure Resolve;
    property Button: TSpinButton read FButton;
  published
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property Color;
    property Constraints;
    property Ctl3D;
    property Decimals : LongInt read FDecimals write SetDecimals;
    property DragCursor;
    property DragMode;
    property EditorEnabled: Boolean read FEditorEnabled write FEditorEnabled default True;
    property Enabled;
    property Font;
    property Increment: Double read FIncrement write FIncrement;
    property MaxLength;
    property MaxValue: Double read FMaxValue write SetMaxValue;
    property MinValue: Double read FMinValue write SetMinValue;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Value: Double read GetValue write SetValue;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
  end;

procedure Register;

implementation

{ TSpinFloatEdit }
uses Math, RHSystem;

procedure Register;
begin
  RegisterComponents('MyComponents', [TSpinFloatEdit]);
end;

constructor TSpinFloatEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FButton := TSpinButton.Create (Self);
  FButton.Width := 15;
  FButton.Height := 17;
  FButton.Visible := True;
  FButton.Parent := Self;
  FButton.FocusControl := Self;
  FButton.OnUpClick := UpClick;
  FButton.OnDownClick := DownClick;
  FDecimals:= 1;
  Text := RealToStrDec(0.0, FDecimals);
  FValue:= 0;
  ControlStyle := ControlStyle - [csSetCaption];
  FIncrement := 1;
  FEditorEnabled := True;
end;

destructor TSpinFloatEdit.Destroy;
begin
  FButton := nil;
  inherited Destroy;
end;

procedure TSpinFloatEdit.GetChildren(Proc: TGetChildProc; Root: TComponent);
begin
end;

procedure TSpinFloatEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  with FormatSettings do begin {-Delphi XE6}

  if Key = VK_UP then UpClick(Self)
  else if Key = VK_DOWN then DownClick(Self)
  else if Key = VK_DECIMAL then KeyPress(DecimalSeparator)
  else if IsValidKey(Key) then
  begin
    inherited KeyDown(Key, Shift);
    if Assigned(OnChange) then OnChange(self);
  end
  else
  begin
    Key:= 0;
  end;

  end; {-Delphi XE6}
end;

procedure TSpinFloatEdit.KeyPress(var Key: Char);
begin

  with FormatSettings do begin {-Delphi XE6}

  if IsValidChar(Key) then
  begin
    Inherited KeyPress(Key);
    if Assigned(OnChange) then OnChange(self);
  end
  else if ((Key = ',') and (DecimalSeparator = '.'))
       or ((Key = '.') and (DecimalSeparator = ',')) then
  begin
    Key:= DecimalSeparator;
    Inherited KeyPress(Key);
    if Assigned(OnChange) then OnChange(self);
  end
  else
  begin
    Key := #0;
    MessageBeep(0)
  end;

  end; {-Delphi XE6}
end;

function TSpinFloatEdit.IsValidChar(Key: Char): Boolean;
begin
  with FormatSettings do begin {-Delphi XE6}

  Result := (Key in [DecimalSeparator, '+', '-', '0'..'9']) or
    ((Key < #32) and (Key <> Chr(VK_RETURN)));
  if not FEditorEnabled and Result and ((Key >= #32) or
      (Key = Char(VK_BACK)) or (Key = Char(VK_DELETE))) then
    Result := False;

  end; {-Delphi XE6}
end;

Function TSpinFloatEdit.IsValidKey(Key : word) : boolean;
begin
  with FormatSettings do begin {-Delphi XE6}

  Result:= (Key >= Ord('0')) AND (Key <= Ord('9'))
           or ((Key >= VK_NUMPAD0) AND (Key <= VK_NUMPAD9))
           or ((Key = 188) AND (DecimalSeparator = ','))
           or ((Key = 190) AND (DecimalSeparator = '.'));

  end; {-Delphi XE6}
end;

procedure TSpinFloatEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
{  Params.Style := Params.Style and not WS_BORDER;  }
  Params.Style := Params.Style or ES_MULTILINE or WS_CLIPCHILDREN;
end;

procedure TSpinFloatEdit.CreateWnd;
begin
  inherited CreateWnd;
  SetEditRect;
end;

procedure TSpinFloatEdit.SetEditRect;
var
  Loc: TRect;
begin
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));
  Loc.Bottom := ClientHeight + 1;  {+1 is workaround for windows paint bug}
  Loc.Right := ClientWidth - FButton.Width - 2;
  Loc.Top := 0;
  Loc.Left := 0;
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@Loc));
  SendMessage(Handle, EM_GETRECT, 0, LongInt(@Loc));  {debug}
end;

procedure TSpinFloatEdit.WMSize(var Message: TWMSize);
var
  MinHeight: Integer;
begin
  inherited;
  MinHeight := GetMinHeight;
    { text edit bug: if size to less than minheight, then edit ctrl does
      not display the text }
  if Height < MinHeight then
    Height := MinHeight
  else if FButton <> nil then
  begin
    if NewStyleControls and Ctl3D then
      FButton.SetBounds(Width - FButton.Width - 5, 0, FButton.Width, Height - 5)
    else FButton.SetBounds (Width - FButton.Width, 1, FButton.Width, Height - 3);
    SetEditRect;
  end;
end;

function TSpinFloatEdit.GetMinHeight: Integer;
var
  DC: HDC;
  SaveFont: HFont;
  I: Integer;
  SysMetrics, Metrics: TTextMetric;
begin
  DC := GetDC(0);
  GetTextMetrics(DC, SysMetrics);
  SaveFont := SelectObject(DC, Font.Handle);
  GetTextMetrics(DC, Metrics);
  SelectObject(DC, SaveFont);
  ReleaseDC(0, DC);
  I := SysMetrics.tmHeight;
  if I > Metrics.tmHeight then I := Metrics.tmHeight;
  Result := Metrics.tmHeight + I div 4 + GetSystemMetrics(SM_CYBORDER) * 4 + 2;
end;

procedure TSpinFloatEdit.UpClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := FValue + FIncrement;
end;

procedure TSpinFloatEdit.DownClick (Sender: TObject);
begin
  if ReadOnly then MessageBeep(0)
  else Value := FValue - FIncrement;
end;

procedure TSpinFloatEdit.WMPaste(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
  if Assigned(OnChange) then OnChange(self);
end;

procedure TSpinFloatEdit.WMCut(var Message: TWMPaste);
begin
  if not FEditorEnabled or ReadOnly then Exit;
  inherited;
end;

Function DecRound(Value : double; Dec : Longint) : Double;
begin
  Result:= Value;
  if Dec > 0 then
    Result:= Power(10, Dec) * Result;
  Result:= round(Result);
  if Dec > 0 then
    Result:= Result / Power(10, Dec);
end;

procedure TSpinFloatEdit.CMExit(var Message: TCMExit);
var V : double;
begin
  V:= StrToReal(Text);
  if DecRound(FValue, FDecimals) <> V then
    SetValue(CheckValue(V));
  inherited;
  if Assigned(OnChange) then OnChange(self);
end;

Procedure TSpinFloatEdit.Resolve;
var V : double;
begin
  V:= StrToReal(Text);
  if DecRound(FValue, FDecimals) <> V then
    SetValue(CheckValue(V));
  inherited;
  if Assigned(OnChange) then OnChange(self);
end;

Procedure TSpinFloatEdit.SetDecimals(NewValue : LongInt);
begin
  if (FDecimals <> NewValue) and (NewValue >= 0) then
  begin
    FDecimals:= NewValue;
    Text := RealToStrDec(FValue, FDecimals);
  end;
end;

function TSpinFloatEdit.GetValue: Double;
begin
  try
    Result := FValue;
  except
    Result := FMinValue;
  end;
end;

procedure TSpinFloatEdit.SetValue (NewValue: Double);
begin
  FValue:= CheckValue(NewValue);
  Text := RealToStrDec(FValue, FDecimals);
end;

function TSpinFloatEdit.CheckValue (NewValue: Double): double;
begin
  Result := NewValue;
  if (FMaxValue <> FMinValue) then
  begin
    if NewValue < FMinValue then
      Result := FMinValue
    else if NewValue > FMaxValue then
      Result := FMaxValue;
  end;
end;

procedure TSpinFloatEdit.SetMinValue(NewValue : double);
begin
  if (FMinValue <> NewValue) and (NewValue < FMaxValue) then
  begin
    FMinValue:= NewValue;
    Value:= CheckValue(FValue);
  end;
end;

procedure TSpinFloatEdit.SetMaxValue(NewValue : double);
begin
  if (FMaxValue <> NewValue) and (NewValue > FMinValue) then
  begin
    FMaxValue:= NewValue;
    Value:= CheckValue(FValue);
  end;
end;

procedure TSpinFloatEdit.CMEnter(var Message: TCMGotFocus);
begin
  if AutoSelect and not (csLButtonDown in ControlState) then
    SelectAll;
  inherited;
end;

end.
