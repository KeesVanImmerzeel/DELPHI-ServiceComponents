unit uTSingleESRIgrid;

interface

uses
  SysUtils, Classes, Controls, Forms,
  ShpAPI129, uESRI, uTabstractESRIgrid;

type
  PSingleESRIgrid = ^TSingleESRIgrid;
  TSingleMatrix = Array of Array of Single;
  TSingleESRIgrid = Class( TabstractESRIgrid )
  Private { private method cannot be called from another module, and a private field or property cannot be read or written to
            from another module. Het gaat meestal om methods die de fysieke gegevensopslag (variabelen) gebruiken of initiëren }
    SingleMatrix: TSingleMatrix;
    {-Private override functions/procedures}
    Function AllocateMyMemory( const iNRows, iNCols: Integer ): Boolean; Override;
    Procedure DeAllocateMyMemory; Override;
    Function GetNRows: Integer; Override;
    Function GetNCols: Integer; Override;
    Function GetCellType: Integer; Virtual;{cCELLINT = 1; cCELLFLOAT = 2 }
    Function GetCellMemorySize: Integer; Override;
    Function GetMatrixMemorySize: Integer; Override;
    Procedure AddValueFieldToPointShape( hDBFHandle: DBFHandle ); Override;
    Procedure WriteValueToPointShape( hDBFHandle: DBFHandle; const Count, RowNr, ColNr: Integer); Override;
    Function SHPCreateObjectFromValue( const RowNr, ColNr: Integer; padfX, padfY, padfM: PDouble ): PShpObject; Override;
    Function PtrToAmatrixCell( const RowNr, ColNr: Integer ): Pointer; Override;
    Function PtrToMatrix: Pointer; Override;
    Function GetWindowRowFromChannel( const Channel, RowNr: Integer ): Boolean; Override;
    Function PutWindowRowToChannel( const Channel, RowNr: Integer ): Boolean; Override;
    {-Leest regel uit ASC file. Getallen vh type 'integer' worden als 'floating point' gelezen}
    Function ReadRowFromTextFile( var f: TextFile; const RowNr: Integer;
      const ASCNoDataValue: Double ): Boolean; Override;

    Procedure WriteElementToASC( var f: TextFile; const Row, Col: Integer ); Override;
    Procedure WriteMissingValueToLogFile; Override;
      Protected  {Members that are intended for use only in the implementation of derived classes are usually protected.}
    {Override functies/procedures die specifiek zijn voor dit grid-type}

  Public {A public member is visible wherever its class can be referenced.}
    Function IsMissing( const RowNr, ColNr: Integer ): Boolean; Override;
//    Constructor Clone( const aSingleESRIgrid: TSingleESRIgrid; const NewName: String;
//      var iResult: Integer; AOwner: TComponent); Virtual;
//    Constructor Clone( const aAbstractESRIgrid: TabstractESRIgrid; const NewName: String;
//      var iResult: Integer; AOwner: TComponent); Virtual;

    {-Overige Public functies/procedures}
    Function  GetValue( const Row, Col: Integer): Single; Virtual;
    Procedure SetValue( const Row, Col: Integer; const Value: Single ); Virtual;
    Function GetValueXY( const x, y: Single ): Single; Virtual;
      {-Retreive value at the closest cell to x, y to a maximum distance of MaxCellDepth cells }
    Procedure GetValueNearXY( const x, y: Single; const MaxCellDepth: Integer; var CellDepth: Integer; var aValue: Single ); Virtual;
    Function AreaSum( const AreaGrid: PSingleESRIgrid; const MinAreaValue, MaxAreaValue,
             MinValue, MaxValue: Single; var AreaOfSelectedCells, SumOfValuesInArea, AverageOfValuesInArea: Double ): Boolean; Virtual;
    Procedure AddConstant( const x: Single ); Virtual;
    Procedure SetToConstantValue( const x: Single ); Virtual;
    Procedure MultiplyBy( const x: Single ); Virtual;

    Constructor InitialiseFromIDFfile( const iFileName: TFileName;
      var iResult: Integer; AOwner: TComponent ); Virtual;
    Function SaveAsInteger( const iFileName: TFileName ): Integer; Virtual;
    Function ExportToUngPar( const iFileName: TFileName; const newBndBox: TBndBox;
      const Pol: TSingleESRIgrid; {-Knoopafstand in Triwaco (op basis van pol.* files van triwaco-grid)}
      const DataRatio: Double {-Aant. geg. punten per (triwaco) modelknoop (ongeveer)}
       ): Integer; Virtual;
    Function ExportToIDFfile( const iFileName: TFileName ): Integer; Virtual;
    Function FillWithCAPSIMdata( const iFileName, Node_Sim_Inp_file: TFileName ): Boolean; Virtual;
    {-Calculate SumOfValuesInArea, AverageOfValuesInArea, ValuesTimesArea of values in data-set MinValue < Value <= MaxValue
      and MinAreaValue < AreaVale <= MaxAreaValue}

    {-Public properties}
    Property Items[ const Row, Col: Integer ]: Single read GetValue write SetValue; Default;

  Published {Used to display properties in the Object Inspector}

  end;

  E_Error_Initialising_TSingleESRIgrid_Descendant_From_File = class( Exception );
  E_Error_CAPSIM_File_Does_not_exist = class (Exception );
  E_Error_opening_CAPSIM_File = class (Exception );
  E_Error_reading_from_CAPSIM_File = class (Exception );

