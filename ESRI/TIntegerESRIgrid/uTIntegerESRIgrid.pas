unit uTIntegerESRIgrid;

interface

uses
  SysUtils, Classes,
  ShpAPI129, uTabstractESRIgrid;

type
  PIntegerESRIgrid = ^TIntegerESRIgrid;

  TIntegerESRIgrid = Class(TAbstractESRIgrid)
  Private { private method cannot be called from another module, and a private field or property cannot be read or written to
      from another module. Het gaat meestal om methods die de fysieke gegevensopslag (variabelen) gebruiken of initiëren }
    IntegerMatrix: Array of Array of Integer;
    { -Private override functions/procedures }
    Function AllocateMyMemory(const iNRows, iNCols: Integer): Boolean; Override;
    Procedure DeAllocateMyMemory; Override;
    Function GetNRows: Integer; Override;
    Function GetNCols: Integer; Override;
    Function GetCellType: Integer; Override; { cCELLINT = 1; cCELLFLOAT = 2 }
    Function GetCellMemorySize: Integer; Override;
    Function GetMatrixMemorySize: Integer; Override;
    Procedure AddValueFieldToPointShape(hDBFHandle: DBFHandle); Override;
    Procedure WriteValueToPointShape(hDBFHandle: DBFHandle;
      const Count, RowNr, ColNr: Integer); Override;
    Function SHPCreateObjectFromValue(const RowNr, ColNr: Integer;
      padfX, padfY, padfM: PDouble): PShpObject; Override;
    Function PtrToAmatrixCell(const RowNr, ColNr: Integer): Pointer; Override;
    Function PtrToMatrix: Pointer; Override;
    Function GetWindowRowFromChannel(const Channel, RowNr: Integer): Boolean; Override;
    Function PutWindowRowToChannel( const Channel, RowNr: Integer ): Boolean; Override;
    {-Leest regel uit ASC file. Getallen vh type 'floating point' worden met 'Trunc' naar integer omgezet}
    Function ReadRowFromTextFile( var f: TextFile; const RowNr: Integer;
      const ASCNoDataValue: Double ): Boolean; Override;
    Procedure WriteElementToASC(var f: TextFile;
      const Row, Col: Integer); Override;
    Procedure WriteMissingValueToLogFile; Override;
  Protected { Members that are intended for use only in the implementation of derived classes are usually protected. }
  Public { A public member is visible wherever its class can be referenced. }
    Function IsMissing(const RowNr, ColNr: Integer): Boolean; Override;
    Constructor Clone( const aIntegerESRIgrid: TIntegerESRIgrid; const NewName: String;
      var iResult: Integer; AOwner: TComponent); Virtual;

    { -Overige Public functies/procedures }
    Function GetValue(const Row, Col: Integer): Integer; Virtual;
    Procedure SetValue(const Row, Col: Integer; const Value: Integer); Virtual;
    Function GetValueXY(const x, y: Single): Integer; Virtual;
    { -Retreive value at the closest cell to x, y to a maximum distance of MaxCellDepth cells }
    Procedure GetValueNearXY(const x, y: Single; const MaxCellDepth: Integer;
      var CellDepth: Integer; var aValue: Integer); Virtual;
    Function AreaSum(const AreaGrid: PIntegerESRIgrid;
      const MinAreaValue, MaxAreaValue, MinValue, MaxValue: Integer;
      var AreaOfSelectedCells, SumOfValuesInArea,
      AverageOfValuesInArea: Double): Boolean; Virtual;
    Procedure AddConstant(const x: Integer); Virtual;
    Procedure SetToConstantValue(const x: Integer); Virtual;
    Procedure MultiplyBy(const x: Integer); Virtual;
    { -Public properties }
    Property Items[const Row, Col: Integer]: Integer read GetValue
      write SetValue; Default;

  Published { Used to display properties in the Object Inspector }
  end;

  E_Error_Initialising_TIntegerESRIgrid_Descendant_From_File = class(Exception);

