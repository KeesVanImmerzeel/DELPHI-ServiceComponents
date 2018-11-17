unit SelectAdoSetDialog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, USelectAdoSetDialog, AdoSets;

type
  TSelectAdoSetDialog = Class(TOpenDialog)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    Constructor Create( AOwner: TComponent ); Override;
    function Execute( SetType: TSetType; MaxNrOfSelectedSets: Integer;
                      ShowSelection: Boolean;
                      var SetNames: TStringList ): Boolean; reintroduce;
  published
    { Published declarations }
  end;

  TSelectRealAdoSetDialog = Class(TSelectAdoSetDialog)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    function Execute( MaxNrOfSelectedSets: Integer; ShowSelection: Boolean;
                      var SetNames: TStringList ): Boolean; reintroduce;
  published
    { Published declarations }
  end;

  TSelectIntegerAdoSetDialog = Class(TSelectAdoSetDialog)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    function Execute( MaxNrOfSelectedSets: Integer; ShowSelection: Boolean;
                      var SetNames: TStringList ): Boolean; reintroduce;
  published
    { Published declarations }
  end;

Const
 cAdoFilterIndex = 1;
 cAcoFilterIndex = 2;
 cFloFilterIndex = 3;
 cTeoFilterIndex = 4;
 casdShowSelectedAdoSets     = True;
 casdDontShowSelectedAdoSets = False;

procedure Register;

implementation

Constructor TSelectAdoSetDialog.Create( AOwner: TComponent );
begin
  Inherited Create( AOwner );
  DefaultExt  := 'ado';
  FileName    := 'FileName.ado';
  FilterIndex := 1;
  Filter      := '*.ado|*.ado|*.aco|*.aco|*.flo|*.flo|*.teo|*.teo|*.grd|*.grd' +
                 '|*.*|*.*';
  Options     := [ofReadOnly,ofPathMustExist,ofFileMustExist,ofShareAware,
                  ofEnableSizing];
  Title       := 'Select Ado-file';
end;

Function TSelectAdoSetDialog.Execute( SetType: TSetType;
         MaxNrOfSelectedSets: Integer; ShowSelection: Boolean;
         var SetNames: TStringList ): Boolean;
var
  Res: Boolean;
  i, SelCount: Integer;
  TryAnotherFile: Word;
  MaxNrOfSelectedSetsStr: String;
begin
  Res := False;
  TryAnotherFile := mrYes;
  while ( TryAnotherFile = mrYes ) do begin
    if Inherited Execute then begin {Er is een bestand geselecteerd}
      if ExtractSetNamesFromTextFile( FileName, SetType, SetNames )then begin
        {Als 1 of meer set-namen gevonden in bestand}
        TryAnotherFile := mrNo;

        AdoSetsForm := TAdoSetsForm.Create( Self );
        with AdoSetsForm do begin

          {Prepare form***********}
          case SetType of
            RealSet: Caption := 'Real ' + Caption;
            IntegerSet: Caption := 'Integer ' + Caption;
            Unknown:;
          end; {case}
          Caption := Caption + ' "' + FileName + '"';
          LB.Clear;
          LB.Items.AddStrings( SetNames );

          {Default: select 1 set}
          LB.Enabled             := true;
          GroupBoxSelectionInfo.Visible := False;
          LB.MultiSelect         := False;

          if ( MaxNrOfSelectedSets <= 0 ) then begin
            LB.Enabled := false;
            BCancelButton.Visible := False;
            BSelectButton.Caption := 'Ok';
          end else if ( MaxNrOfSelectedSets = 1 ) then begin
          end else begin
            with LB do begin
              MultiSelect := true;
              ExtendedSelect := true;
            end;
            Str( MaxNrOfSelectedSets, MaxNrOfSelectedSetsStr );
            with MaxSelectLabel do begin
              Caption := Caption + MaxNrOfSelectedSetsStr;
            end;
            with SelectedLabel do begin
              Caption := Caption + '0';
            end;
            GroupBoxSelectionInfo.Visible := True;
          end;
          {End Prepare form***********}

          SelCount := 0;
          if ( ShowModal = mrOK ) then begin {Er is OK-geklikt}

            {Nu kijken hoeveel sets er zijn geselecteerd en deze setnamen
             toevoegen aan SetNames}
            if ( MaxNrOfSelectedSets > 0 ) then begin
              SetNames.Clear;
              for i := 0 to LB.Items.Count - 1 do begin
                if LB.Selected[ i ] then begin
                  if ( SelCount < MaxNrOfSelectedSets ) then begin
                    SetNames.Add( LB.Items[ i ] );
                    Inc( SelCount );
                  end;
                end;
              end;
            end;

            if ( SelCount > 0 ) then begin {Er is ok-gedrukt en geselecteerd}

              Res := True; {Het eindresultaat:}

              if ShowSelection then begin
                {Laat resultaat van de selectie zien}
                if ( SelCount = 1 ) then begin
                  MessageDlg( 'Selected Ado-set:' + #13 +
                          '"' + SetNames[ 0 ] + '"',
                          mtInformation, [mbOk], 0);
                end else begin
                  Caption := 'Selected Ado-Set(s).';
                  with LB do begin
                    Items.Clear;
                    Items.AddStrings( SetNames );
                    Enabled := false;
                  end;
                  BSelectButton.Caption := 'Ok';
                  BCancelButton.Visible := False;
                  SelectedLabel.Caption := 'Selected:      ' +
                                           IntToStr( SelCount );
                  ShowModal;
                end;
              end; {if ShowSelection}

            end else; {Er is ok-gedrukt en niet geselecteerd}

          end else begin {Er is cancel gedrukt}
          end;
        end; {with AdoSetsForm}

      end else begin {if ExtractSetNamesFromTextFile; geen ado-set gevonden}

        TryAnotherFile:= MessageDlg( 'No valid Ado-sets present in this file.' +
                          #13 + 'Select another file?' , mtConfirmation,
                          [mbYes,mbNo], 0);

      end;

    end else begin {if Inherited Execute; er is geen bestand geselecteerd}
      TryAnotherFile := mrNo;
    end;
  end; {while ( TryAnotherFile = mrYes )}

  if ( ( MaxNrOfSelectedSets > 0 ) and ( not Res ) ) then
    MessageDlg( 'No Ado-set selected' , mtInformation, [mbOk], 0);

  Execute := Res;
end;

Function TSelectRealAdoSetDialog.Execute( MaxNrOfSelectedSets: Integer;
         ShowSelection: Boolean; var SetNames: TStringList ): Boolean;
begin
  Execute := Inherited Execute( RealSet, MaxNrOfSelectedSets, ShowSelection,
                                SetNames );
end;

Function TSelectIntegerAdoSetDialog.Execute( MaxNrOfSelectedSets: Integer;
         ShowSelection: Boolean; var SetNames: TStringList ): Boolean;
begin
  Execute := Inherited Execute( IntegerSet, MaxNrOfSelectedSets, ShowSelection,
                                SetNames );
end;

procedure Register;
begin
  RegisterComponents('MyComponents', [TSelectAdoSetDialog]);
  RegisterComponents('MyComponents', [TSelectRealAdoSetDialog]);
  RegisterComponents('MyComponents', [TSelectIntegerAdoSetDialog]);
end;

end.