Resourcestring
  sE_Error_Initialising_TSingleESRIgrid_Descendant_From_File = 'Error initialising TSingleESRIgrid (descendant) from file [%s].';
  sE_Error_CAPSIM_File_Does_not_exist = 'Error: CAPSIM-file [%s] does not exist.';
  sE_Error_opening_CAPSIM_File = 'Error opening CAPSIM-file [%s].';
  sE_Error_reading_from_CAPSIM_File = 'Read-error in line [%d] in CAPSIM-file [%s].';

Const
  IDFmissingSingle = -9999.0;

Function ExtractYearMonthDayFromIDFfilename( const aFileName: String; var year, month, day: Integer ): Boolean;

procedure Register;

implementation

uses
  Dialogs, Math,
  uError, OpWstring, AVGRIDIO;

Function ExtractYearMonthDayFromIDFfilename( const aFileName: String; var year, month, day: Integer ): Boolean;
Const
  WordDelims: CharSet = ['_'];
var
  Len: Integer;
  S, S1: String;
begin
  Result := false;
  Try
    S := ExtractWord( 2, aFileName, WordDelims, Len );
    if ( len = 8 ) then begin
      S1 := copy( S, 1, 4 );
      Year := StrToInt( S1 );
      S1 := copy( S, 5, 2 );
      Month := StrToInt( S1 );
      S1 :=  copy( S, 7, 2 );
      Day := StrToInt( S1 );
    end;
    Result := true;
  except
  end;
end;

{-TSingleESRIgrid: private methods---------------------------------------------}

{-Private override functions/procedures}

Function TSingleESRIgrid.AllocateMyMemory( const iNRows, iNCols: Integer ): Boolean;
//var
//  Len: array[0..1] of Integer;
begin
  Result := true;
  Try
    SetLength( SingleMatrix, iNRows, iNCols );
    //Len[0] := iNCols;
    //Len[1] := iNRows;
    //DynArraySetLength(Pointer(SingleMatrix), TypeInfo(TSingleMatrix), 2, PNativeInt(@len[0]));
  except
    Result := false;
  End;
end;

Procedure TSingleESRIgrid.DeAllocateMyMemory;
begin
  SetLength(SingleMatrix, 0, 0);
end;

Function TSingleESRIgrid.GetNRows: Integer;
begin
  Result := High( SingleMatrix ) + 1;
end;

Function TSingleESRIgrid.GetNCols: Integer;
begin
  Result := High( SingleMatrix[ 0 ] ) + 1;
end;

Function TSingleESRIgrid.GetCellType: Integer; {cCELLINT = 1; cCELLFLOAT = 2 }
begin
  Result := cCELLFLOAT;
end;

Function TSingleESRIgrid.GetCellMemorySize: Integer;
begin
  Result := SizeOf( Single );
end;

Function TSingleESRIgrid.GetMatrixMemorySize: Integer;
begin
  Result := SizeOf( SingleMatrix );
  WriteToLogFileFmt( 'SizeOf( SingleMatrix ) = [%d]', [Result] );
end;

Function TSingleESRIgrid.SHPCreateObjectFromValue( const RowNr, ColNr: Integer; padfX, padfY, padfM: PDouble ): PShpObject;
var
  z: Single;
  zd: Double;
  nSHPType: LongInt;
begin
  z := GetValue( RowNr, ColNr );
  zd := z;
  nSHPType := SHPT_POINT;
  Result := SHPCreateObject( nSHPType, -1, 0, NIL, NIL, 1, padfX, padfY, @zD, padfM );
end;

Procedure TSingleESRIgrid.WriteElementToASC( var f: TextFile; const Row, Col: Integer );
var
  z: Single;