Resourcestring
  sE_Error_Initialising_TIntegerESRIgrid_Descendant_From_File =
    'Error initialising TSingleESRIgrid (descendant) from file [%s].';

procedure Register;

implementation

uses
  Dialogs, Math,
  uError, AVGRIDIO;

{ -TSingleESRIgrid: private methods--------------------------------------------- }

{ -Private override functions/procedures }

Function TIntegerESRIgrid.AllocateMyMemory(const iNRows,
  iNCols: Integer): Boolean;
begin
  Result := true;
  Try
    SetLength(IntegerMatrix, iNRows, iNCols);
  except
    Result := false;
  End;
end;

Procedure TIntegerESRIgrid.DeAllocateMyMemory;
begin
  SetLength(IntegerMatrix, 0, 0);
end;

Function TIntegerESRIgrid.GetNRows: Integer;
begin
  Result := High(IntegerMatrix) + 1;
end;

Function TIntegerESRIgrid.GetNCols: Integer;
begin
  Result := High(IntegerMatrix[0]) + 1;
end;

Function TIntegerESRIgrid.GetCellType: Integer; { cCELLINT = 1; cCELLFLOAT = 2 }
begin
  Result := cCELLINT;
end;

Function TIntegerESRIgrid.GetCellMemorySize: Integer;
begin
  Result := SizeOf( Integer );
end;

Function TIntegerESRIgrid.GetMatrixMemorySize: Integer;
begin
  Result := SizeOf( IntegerMatrix )
end;

Function TIntegerESRIgrid.SHPCreateObjectFromValue(const RowNr, ColNr: Integer;
  padfX, padfY, padfM: PDouble): PShpObject;
var
  z: Integer;
  nSHPType: LongInt;
begin
  z := GetValue(RowNr, ColNr);
  nSHPType := SHPT_POINT;
  Result := SHPCreateObject(nSHPType, -1, 0, NIL, NIL, 1, padfX, padfY,
    @z, padfM);
end;

Procedure TIntegerESRIgrid.WriteElementToASC(var f: TextFile;
  const Row, Col: Integer);
var
  z: Integer;
begin
  z := GetValue(Row, Col);
  if IsMissing(Row, Col) then
    z := -9999;
  Write(f, z, ' ');
end;

Procedure TIntegerESRIgrid.WriteMissingValueToLogFile;
begin
  WriteToLogFileFmt( '  MissingInteger = %d', [MISSINGINT] );
end;

Procedure TIntegerESRIgrid.AddValueFieldToPointShape(hDBFHandle: DBFHandle);
begin
  DBFAddField(hDBFHandle, 'Value', FTInteger, 10, 0);
end;

Procedure TIntegerESRIgrid.WriteValueToPointShape(hDBFHandle: DBFHandle;
  const Count, RowNr, ColNr: Integer);
begin
  DBFWriteIntegerAttribute(hDBFHandle, Count, 1, GetValue(RowNr, ColNr));
  // -hDBFHandle, iShape, iField, Fieldvalue
end;

Function TIntegerESRIgrid.PtrToAmatrixCell(const RowNr, ColNr: Integer)
  : Pointer; { Specifiek voor grid-type }
begin
  Result := @IntegerMatrix[RowNr - 1, ColNr - 1];
end;

Function TIntegerESRIgrid.PtrToMatrix: Pointer;
begin
  Result := @IntegerMatrix;
end;

Function TIntegerESRIgrid.GetWindowRowFromChannel(const Channel,
  RowNr: Integer): Boolean;
begin
  Result := True;
  Try
    GetWindowRowInt(Channel, RowNr - 1, IntegerMatrix[RowNr - 1, 0]);
  Except
    {showmessage( Format( 'Error AllocateMatrixRowFromChannel %d rownr %d', [Channel,RowNr] ) );}
    Result := false;
  End;
end;

