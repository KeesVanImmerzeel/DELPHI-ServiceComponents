unit USelectAdoSetDialog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, CheckLst, ExtCtrls, Buttons;

type
  TAdoSetsForm = class(TForm)
    LB: TListBox;
    BSelectButton: TBitBtn;
    BCancelButton: TBitBtn;
    GroupBoxSelectionInfo: TGroupBox;
    SelectedLabel: TLabel;
    MaxSelectLabel: TLabel;
    procedure LBClick(Sender: TObject);
    procedure LBEnter(Sender: TObject);
    procedure LBDblClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AdoSetsForm: TAdoSetsForm;

implementation

{$R *.DFM}

procedure TAdoSetsForm.LBClick(Sender: TObject);
var SelCountStr: String;
begin
  if LB.MultiSelect then begin
    Str( LB.SelCount, SelCountStr );
  end else begin
    if ( lb.ItemIndex >= 0 ) then
      SelCountStr := '1';
  end;
  SelectedLabel.Caption := 'Selected:      ' + SelCountStr;
end;

procedure TAdoSetsForm.LBEnter(Sender: TObject);
begin
  LB.ItemIndex := 0;
end;

procedure TAdoSetsForm.LBDblClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TAdoSetsForm.FormDestroy(Sender: TObject);
begin
  LB.Items.Clear;
  ModalResult := mrCancel;
end;

procedure TAdoSetsForm.FormPaint(Sender: TObject);
begin
if LB.MultiSelect then
    LB.Hint := 'Hold shift and double-click to select ado-sets.'
  else
    LB.Hint := 'Double-click to select ado-set.'
end;

end.