begin
  z := GetValue( Row, Col );
  if IsMissing( Row, Col ) then
    z := -9999;
  Write( f, GetAdoGetal( z ) + ' ' );
end;

Procedure TSingleESRIgrid.WriteMissingValueToLogFile;
begin
  WriteToLogFileFmt( '  MissingSingle = %g', [MissingSingle] );
end;

Procedure TSingleESRIgrid.AddValueFieldToPointShape( hDBFHandle: DBFHandle );
begin
  DBFAddField( hDBFHandle,'Value',FTDouble, 12,6 );
end;

Procedure TSingleESRIgrid.WriteValueToPointShape( hDBFHandle: DBFHandle; const Count, RowNr, ColNr: Integer);
begin
  DBFWriteDoubleAttribute( hDBFHandle, Count, 1, GetValue( RowNr, ColNr ) );     //hDBFHandle, iShape, iField, Fieldvalue
end;

Function TSingleESRIgrid.PtrToAmatrixCell( const RowNr, ColNr: Integer ): Pointer; {Specifiek voor grid-type}
begin
  Result := @SingleMatrix[ RowNr-1, ColNr-1 ];
end;

Function TSingleESRIgrid.PtrToMatrix: Pointer;
begin
  Result := @SingleMatrix;
end;

Function TSingleESRIgrid.GetWindowRowFromChannel( const Channel, RowNr: Integer ): Boolean;
begin
  Result := true;
  Try
    GetWindowRowFloat( Channel, RowNr-1, SingleMatrix[ RowNr-1, 0 ]);
  Except
    {showmessage( Format( 'Error AllocateMatrixRowFromChannel %d rownr %d', [Channel,RowNr] ) );}
    Result := false;
  End;
end;

{-TSingleESRIgrid: public methods---------------------------------------------}

{-Public override functions/procedures}

Function TSingleESRIgrid.IsMissing( const RowNr, ColNr: Integer ): Boolean;
begin
  Result := ( GetValue( RowNr, ColNr ) = MissingSingle );
end;

{Constructor TSingleESRIgrid.Clone( const aAbstractESRIgrid: TabstractESRIgrid; const NewName: String;
      var iResult: Integer; AOwner: TComponent);
var
  Row: Integer;
begin
  Create( aAbstractESRIgrid.NRows, aAbstractESRIgrid.NCols, iResult, AOwner );
  if iResult <> cNoError then begin
    MessageDlg( 'Error in "TSingleESRIgrid.Clone".', mtError, [mbOk], 0);
    Exit;
  end;
  FileName := aAbstractESRIgrid.FileName;
  for Row:=0 to NRows-1 do
    SingleMatrix[ Row ] := Copy( aAbstractESRIgrid.SingleMatrix[ Row ], 0, NCols );
  xMin   := aAbstractESRIgrid.xMin;
  xMax   := aAbstractESRIgrid.xMax;
  yMin   := aAbstractESRIgrid.yMin;
  yMax   := aAbstractESRIgrid.yMax;
  CellSize := aAbstractESRIgrid.CellSize;
end;}

{-Other public methods}

Function TSingleESRIgrid.GetValue( const Row, Col: Integer): Single;
begin
  Try
    Result := SingleMatrix[ Row-1, Col-1 ];
  Except
    On E: Exception do begin
      MessageDlg( 'Error in "TSingleESRIgrid.GetValue".', mtError, [mbOk], 0);
    end;
  end;
end;

Procedure TSingleESRIgrid.SetValue( const Row, Col: Integer; const Value: Single );
begin
  Try
    SingleMatrix[ Row-1, Col-1 ] := Value;
  Except
    On E: Exception do begin
      MessageDlg( 'Error in "TSingleESRIgrid.SetValue".', mtError, [mbOk], 0);
    end;
  end;
end;

Function TSingleESRIgrid.GetValueXY( const x, y: Single ): Single;
begin
  Result := MissingSingle;
  Try
    if IsValidXY( x, y ) then
      Result := GetValue( GetRowNrFromYcoord( y ), GetColNrFromXcoord( x )  );
  Except
  end;
end;


Procedure TSingleESRIgrid.GetValueNearXY( const x, y: Single; const MaxCellDepth: Integer; var CellDepth: Integer; var aValue: Single );
var
  Found: Boolean;
  cRow, cCol, Row, Col: Integer;