Function TIntegerESRIgrid.PutWindowRowToChannel( const Channel, RowNr: Integer ): Boolean;
begin
  Result := true;
  Try
    PutWindowRow( Channel, RowNr-1, IntegerMatrix[RowNr - 1, 0] );
  Except
    Result := false;
  End;
end;

{ -TIntegerESRIgrid: public methods--------------------------------------------- }

{ -Public override functions/procedures }

Function TIntegerESRIgrid.IsMissing(const RowNr, ColNr: Integer): Boolean;
begin
  Result := (GetValue(RowNr, ColNr) = MISSINGINT);
end;

Constructor TIntegerESRIgrid.Clone( const aIntegerESRIgrid: TIntegerESRIgrid;
  const NewName: String; var iResult: Integer; AOwner: TComponent);
var
  Row: Integer;
begin
  Create( aIntegerESRIgrid.NRows, aIntegerESRIgrid.NCols, iResult, AOwner );
  if iResult <> cNoError then
  begin
    HandleError( 'Error in "TIntegerESRIgrid.Clone".', true );
    Exit;
  end;
 FileName := NewName;
  for Row := 0 to NRows - 1 do
    IntegerMatrix[Row] := Copy( aIntegerESRIgrid.IntegerMatrix[Row], 0, NCols);
  xMin := xMin;
  xMax := aIntegerESRIgrid.xMax;
  yMin := aIntegerESRIgrid.yMin;
  yMax := aIntegerESRIgrid.yMax;
  CellSize := aIntegerESRIgrid.CellSize;
end;

{ -Other public methods }

Function TIntegerESRIgrid.GetValue(const Row, Col: Integer): Integer;
begin
  Try
    Result := IntegerMatrix[Row - 1, Col - 1];
  Except
    On E: Exception do
    begin
      MessageDlg('Error in "TIntegerESRIgrid.GetValue".', mtError, [mbOk], 0);
    end;
  end;
end;

Procedure TIntegerESRIgrid.SetValue(const Row, Col: Integer;
  const Value: Integer);
begin
  Try
    IntegerMatrix[Row - 1, Col - 1] := Value;
  Except
    On E: Exception do
    begin
      MessageDlg('Error in "TIntegerESRIgrid.SetValue".', mtError, [mbOk], 0);
    end;
  end;
end;

Function TIntegerESRIgrid.GetValueXY(const x, y: Single): Integer;
begin
  Result := MISSINGINT;
  Try
    if IsValidXY(x, y) then
      Result := GetValue(GetRowNrFromYcoord(y), GetColNrFromXcoord(x));
  Except
  end;
end;

Procedure TIntegerESRIgrid.GetValueNearXY(const x, y: Single;
  const MaxCellDepth: Integer; var CellDepth: Integer; var aValue: Integer);
var
  Found: Boolean;
  cRow, cCol, Row, Col: Integer;
begin
  CellDepth := 0;
  aValue := MISSINGINT;
  if IsValidXY(x, y) then
  begin
    aValue := GetValueXY(x, y);
    Found := (aValue <> MISSINGINT);
    if ((not Found) and (MaxCellDepth > 0)) then
    begin
      XYToWindowColRow(x, y, cRow, cCol);
      CellDepth := 1;
      Repeat
        Row := cRow - CellDepth;
        Repeat
          if ((Row > 0) and (Row <= NRows)) then
          begin { -valid Rownr }
            Col := cCol - CellDepth;
            Repeat
              if ((Col > 0) and (Col <= NCols)) then
              begin { -valid Colnr }
                aValue := Items[Row, Col];
                Found := (aValue <> MISSINGINT);
              end; { -if }
              Inc(Col);
            Until ((Found) or (Col > cCol + CellDepth))
          end; { -if }
          Inc(Row);
        until ((Found) or (Row > cRow + CellDepth));
        Inc(CellDepth);
      until ((Found) or (CellDepth > MaxCellDepth));
        CellDepth := min(CellDepth, MaxCellDepth);
    end; { -if }
  end;