begin
  CellDepth := 0;
  aValue := MissingSingle;
  if IsValidXY( x, y ) then begin
    aValue := GetValueXY( x, y );
    Found := ( aValue <> MissingSingle );
    if ( ( not Found ) and ( MaxCellDepth > 0 ) ) then begin
      XYToWindowColRow( x, y, cRow, cCol );
      CellDepth := 1;
      Repeat
        Row := cRow -CellDepth;
        Repeat
          if ( ( Row > 0 ) and ( Row <= NRows ) ) then begin {-valid Rownr}
            Col := cCol-CellDepth;
            Repeat
              if ( ( Col > 0 ) and ( Col <= NCols ) ) then begin {-valid Colnr}
                aValue :=  Items[ Row, Col ];
                Found := ( aValue <> MissingSingle );
              end; {-if}
              Inc( Col );
            Until ( ( Found ) or ( Col > cCol+CellDepth ) )
          end; {-if}
          Inc( Row );
        until ( ( Found ) or ( Row > cRow+CellDepth ) );
        Inc( CellDepth );
      until ( ( Found ) or ( CellDepth > MaxCellDepth ) );
      CellDepth := min( CellDepth, MaxCellDepth );
    end; {-if}
  end;
end;

Function TSingleESRIgrid.AreaSum( const AreaGrid: PSingleESRIgrid; const MinAreaValue, MaxAreaValue,
             MinValue, MaxValue: Single; var AreaOfSelectedCells, SumOfValuesInArea, AverageOfValuesInArea: Double ): Boolean;
var
  i, j, k, iNRows, iNCols: Integer;
  x, y, AreaValue, aValue: Single;
begin
  Result := false;
  AreaOfSelectedCells := 0;
  SumOfValuesInArea := 0;
  AverageOfValuesInArea := 0;

  iNRows := NRows;
  iNCols := NCols;
  k := 0;
  for i:=1 to iNRows do begin
    for j:=1 to iNCols do begin
      GetCellCentre( i, j, x, y );
      if not ( AreaGrid^.IsValidXY( x, y ) ) then begin
        WriteToLogFileFmt( 'Point [%g, %g] is outside area grid', [x, y]);
        Result := false; Exit;
      end;
      AreaValue := AreaGrid^.GetValueXY( x, y );
      if ( AreaValue > MinAreaValue ) and ( AreaValue <= MaxAreaValue ) then begin
        aValue := GetValue( i, j );
        if ( aValue > MinValue ) and ( aValue <= MaxValue ) then begin
          Inc( k );
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

Procedure TSingleESRIgrid.AddConstant( const x: Single );
var
  i, j, iNRows, iNCols: Integer;
begin
  iNRows := NRows;
  iNCols := NCols;
  for i:=0 to iNRows-1 do
    for j:=0 to iNCols-1 do
      if ( SingleMatrix[ i, j ] <> MissingSingle ) then
            SingleMatrix[ i, j ] := SingleMatrix[ i, j ] + x;
end;

Procedure TSingleESRIgrid.SetToConstantValue( const x: Single );
var
  i, j, iNRows, iNCols: Integer;
begin
  iNRows := NRows;
  iNCols := NCols;
  for i:=0 to iNRows-1 do
    for j:=0 to iNCols-1 do
      if ( SingleMatrix[ i, j ] <> MissingSingle ) then
            SingleMatrix[ i, j ] := x;
end;

Procedure TSingleESRIgrid.MultiplyBy( const x: Single );
var
  i, j, iNRows, iNCols: Integer;
begin
  if ( x <> 1 ) then begin
    iNRows := NRows;
    iNCols := NCols;
    for i:=0 to iNRows-1 do
      for j:=0 to iNCols-1 do
        if ( SingleMatrix[ i, j ] <> MissingSingle ) then
              SingleMatrix[ i, j ] := SingleMatrix[ i, j ] * x;
  end;
end;

Function TSingleESRIgrid.FillWithCAPSIMdata( const iFileName,
  Node_Sim_Inp_file: TFileName ): Boolean;
var
  Save_Cursor: TCursor;
  f, g: TextFile;
  i, j, k, aIntegerValue: Integer;
  aSingleValue, x, y: Single;
begin
  Result := false;
  Save_Cursor := Screen.Cursor;
  Screen.Cursor := crHourglass;
  Try
    Try
    if not FileExists( iFileName ) then
      Raise E_Error_CAPSIM_File_Does_not_exist.CreateResFmt( @sE_Error_CAPSIM_File_Does_not_exist, [expandFileName( iFileName )] );

    if not FileExists( Node_Sim_Inp_file ) then
      Raise E_Error_CAPSIM_File_Does_not_exist.CreateResFmt( @sE_Error_CAPSIM_File_Does_not_exist, [expandFileName( Node_Sim_Inp_file )] );

    {$I-} AssignFile( f, iFileName ); Reset( f ); {I+}
    if ( IOResult <> 0 ) then
      Raise E_Error_opening_CAPSIM_File.CreateResFmt( @sE_Error_opening_CAPSIM_File, [expandFileName( iFileName )] );

    {$I-} AssignFile( g, Node_Sim_Inp_file ); Reset( g ); {I+}
    if ( IOResult <> 0 ) then
      Raise E_Error_opening_CAPSIM_File.CreateResFmt( @sE_Error_opening_CAPSIM_File, [expandFileName( Node_Sim_Inp_file )] );

    WriteToLogFileFmt( 'FillWithCAPSIMdata from file [%s].', [expandFileName( iFileName )] );
    k := 0;
    while ( not EOF( g ) ) do begin
      Inc( k );
      {$I-} Readln( g, aIntegerValue, aSingleValue, x, y ); {$I+}
      if ( IOResult <> 0 ) then
        Raise E_Error_reading_from_CAPSIM_File.CreateResFmt( @sE_Error_reading_from_CAPSIM_File, [k, expandFileName( Node_Sim_Inp_file )] );
      {$I-} Readln( f, aIntegerValue, aSingleValue ); {$I+}
      if ( IOResult <> 0 ) then
        Raise E_Error_reading_from_CAPSIM_File.CreateResFmt( @sE_Error_reading_from_CAPSIM_File, [k, expandFileName( iFileName )] );

      if IsValidXY( x, y ) then begin
        j := GetColNrFromXcoord( x );
        i := GetRowNrFromYcoord( y );
        SetValue( i, j, aSingleValue );
      end;
    end; {-while}
    Result := true;
    WriteToLogFile( 'all values are replaced bij CAPSIM data.' );
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    Screen.Cursor := Save_Cursor;
    Try {$I-} CloseFile( f ); CloseFile( g ); {$I+} except end;
  end;
end;


Function TSingleESRIgrid.SaveAsInteger( const iFileName: TFileName ): Integer;
var
  Channel, i, j, AccessWindowSetResult: Integer;
  Save_Cursor: TCursor;
  SaveFileName: AnsiString;
  Ptr: ^TCELLTYPE;
  aDoubleValue: Double;
  IntValue: Int16;
  SingleIntRow: Array of Integer;
  MyBndBox: TBndBox;
begin
  WriteToLogFile( 'TSingleESRIgrid.SaveAsInteger' );
  Result := cUnknownError;
  Save_Cursor := Screen.Cursor;
  Screen.Cursor := crHourglass;
  Try
    Try
      {-Open ESRI GRID raster dataset}
      SaveFileName := Trim( iFileName );
      if ( GridIOSetup < 0 ) then
        Raise Exception.CreateRes( @sErrorInitiating_IO_Library_for_ESRI_GRID_raster_datasets );
      WriteToLogFile( 'IO library for ESRI GRID raster datasets is initiated (GridIOSetup).' );
      if ( ( CellLyrExists( PAnsiChar( SaveFileName ) ) = cTRUE ) ) then  begin
        GridKill( PAnsiChar( SaveFileName ), 0 );
      end;
      MyBndBox := BndBox;
      channel := CellLayerCreate( PAnsiChar( SaveFileName ), cWRITEONLY, {cCELLIO}cROWIO, cCELLINT, CellSize, MyBndBox );
      if ( channel < 0 ) then Raise Exception.CreateResFmt( @sE_ESRI_GRID_raster_dataset_could_not_be_created,
            [SaveFileName] );
      AccessWindowSetResult := AccessWindowSet( MyBndBox, CellSize, MyBndBox );
      if ( AccessWindowSetResult < 0 ) then
        Raise Exception.CreateResFmt( @sErrorAccessWindowSetResult,
        [ExpandFileName( SaveFileName ), AccessWindowSetResult ] );
      WriteToLogFileFmt( 'AccessWindowSetResult OK:  [%d]', [AccessWindowSetResult] ) ;
      {-Allocate data}
      WriteToLogFile( 'Allocating data...' );

      SetLength( SingleIntRow, NCols );
      for i:=0 to NRows-1 do begin
        for j:=0 to NCols-1 do begin
          aDoubleValue := SingleMatrix[ i, j ];
          if not IsMissing( i+1, j+1 ) then
            SingleIntRow[ j ] := Trunc( EnsureRange( aDoubleValue, -MaxInt, MaxInt ) )
          else
            SingleIntRow[ j ] := MISSINGINT;
        end;
        Ptr := @SingleIntRow[ 0 ];
        PutWindowRow( channel, i, Ptr^ );
      end;
      SetLength( SingleIntRow, 0 );

      CellLyrClose(channel);
      WriteToLogFile( 'Done.' );
      Result := cNoError;
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    Screen.Cursor := Save_Cursor;
    Try
      GridIOExit;
    Except
    end;
  end;