end;

Function TIntegerESRIgrid.AreaSum(const AreaGrid: PIntegerESRIgrid;
  const MinAreaValue, MaxAreaValue, MinValue, MaxValue: Integer;
  var AreaOfSelectedCells, SumOfValuesInArea, AverageOfValuesInArea: Double): Boolean;
var
  i, j, k, iNRows, iNCols, aValue: Integer;
  x, y, AreaValue: Single;
begin
  Result := false;
  AreaOfSelectedCells := 0;
  SumOfValuesInArea := 0;
  AverageOfValuesInArea := 0;

  iNRows := NRows;
  iNCols := NCols;
  k := 0;
  for i := 1 to iNRows do
  begin
    for j := 1 to iNCols do
    begin
      GetCellCentre(i, j, x, y);
      if not(AreaGrid^.IsValidXY(x, y)) then
      begin
        HandleErrorFmt( 'Point [%d, %d] is outside area grid', [x, y], false );
        Result := false;
        Exit;
      end;
      AreaValue := AreaGrid^.GetValueXY(x, y);
      if (AreaValue > MinAreaValue) and (AreaValue <= MaxAreaValue) then
      begin
        aValue := GetValue(i, j);
        if (aValue > MinValue) and (aValue <= MaxValue) then
        begin
          Inc(k);
          SumOfValuesInArea := SumOfValuesInArea + aValue;
        end;
      end;
    end;
  end;
  AreaOfSelectedCells := k * CellArea;
  if k > 0 then
    AverageOfValuesInArea := SumOfValuesInArea / k;
  Result := true;
end;

Procedure TIntegerESRIgrid.AddConstant(const x: Integer);
var
  i, j, iNRows, iNCols: Integer;
begin
  iNRows := NRows;
  iNCols := NCols;
  for i := 0 to iNRows - 1 do
    for j := 0 to iNCols - 1 do
      if (IntegerMatrix[i, j] <> MISSINGINT) then
        IntegerMatrix[i, j] := IntegerMatrix[i, j] + x;
end;

Procedure TIntegerESRIgrid.SetToConstantValue(const x: Integer);
var
  i, j, iNRows, iNCols: Integer;
begin
  iNRows := NRows;
  iNCols := NCols;
  for i := 0 to iNRows - 1 do
    for j := 0 to iNCols - 1 do
      if (IntegerMatrix[i, j] <> MISSINGINT) then
        IntegerMatrix[i, j] := x;
end;

Procedure TIntegerESRIgrid.MultiplyBy(const x: Integer);
var
  i, j, iNRows, iNCols: Integer;
begin
  if (x <> 1) then
  begin
    iNRows := NRows;
    iNCols := NCols;
    for i := 0 to iNRows - 1 do
      for j := 0 to iNCols - 1 do
        if (IntegerMatrix[i, j] <> MISSINGINT) then
          IntegerMatrix[i, j] := IntegerMatrix[i, j] * x;
  end;
end;

Function TIntegerESRIgrid.ReadRowFromTextFile( var f: TextFile;
  const RowNr: Integer; const ASCNoDataValue: Double ): Boolean;
var
  j, iNCols: Integer;
  aValue: Double;
begin
  Result := false;
  iNCols := NCols;
  Try
    for j := 0 to iNCols-1 do begin
      Read( f, aValue );
      if ( aValue = ASCNoDataValue ) then
        IntegerMatrix[ RowNr-1, j ] := MISSINGINT
      else
        IntegerMatrix[ RowNr-1, j ] := trunc( aValue );
    end;
    Result := true;
  Except
  End;
end;

procedure Register;
begin
  RegisterComponents('MyComponents', [TIntegerESRIgrid]);
end;


begin
  with FormatSettings do
    begin { -Delphi XE6 }
      Decimalseparator := '.';
    end;
end.