end; {-Function TSingleESRIgrid.SaveAs}

Function TSingleESRIgrid.ExportToIDFfile( const iFileName: TFileName ): Integer;
var
  f: File;
  i, j, iNCols, iNRows, iNumber, NumWrite, Count: Integer;
  aNumber, anotherNumber, FxMin, FxMax, FyMin, FyMax, MinValue, MaxValue: Single;
  Save_Cursor: TCursor;
  aFileName: TFileName;

Procedure SetMinMaxValue;
var
 i, j, NCls, NRws: LongInt;
 aNumber: Single;
begin
  NCls := NCols;
  NRws := NRows;
  WriteToLogFileFmt( 'MissingSingle = %g', [MissingSingle] );
  MinValue := MissingSingle;
  MaxValue := MissingSingle;
  for i:=1 to NRws do begin
    for j:=1 to NCls do begin
      aNumber := GetValue( i, j );
      if ( aNumber <> MissingSingle ) then begin
        if ( MinValue <> MissingSingle ) then begin
          if ( aNumber < MinValue ) then
            MinValue := aNumber;
        end else
          MinValue := aNumber;
        if ( MaxValue <> MissingSingle ) then begin
          if ( aNumber > MaxValue ) then
            MaxValue := aNumber;
        end else
          MaxValue := aNumber;
      end;
    end;
  end;
end;

begin
  WriteToLogFile( 'Export TSingleESRIgrid (or descendant) to IDF-file.' );
  Save_Cursor := Screen.Cursor;
  Result := cUnknownError;
  Try
    Screen.Cursor := crHourglass;
    Try
      aFileName := ExpandFileName( iFileName );
      iNumber := 1271; aNumber := 0;
      AssignFile( f, aFileName ); Rewrite( f, 1 );
      BlockWrite( f, iNumber, SizeOf( Integer ), NumWrite );   {WriteToLogFileFmt( 1, ' ', iNumber );}
      iNCols := NCols;
      BlockWrite( f, iNCols, SizeOf( Integer ), NumWrite );
      iNRows := NRows;
      BlockWrite( f, iNRows, SizeOf( Integer ), NumWrite );
      FxMin := xMin;
      BlockWrite( f, FxMin, SizeOf( single ), NumWrite );
      FxMax := xMax;
      BlockWrite( f, FxMax, SizeOf( single ), NumWrite );
      FyMin := yMin;
      BlockWrite( f, FyMin, SizeOf( single ), NumWrite );
      FyMax := yMax;
      BlockWrite( f, FyMax, SizeOf( single ), NumWrite );
      SetMinMaxValue;
      BlockWrite( f, MinValue, SizeOf( single ), NumWrite ); {min}
      BlockWrite( f, MaxValue, SizeOf( single ), NumWrite ); {max}
      anotherNumber := IDFmissingSingle;
      BlockWrite( f, anotherNumber, SizeOf( single ), NumWrite );
      BlockWrite( f, aNumber, SizeOf( single ), NumWrite );    {WriteToLogFileFmt( 11, ' ', aNumber ); HEEFT BETEKENIS, MAAR WELKE???}
      aNumber := CellSize;
      BlockWrite( f, aNumber, SizeOf( single ), NumWrite );    {dx}
      BlockWrite( f, aNumber, SizeOf( single ), NumWrite );    {dy}

      Count := NCols * SizeOf( Single );
      for i:=0 to iNRows-1 do begin
        for j:=0 to iNCols-1 do begin
          if ( SingleMatrix[ i, j ] = MissingSingle ) then
            SingleMatrix[ i, j ] := IDFmissingSingle;
        end;
        BlockWrite( f, SingleMatrix[ i, 0 ], Count, NumWrite );
        for j:=0 to iNCols-1 do begin
          if ( SingleMatrix[ i, j ] = IDFMissingSingle ) then
            SingleMatrix[ i, j ] := missingSingle;
        end;
      end;

      WriteToLogFile( 'TSingleESRIgrid (or descendant) exported to IDF-file.' );
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    CloseFile( f );
    Screen.Cursor := Save_Cursor;
  end;
end; {-Function TSingleESRIgrid.ExportToIDFfile}

Function TSingleESRIgrid.ExportToUngPar( const iFileName: TFileName; const newBndBox: TBndBox;
  const Pol: TSingleESRIgrid; const DataRatio: Double ): Integer;
var
  i, j,
  OffSetRow, OffSetCol, EndRow, EndCol, iCount: Integer;
  Save_Cursor: TCursor;
  UngFileName, ParFileName: TFileName;
  f, g: TextFile;
    Procedure WriteUngParValue( const Row, Col: Integer; var iCount: Integer );
    var
      x, y: Single;
      aValue: Single;
      Function PointIsSelected( const Row, Col: Integer ): Boolean;
      var
        Dichtheidsverhouding: Double;
      begin
        Result := False;
        aValue := GetValue( i, j );
        if ( aValue <> MissingSingle ) then begin
          GetCellCentre( Row, Col, x, y );
          Dichtheidsverhouding := Sqr( CellSize ) / Sqr( Pol.GetValueXY( x, y ) );
          Result := Random < ( Dichtheidsverhouding * DataRatio );
        end;
      end;
  begin
    if PointIsSelected( Row, Col ) then begin
      Inc( iCount );
      Writeln( g, iCount, ' ', aValue );
      GetCellCentre( Row, Col, x, y );
      Writeln( f, iCount, ' ', x:8:1, ' ', y:8:1 );
    end;
  end;
begin
  WriteToLogFile( 'TSingleESRIgrid.ExportToUngPar' );
  Result := cUnknownError;
  Save_Cursor := Screen.Cursor;
  Screen.Cursor := crHourglass;
  Try
    Try
      UngFileName := ChangeFileExt( Trim( iFileName ), '.ung' );
      ParFileName := ChangeFileExt( UngFileName, '.par' );
      AssignFile( f, UngFileName ); Rewrite( f );
      AssignFile( g, ParFileName ); Rewrite( g );

      OffSetRow := GetRowNrFromYcoord( NewBndBox[cymax] - 0.5*CellSize ); WriteToLogFileFmt( 'OffSetRow= %d', [OffSetRow] );
      EndRow := GetRowNrFromYcoord( NewBndBox[cymin] + 0.5*CellSize );    WriteToLogFileFmt( 'EndRow= %d', [EndRow] );
      OffSetCol := GetColNrFromXcoord( NewBndBox[cxmin] + 0.5*CellSize ); WriteToLogFileFmt( 'OffSetCol= %d', [OffSetCol] );
      EndCol := GetColNrFromXcoord( NewBndBox[cxmax] - 0.5*CellSize ); WriteToLogFileFmt( 'EndCol= %d', [EndCol] );

      {-Allocate data}
      WriteToLogFile( 'Allocating data...' );
      iCount := 0;
      Randomize;
      for i:=OffSetRow to EndRow do begin
        for j:=OffSetCol to EndCol do begin
          WriteUngParValue( i, j, iCount );
        end;
      end;
      Writeln( f, 'END' );

      WriteToLogFileFmt( 'Done. Nr. of values written: %d', [iCount] );
      Result := cNoError;
    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    Screen.Cursor := Save_Cursor;
    Try
      CloseFile( f ); CloseFile( g );
    Except
    end;
  end;
end; {-Function TSingleESRIgrid.ExportToUngPar}

Constructor TSingleESRIgrid.InitialiseFromIDFfile( const iFileName: TFileName;
  var iResult: Integer; AOwner: TComponent );
var
  f: File;
  i, j, iNCols, iNRows, iNumber, NumRead, Count, NrOfMissingSingles: Integer;
  aNumber, FxMin, FxMax, FyMin, FyMax, FMissingSingle: Single;
  Save_Cursor: TCursor;
begin
  WriteToLogFile( 'Initialise TSingleESRIgrid (or descendant) from IDF-file.' );
  Save_Cursor := Screen.Cursor;
  iResult := cUnknownError;
  Try
    Screen.Cursor := crHourglass;
    Try
      FileName := ExpandFileName( iFileName );
      AssignFile( f, FileName ); Reset( f, 1 );
      BlockRead( f, iNumber, SizeOf( Integer ), NumRead );   WriteToLogFileFmt( '1 %d', [iNumber] );
      BlockRead( f, iNCols, SizeOf( Integer ), NumRead );    WriteToLogFileFmt( '2 %d', [iNCols] );
      BlockRead( f, iNRows, SizeOf( Integer ), NumRead );    WriteToLogFileFmt( '3 %d', [iNRows] );
      BlockRead( f, FxMin, SizeOf( single ), NumRead );  xMin := FxMin;  WriteToLogFileFmt( '4 %g', [FxMin] );
      BlockRead( f, FxMax, SizeOf( single ), NumRead );  xMax := FxMax;  WriteToLogFileFmt( '5 %g', [FxMax] );
      BlockRead( f, FyMin, SizeOf( single ), NumRead );  yMin := FyMin;  WriteToLogFileFmt( '6 %g', [FyMin] );
      BlockRead( f, FyMax, SizeOf( single ), NumRead );  yMax := FyMax;  WriteToLogFileFmt( '7 %g', [FyMax] );
      BlockRead( f, aNumber, SizeOf( single ), NumRead ); {min} WriteToLogFileFmt( '8 %g', [aNumber] );
      BlockRead( f, aNumber, SizeOf( single ), NumRead ); {max} WriteToLogFileFmt( '9 %g', [aNumber] );
      BlockRead( f, FMissingSingle, SizeOf( single ), NumRead ); WriteToLogFileFmt( '10 %g', [FMissingSingle] );
      WriteToLogFileFmt( 'FMissingSingle = %g.', [FMissingSingle] );
      BlockRead( f, aNumber, SizeOf( single ), NumRead );    WriteToLogFileFmt( '11 %g',[aNumber] );
      BlockRead( f, aNumber, SizeOf( single ), NumRead );    {dx}  WriteToLogFileFmt( '12 %g', [aNumber] );
      BlockRead( f, aNumber, SizeOf( single ), NumRead );    {dy}  WriteToLogFileFmt( '13 %g', [aNumber] );
      CellSize := aNumber;

      if not AllocateMemory( iNRows, iNCols )  then
        Raise Exception.CreateRes( @sE_Error_Initialising_TSingleESRIgrid_Descendant_From_File );

      Count := iNCols * SizeOf( Single );
      for i:=0 to iNRows-1 do
        BlockRead( f, SingleMatrix[ i, 0 ], Count, NumRead );

      NrOfMissingSingles := 0;
      for i:=0 to iNRows-1 do
        for j:=0 to iNCols-1 do
          if ( SingleMatrix[ i, j ] = FMissingSingle ) or ( SingleMatrix[ i, j ] = IDFmissingSingle ) then begin
            SingleMatrix[ i, j ] := MissingSingle;
            Inc( NrOfMissingSingles );
          end;
      WriteToLogFileFmt( 'NrOfMissingSingles= %d', [NrOfMissingSingles] );

      WriteCharacteristicsToLogFile;

      WriteToLogFile( 'TSingleESRIgrid (or descendant) initialised from IDF-file.' );

      iResult := cNoError;

    Except
      On E: Exception do begin
        HandleError( E.Message, true );
      end;
    end;
  Finally
    CloseFile( f );
    Screen.Cursor := Save_Cursor;
  end;
end;

Function TSingleESRIgrid.ReadRowFromTextFile( var f: TextFile;
  const RowNr: Integer; const ASCNoDataValue: Double ): Boolean;
var
  j, iNCols: Integer;
  aValue: Double;
begin
  Result := false;
  iNCols := NCols;
  // ShowMessage( 'ASCNoDataValue, MissingSingle = ' + FloatToStr( ASCNoDataValue ) +
  //  FloatToSTr( MissingSingle ) );

  Try
    for j := 0 to iNCols-1 do begin
      Read( f, aValue );
      if ( aValue = ASCNoDataValue ) then begin
        SingleMatrix[ RowNr-1, j ] := MissingSingle;
//        ShowMessage( 'Set to missing single' + FloatToStr( aValue ) );
      end else begin
        SingleMatrix[ RowNr-1, j ] := aValue;
//        ShowMessage( 'not set to missing single ' + FloatToStr( aValue ) );
      end;
    end;
    Result := true;
  Except
  End;
end;

Function TSingleESRIgrid.PutWindowRowToChannel( const Channel, RowNr: Integer ): Boolean;
var
  Ptr: ^TCELLTYPE;
begin
  Result := true;
  Try
    Ptr := @SingleMatrix[RowNr - 1, 0];
    PutWindowRow( Channel, RowNr-1, Ptr^ );
  Except
    Result := false;
  End;
end;

procedure Register;
begin
  RegisterComponents('MyComponents', [TSingleESRIgrid]);
end;

begin
 with FormatSettings do begin {-Delphi XE6}
   Decimalseparator := '.';
 end;
end.
